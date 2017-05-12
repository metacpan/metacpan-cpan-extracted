#
# bibliography package for Perl
#
# tib routines
#
# Dana Jacobsen (dana@acm.org)
# 22 January 1995  (last modified 18 November 1995)
#
#           This is untested!
#

package bp_tib;

$version = "tib (dj 22 jan 95)";

######

# Most of our stuff will just use the refer routines.

&bib'reg_format(
  'tib',      # name
  'tib',      # short name
  'bp_tib',   # package name
  'tex',      # default character set
  'suffix is tib',
# functions
  'open      uses refer',
  'close     uses refer',
  'write     uses refer',
  'clear     uses refer',
  'read      uses refer',
  'options',
  'implode',
  'explode',
  'tocanon',
  'fromcanon uses refer',
);

######

$opt_order = 'L A Q E T B J R S V N P I C D $ * K M G l U X O Y';

# set this if you want checks for proper fields in implode and explode.
# It will slow the routines down somewhat.
$opt_validate = 1;

# These are the fields that can be multiply defined.
$opt_multFieldList = 'A E K';

######

sub options {
  local($opts) = @_;

  print "setting options to $opts\n";
}

######

sub explode {
  local($rec) = @_;
  local($field, $value);
  local(%entry);
  local(@lines);

  substr($rec, 0, 0) = "\n";
  @lines = split(/\n\%/, $rec);
  shift @lines;
  foreach (@lines) {
    $field = substr($_, 0, 1);
    if (length($_) < 3) {
      &bib'gotwarn("tib explode got empty field \%$field");
      next;
    }
    $value = substr($_, 2);
    $value =~ s/\n+/ /g;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;
    if (defined $entry{$field}) {
      $opt_validate && $opt_multFieldList !~ /\b$field\b/
                    && &bib'gotwarn("Field $field multiply defined");
      $entry{$field} .= $bib'cs_sep . $value;
    } else {
      $entry{$field} = $value;
    }
  }
  %entry;
}


######

sub implode {
  local(%entry) = @_;
  local($ent) = '';

# tib's implode method 0.
local(@keys) = sort { index($opt_order,$a) <=> index($opt_order,$b) }
                 keys(%entry);
  local($unknown_ent) = '';
  # unknown fields are at the top
  foreach $field (@keys) {
    last if index($opt_order,$field) >= $[;
    &bib'gotwarn("tib implode: unknown field identifier: $field");
    $unknown_ent .= "\%$field $entry{$field}\n" if length($field) == 1;
    shift @keys;
  }
  # XXXXXX Shouldn't unknown_ent's be checked for seperators also?
  foreach $field (@keys) {
    $entry{$field} =~ s/$bib'cs_sep/\n\%$field /g;
    $ent .= "\%$field $entry{$field}\n";
  }
  $ent .= $unknown_ent;

  $ent;
}

#####

sub tocanon {
  local(%entry) = @_;
  local(%can);

  %can = &bp_refer'tocanon(%entry);

  if (defined $can{'o'}) {
    $can{'Edition'} = $can{'o'};
    delete $can{'o'};
  }
  if (defined $can{'f'}) {
    $can{'CiteKey'} = $can{'f'};
    delete $can{'f'};
  }
  # XXXXX Look to see if \Refformat is defined.
  if (defined $can{'\\'}) {
    $can{'BibPreComment'} = $can{'\\'};
    delete $can{'\\'};
  }
  %can;
}

#####

# fromcanon is refer's.
# XXXXX we should do our own for fields like Key and AuthorAddress.



#######################
# end of package
#######################

1;
