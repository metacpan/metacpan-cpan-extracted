#
# bibliography package for Perl
#
# ProCite format
#
# Dana Jacobsen (dana@acm.org)
# 18 January 1996 (last modified 17 March 1996)
#
# This format read the "Pro-Cite Comma-delimited Import Format".  EndNote
# will import/export this format.  There are quite a few files on the net
# that call themselves "Procite" format, but they all seem to be different.
# I have documentation for this format, and I know at least some people use
# it.  Note that it is wildly different from the tabbed format with an @
# sign at record beginnings.
#
# The field tables need a little more filling out.
#

package bp_procite;

$version = "procite (dj 17 mar 96)";

######

&bib'reg_format(
  'procite',    # name
  'pro',        # short name
  'bp_procite', # package name
  '8859-1',     # default character set
  'suffix is pro',
# our functions
  'options   is standard',
  'open      is standard',
  'close     is standard',
  'read',
  'write',
  'clear     is standard',
  'explode',
  'implode',
  'tocanon',
  'fromcanon',
);

######

sub read {
  local($file) = @_;
  local($record);

  &bib'debugs("reading $file<$bib'glb_current_fmt>", 32);

  # XXXXX We assume that no newlines are present, so we just read one
  #       line and that's it.  To be more robust, we could read until
  #       we found the next record, and save it.  I dislike having state
  #       information if I can help it though.
  #while ($record = <$bib'glb_current_fh>) {
  #  last if $record =~ /^"[A-Z]"/;
  #}

  # XXXXX We're going to try a little different way.  This allows newlines
  #       inside a record.

  local($prec);
  while ($prec = <$bib'glb_current_fh>) {
    $prec =~ s/\r$//;
    if (!defined $record) {
      next unless $prec =~ /^"[A-Z]"/;
      $record = $prec;
    } else {
      $record .= $prec;
    }
    last if $record =~ /"\s*$/;
  }
  $record;
}

######

sub write {
  local($file, $out) = @_;

  &bib'debugs("writing $file<$bib'glb_current_fmt>", 32);

  print $bib'glb_current_fh ($out, "\n");
}

######

sub explode {
  local($rec) = @_;
  local(%entry);
  local(@fields);
  local($field);
  local($fnum) = 1;

  $rec =~ s/^"//;
  $rec =~ s/"$//;
  @fields = split(/","/, $rec);

  $entry{'TYPE'} = shift @fields;
  # Clear one empty field
  $field = shift @fields;

  foreach $field (@fields) {
    $entry{$fnum} = $field  if $field =~ /\S/;
    $fnum++;
  }
  &bib'debugs("procite explode got $fnum fields", 64, 'module');
  %entry;
}

######

sub implode {
  local(%entry) = @_;
  local($ent);
  local($field);
  local($fnum);

  # XXXXX We ought to delete entries so we can check if we missed anybody.
  $ent = "\"$entry{'TYPE'}\"";
  delete $entry{'TYPE'};

  $ent .= ',""';

  $fnum = 1;
  local(@tags) = sort { $a <=> $b } keys(%entry);
  foreach $field (@tags) {
    $ent .= ',""' x ($field - $fnum) . ",\"$entry{$field}\"";
    $fnum = $field+1;
  }

  $ent;
}

%ptc_fields_common = (
 '1',	'Authors',
 '3',	'AuthorAddress',
 '4',	'Title',
 '9',	'SuperTitle',
 '13',	'Location',
 '15',	'Edition',
 '18',	'PubAddress',
 '19',	'Publisher',
#'20',	'Year',
 '22',	'Volume',
 '23',	'ReportNumber',
 '24',	'Number',
 '25',	'Pages',
 '26',	'PagesWhole',
 '27',	'HowPublished',
 '32',	'Series',
 '40',	'ISSN',
 '41',	'ISBN',
 '42',	'Note',
 '43',	'Abstract',
 '44',	'Keywords',
);

%can_to_pro_fields = (
 'Journal',	'9',
 'School',	'19',
 'ReportType',	'5',	# XXXXX Where does this go?
 'Annotation',	'42',	# XXXXX On top of Note?
);

while ( ($pfld, $cfld) = each %ptc_fields_common) {
  $can_to_pro_fields{$cfld} = $pfld;
}
undef $pfld;
undef $cfld;

%ptc_fields_type = (
 'A16',	'Editors',
#'C9',	'Journal',
#'G19',	'School',
 'G5',	'ReportType',
 'E5',	'ReportType',
 'A5',	'ReportType', # XXXXX This is the section type...
);

%pro_types = (
'A',	'book',
'B',	'book',
'C',	'article',
'D',	'article',
'E',	'report',
'F',	'article',
'G',	'thesis',
'H',	'misc',
'I',	'unpublished',
'J',	'misc',
'K',	'proceedings',
'L',	'avmaterial',
'M',	'avmaterial',
'N',	'avmaterial',
'O',	'avmaterial',
'P',	'avmaterial',
'Q',	'avmaterial',
'R',	'avmaterial',
'S',	'misc',
'T',	'misc',
);


######

sub tocanon {
  local(%entry) = @_;
  local(%can);
  local($field, $value, $type);

  if (!defined $entry{'TYPE'}) {
    &bib'gotwarn("No type entry!");
    $entry{'TYPE'} = 'A';
  }
  $type = $entry{'TYPE'};
  if (defined $pro_types{$entry{'TYPE'}}) {
    $can{'CiteType'} = $pro_types{$entry{'TYPE'}};
  } else {
    &bib'gotwarn("Improper entry type: $entry{'TYPE'}");
    $can{'CiteType'} = 'misc';
  }
  delete $entry{'TYPE'};

  if (defined $entry{'1'}) {
    local(@cname) = ();
    foreach $field ( split(/\/\//, $entry{'1'}) ) {
      push( @cname,  &bp_util'name_to_canon($field, 1) );
    }
    $can{'Authors'} = join($bib'cs_sep, @cname);
    delete $entry{'1'};
  }
  if (defined $entry{'16'}) {
    local(@cname) = ();
    foreach $field ( split(/\/\//, $entry{'16'}) ) {
      push( @cname,  &bp_util'name_to_canon($field, 1) );
    }
    $can{'Editors'} = join($bib'cs_sep, @cname);
    delete $entry{'16'};
  }
  # The Journal name is in the SuperTitle position.
  if (defined $entry{'9'} && $type =~ /[CD]/) {
    $can{'Journal'} = $entry{'9'};
    delete $entry{'9'};
  }
  # Organization is in 7 and 8 possibly
  if (defined $entry{'7'} && defined $entry{'8'}) {
    if ($entry{'8'} eq 'sponsoring organization') {
      $can{'Organization'} = $entry{'7'};
      delete $entry{'7'};
      delete $entry{'8'};
    }
  }
  # The School name is in the Publisher position.
  if (defined $entry{'19'}) {
    if      ($type eq 'G') {
      $can{'School'} = $entry{'19'};
      delete $entry{'19'};
    } elsif ($type eq 'E' && !defined $can{'Organization'}) {
      $can{'Organization'} = $entry{'19'};
      delete $entry{'19'};
    }
  }
  # Move meeting location to publication date if none exists.
  if ( (defined $entry{'12'}) && (!defined $entry{'20'}) ) {
    $entry{'20'} = $entry{'12'};
    delete $entry{'12'};
  }
  # Chapter is held in 25 with pages
  if ( defined $entry{'25'} ) {
    if ($entry{'25'} =~ s/,?\s*chapter\s+(\w+),?\s*//i) {
      $can{'Chapter'} = $1;
    }
  }
  # Handle date
  if ( defined $entry{'20'} ) {
    ($can{'Month'}, $can{'Year'}) = &bp_util'parsedate($entry{'20'});
    delete $can{'Month'} unless defined $can{'Month'} && $can{'Month'} =~ /\S/;
    delete $can{'Year'}  unless defined $can{'Year'}  && $can{'Year'}  =~ /\S/;
    delete $entry{'20'};
  }
  # Possibly correct CiteType
  if ($can{'CiteType'} eq 'book') {
    if (defined $entry{'9'}) {
      # We have a SuperTitle
      $can{'CiteType'} = 'inbook';
    } elsif (defined $can{'Chapter'}) {
      # They gave us a chapter location
      $can{'CiteType'} = 'inbook';
    } elsif ( (defined $entry{'25'}) && ($entry{'25'} =~ /[-,]/) ) {
      # They gave us a page range
      $can{'CiteType'} = 'inbook';
    }
  } elsif ($can{'CiteType'} eq 'proceedings') {
    if ( (defined $entry{'4'}) && (defined $entry{'9'}) ) {
      # We have both a title and supertitle
      $can{'CiteType'} = 'inproceedings';
    }
  }

  while ( ($field, $value) = each %entry) {
    next unless $value =~ /\S/;
    if (defined $ptc_fields_common{$field}) {
      $can{$ptc_fields_common{$field}} = $value;
    } elsif (defined $ptc_fields_type{"$type$field"}) {
      $can{$ptc_fields_type{"$type$field"}} = $value;
    } else {
      &bib'gotwarn("Unknown field $field in $type entry.");
      $can{$field} = $value;
    }
  }

  $can{'OrigFormat'} = $version;

  %can;
}

######

sub fromcanon {
  local(%can) = @_;
  local($canf, $canv);
  local(%rec);

  if (!defined $can{'CiteType'}) {
    &bib'gotwarn("Procite didn't find a CiteType field!");
    $can{'CiteType'} = 'book';
  }

  local($_) = $can{'CiteType'};
  if    (/^article/       ) { $rec{'TYPE'} = 'C'; }
  elsif (/^avmaterial/    ) { $rec{'TYPE'} = 'P'; }
  elsif (/^book/          ) { $rec{'TYPE'} = 'A'; }
  elsif (/^inbook/        ) { $rec{'TYPE'} = 'A'; }
  elsif (/^inproceedings/ ) { $rec{'TYPE'} = 'K'; }
  elsif (/^manual/        ) { $rec{'TYPE'} = 'T'; }  # data file?
  elsif (/^misc/          ) { $rec{'TYPE'} = 'J'; }  # manuscript?
  elsif (/^thesis/        ) { $rec{'TYPE'} = 'G'; }
  elsif (/^proceedings/   ) { $rec{'TYPE'} = 'K'; }
  elsif (/^report/        ) { $rec{'TYPE'} = 'E'; }
  elsif (/^unpublished/   ) { $rec{'TYPE'} = 'I'; }
  else {
    &bib'gotwarn("Improper entry type: $can{'CiteType'}");
    $rec{'TYPE'} = 'J';
  }

  if ( defined $can{'Authors'} ) {
    $rec{'1'} = join('//', &bp_util'canon_to_name($can{'Authors'}, 'reverse2'));
    delete $can{'Authors'};
  }
  if ( defined $can{'Editors'} ) {
   $rec{'16'} = join('//', &bp_util'canon_to_name($can{'Editors'}, 'reverse2'));
   delete $can{'Editors'};
  }
  if ( defined $can{'CorpAuthor'} ) {
    if ( defined $rec{'1'} ) {
      if ( defined $rec{'16'} ) {
        # XXXXX This probably isn't right.
        $rec{'7'} = join('//', &bp_util'canon_to_name($can{'CorpAuthor'},
                               'plain') );
      } else {
        $rec{'16'} = join('//', &bp_util'canon_to_name($can{'CorpAuthor'},
                                'plain') );
      }
    } else {
      $rec{'1'}=join('//',&bp_util'canon_to_name($can{'CorpAuthor'}, 'plain') );
    }
    delete $can{'CorpAuthor'};
  }
  # Chapter and pages in 25
  if ( defined $can{'Chapter'} ) {
    if ( defined $can{'Pages'} ) {
      $rec{'25'} = "$can{'Pages'}, Chapter $can{'Chapter'}";
      delete $can{'Pages'};
    } else {
      $rec{'25'} = "Chapter $can{'Chapter'}";
    }
    delete $can{'Chapter'};
  }

  # Handle date
  $rec{'20'} = &bp_util'output_date($can{'Month'}, $can{'Year'});
  delete $rec{'20'} unless $rec{'20'} =~ /\S/;
  delete $can{'Month'};
  delete $can{'Year'};

  if (defined $can{'Organization'}) {
    if ( ($rec{'TYPE'} eq 'E') && (!defined $can{'Publisher'}) ) {
      $rec{'19'} = $can{'Organization'};
    } else {
      $rec{'7'} = $can{'Organization'};
      $rec{'8'} = "sponsoring organization";
    }
    delete $can{'Organization'};
  }

  delete $can{'Key'};
  delete $can{'CiteType'};
  delete $can{'CiteKey'};
  delete $can{'OrigFormat'};

  while ( ($canf, $canv) = each %can) {
    if (defined $can_to_pro_fields{$canf}) {
      $rec{$can_to_pro_fields{$canf}} = $canv;
    } else {
      &bib'gotwarn("Unknown field: $canf");
      # For pro-cite, we can't have text fields, so throw them out
      #$rec{$canf} = $canv;
    }
  }

  %rec;
}

#######################
# end of package
#######################

1;
