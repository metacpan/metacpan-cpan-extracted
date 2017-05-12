#
# bibliography package for Perl
#
# debugging subroutines
#
# Dana Jacobsen (dana@acm.org)
# 14 January 1995

##################
#
# Debugging code.  We handle assertions, panics with variable dumps,
# debugging statements (with variable levels), consistency checks, and
# variable dumping.
#

# This is assert.pl by Tom Christiansen, but changed slightly.
#
# We should use:
#
#     &panic("function called with no arguments") unless defined $foo;
#
# instead, if that's what you're doing.  First, it's quite a bit faster,
# and second, because panic can be changed to give a usage message.
#

sub assert {
  &panic("Assertion failed: $_[$[]",$@) unless eval $_[$[];
}

sub panic {
  select(STDERR);
  print "\nBP ERROR: @_\n";

  if ($] >= 5.000) {
    local($i,$_);
    local($p,$f,$l,$s,$h,$w,$a,@a,@sub);
    for ($i = 1; ($p,$f,$l,$s,$h,$w) = caller($i); $i++) {
      @a = @DB'args;
      for (@a) {
            if (/^StB\000/ && length($_) == length($_main{'_main'})) {
                $_ = sprintf("%s",$_);
            }
            else {
                s/'/\\'/g;
                s/([^\0]*)/'$1'/ unless /^-?[\d.]+$/;
                s/([\200-\377])/sprintf("M-%c",ord($1)&0177)/eg;
                s/([\0-\37\177])/sprintf("^%c",ord($1)^64)/eg;
            }
      }
      $w = $w ? '@ = ' : '$ = ';
      $a = $h ? '(' . join(', ', @a) . ')' : '';
      push(@sub, "$w&$s$a from file $f line $l");
    }
    print join("\n", @sub), "\n";
  }
  &debug_dump('all');
  exit 1;
}


# debugging statement.  Use level for increasing severity.

sub debugs {
  local($statement, $level, $mod) = @_;
  local($debl);

  &panic("debugging called with no arguments")  unless defined $statement;
  &panic("debugging called with no level")      unless defined $level;

  $debl = (defined $mod) ? $glb_moddebug : $glb_debug;

  # False
  return if $debl == 0;
  # True
  return if (  ($debl == 1)  &&  ($opt_default_debug_level > $level)  );
  # some number
  return if $debl > $level;

  local($p,$f,$l,$s,$h,$w);
  if ($] >= 5.000) {
    ($p,$f,$l,$s,$h,$w) = caller(1);
    $s = '' unless defined $s;  # to initialize
    $s =~ s/^bib:://;
  } else {
    # sigh -- caller is broken in perl 4 apparently, so make the best of it
    if (defined $mod) {
      $s = 'mod ' . $glb_current_fmt;
    } else {
      ($p,$f,$l) = caller;
      if ($p ne 'bib') {
        $s = 'pkg ' . $p;
      } else {
        substr($f, 0, rindex($f, '/')+1) = '' if $f =~ /\//;
        if ($f eq 'bp.pl') {
          $s = 'bp';
        } else {
          # if it's one of our packages, strip the header/trailer
          $f =~ s/^${glb_bpprefix}p-(\w+)\.pl/$1/;
          $s = $f;
        }
      }
    }
  }

  local($width) = 16 - &log2($level);

  printf STDERR "BPD: (%14s) %s%s\n", $s, ' ' x $width, $statement;
}

sub log2 {
  log($_[$[]) / log(2);
}


#
# Consistency checker.
#
# This is called in various spots throughout the package, usually before and
# after opening and closing a file, and when changing formats.  This will
# probably go with the production version, but just called fewer times.  It's
# not that long right now, and it doesn't get called often.
#
# The more assertions and double checks here, the better.

sub check_consist {
  local(@incons);
  local(%aainter);

  &debugs("Checking bp variable consistency", 8192);

  # if we're at our maximum debugging level, then spit out copious information
  # each time we're here.
  &debug_dump('all') if $glb_debug == 2;

  local(@ifiles, @ofiles);
  @ifiles = (keys %glb_Irfmt, keys %glb_Ircset, keys %glb_Ifilemap, keys %glb_filelocmap);
  @ofiles = (keys %glb_Orfmt, keys %glb_Orcset, keys %glb_Ofilemap);

  undef %aainter;
  @ifiles = grep($aainter{$_}++ == 0, @ifiles);
  undef %aainter;
  @ofiles = grep($aainter{$_}++ == 0, @ofiles);
  undef %aainter;

  foreach $file (@ifiles) {
    push(@incons, "filelocmap{$file} is undefined") unless defined $glb_filelocmap{$file};

    if (!defined $glb_Irfmt{$file}) {
      push(@incons, "Irfmt{$file} is undefined");
    } else {
      push(@incons, "file: $file has no format: " . &okprint($glb_Irfmt{$file}))
          unless defined $formats{$glb_Irfmt{$file}, 'i_name'};
    }
    if (!defined $glb_Ircset{$file}) {
      push(@incons, "Ircset{$file} is undefined");
    } else {
      push(@incons, "file: $file has no cset: " . &okprint($glb_Ircset{$file}))
          unless defined $charsets{$glb_Ircset{$file}, 'i_name'};
    }
    push(@incons, "filemap{$file} is undefined") unless defined $glb_Ifilemap{$file};
  }
  foreach $file (@ofiles) {
    if (!defined $glb_Orfmt{$file}) {
      push(@incons, "Orfmt{$file} is undefined");
    } else {
      push(@incons, "file: $file has no format: " . &okprint($glb_Orfmt{$file}))
          unless defined $formats{$glb_Orfmt{$file}, 'i_name'};
    }
    if (!defined $glb_Orcset{$file}) {
      push(@incons, "Orcset{$file} is undefined");
    } else {
      push(@incons, "file: $file has no cset: " . &okprint($glb_Orcset{$file}))
          unless defined $charsets{$glb_Orcset{$file}, 'i_name'};
    }
    push(@incons, "filemap{$file} is undefined") unless defined $glb_Ofilemap{$file};
  }

  local($format, $function);
  local(%aaformats);
  foreach $fmts (keys %formats) {
    ($format, $function) = split(/$;/, $fmts);
    $aaformats{$format} = 1;
  }
  foreach $fmt (keys %aaformats) {
    if (!defined $formats{$fmt, 'i_name'}) {
      push(@incons, "format $fmt has no i_name");
    } elsif ( $formats{$fmt, 'i_name'} ne $fmt ) {
      # This one might be questionable, as we allow this, but it is confusing.
      push(@incons, "format $fmt calls itself $formats{$fmt, 'i_name'}");
    }
    push(@incons, "format $fmt has no i_sname") unless defined $formats{$fmt, 'i_sname'};
   #push(@incons, "format $fmt has no i_charset") unless defined $formats{$fmt, 'i_charset'};

    foreach $f ( @glb_expfuncs ) {
      if (defined $formats{$fmt, $f}) {
        $function = $formats{$fmt, $f};
        push(@incons, "format $fmt routine $f ($function) isn't defined")
           unless defined &$function;
      } else {
        push(@incons, "format $fmt missing sub $f");
      }
    }
  }

  # XXXXX check that each function in charsets, and special_converters
  #       is actually defined.

  if (@incons) {
   #@incons = grep($aainter{$_}++ == 0, @incons);
   #undef %aainter;
    print STDERR "---------------- BP package inconsistencies ----------------\n";
    print STDERR join("\n", @incons), "\n";
    print STDERR "------------------------------------------------------------\n";
    return 0;
  }
  undef %aainter;
  undef %aaformats;
  1;
}


sub debug_dump {
  local($what) = @_;
  local($file);
  local($name);

  if ($what =~ /\bconsist\w*\b/) {
    &check_consist;
  } else {
    # for now, do everything.
    local($oldfh);
    $oldfh = select(STDERR);
    print "---------------- Debugging dump ----------------\n";

    print "debug:       ", &okprint($glb_debug), " : ", &okprint($glb_moddebug), "\n";
  # print "prefix:      ", &okprint($glb_bpprefix), "\n";
    print "Iformat:     ", &okprint($glb_Iformat), "\n";
    print "Oformat:     ", &okprint($glb_Oformat), "\n";
    print "current fmt: ", &okprint($glb_current_fmt), "\n";
    print "current fh:  ", &okprint($glb_current_fh), "\n";
    print "Ifilename:   ", &okprint($glb_Ifilename), "\n";
    print "Ofilename:   ", &okprint($glb_Ofilename), "\n";
    print "vloc:        ", &okprint($glb_vloc), "\n";
    print "cvtname:     ", &okprint($glb_cvtname), "\n";
    printf "warn  level %d with %d warnings\n",
          &okprint($glb_warn_level),  &okprint($glb_num_warns);
    printf "error level %d with %d errors\n",
          &okprint($glb_error_level), &okprint($glb_num_errors);

    local(@ifnames, @ofnames, @fnames, @cnames);

    print "files:       file      format     charset locmap           handle\n";
    @ifnames = sort keys %glb_Irfmt;
    @ofnames = sort keys %glb_Orfmt;
    foreach $file (@ifnames) {
      printf "     < %10s  %10s  %10s  %5s  %15s\n", $file,
             &okprint($glb_Irfmt{$file}), &okprint($glb_Ircset{$file}),
             &okprint($glb_filelocmap{$file}), &okprint($glb_Ifilemap{$file});
    }
    foreach $file (@ofnames) {
      printf "     > %10s  %10s  %10s  %10s  %15s\n", $file,
             &okprint($glb_Orfmt{$file}), &okprint($glb_Orcset{$file}),
             '', &okprint($glb_Ofilemap{$file});
    }
    if ( (!@ifnames) && (!@ofnames) ) {
      print "       (none)\n";
    }

    print "formats:       name sname   charset     package\n";
    @fnames = sort grep(/i_name$/, keys %formats);
    if (@fnames) {
      foreach $fname (@fnames) {
        $name = $formats{$fname};
        printf "         %10s (%s)  %8s  %10s\n",
               &okprint($name),
               &okprint($formats{$name, 'i_sname'}),
               &okprint($formats{$name, 'i_charset'}),
               &okprint($formats{$name, 'i_package'});
      }
    } else {
      print "            (none)\n";
    }

    print "converters:\n";
    @cnames = sort grep(/i_name$/, keys %special_converters);
    if (@cnames) {
      foreach $fname (@cnames) {
        $name = $special_converters{$fname};
        printf "         %10s\n",
               &okprint($name);
      }
    } else {
      print "            (none)\n";
    }

    local($fmts, $csets) = &find_bp_files();
    print "found fmts:  $fmts\n";
    print "found csets: $csets\n";

    # XXXXX dump filemap

    # XXXXX dump formats and charsets

    print "------------------------------------------------\n";
    select($oldfh);
  }
}



sub okprint {
  return '<undef>' unless defined $_[0];
  $_[0];
}

1;
