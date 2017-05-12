#
# bibliography package for Perl
#
# BibTeX routines
#
# Dana Jacobsen (dana@acm.org)
# 8 July 1995 (last modified 30 November 1995)
#
# 30 Nov 95: Changed the way string parsing works.  It used to do a search
#            and replace over the entire string, but some bibliographies make
#            a string named, "el" for instance, which will just trash the
#            entire file.  So we look for _1_ unquoted string on the same
#            line as the field name.  That's a lot safer, but also won't
#            properly handle multiple strings on a line, or strings not in
#            the first position.  Those are fairly rare though.
#
# XXXXX Parsing BibTeX is extremely difficult to do correctly in Perl.  The
#       proper thing to do in my opinion is to write a yacc parser and compile
#       that in.  Not only will it be able to handle more bizarre cases
#       properly, but it will probably be much faster.

package bp_bibtexo;

$version = "bibtex (dj 23 mar 96)";

######

&bib'reg_format(
  'bibtexo',    # name
  'btx',       # short name
  'bp_bibtexo', # package name
  'tex',       # default character set
  'suffix is bib',
# our functions
  'open is standard',
  'close is standard',
  'write is standard',
  'options',
  'read',
  'explode',
  'implode',
  'tocanon',
  'fromcanon',
  'clear',
);

######

# Set to 0 for handling bibclean (faster, but makes a lot of assumptions)
#        1 for arbitrary bibtex
#
$opt_complex = 1;

######

sub options {
  local($opts) = @_;

  &bib'gotwarn("setting BibTeX options to $opts\n", 'bibtex');
}

######

$glb_eval_repl = 0;
%glb_replace = ();
$glb_replace = '';

$ent = '';


$protectB = "${bib'cs_meta}3100";
$protectE = "${bib'cs_meta}3110";
######

# XXXXX todo:
#
#	handle multi-line string statements
#	don't just throw away preamble statements
#	handle crossref fields (Ack, we'd have to keep reading until we
#		found the cross reference....  Maybe it should go in
#		explode instead?)
#       mismatched braces in an entry will make us read the whole file
#               looking for the ending brace!!
#
# It ssems like reading BibTeX records are perfect for a program like
# yacc/lex or a similar state machine.  The format is nice and regular,
# but it contains too many oddities for a nice perl implmentation.  The
# best way I can describe the problem is that it is character based, rather
# than line based, like refer.  We can even have the end of one record on
# the same line as the beginning of the next.
#
#   The opt_complex variable can be set to 0 to remove most of the time-
# consuming regex stuff.  This will only work if the file has been run
# through bibclean, or is otherwise "regular" (the @ of a start record
# must be flush left, only { and not scribe's ( are allowed to surround
# a record, and records end with a single } flush left by itself).
#
# This would be a perfect use for perl5's interface to a C program.  A
# fairly simple lex/yacc parser could be written and be _much_ faster
# as well as less error prone.
#
sub read {
  local($file) = @_;
  local($_);
  local($type);

  BREAD: {
    if ($opt_complex == 0) {
      while (<$bib'glb_current_fh>) {
        last if /^\@/;
      }
      return undef if eof;
      $ent = $_;

      $bib'glb_vloc = sprintf("line %5d", $.);

      ($type) = /^\@(\w+){/;
      return &bib'goterror("Unable to parse field $ent")  unless defined $type;

      # skip comments
      redo BREAD if $type =~ /^comment/i;
      # we really ought to do something with this instead of tossing it
      redo BREAD if $type =~ /^preamble/i;

      if ($type =~ /^string/i) {
        # XXXXX should handle multi-line string statements.
        local($name, $value);
        if ( ($name,$value) = /^\@string{(\S+)\s*=\s*"([^"]*)"}$/i) {
          $name =~ s/(\W)/\\$1/g;   # quote special chars
          $name =~ s/\\ / /g;
          $value =~ s/(\W)/\\$1/g;
          $value =~ s/\\ / /g;
          $glb_replace .= "s/\\b$name\\b/$value/g;\n";
          $glb_eval_repl = 1;
          redo BREAD;
        } else {
          &bib'gotwarn("Could not parse field $ent");
        }
      }

      while (<$bib'glb_current_fh>) {
        $ent .= $_;
        last if  /^\}\s*$/;
      }
    } elsif ($opt_complex == 1) {
      local($braces) = 1;
      local($delim);

      while (<$bib'glb_current_fh>) {
        if (/^\s*\@/) {
          $ent = $_;
          last;
        }
      }
      return undef if eof;

      $bib'glb_vloc = sprintf("line %5d", $.);

      ($type, $delim) = $ent =~ /^\s*\@\s*(\w+)\s*([{(])/;
      return &bib'goterror("Unable to parse field $ent")  unless defined $type;

      # skip comments
      redo BREAD if $type =~ /^comment/i;
      # we really ought to do something with this instead of tossing it
      redo BREAD if $type =~ /^preamble/i;

      if ($type =~ /^string/i) {
        # XXXXX should handle multi-line string statements.
        # XXXXX should be smarter about not going inside "" or {}.
        local($name, $value);
        if ( ($name,$value) = /^\s*\@\s*string{\s*(\S+)\s*=\s*([^}]*)\s*}/i) {
          if ($name =~ /\W/) {
            &bib'gotwarn("Illegal string name: $name");
          } else {
            $name =~ tr/A-Z/a-z/;
            &bib'gotwarn("Redefinition of string: $name") if defined $glb_replace{$name};
            #$value =~ s/(\W)/\\$1/g;
            $glb_replace{$name} = $value;
            $glb_eval_repl = 1;
          }
        } else {
          &bib'gotwarn("Couldn't parse string entry");
        }
        redo BREAD;
      }

      if (!/,/) {         # preamble is split on multiple lines
        while (<$bib'glb_current_fh>) { 
          $ent .= $_;
          last if /,/;
        }
        return undef if eof;
      }

      if ($delim eq '{') {
        while (<$bib'glb_current_fh>) {
          # XXXXX This misses: foo = "bar" # bar2
          #                    foo = bar # bar2
          #                    foo = bar # bar2 # bar3
          if ($glb_eval_repl  &&  /^(\s*\S+\s*=\s*)(\w+)/) {
            if (defined $glb_replace{$2}) {
              s/^(\s*\S+\s*=\s*)(\w+)/$1$glb_replace{$2}/;
            }
          }
          $ent .= $_;
          while (/\{/g) { $braces++; }
          while (/\}/g) { $braces--; }
          last if ($braces <= 0);
        }
      } else {
        while (<$bib'glb_current_fh>) {
          if ($glb_eval_repl  &&  /^(\s*\S+\s*=\s*)(\w+)/) {
            if (defined $glb_replace{$2}) {
              s/^(\s*\S+\s*=\s*)(\w+)/$1$glb_replace{$2}/;
            }
          }
          $ent .= $_;
          last if $ent =~ /\)\s*$/;
        }
      }
    } else {
      &bib'goterror("Unknown complexity level asked for");
    }
  }  # end of BREAD

  $_ = $ent;
  if ( ($opt_complex == 0) && $glb_eval_repl ) {
    study;
    eval $glb_replace;
    $@ && return &bib'goterror("Error in string eval, $@");
  }
  # string concatenation
  s/\"\s*\#\s*\"//g;
  $_;
}

######

sub explode {
  local($rec) = @_;
  local(%be_entry);
  local(@e_values);
  local($fld, $val);

  @e_values = split(/,\s*(\w+)\s*=\s*/, $rec);
  ($be_entry{'TYPE'}, $be_entry{'CITEKEY'}) =
       ( shift(@e_values) =~ /^\s*\@\s*(\w+)\s*[{(]\s*(\S+)/ );
  &bib'goterror("error exploding bibtex record") unless scalar(@e_values) > 1;
  $e_values[$#e_values] =~ s/\s*,?\s+[})]\s*$//;  # zap the final delimiter
  while (@e_values) {
      ($fld, $val) = splice(@e_values, 0, 2);
      $fld =~ tr/A-Z/a-z/;
      $val =~ s/^\s*\{((.|\n)*)\}\s*$/$1/
   || $val =~ s/^\s*\"((.|\n)*)\"\s*$/$1/;
      # XXXXX Check to see if squeezing spaces here is ok.
      $val =~ s/\s+/ /g;
      $be_entry{$fld} = $val;
  }
  %be_entry;
}

######

# This is the ordering r2b uses.
%i_order = (
'key',		10,
'author',	20,
'affiliation',	25,
'editor',	30,
'title',	40,
'booktitle',	50,
'institution',	60,
'school',	70,
'journal',	80,
'type',		90,
'series',	100,
'volume',	110,
'number',	120,
'edition',	130,
'chapter',	140,
'pages',	150,
'publisher',	160,
'address',	170,
'month',	180,
'year',		190,
'price',	200,
'copyright',	210,
'keywords',	220,
'mrnumber',	230,
'language',	240,
'annote',	250,
'isbn',		260,
'ISBN',		261,
'issn',		270,
'ISSN',		271,
'subject',      275,
'abstract',	280,
'note',		290,
'contents',	300,
'url',		310,
);
sub bykey {
  # undefined fields always go last
  return 1 unless defined $i_order{$a};
  return -1 unless defined $i_order{$b};
  $i_order{$a} <=> $i_order{$b};
}

sub implode {
  local(%entry) = @_;
  local($ent);

  return &bib'goterror("BibTeX: no TYPE field") unless defined $entry{'TYPE'};
  return &bib'goterror("BibTeX: no CITEKEY field") unless defined $entry{'CITEKEY'};

  $ent = join("", '@', $entry{'TYPE'}, '{', $entry{'CITEKEY'}, ",\n");
  delete $entry{'TYPE'};
  delete $entry{'CITEKEY'};

  # I hope we're using the TeX character set, because if $entry{$field}
  # contains a { without matching }'s, we're going to have hell to pay
  # when we try to read it.  We could check for it here, but what would
  # we replace it with?  $\lbrace$ is TeX-specific.  It's also very slow.
  foreach $field (sort bykey keys %entry) {
    $ent .= "   $field = \{$entry{$field}\},\n";
  }

  # This should be smarter
  $ent =~ s/   month = \{(...)\},/   month = \L$1,/;

  substr($ent, -2, 1) = '';
  $ent .= "\}\n";

  # We now might have some fields that still have separators left in them,
  # notably the keywords field.  Right now we change them to space.
  # XXXXX Should this be a newline, ';', '/', ',', or space?
  $ent =~ s/$bib'cs_sep/ /go;

  $ent;
}

######

# XXXXX A type field in an inbook citation does not mean ReportType, but
#       the type of section.

%btx_to_can_fields =
   ('CITEKEY',      'CiteKey',
    'title',        'Title',
    'booktitle',    'SuperTitle',
    'affiliation',  'AuthorAddress',
    'school',       'School',
    'organization', 'Organization',
    'journal',      'Journal',
    'type',         'ReportType',
    'series',       'Series',
    'volume',       'Volume',
    'edition',      'Edition',
    'chapter',      'Chapter',
    'pages',        'Pages',
    'howpublished', 'HowPublished',
    'institution',  'Organization',
    'publisher',    'Publisher',
    'address',      'PubAddress',
    'month',        'Month',
    'year',         'Year',
    'price',        'Price',
    'copyright',    'Copyright',
    'keywords',     'Keywords',
    'mrnumber',     'MRNumber',
    'language',     'Language',
    'annote',       'Annotation',
    'isbn',         'ISBN',
    'issn',         'ISSN',
    'subject',      'Field',
    'abstract',     'Abstract',
    'note',         'Note',
    'contents',     'Contents',
    'key',          'Key',
    'url',          'Source',
   );

sub tocanon {
  local(%rec) = @_;
  local(%can);
  local($name, $btxf, $canf, $btxv);

  local($_) = $rec{'TYPE'};
  tr/A-Z/a-z/;
  #                  NEW CANON TYPE <-- ORIGINAL BIBTEX
  $can{'CiteType'} = 'article'       if /^article/;
  $can{'CiteType'} = 'book'          if /^book/;
  $can{'CiteType'} = 'book'          if /^booklet/;
  $can{'CiteType'} = 'book'          if /^collection/;
  $can{'CiteType'} = 'inproceedings' if /^conference/;
  $can{'CiteType'} = 'inbook'        if /^inbook/;
  $can{'CiteType'} = 'inbook'        if /^incollection/;
  $can{'CiteType'} = 'inproceedings' if /^inproceedings/;
  $can{'CiteType'} = 'manual'        if /^manual/;
  $can{'CiteType'} = 'thesis'        if /^mastersthesis/;
  $can{'CiteType'} = 'misc'          if /^misc/;
  $can{'CiteType'} = 'thesis'        if /^phdthesis/;
  $can{'CiteType'} = 'proceedings'   if /^proceedings/;
  $can{'CiteType'} = 'report'        if /^techreport/;
  $can{'CiteType'} = 'unpublished'   if /^unpublished/;

  if (!defined $can{'CiteType'}) {
    &bib'gotwarn("Improper entry type: $rec{'TYPE'}");
    $can{'CiteType'} = 'misc';
  }

  if (!defined $rec{'type'}) {
    if ( $rec{'TYPE'} =~ /^phdthesis/i ) {
      $rec{'type'} = 'Ph.D.';
    } elsif ( $rec{'TYPE'} =~ /^mastersthesis/i ) {
      $rec{'type'} = 'Masters';
    }
  }


  if (defined $rec{'author'} ) {
    # check for braces around the whole name, in which case we will
    # assume it is a corporate author.
    if ( ($rec{'author'} =~ /^\{/) && ($rec{'author'} =~ /\}$/) ) {
      $can{'CorpAuthor'} = substr($rec{'author'}, $[+1, length($rec{'author'})-2);
    } else {
      $can{'Authors'} = &bibtex_name_to_canon( $rec{'author'} );
    }
    delete $rec{'author'};
  }

  if (defined $rec{'editor'}) {
    $can{'Editors'} = &bibtex_name_to_canon( $rec{'editor'} );
    # XXXXX either we don't need this, or we need it for authors also.
    delete $can{'Editors'} unless $can{'Editors'} =~ /\S/;
    delete $rec{'editor'};
  }

  if ( defined $rec{'organization'} && defined $rec{'school'} )  {
    &bib'gotwarn("Both school and organization defined.");
    delete $rec{'school'};
  }

  if ( defined $rec{'publisher'} && defined $rec{'institution'} )  {
    &bib'gotwarn("Both publisher and institution defined.");
    delete $rec{'institution'};
  }

  if (defined $rec{'number'}) {
    if ($can{'CiteType'} =~ /report|thesis/) {
      $can{'ReportNumber'} = $rec{'number'};
    } else {
      $can{'Number'} = $rec{'number'};
    }
    delete $rec{'number'};
  }

  if (defined $rec{'month'}) {
    $can{'Month'} = &bp_util'canon_month($rec{'month'});
    delete $rec{'month'} if defined $can{'Month'};
  }

  # done with massaging the fields
  delete $rec{'TYPE'};

  while ( ($btxf, $btxv) = each %rec) {
    next unless $btxv =~ /\S/;
    if (defined $btx_to_can_fields{$btxf}) {
      $can{$btx_to_can_fields{$btxf}} = $btxv;
    } else {
      # Unknown, so enter literal.  Perhaps a warning?
      $can{$btxf} = $btxv;
    }
  }

  # Handle title-like fields.
  foreach $canf ('Title', 'SuperTitle', 'ReportType') {
    next unless defined $can{$canf};
    $can{$canf} =~ s/\{([^\s}]+)\}/${bib'cs_meta}3100$1${bib'cs_meta}3110/g;
    $can{$canf} =~ s/\s\s+/ /g;
  }

  # tell them who we are
  $can{'OrigFormat'} = $version;

  %can;
}

######
#
# This routine will convert a BibTeX name into it's canon form.
# It protects items in braces, such as {O'Rielly and Associates}, so that
# they are dealt with as one unit.
#

sub bibtex_name_to_canon {
  local($name) = @_;
  local($n);
  local($vonlast, $von, $last, $jr, $first, $part);
  local(@savechars);
  local($saveptr) = '00';
  local($canon_name) = '';

  $name =~ s/\s+/ /g;

  # Move each item enclosed in braces to an atomic character.
  while ($name =~ s/(\{[^\}]*\})/$bib'cs_temp$saveptr/) {
    push(@savechars, $1);
    $saveptr++;
  }

  foreach $n ( split(/ and /, $name) ) {

    if ( ($vonlast, $jr, $first) = $n =~ /^([^,]*),\s*([^,]*),\s*([^,]*)$/ ) {
      # sep vonlast
    } elsif ( ($vonlast, $first) = $n =~ /([^,]*),\s*([^,]*)/ ) {
      $jr = '';
      # sep vonlast
    } else {
      $first = '';
      $jr = '';
      $vonlast = '';
      foreach $part (split(/ /, $n)) {
        if ($part =~ /^[^a-z]/ && ($vonlast eq '')) {
          $first .= " $part";
        } else {
          $vonlast .= " $part";
        }
      }
    }
    $vonlast =~ s/^\s+//;
    $von = '';
    if ($vonlast ne '') {
      if ( $vonlast =~ /^[a-z]/ ) {
        $last = '';
        foreach $part (split(/ /, $vonlast)) {
          if ($part =~ /^[a-z]/ && ($last eq '')) {
            $von .= " $part";
          } else {
            $last .= " $part";
          }
        }
        $von =~ s/^\s+//;
        $last =~ s/^\s+//;
      } else {
        $last = $vonlast;
      }
    } else {
      ($first, $last) = ($first =~ /^(.*)\s+(\S+)$/);
    }
    $first =~ s/^\s+//;

    $canon_name .= $bib'cs_sep . join($bib'cs_sep2, $last, $von, $first, $jr);
  }
  $canon_name =~ s/^$bib'cs_sep//o;

  if (@savechars) {
    local($oldchar, $oldcharmb);
    $saveptr = '00';
    while (@savechars) {
      $oldchar = shift @savechars;
      $oldcharmb = $oldchar;
      $oldcharmb =~ s/^{(.*)}$/$1/;
      $canon_name =~ s/(^|$bib'cs_sep|$bib'cs_sep2)$bib'cs_temp$saveptr($|$bib'cs_sep|$bib'cs_sep2)/$1$oldcharmb$2/  ||  $canon_name =~ s/$bib'cs_temp$saveptr/$oldchar/;
      $saveptr++;
    }
  }

  $canon_name;
}

######

# XXXXX We really ought to generate these at load time from the other list.
# XXXXX Format?

%can_to_btx_fields =
   ('CiteKey',      'CITEKEY',
    'Title',        'title',
    'SuperTitle',   'booktitle',
    'AuthorAddress','affiliation',
    'School',       'school',
    'Organization', 'organization',
    'Journal',      'journal',
    'ReportType',   'type',
    'Series',       'series',
    'Volume',       'volume',
    'Edition',      'edition',
    'Chapter',      'chapter',
    'Pages',        'pages',
    'PagesWhole',   'pages',
    'HowPublished', 'howpublished',
    'Publisher',    'publisher',
    'PubAddress',   'address',
    'Month',        'month',
    'Year',         'year',
    'Price',        'price',
    'Copyright',    'copyright',
    'Keywords',     'keywords',
    'MRNumber',     'mrnumber',
    'Language',     'language',
    'Annotation',   'annote',
    'ISBN',         'isbn',
    'ISSN',         'issn',
    'Field',        'subject',
    'Abstract',     'abstract',
    'Note',         'note',
    'Contents',     'contents',
    'Key',          'key',
    'Source',       'url',
   );

sub fromcanon {
  local(%reccan) = @_;
  local(%record);
  local($name, $btxf, $canf, $canv);

  if (!defined $reccan{'CiteType'}) {
    &bib'gotwarn("BibTeX didn't find a CiteType field!");
    $reccan{'CiteType'} = 'book';
  }

  # XXXXX 22Mar96: I think we had some mixup with incollection vs. inbook.

  local($_) = $reccan{'CiteType'};
  if    (/^article/       ) { $record{'TYPE'} = 'article'; }
  elsif (/^avmaterial/    ) { $record{'TYPE'} = 'misc'; }
  elsif (/^book/          ) {
    if (defined $reccan{'Publisher'}) { $record{'TYPE'} = 'book'; }
    else                              { $record{'TYPE'} = 'booklet'; } }
  elsif (/^inbook/        ) {
    if (defined $reccan{'SuperTitle'}) { $record{'TYPE'} = 'incollection' }
    else                               { $record{'TYPE'} = 'inbook'; } }
  elsif (/^inproceedings/ ) { $record{'TYPE'} = 'inproceedings'; }
  elsif (/^manual/        ) { $record{'TYPE'} = 'manual'; }
  elsif (/^misc/          ) { $record{'TYPE'} = 'misc'; }
  elsif (/^thesis/        ) {
    if ( (defined $reccan{'ReportType'}) && ($reccan{'ReportType'} =~ /master/i)
       )                    { $record{'TYPE'} = 'mastersthesis' }
    else                    { $record{'TYPE'} = 'phdthesis'; } }
  elsif (/^proceedings/   ) { $record{'TYPE'} = 'proceedings'; }
  elsif (/^report/        ) { $record{'TYPE'} = 'techreport'; }
  elsif (/^unpublished/   ) { $record{'TYPE'} = 'unpublished'; }
  else {
    &bib'gotwarn("Improper entry type: $reccan{'CiteType'}");
    $record{'TYPE'} = 'misc';
  }

  # generate key if necessary, using the default method.
  $reccan{'CiteKey'} = &bp_util'genkey(%reccan) unless defined $reccan{'CiteKey'};

  # register our citekey
  $reccan{'CiteKey'} = &bp_util'regkey($reccan{'CiteKey'});

  if ( defined $reccan{'Authors'} ) {
    $record{'author'} = &bp_util'canon_to_name($reccan{'Authors'}, 'bibtex');
    delete $reccan{'Authors'};
    if ($record{'author'} !~ / /) {
      if ($record{'author'} =~ s/\240/ /g) {
        $record{'author'} = $protectB . $record{'author'} . $protectE;
      }
    }
  }
  if ( defined $reccan{'CorpAuthor'} ) {
    # no need for no-break spaces, as we're putting braces around it.
    $reccan{'CorpAuthor'} =~ s/\240/ /g;
    if (defined $record{'author'}) {
      if (defined $reccan{'Organization'}) {
        $record{'author'} .= ' and ' . $protectB . $reccan{'CorpAuthor'} . $protectE;
      } else {
        $record{'organization'} = $reccan{'CorpAuthor'};
      }
    } else {
      $record{'author'} = $protectB . $reccan{'CorpAuthor'} . $protectE;
    }
    delete $reccan{'CorpAuthor'};
  }

  if ( defined $reccan{'Editors'} ) {
    $record{'editor'} = &bp_util'canon_to_name($reccan{'Editors'}, 'bibtex');
    delete $reccan{'Editors'};
  }

  if ( $reccan{'CiteType'} =~ /^(report|unpublished)/ ) {
    if ( defined $reccan{'Publisher'} ) {
      $record{'institution'} = $reccan{'Publisher'};
      delete $reccan{'Publisher'};
    } elsif ( defined $reccan{'Organization'} ) {
      $record{'institution'} = $reccan{'Organization'};
      delete $reccan{'Organization'};
    }
  }

#  if ( $reccan{'CiteType'} =~ /^thesis/ ) {
#    if ( defined $reccan{'Organization'} ) {
#      $record{'school'} = $reccan{'Organization'};
#      delete $reccan{'Organization'};
#    }
#  }

  if (defined $reccan{'ReportNumber'}) {
    if (defined $reccan{'Number'}) {
      &bib'gotwarn("Both Number and ReportNumber.");
      delete $reccan{'Number'};
    }
    if ($reccan{'CiteType'} !~ /report|thesis/) {
      &bib'gotwarn("ReportNumber defined, but not in a report.");
    }
    $record{'number'} = $reccan{'ReportNumber'};
    delete $reccan{'ReportNumber'};
  } elsif (defined $reccan{'Number'}) {
    if ($reccan{'CiteType'} =~ /report|thesis/) {
      &bib'gotwarn("Number defined inside a report.");
    }
    $record{'number'} = $reccan{'Number'};
    delete $reccan{'Number'};
  }

  if (defined $reccan{'ReportType'}) {
    if ($reccan{'ReportType'} !~ /($protectB|$protectE)/o) {
      $reccan{'ReportType'} =~ s/Ph\.\s*D\./${protectB}Ph.D.${protectE}/o;
    }
  }

  # done with massaging the fields
  delete $reccan{'CiteType'};
  # We don't know any special information about any types
  delete $reccan{'OrigFormat'};

  while ( ($canf, $canv) = each %reccan) {
    if (defined $can_to_btx_fields{$canf}) {
      $record{$can_to_btx_fields{$canf}} = $canv;
    } else {
      &bib'gotwarn("Unknown field: $canf");
      $record{$canf} = $canv;
    }
  }

  %record;
}

######

sub clear {
  local($file) = @_;

  # XXXXX currently we have just one strings mapping for all files.

  %glb_replace = ();
  $glb_eval_repl = 0;
}


#######################
# end of package
#######################

1;
