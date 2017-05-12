#
# bibliography package for Perl
#
# Powell's bookstore query results routines
#
# Dana Jacobsen (dana@acm.org)
# 5 January 1995
#
# I don't think they use this format any more.  Oh well.
#

package bp_powells;

######

&bib'reg_format(
  'powells',    # name
  'pow',        # short name
  'bp_powells', # package name
  'none',       # default character set
# our functions
  'options is standard',
  'open is standard',
  'close is standard',
  'write is standard',
  'clear is standard',
  'read',
  'explode',
  'implode',
  'tocanon',
  'fromcanon is unsupported',
);

######

sub read {
  local($file) = @_;
  local($ent);

  while (<$bib'glb_current_fh>) {
    last if /^`/;
  }
  $bib'glb_vloc = "line $.";
  return undef if eof;
  $ent = $_;
  while (<$bib'glb_current_fh>) {
    last if /^\s*$/;
    $ent .= $_;
  }
  $ent;
}

######

sub explode {
  local($_) = @_;
  local(%entry) = ();

  local(@values) = split(/\n/);

  ($entry{'title'}, $entry{'author'}) = shift(@values)
      =~ /^`(.*)' by\s*(.*)$/;
  ($entry{'publisher'}, $entry{'ISBN'}) = shift(@values)
      =~ /^Published:\s*(.*)ISBN:(\S*)$/;
  if ($entry{'publisher'} =~ s/\s*(\d\d\d\d)\s*$//) {
    $entry{'year'} = $1;
  } else {
    $entry{'publisher'} =~ s/\s+$//;
    $entry{'year'} = '????';
  }
  ($entry{'subject'}, $entry{'entrydate'}) = shift(@values)
      =~ /^Subject:\s*(.*)\s+\(([\d\/]*)\)$/;
  ($entry{'instock'}, $entry{'price'}, $entry{'type'}, $entry{'binding'}) = shift(@values)
      =~ /^In Stock: (.+) @ \$(.+) \((.+),(.*)\)$/;
  foreach $f ('binding', 'entrydate', 'publisher') {
    delete $entry{$f} if $entry{$f} =~ /^\s*$/;
  }

  %entry;
}

######


sub implode {
  local(%entry) = @_;
  local($ent);

  $ent = "`$entry{'title'}' by $entry{'author'}\n";
  $ent =~ s/ +$//;

  $ent .= "Published: ";
  $ent .= "$entry{'publisher'} " if defined $entry{'publisher'};
  $ent .= "$entry{'year'} " if defined $entry{'year'};
  $ent .= "ISBN:$entry{'ISBN'}\n";

  $_ = join("", "Subject: ", $entry{'subject'}, " (", $entry{'entrydate'}, ")\n");
  s/ +/ /g;
  $ent .= $_;

  $_ = join("", "In Stock: ", $entry{'instock'}, " \@ \$", $entry{'price'},
                   " (", $entry{'type'}, ",", $entry{'binding'}, ")\n");
  s/ +/ /g;
  $ent .= $_;

  $ent;
}

######

%flds_powcan = (
  'title',	'Title',
  'author',	'Authors',
  'publisher',	'Publisher',
  'year',	'Year',
  'ISBN',	'ISBN',
  'subject',	'Field',
  'price',	'Price',
  'binding',	'Format',
);

sub tocanon {
  local(%record) = @_;
  local(%reccan);
  local($f, $v);
  local($book);

  if (defined $record{'author'}) {
    $reccan{'Authors'} = &bp_util'name_to_canon($record{'author'}, 'reverse');
    delete $record{'author'};
  }
  if ($record{'instock'} == 1) {
    $book = 'book';
  } else {
    $book = 'books';
  }
  if (defined $record{'entrydate'}) {
    $reccan{'Note'} = "Powell's has $record{'instock'} $record{'type'} $book as of $record{'entrydate'}";
  } else {
    $reccan{'Note'} = "Powell's has $record{'instock'} $record{'type'} $book";
  }
  delete $record{'instock'};
  delete $record{'type'};
  delete $record{'entrydate'};
  $reccan{'CiteType'} = 'book';

  while ( ($f, $v) = each %record) {
    if (defined $flds_powcan{$f}) {
      $reccan{$flds_powcan{$f}} = $v;
    } else {
      &bib'gotwarn("powells tocanon: unknown field type $f");
      $f =~ tr/A-Z/a-z/;
      $reccan{$f} = $v;
    }
  }

  %reccan;
}

######

# sub fromcanon {}

######


#######################
# end of package
#######################

1;
