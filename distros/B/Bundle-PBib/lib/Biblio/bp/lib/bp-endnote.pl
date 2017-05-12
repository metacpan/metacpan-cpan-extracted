#
# bibliography package for Perl
#
# EndNote routines (based on the refer module)
#
# Dana Jacobsen (dana@acm.org)
# 12 January 1995 (last modified 11 December 1996)
#
# This handles the endnote format, as described in the web page:
# <http://www.ecst.csuchico.edu/~jacobsd/bib/formats/endnote.html>
#
# XXXXX Some limitations include:
#  1) it doesn't properly handle some of the %0 types (distinguising between
#     magazine, newspaper, and journal article; artwork vs. avmaterial)
#  2) it doesn't handle all the extra fields.
#  3) how does EndNote want the %E field formatted?
#

package bp_endnote;

$version = "endnote (dj 11 dec 96)";

######

&bib'reg_format(
  'endnote',    # name
  'end',        # short name
  'bp_endnote', # package name
  '8859-1',     # default character set
  'suffix is end',
# functions
  'open      is standard',
  'close     is standard',
  'write     is standard',
  'clear     is standard',
  'options',
  'read',
  'explode',
  'implode',
  'tocanon',
  'fromcanon',
);

######

$opt_order = '0 F L A Q E T B J R S V N P I C D $ * K M G l U X O Y Z 7 8 9';

# set this if you want checks for proper fields in implode and explode.
# It will slow the routines down somewhat.
$opt_validate = 1;

# These are the fields that can be multiply defined.
$opt_multFieldList = 'A E K';

# Read in by line rather than paragraph.  A tad bit slower, but we get the
# line number of the record instead of just the record number.
$opt_readline = 1;

# Set this if authors are in format "Last, First, Jr."
# (which is incorrect according to the refer documentation, by the way)
$opt_reverseauthor = 1;

$ent = '';
######

sub options {
  local($opt) = @_;

  &bib'panic("refer options called with no arguments!") unless defined $opt;
  &bib'debugs("parsing refer option '$opt'", 64);
  if ($opt !~ /=/) {
    $opt =~ s/^reverseauthor$/reverseauthor=1/;
    return undef unless $opt =~ /=/;
  }
  local($_, $val) = split(/\s*=\s*/, $opt, 2);
  &bib'debugs("option split: $_ = $val", 8);
  /^reverseauthor$/  && do { $opt_reverseauthor = &bib'parse_num_option($val);
                             return 1; };
  undef;
}

######

######

# XXXXX Do we really need this?  Why not stdbib?

sub read {
  local($file) = @_;    # Ignored.  We directly use the file handle.

  while (<$bib'glb_current_fh>) {
    last if /^\%/;
  }

  # We can't use this unless we're reading line by line
  if ($opt_readline) {
    $bib'glb_vloc = sprintf("line %5d", $.);
  }

  return undef if eof;

  $ent = $_;

  if ($opt_readline) {
    while (<$bib'glb_current_fh>) {
      last unless /\S/;
      $ent .= $_;
    }
  } else {
    local($/) = '';
    $ent .= scalar(<$bib'glb_current_fh>);
  }
  $ent;
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
      &bib'gotwarn("refer explode got empty field \%$field");
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
  $ent = '';

  local(@keys) = sort { index($opt_order,$a) <=> index($opt_order,$b) }
                 keys(%entry);
  local($unknown_ent) = '';
  # unknown fields are at the top
  foreach $field (@keys) {
    last if index($opt_order,$field) >= $[;
    &bib'gotwarn("refer implode: unknown field identifier: $field");
    $unknown_ent .= "\%$field $entry{$field}\n" if length($field) == 1;
    shift @keys;
  }
  foreach $field (@keys) {
    $entry{$field} =~ s/$bib'cs_sep/\n\%$field /go;
    $ent .= "\%$field $entry{$field}\n";
  }
  $ent .= $unknown_ent;

  $ent =~ s/$bib'cs_sep/ /go;
  $ent;
}

######


%ref_to_can_fields = (
'L',		'CiteKey',
'A',		'Authors',
'E',		'Editors',
'T',		'Title',
'B',		'SuperTitle',
'J',		'Journal',
'S',		'Series',
'V',		'Volume',
'N',		'Number',
'P',		'Pages',
'I',		'Publisher',
'C',		'PubAddress',
'$',		'Price',
'*',		'Copyright',
'K',		'Keywords',
'M',		'MRNumber',
'l',		'Language',
'U',		'Annotation',
'X',		'Abstract',
'G',		'GovNumber',
'O',		'Note',
'Q',		'CorpAuthor',
'W',		'Location',
'Y',		'Contents',
'Z',		'PagesWhole',
);

# Generate the opposite map upon loading the format.
local($key, $val);
while (($key, $val) = each %ref_to_can_fields) {
  $can_to_ref_fields{$val} = $key;
}
undef $key; undef $val;

%end_to_can_types = (
'Journal Article',	  'article',
'Book',			  'book',
'Book Section',		  'inbook',
'Edited Book',		  'book',
'Magazine Article',	  'article',
'Newspaper Article',	  'article',
'Conference Proceedings', 'proceedings',
'Thesis',		  'thesis',
'Personal Communication', 'unpublished',
'Computer Program',	  'misc',
'Report',		  'report',
'Map',			  'map',
'Audiovisual Material',	  'avmaterial',
'Artwork',		  'avmaterial',
'Patent',		  'misc',
'Generic',		  'misc',
);

# Since we're not one-to-one, we have to do this separately.
%can_to_end_types = (
'article',	'Journal Article',
'book',		'Book',
'inbook',	'Book Section',
'inproceedings','Book Section',
'proceedings',	'Conference Proceedings',
'thesis',	'Thesis',
'unpublished',	'Personal Communication',
'report',	'Report',
'map',		'Map',
'manual',	'Generic',
'avmaterial',	'Audiovisual Material',
'misc',		'Generic',
);


sub tocanon {
  local(%entry) = @_;
  local(%reccan);
  local($reptype, $repnumber, $type, $field);
  local($_);

  # XXXXX Note for optimizations:
  #       The most time consuming parts of this are:
  #          2:  Author processing
  #          1f: date parsing
  #          5:  packing the rest of the fields in
  #       Those account for over 70% of the time.

  # ---- 0 ---- record specific booleans

  # XXXXX Should we count the EndNote records, and decide the file is
  #       EndNote after a certain number?
  #

  if (!defined $entry{0}) {
    &bib'gotwarn("EndNote records must have %0 entries");
  }


  # ---- 1 ---- preprocessing of fields

  # -- 1a:  Look for ISBN/ISSN # in G field and move to ISBN/ISSN
  if      ( (defined $entry{G}) && ($entry{G} =~ /IS[BS]N/) ) {
    while ($entry{G} =~ s/\s*[,;]?\s*(IS[BS]N)\s*:?\s*(\d\S*)\s*[,;]?//i) {
      $field = $1;
      $reccan{$field} = $2;
      $reccan{$field} =~ s/[;.,]$//g;
      $reccan{$field} =~ s/\240/-/g;
      delete $entry{G} unless $entry{G} =~ /\S/;
    }
  }

  # -- 1b:  O field (note) processing
  if (defined $entry{O}) {
    # Look for Thesis or Dissertation and move to R
    if (!defined $entry{R}) {
      if ( ($entry{O} =~ /thesis/i) || ($entry{O} =~ /dissert/i) ) {
        $entry{R} = $entry{O};
        $entry{O} = '';
      }
    }
    # Look for "* Edition" and move to Edition
    if ( $entry{O} =~ /edition/i ) {
      if ($entry{O} =~ /([\w\d]+)\s+edition/i) {
        $reccan{'Edition'} = $1;
        $entry{O} =~ s/\s*[-,;(]?\s*([\w\d]+)\s+edition\s*[),;]?\s*//i;
      }
    }
    # Look for Chapter number
    if ( $entry{O} =~ /chapter/i ) {
      if ($entry{O} =~ /\bchapter\s+([\d]+)\b/i) {
        $reccan{'Chapter'} = $1;
        $entry{O} =~ s/\s*[-,;(]?\s*chapter\s+([\d]+)\s*[),;]?\s*//i;
      }
    }
    # Look for ISBN and/or ISSN
    if (    $entry{O} =~ /IS[BS]N/
         && (!defined $reccan{'ISBN'})
         && (!defined $reccan{'ISSN'}) ) {
      while ($entry{O} =~ s/\s*[,;]?\s*(IS[BS]N)\s*:?\s*(\d\S*)\s*[,;]?//i) {
        $field = $1;
        $reccan{$field} = $2;
        $reccan{$field} =~ s/[;.,]$//g;
        $reccan{$field} =~ s/\240/-/g;
      }
    }
    # look for pp or pages in O if P not found.
    if (!defined $entry{P}) {
      if ($entry{O} =~ /pp|pages/i) {
        if ( $entry{O} =~ s/\s*[,;]?\s*[XIVxiv]*\+?(\d+)\s*(pp\.?|pages),?\s*//i ) {
          $entry{P} = $1;
        }
      }
    }
  }
  if ( (!defined $entry{O}) || ($entry{O} !~ /\S/) ) {
    $entry{O} = '';
  }

  # -- 1c:  Look for "Tech* Rep*" or "Tech* Mem*" in S and move to R
  if (    (defined $entry{S})
       && (!defined $entry{R})
       && ($entry{S} =~ /tech\w*\s+(rep|mem)\w*/i) ) {
    $entry{R} = $entry{S};
    delete $entry{S};
  }

  # -- 1d:  Look for "* No. *" in V and move to N
  if (    (defined $entry{V})
       && (!defined $entry{N})
       && ($entry{V} =~ /(\d+)\s+(no\.?|numb?e?r?\.?)\s+(\d+)/i) ) {
    $entry{N} = $3;
    $entry{V} =~ s/(\d+)\s+(no\.?|numb?e?r?\.?)\s+(\d+)/$1/i;
  }

  # -- 1e:  Look for "* Edition" in some fields and move to Edition field
  if (!defined $reccan{'Edition'}) {
    if      ( (defined $entry{R}) && ($entry{R} =~ /edition/i) ) {
      $field = 'R';
    } elsif ( (defined $entry{S}) && ($entry{S} =~ /edition/i) ) {
      $field = 'S';
    } elsif ( (defined $entry{V}) && ($entry{V} =~ /edition/i) ) {
      $field = 'V';
    } elsif ( (defined $entry{T}) && ($entry{T} =~ /edition/i) ) {
      $field = 'T';
    } elsif ( (defined $entry{B}) && ($entry{B} =~ /edition/i) ) {
      $field = 'B';
    } else {
      $field = undef;
    }
    if ( (defined $field) && ($entry{$field} =~ /([\w\d]+)\s+edition/i) ) {
      $reccan{'Edition'} = $1;
      $entry{$field} =~ s/\s*[-,;(]?\s*([\w\d]+)\s+edition\s*[),;]?\s*//i;
      delete $entry{$field} unless $entry{$field} =~ /\S/;
    }
  }

  # -- 1f:  Set up Month and Year fields, and look for them in B if not in D.
  if (defined $entry{D}) {
    ($reccan{'Month'}, $reccan{'Year'}) = &bp_util'parsedate($entry{D});
    if ( (!defined $reccan{'Month'}) || ($reccan{'Month'} eq '') ) {
      delete $reccan{'Month'};
    }
    if ( (!defined $reccan{'Year'}) || ($reccan{'Year'} eq '') ) {
      delete $reccan{'Year'};
    }
    delete $entry{D};
  } elsif (defined $entry{B}) {
    if ($entry{B} =~ /\b(\d\d\d\d)\b/) {
      $reccan{'Year'} = $1;
    } elsif ($entry{B} =~ /'(\d\d)\b/) {
      $reccan{'Year'} = $1;
    }
  }

  # -- 1g:  pick out reptype and repnumber
  if (defined $entry{R}) {
    $entry{R} =~ s/${bib'cs_meta}01..//go;   # remove all font changes
    ($reptype, $repnumber) = $entry{R} =~ /(.+)\s+(\S+)$/;
    if (  (!defined $repnumber)  ||  ($repnumber !~ /\d/)  ) {
      $reptype = $entry{R};
      undef $repnumber;
    }
  }

  # ---- 2 ---- process author and editor fields

  if (defined $entry{A}) {
    if (    ($entry{A} =~ /ed/i)
         && ($entry{A} =~ s/,?\s*\(?\s*ed(itors|\.|s\.)\)?\s*$//i) ) {
      if (defined $entry{E}) {
        &bib'gotwarn("editors in \%A and \%E?");
        # XXXXX What now?
      } else {
        $entry{E} = $entry{A};
        delete $entry{A};
      }
    } else {
      if ($entry{A} =~ /$bib'cs_sep/o) {
        # -multiple authors
        local(@cname) = ();
        foreach $field (split(/$bib'cs_sep/o, $entry{A})) {
          push( @cname, &bp_util'name_to_canon($field, $opt_reverseauthor) );
        }
        $reccan{'Authors'} = join($bib'cs_sep, @cname);
      } else {
        # -single author
        $reccan{'Authors'} = &bp_util'name_to_canon($entry{A}, $opt_reverseauthor);
        # Check for corporate authors.
        # only if: 1) only one name; and 2) that name is a last name;
        if ( $reccan{'Authors'} =~ s/$bib'cs_sep2$bib'cs_sep2$bib'cs_sep2$//o ) {
          if (defined $entry{Q}) {
            &bib'gotwarn('Corporate Author (%Q) in %A (already a Q field!)');
          } else {
            &bib'gotwarn('Corporate Author (%Q) in %A');
            $reccan{'CorpAuthor'} = $reccan{'Authors'};
            delete $reccan{'Authors'};
          }
        } # end check for corporate author
      }
      delete $entry{A};
    } # end author or editor if statement
  } # end author field

  if (defined $entry{E}) {
    $entry{E} =~ s/$bib'cs_sep/ and /go;
    # XXXXX Does EndNote always put editors in normal form?
    $reccan{'Editors'} = &bp_util'mname_to_canon($entry{E}, 0);
    delete $entry{E};
  }

  # ---- 3 ---- determine the entry type

    if (defined $end_to_can_types{$entry{0}}) {
      $type = $end_to_can_types{$entry{0}};
    } else {
      &bib'gotwarn("Unknown endnote entry type: $entry{0}");
      $type = 'misc';
    }
    delete $entry{0};

    if      ($type =~ /^report|thesis$/) {
      if (defined $entry{9}) {
        $reccan{'ReportType'} = $entry{9};
        delete $entry{9};
      }
      if (defined $entry{N}) {
        $reccan{'ReportNumber'} = $entry{N};
        delete $entry{N};
      }
    } elsif ($type =~ /^unpublished$/) {
      if (defined $entry{9}) {
        $reccan{'HowPublished'} = $entry{9};
        delete $entry{9};
      }
    } elsif ($type =~ /^article$/) {
      if ( (defined $entry{B}) && (!defined $entry{J}) ) {
        # EndNote wrongly puts the journal name in the %B field sometimes.
        $entry{J} = $entry{B};
        delete $entry{B};
      }
    }

    # XXXXX %6 seems to be the "Number of Volumes".  I'm not sure what
    #       to do with it at the moment.
    # XXXXX %Y is the "Series Editor"

    if (defined $entry{7}) {
      $reccan{'Edition'} = $entry{7};
      delete $entry{7};
    }
    if ( (defined $entry{8}) && (!defined $reccan{'Month'}) ) {
      $reccan{'Month'} = $entry{8};
      delete $entry{8};
    }
    # XXXXX %9 is the "Thesis Type" ?
    if (defined $entry{9}) {
      $entry{O} .= $entry{9};
      delete $entry{9};
    }

    if (defined $entry{F} && (!defined $entry{L}) ) {
      $reccan{'CiteKey'} = $entry{F};
      delete $entry{F};
    }

  # ---- 4 ---- postprocessing of fields

  # -- 4a: various things

  # if there is no address, but a "header" field, assume H stands for "held in"
  if ( ($entry{H}) && (!$entry{C}) ) {
    $reccan{'PubAddress'} = $entry{H};
    delete $entry{H};
  }

  # If reptype is still defined, then there is an R field in a journal
  # or proceedings entry.  XXXXX Should this be deleted?
  if (defined $entry{R}) {
    $entry{O} .= $entry{R};
    delete $entry{R};
  }

  # if we have a booktitle but no title, set title to booktitle
  if (defined $entry{B} && !defined $entry{T}) {
    $reccan{'Title'} = $entry{B};
    delete $entry{B};
  }

  # -- 4b: type related
  if ($type =~ /^unpublished/) {
    if (defined $entry{Q}) {
      $entry{O} .= $entry{Q};
      delete $entry{Q};
    }
  }
  if ($type =~ /^thesis/) {
    if (defined $entry{Q}) {
      $reccan{'School'} = $entry{Q};
      delete $entry{Q};
    } elsif (defined $entry{I}) {
      $reccan{'School'} = $entry{I};
      delete $entry{I};
    }
  }

  # ---- 5 ---- pack the rest of the entry into reccan

  $reccan{'CiteType'} = $type;

  $reccan{'Note'} = $entry{O} if $entry{O} =~ /\S/;
  delete $entry{O};

  while ( ($fld, $val) = each %entry) {
    next if ( (!defined $val) || ($val eq ''));
    if (defined $ref_to_can_fields{$fld}) {
      $reccan{$ref_to_can_fields{$fld}} = $val;
    } else {
      $fld =~ tr/A-Z/a-z/;
      $reccan{$fld} = $val;
    }
  }

  # tell them who we are
  $reccan{'OrigFormat'} = $version;

  %reccan;
}


######

sub fromcanon {
  local(%can) = @_;
  local(%rec);
  local($canf, $canv);

  local($name_style) = ($opt_reverseauthor)  ?  'reverse2'  :  'plain';

  if (defined $can_to_end_types{$can{'CiteType'}}) {
    $rec{'0'} = $can_to_end_types{$can{'CiteType'}};
  } else {
    &bib'gotwarn("Unrecognized CiteType: $can{'CiteType'}");
  }
  delete $can{'CiteType'};

  if (defined $can{'Authors'}) {
    $rec{'A'} = join($bib'cs_sep, &bp_util'canon_to_name($can{'Authors'}, $name_style));
    delete $can{'Authors'};
  }
  if (defined $can{'Editors'}) {
    # XXXXX How exactly does EndNote want it's editors?
    $rec{'E'} = &bp_util'canon_to_name($can{'Editors'}, 'plain');
    $rec{'E'} =~ s/, and / and /;
    delete $can{'Editors'};
    # Add Edited Book type
    if ($rec{'0'} eq 'Book') {
      $rec{'0'} = 'Edited Book';
    }
  }

  if (defined $can{'ReportType'}) {
    $rec{'9'} = $can{'ReportType'};
  }
  if (defined $can{'ReportNumber'}) {
    $rec{'N'} = $can{'ReportNumber'};
  }
  delete $can{'ReportType'};
  delete $can{'ReportNumber'};

  if (defined $can{'Year'}) {
    $rec{'D'} = $can{'Year'};
    delete $can{'Year'};
  }
  if (defined $can{'Month'}) {
    $rec{'8'} = &bp_util'output_month( $can{'Month'}, 'long');
    delete $can{'Month'};
  }
  
  if (defined $can{'School'}) {
    &bib'gotwarn("refer from_canon: got Publisher and School") if defined $can{'Publisher'};
    &bib'gotwarn("refer from_canon: got Organization and School") if defined $can{'Organization'};
    $rec{'I'} = $can{'School'};
    delete $can{'School'};
  }
  if (defined $can{'Organization'}) {
    &bib'gotwarn("refer from_canon: got Publisher and Organization") if defined $can{'Publisher'};
    $rec{'I'} = $can{'Organization'};
    delete $can{'Organization'};
  }

  if (defined $can{'Edition'}) {
    $rec{'7'} = $can{'Edition'};
    delete $can{'Edition'};
  }

  if (defined $can{'Chapter'}) {
    if (defined $can{'Note'}) {
      $can{'Note'} .= ", Chapter $can{'Chapter'}";
    } else {
      $can{'Note'}  = "Chapter $can{'Chapter'}";
    }
    delete $can{'Chapter'};
  }

  if (defined $can{'ISBN'}) {
    if (defined $can{'GovNumber'}) {
      $can{'GovNumber'} .= ", ISBN: $can{'ISBN'}";
    } else {
      $can{'GovNumber'} = "ISBN: $can{'ISBN'}";
    }
    delete $can{'ISBN'};
  }
  if (defined $can{'ISSN'}) {
    if (defined $can{'GovNumber'}) {
      $can{'GovNumber'} .= ", ISSN: $can{'ISSN'}";
    } else {
      $can{'GovNumber'} = "ISSN: $can{'ISSN'}";
    }
    delete $can{'ISSN'};
  }

  if (defined $can{'Source'}) {
    if (defined $can{'Annotation'}) {
      $can{'Annotation'} .= $bib'cs_sep . $can{'Source'};
    } else {
      $can{'Annotation'} = $can{'Source'};
    }
    delete $can{'Source'};
  }

  if (defined $can{'HowPublished'}) {
    if ( (defined $rec{'0'}) && ($rec{'0'} !~ /^report/) ) {
      $rec{'9'} = $can{'HowPublished'};
    }
    # XXXXX We should handle this field.
    delete $can{'HowPublished'};
  }

  if (defined $can{'CiteKey'}) {
    $rec{'F'} = $can{'CiteKey'};
    # don't put each CiteKey into label %L
    delete $can{'CiteKey'};
  }

  # not sure what to do with 'Key', so throw it out
  delete $can{'Key'};

  # We don't know any special information about any types
  delete $can{'OrigFormat'};

  # XXXXX Check to make sure we're not overwriting any fields!

  while ( ($canf, $canv) = each %can) {
    if (defined $can_to_ref_fields{$canf}) {
      $rec{$can_to_ref_fields{$canf}} = $canv;
    } else {
      &bib'gotwarn("Unknown field: $canf");
      $rec{$canf} = $canv;
    }
  }

  %rec;
}

######

sub clear {
}


#######################
# end of package
#######################

1;
