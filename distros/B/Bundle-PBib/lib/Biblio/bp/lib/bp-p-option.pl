#
# bibliography package for Perl
#
# options and documentation
#
# Dana Jacobsen (dana@acm.org)
# 12 January 1995  (last modified on 18 January 1996)

sub stdargs {
  local(@oldargv) = @_;
  local(@args, @nargv);
  local($_, $opt, $ret);

  &debugs("processing std args", 8192);

  # We do this in two steps.
  # 1) Look for options we want to parse right away.
  # 2) Check the rest.
  while (@oldargv) {
    $_ = shift @oldargv;
    /^--$/             && do { push(@nargv, @args, @oldargv); return @nargv; };
    /^-bibhelp$/       && do { die &doc('bibpkg'); };
    /^-supported$/     && do { die &doc('supported'); };
    /^-hush$/          && do { &errors('ignore'); next; };
    /^-(debugging=.*)/ && do { $ret = &parse_option($1);
                               next; };
    /^-(format=.*)/    && do { $ret = &parse_option($1);
                               next; };
    /^-(informat=.*)/  && do { $ret = &parse_option($1);
                               next; };
    /^-(outformat=.*)/ && do { $ret = &parse_option($1);
                               next; };
    push(@args, $_);
  }
  foreach $opt (@args) {
    if ($opt =~ /^-(.*)/) {
      $ret = &parse_option($1);
      next if defined $ret;
      # fall through if we didn't recognize it
    }
    push(@nargv, $opt);
  }

  @nargv;
}


######
#
# XXXXX what about cset options?
#
# XXXXX we use the "$ret = &foo; next if defined $ret" construct because
#       perl4 can't handle "if defined &foo".
sub options {
  local($gen, $conv, $in, $out) = @_;
  local($fmt, $cset);
  local($sopt, $ret);

  # general
  if ($gen) {
    &debugs("general options: $gen", 2048);
    foreach $sopt (split(/\s+/, $gen)) {
      $ret = &parse_option($sopt);
      next if defined $ret;
      &gotwarn("Unknown general option: $sopt");
    }
  }

  # conversion
  if ($conv) {
    &debugs("conversion options: $conv", 2048);
  }

  # in format

  if ($in) {
    ($fmt, $cset) = &parse_format($glb_Iformat);
    $func = $formats{$fmt, "options"};
    &debugs("informat ($fmt) options: $in", 2048);
    foreach $sopt (split(/\s+/, $in)) {
      $ret = &$func($sopt);
      next if defined $ret;
      &gotwarn("Unknown $fmt option: $sopt");
    }
  }

  # out format

  if ($out) {
    ($fmt, $cset) = &parse_format($glb_Oformat);
    $func = $formats{$fmt, "options"};
    &debugs("outformat ($fmt) options: $out", 2048);
    foreach $sopt (split(/\s+/, $out)) {
      $ret = &$func($sopt);
      next if defined $ret;
      &gotwarn("Unknown $fmt option: $sopt");
    }
  }

  # done

  1;
}

sub parse_num_option {
  local($val) = @_;

  &debugs("parsing numerical option $val", 64);

  return 1 if $val =~ /^(T|true|yes|on)$/i;
  return 0 if $val =~ /^(F|false|no|off)$/i;
  if ($val =~ /\D/) {
    &gotwarn("expected numeric or boolean value: $val");
  }
  $val;
}

#
# This routine is given an option string like "informat=refer" and does the
# appropriate action.  It will be called by bib'options and by bib'stdargs.
# If it doesn't recognize the option it will return undef.
#
sub parse_option {
  local($opt) = @_;

  # XXXXX probably don't want this to be panic.
  &panic("parse_option called with no arguments!") unless defined $opt;

  &debugs("parsing option '$opt'", 64);

  # all our options are <opt>=<value>.
  return undef unless $opt =~ /=/;

  local($_, $val) = split(/\s*=\s*/, $opt, 2);

  &debugs("option split: $_ = $val", 8);

  /^noconverter$/ && do { undef $glb_cvtname if &parse_num_option($val);
                          return 1; };
  /^debugging$/   && do { $glb_debug = &parse_num_option($val);
                          $glb_moddebug = $glb_debug;
                          return $glb_debug; };
  /^csconv$/      && do { $opt_CSConvert = &parse_num_option($val);
                          return 1; };
  /^csprot$/      && do { $opt_CSProtect = &parse_num_option($val);
                          return 1; };
  /^informat$/    && return &format($val, '');
  /^outformat$/   && return &format('', $val);
# XXXXX This is the wrong place for options.  We very well might have not
#       picked our format yet!
  /^inopts$/      && return &options('', '', $val, '');
  /^outopts$/     && return &options('', '', '', $val);
  /^format$/      && return &format( split(/,/, $val) );

  /^error_savelines$/	&& do { $glb_error_saveline = &parse_num_option($val);
				return 1; };

  return undef;
  
}

######

sub doc {
  local($what) = @_;
  local($retstr);

  $what = "bibpkg"  unless defined($what);

  &debugs("documentation on $what", 2048);

  return $glb_version if $what eq 'version';

  if ($what eq "bibpkg" || $what eq "bibpackage" || $what eq "bp") {
    $retstr = "See http://www.ecst.csuchico.edu/~jacobsd/bib/bp/index.html\n" .
              "for documentation on bp.  Online help has not been added yet.\n";
  }

  # XXXXX we should go through each format and check the support:
  #       is it full, readconv only, or writeconv only.
  if ($what eq "supported") {
    $retstr = "";
    local($fmts, $csets) = &find_bp_files();
    $retstr .= "Formats supported:\n";
    foreach ( split(/\s+/, $fmts) ) {
      $retstr .= "  $_\n";
    }
    $retstr .= "Character sets supported:\n";
    foreach ( split(/\s+/, $csets) ) {
      $retstr .= "  $_\n";
    }
  }

  $retstr;
}

1;
