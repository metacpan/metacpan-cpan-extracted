#
# bibliography package for Perl
#
# "canon format routines
#
# Dana Jacobsen (dana@acm.org)
# 17 March 1996
#
# This is here so that I can easily see all the steps taken in conversion.
#

package bp_canon;

$version = "canon (dj 17 mar 96)";

######

&bib'reg_format(
  'canon',     # name
  'can',       # short name
  'bp_canon',  # package name
  'canon',     # default character set
  'suffix is can',
# our functions
  'open    is standard',
  'close   is standard',
  'write   is standard',
  'options is standard',
  'read    is standard',
  'explode is unimplemented',
  'implode',
  'tocanon',
  'fromcanon',
  'clear   is standard',
);

######

######

######

######

sub explode {
  local($rec) = @_;

}

######

sub implode {
  local(%entry) = @_;
  local($key);
  local($ent) = '';

  foreach $key (sort keys %entry) {
    $ent .= "$key = $entry{$key}\n";
  }
  #$ent =~ s/$bib'cs_sep/\//go;
  #$ent =~ s/$bib'cs_sep2/,/go;

  $ent;
}

######

sub tocanon {
  @_;
}

######

sub fromcanon {
  @_;
}

######


#######################
# end of package
#######################

1;
