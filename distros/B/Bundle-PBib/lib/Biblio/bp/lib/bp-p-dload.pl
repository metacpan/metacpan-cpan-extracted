#
# bibliography package for Perl
#
# The dynamic format and character set loading.
#
# Dana Jacobsen (dana@acm.org)
# 22 January 1995 (last modified 14 March 1996)


# load_format safely loads a format.  It calls goterror if it can't find the
# format, and returns that result (undef).  Be sure to check the result!  It
# is not meant for users to call (although it doesn't hurt anything).
#
# It also loads a character set -- either the default for the format, or one
# asked for by name.
#
# It returns an array of two values:
#    the format name, appropriate for use with the formats array
#    the cset name, for use with the charsets array
#
# Thus, load_format will find, say "myRefer" and return "refer" if that is
# how the format is installed.
#
#  XXXXX Should we install them as the name they gave us, or the format's name?
#  XXXXX How about changing this so we can load formats like:
#         '/usr/local/lib/formats/refer"
#  XXXXX Added options as "format/opt1/opt2:cset"
#        We don't support cset options, and won't until csets are 1st class.
#
sub load_format {
  local($format) = @_;
  local($fmt, $cset);
  local(@opts);

  &panic("load_format called with no arguments") unless defined $format;

#  print "load_format $format\n";
  ($fmt, $cset) = &parse_format($format);

  &debugs("fmt: $fmt, cset: ".&okprint($cset), 16384);

  # check the common case first
  if (    (defined $formats{$fmt, 'i_name'})
       && (!defined $cset)
       && ($fmt !~ /\//)
      ) {
    return ($formats{$fmt, 'i_name'}, $formats{$fmt, 'i_charset'});
  }

  while ($fmt =~ s/\/([^\/]+)$//) {
    push(@opts, $1);
  }
  &debugs("loading format $fmt...", 1024);
  $glb_current_fmt = $fmt;
  # XXXXX  Should we set the error level to die before doing this?
  $func = "require \"$glb_bpprefix$fmt.pl\";";
  eval $func;
  if ($@) {
    if ($@ =~ /^Can't locate $glb_bpprefix/) {
      return &goterror("format $fmt is not supported.");
    }
    if ($@ =~ /^bp error /) {
      print STDERR $@;
      return &goterror("error in format $fmt", "module");
    }
    return &goterror("error in format $fmt: $@", "module");
  }

  if (@opts) {
    $func = $formats{$fmt, "options"};
    local($opt, $ret);
    foreach $opt (@opts) {
      $ret = &$func($opt);
      next if defined $ret;
      &gotwarn("Unknown $fmt option: $opt");
    }
  }

  # We make sure our format name is the right one.
  # XXXXX right now we don't do anything.  We should get this from register.

  # use the format's default character set unless they asked for one.
  $cset = $formats{$fmt, 'i_charset'} unless defined $cset;

  # XXXXX We will die right here if the charset isn't named correctly

  $cset = &load_charset($cset);

  &debugs("loaded format $fmt, cset $cset", 1024);

  ($fmt, $cset);
}

#
# This loads a character set.  It returns the correct name of the character
# set.
#
sub load_charset {
  local($cset) = @_;

  &panic("load_charset called with no arguments") unless defined $cset;

  &debugs("cset: $cset", 8192);

  return $cset if defined $charsets{$cset, 'i_name'};

  # XXXXX auto charset is unimplemented, so don't try to load it
  return $cset if $cset eq "auto";

  &debugs("loading charset $cset...", 1024);
  $glb_current_cset = $cset;
  $func = "require \"${glb_bpprefix}cs-$cset.pl\";";
  eval $func;
  if ($@) {
    if ($@ =~ /^Can't locate $glb_bpprefix/) {
      return &goterror("character set $cset is not supported.");
    }
    return &goterror("error in character set $cset: $@", "module");
  }
  # XXXXX get real name from register
  &debugs("loaded charset $cset", 1024);
  $cset;
}

#
# load_converter returns either the name of the converter or undef.
#
sub load_converter {
  local($conv) = @_;

  &panic("load_converter called with no arguments") unless defined $conv;

  &debugs("conv: $conv", 8192);

  return $conv if defined $special_converters{$conv, 'i_name'};
  
  &debugs("loading converter $conv...", 1024);
  $func = "require \"${glb_bpprefix}c-$conv.pl\";";
  eval $func;
  if ($@) {
    if ($@ =~ /^Can't locate $glb_bpprefix/) {
      &debugs("converter $conv not found", 1024);
      return undef;
    } else {
      return &goterror("error in converter $glb_cvtname: $@", "module");
    }
  }
  &debugs("loaded converter $conv", 1024);
  $conv;
}

######

sub find_bp_files {
  local($rehash) = @_;

  if ( (defined $rehash) && ($rehash eq 'rehash') ) {
    undef $glb_supported_files;
  }

  if (!defined $glb_supported_files) {
    local(*DIR);
    local(@bpfiles);
    local($path, $fmts, $csets);
    local(%uniar);

    foreach $path (@INC) {
      opendir(DIR, $path);
      push(@bpfiles, grep(/^${glb_bpprefix}.*\.pl$/, readdir(DIR)) );
      closedir(DIR);
    }
    # remove the header and trailer stuff
    grep(s/^${glb_bpprefix}(.*)\.pl$/$1/, @bpfiles);

    # remove our packages
    @bpfiles = grep(!/^p-\w+$/, @bpfiles);
    # remove styles
    @bpfiles = grep(!/^s-\w+$/, @bpfiles);

    # weed out duplicates (if packages are in multiple paths)
    @bpfiles = grep($uniar{$_}++ == 0, @bpfiles);

    # now return formats and csets
    $fmts  = join(" ", sort grep(!/^cs-/, @bpfiles));
    $csets = join(" ", sort grep(s/^cs-//, @bpfiles));

    $glb_supported_files = join("\000", $fmts, $csets);
  }

  split("\000", $glb_supported_files);
}

######

#
# The format registry subroutine.
#
# When a format starts up, it calls this routine, which registers all its
# exported procedures to bp.  If any of the necessary functions are not
# given as arguments, they will default to the stdbib routines.  If you
# know about a stdbib routine, it is suggested that you actually call this
# using the "foo is standard" method of registering foo, so people can see
# right off that you mean it, not that you just forgot.  This also allows
# us to add functions (for example, maybe "readcanon" that reads right into
# canonical format) and then define a stdbib routine that would do the
# equivalent the long way around.  Your module continues to work, because
# the registry will see that you didn't define one, and set up the mapping.

# There are seven different formats for the function registry:
#
#   "read is standard"      registers read as the standard read routine.
#   "read"                  registers read as your function of the same name.
#   "read uses format"      registers read as format's read.
#   "read as myread"        registers read as your function named "myread".
#   "read as pkg'myread"    registers read as the function "pkg'myread".
#   "read is unsupported"   registers read as an unsupported function.
#   "read is unimplemented" registers read as an unimplemented function.
#
# Examples:
#  "write is standard"
#        Our format is going to use the standard write function, which prints
#        the record with a single empty line after it.
#  "read"
#        Our format has it's own read function, declared with "sub read".
#  "read uses refer"
#        Our format will use whatever read function the refer format uses to
#        do its reading.  This will also take care of loading the refer format
#        for you.  Use this style when your format has a lot of similarities
#        to one particular format.  Don't use it otherwise, as it would waste
#        time and memory loading a format that isn't needed.
#  "read as lukea"
#        Just in case you like naming your functions in Finnish, for example.
#  "read as bp_refer'read"
#        Not really recommended, but this lets you give the full name of the
#        function you want called.
#  "read is unsupported"
#        This makes it explicit to anyone looking at your module code that
#        you purposely do not support this function.  It sets any call to
#        this routine to code that returns an error message about the
#        procedure not being supported.
#  "read is unimplemented"
#        This makes it explicit to anyone looking at your module code that
#        you have not finished coding this function.  Similarly to the
#        unsupported option, this produces an error message about the procedure
#        having not yet been implemented.
#
# For the unsupported and unimplemented calls, you may also wish to define
# your own call that does the same thing but gives more information.
#

# On success, we return 1.  If we couldn't parse your strings, or one of the
# functions given doesn't exist, we return undef.  Your format should return
# undef if you are unable to register yourself.

# XXXXX document suffix registration

sub reg_format {
  local($lname, $sname, $pname, $cname, @rest) = @_;

  &panic("reg_format called with no longname")        unless defined $lname;
  &panic("reg_format called with no shortname")       unless defined $sname;
  &panic("reg_format called with no package name")    unless defined $pname;
  &panic("reg_format called with no default charset") unless defined $cname;
  &panic("Format $lname already registered") if defined $formats{$lname, 'i_name'};

  &debugs("registering format $lname:$cname ($sname) in $pname", 16384);

  $formats{$lname, 'i_name'}    = $lname;
  $formats{$lname, 'i_sname'}   = $sname;
  $formats{$lname, 'i_package'} = $pname;
  $formats{$lname, 'i_charset'} = $cname;

  # Go through all of our functions, and assign to stdbib.

  foreach $f ( @glb_expfuncs ) {
    $formats{$lname, $f} = "bib'${f}_stdbib";
  }

  # next, walk through all the arguments they gave us

  local($f, $p, $as, $uses, $inst);
  local(%seen);  # check for duplicate definitions
  foreach (@rest) {
    $inst = undef;
    s/\s+/ /g; # so the string can be spaced however one wants
    if ( ($f) = /^suffix is (\w+)$/) {
      $formats{$lname, 'i_suffix'} = $f;
      next;
    } elsif ( ($f) = /^(\w+) is standard$/) {
      $inst = "bib'${f}_stdbib";
    } elsif ( ($f, $p) = /^(\w+) is unimplemented$/) {
      $inst = "bib'${f}_unimpl_stdbib";
      if (!defined &$inst) {
        $inst = "bib'generic_unimpl_stdbib";
      }
    } elsif ( ($f, $p) = /^(\w+) is unsupported$/) {
      $inst = "bib'${f}_unsup_stdbib";
      if (!defined &$inst) {
        $inst = "bib'generic_unsup_stdbib";
      }
    } elsif ( ($f) = /^(\w+)$/) {
      $inst = $pname . "'" . $f;
    } elsif ( ($f, $uses) = /^(\w+) uses (\w+)$/) {
      if (!defined $formats{$uses, $f}) {
        return &goterror("Could not load format $uses") unless &load_format($uses);
      }
      $inst = $formats{$uses, $f};
    } elsif ( ($f, $p, $as) = /^(\w+) as (\w+)'(\w+)$/) {
      $inst = $p . "'" . $as;
    } elsif ( ($f, $as) = /^(\w+) as (\w+)$/) {
      $inst = $pname . "'" . $as;
    } else {
      return &goterror("Format register unable to parse '$_'", $glb_current_fmt);
    }
    return &goterror("Tried to register unknown function $f", $glb_current_fmt)
           unless defined $formats{$lname, $f};
    return &bib'goterror("$f function '$inst' does not exist", $glb_current_fmt)
           unless defined &$inst;
    return &bib'goterror("duplicate registration of function $f", $glb_current_fmt)
           if defined $seen{$f};
    $seen{$f} = 1;
    $formats{$lname, $f} = $inst;
  }
  foreach $f ( @glb_expfuncs ) {
    &debugs("$lname registered $f as $formats{$lname, $f}", 16);
    #printf STDERR "%-12s registered to $lname as %s\n", $f, $formats{$lname, $f};
    &gotwarn("Using default behavior for function $f", $glb_current_fmt)
       unless defined $seen{$f};
  }
  $formats{$lname, 'i_suffix'} = $sname unless defined $formats{$lname, 'i_suffix'};

  1;
}

# XXXXX We should have an "unreg_format" function to unregister a format.
#       This could be used to remap formats through an option.

1;
