#
# bibliography package for Perl
#
# Auto format recognizer routines.
#
# Note that this package is intimately tied to the internals of the main
# package.  Most format packages will _not_ look like this one.  Since this
# does automatic recognition, it needs to change what the main package
# thinks the format of the file is.
#
# The basic idea is that we define open and openwrite, which they call on
# some file.  We then determine the real format of the file (either by name,
# or by slogging through it trying to guess at the type <not implemented yet>)
# and then change the main package's pointers for this file to point to the
# real type.  So we shouldn't ever be called again for that file.
#
# Dana Jacobsen (dana@acm.org)
# 14 January 1995  (last modified on 21 Jan 1996)
#

package bp_auto;

######

&bib'reg_format(
  'auto',    # name
  'aut',     # short name
  'bp_auto', # package name
  'auto',    # default character set
  'suffix is bib',    # <--- This must match the default format.
# functions
  'options',
  'open',
  'close      is unsupported',
  'read       is unsupported',
  'write      is unsupported',
  'explode    is unsupported',
  'implode    is unsupported',
  'tocanon    is unsupported',
  'fromcanon  is unsupported',
  'clear',
);

######

$opt_complex = 1;

$opt_default_format = 'bibtex';

######

sub options {
  local($opts) = @_;

  print "setting options to $opts\n";
}

######

sub autoformat {
  local($file) = @_;
  local($fmt) = undef;

  return $opt_default_format  if $opt_complex == 0;
  if ($opt_complex == 1) {
    # XXXXX We should use the i_suffix fields from each format for this.
    #       But...  that would mean loading in _every_ format just so we
    #       can check these out.  That's too painful.
    $file =~ /\.bib$/  && return 'bibtex';
    $file =~ /\.ref$/  && return 'refer';
    $file =~ /\.tib$/  && return 'tib';
    $file =~ /\.pow$/  && return 'powells';
    $file =~ /\.pro$/  && return 'procite';
    $file =~ /\.med$/  && return 'medline';
    $file =~ /\.html?$/ && return 'html';
    $file =~ /\.mel$/  && return 'melvyl';
    $file =~ /\.txt$/  && return 'text';
    $file =~ /\.rfc1807$/ && return 'rfc1807';
  } elsif ($opt_complex == 2) {
    # autorecognize by open, read, close
    # XXXXX This will be pretty complicated....
    #       First, we should check all the formats we have already loaded.
    #       Next, call find_bp_files and get the list of supported formats,
    #       then call their auto-recognize functions if they have one.
    return &bib'goterror("auto format complexity level 2 is not implemented");
  } else {
    &bib'panic("format auto has invalid complexity level");
  }

  $fmt;
}

######

sub open {
  local($file) = @_;
  local($name, $mode);
  local($func, $fmt, $cset);

  &bib'panic("auto format open called with no arguments") unless defined $file;

  # get the name and mode
  if ($file =~ /^>>(.*)/) {
    $mode = 'append';  $name = $1;
  } elsif ($file =~ /^>(.*)/) {
    $mode = 'write';   $name = $1;
  } else {
    $mode = 'read';    $name = $file;
  }

  #
  #   1) determine the format of the file
  #
  if ($mode eq 'read') {
    $fmt = &autoformat($name);
    $fmt = $bib'glb_Irfmt{$bib'glb_Ifilename}  unless defined $fmt;
  } else {
    if ( $opt_complex == 1 ) {
      $fmt = &autoformat($name);
    } else {
      $fmt = undef;
    }
    # Try the format we last wrote
    $fmt = $bib'glb_Orfmt{$bib'glb_Ofilename}  unless defined $fmt;
    # Hmm.  How about the format we just read?
    $fmt = $bib'glb_Irfmt{$bib'glb_Ifilename}  unless defined $fmt;
  }
  if (!defined $fmt) {
    $fmt = $opt_default_format;
    &bib'gotwarn("auto format using default format $fmt for $file")
  }

  # if there is no default, and we don't know the type, then we lose.
  return &bib'goterror("Auto format cannot determine type of name")
    unless defined $fmt;

  &bib'debugs("auto step 1: $name<$fmt> with mode $mode", 8192, 'module');

  #
  #   2) make sure the real format is loaded
  #
  #      This also a) makes sure we have the right name
  #            and b) sets the character set to the format's default
  #
  # XXXXX sure this is the right cset to load?
  return undef unless ($fmt, $cset) = &bib'load_format($fmt);

  &panic("auto charset recognition is unimplemented") if $cset eq 'auto';

  &bib'debugs("auto step 2: $name<$fmt:$cset>", 32, 'module');

  #
  #   3) open the file using the real format
  #
  $bib'glb_current_fmt = $fmt;
  $func = $bib'formats{$fmt, "open"};
  $fmt = &$func($file);
  return undef unless defined $fmt;

  &bib'debugs("auto step 3: $name<$fmt:$cset>", 32, 'module');

  #
  #   4) return the real format and character set
  #

  $fmt .= ':' . $cset;

  $fmt;
}

######

######

sub clear {
  # for now, we don't do anything
  1;
}





#######################
# end of package
#######################

1;