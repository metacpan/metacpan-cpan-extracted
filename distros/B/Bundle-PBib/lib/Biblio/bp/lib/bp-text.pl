#
# bibliography package for Perl
#
# text routines
#
# This reads raw text and does no processing on it.  We use this for
# character conversion, for instance.
#
# Dana Jacobsen (dana@acm.org)
# 6 January 1995
#

package bp_text;

######

&bib'reg_format(
  'text',    # name
  'txt',     # short name
  'bp_text', # package name
  'none',    # default character set
# our functions
  'open is standard',
  'close is standard',
  'clear is standard',
  'options',
  'read',
  'write',
  'explode',
  'implode',
  'tocanon',
  'fromcanon',
);

######

#
# This controls how many lines to read in at a time.  Values less than 1
# indicate we are to read a paragraph at a time.
#
# Setting this to paragraph instead of line is a going to be a lot faster,
# as most of the time will be spent traversing subroutines otherwise.
#
$glb_inlines = -1;

######

sub options {
  local($opts) = @_;

  print "setting options to $opts\n";
}

######

sub read {
  local($file) = @_;

  return scalar(<$bib'glb_current_fh>) if $glb_inlines == 1;

  if ($glb_inlines < 1) {
    local($/) = '';
    return scalar(<$bib'glb_current_fh>);
  }

  local($ent) = '';
  local($loops) = $glb_inlines;
  while (<$bib'glb_current_fh>) {
    $ent .= $_;
    last unless --$loops;
  }
  $ent;
}

######

sub write {
  local($file, $out) = @_;

  print $bib'glb_current_fh ($out, "\n");
}

######

sub explode {
  local($_) = @_;
  local(%entry) = ();

  $entry{'TEXT'} = $_;
  %entry;
}

######

sub implode {
  local(%entry) = @_;
  return $entry{'TEXT'}  if defined $entry{'TEXT'};

  # This is probably wrong for any given application, but I'm not sure what
  # else to do.  We just spit out the values, ignoring the keys.
  join("\n", values(%entry) );
}

######

sub tocanon {
  local(%entry) = @_;
  %entry;
}

######

sub fromcanon {
  local(%entry) = @_;
  %entry;
}

#######################
# end of package
#######################

1;
