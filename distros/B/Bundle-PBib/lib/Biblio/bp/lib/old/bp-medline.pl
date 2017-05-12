#
# bibliography package for Perl
#
# Medline
#
# Dana Jacobsen (dana@acm.org)
# 22 January 1995 (last modified 17 January 1996)
#
# Note that there are many, many variations of the format called "medline".
# This currently reads the MEDLARS format used by Entrez (available at
# <http://atlas.nlm.nih.gov:5700/Entrez/index.html>).  I believe it also
# handles BRS MedLine.
#
# It does NOT understand MELVYL MEDLINE D TAG format, since that format
# is incompatable with MEDLARS.  It looks very similar, but uses different
# tag names for each field.  It should not be hard to modify this to read
# that format.
#

package bp_medline;

$version = "medline (dj 17 jan 96)";

######

&bib'reg_format(
  'medline',    # name
  'med',        # short name
  'bp_medline', # package name
  'none',       # default character set
  'suffix is med',
# our functions
  'options',
  'open is standard',
  'close is standard',
  'read',
  'write is standard',
  'clear is standard',
  'explode',
  'implode is unsupported',
  'tocanon',
  'fromcanon is unsupported',
);

######

$opt_html = 0;

######

sub options {
  local($opt) = @_;

  &bib'panic("medline options called with no arguments!") unless defined $opt;
  &bib'debugs("parsing medline option '$opt'", 64);
  return undef unless $opt =~ /=/;
  local($_, $val) = split(/\s*=\s*/, $opt, 2);
  &bib'debugs("option split: $_ = $val", 8);
  /^html$/       && do { $opt_html = &bib'parse_num_option($val);
                         return 1; };
  undef;
}

######

# We have our own read routine because we would like to handle the case
# of HTML output from Entrez.  For example, turn on the HTML option, then
# it can parse the output of:
#   <http://atlas.nlm.nih.gov:5700/htbin-post/Entrez/query?
#    db=m&form=4&term=ras&field=word&dispmax=10&dopt=l&title=no>
# directly.  Unfortunately, we have to do this specially since they don't
# put blank lines between entries.

sub read {
  local($file) = @_;
  local($record);

  &bib'debugs("reading $file<$bib'glb_current_fmt>", 32);

  if ($opt_html) {
    local($/) = '</pre>';
    $record = scalar(<$bib'glb_current_fh>);
    $record =~ s/^<HR>\s*//;
    $record =~ s/^<pre>\s*//;
    # Check for the last part of the file.  If we think we found it,
    # read again.  This should yield an eof.
    if ($record =~ /^<\/form>\s*$/) {
      $record = scalar(<$bib'glb_current_fh>);
    }
  } else {
    # read a paragraph
    local($/) = '';
    $record = scalar(<$bib'glb_current_fh>);
  }
  $record;
}

######

sub explode {
  local($_) = @_;
  local(%entry) = ();
  local($val);

  local($field) = undef;
  local(@lines) = split(/\n/);

  foreach (@lines) {
    if (/^<title>.*<\/title>$/) {
      next if $opt_html;
      # We could guess that it's html and change options here.
    }
    if ($opt_html) {
      s/^<pre>\s*//i;
      next if /^</;
      next if /^\s*$/;
    }
    if (/^\s/) {
      return &bib'goterror("Medline explode--Problems parsing entry") unless defined $field;
      s/^\s+//;
      $entry{$field} .= " " . $_;
      next;
    }
    if (/^[A-Z]/) {
      ($field, $val) = /^([A-Z]+)\s*-\s*(.*)/;
      if (defined $entry{$field}) {
        $entry{$field} .= $bib'cs_sep . $val;
      } else {
        $entry{$field} = $val;
      }
      next;
    }
    next if /^\d+$/;   # RefMan puts numbers here
    &bib'gotwarn("Medline explode--can't parse: $_");
  }

  %entry;
}

######


sub implode {
  local(%entry) = @_;
  return &bib'goterror("medline implode isn't supported.");
}

######

# We want to check for any fields we don't recognize, because we don't
# have documentation on the format, so there may be something important
# being missed.

%med_to_can_fields = (
  'MH', 'Keywords',
  'AD', 'AuthorAddress',
  'TI', 'Title',
  'AB', 'Abstract',
  'BK', 'SuperTitle',
  'TA', 'Journal',
  'PB', 'Publisher',
  'Yr', 'Year',
  'Mo', 'Month',
  'PG', 'Pages',
  'VI', 'Volume',
  'IP', 'Number',
  'UI', 0,
  'RN', 0,
  'EM', 0,
  'GS', 0,
  'SI', 0,
);


sub tocanon {
  local(%entry) = @_;
  local(%can);
  local($type, $field);

  # AU
  if (defined $entry{'AU'}) {
    local($n);
    $can{'Authors'} = '';
    foreach $n (split(/$bib'cs_sep/, $entry{'AU'})) {
      $can{'Authors'} .= $bib'cs_sep . &medname_to_canon($n);
    }
    $can{'Authors'} =~ s/^$bib'cs_sep//;
  }
  # ED
  if (defined $entry{'ED'}) {
    $can{'Editors'} = '';
    foreach $n (split(/$bib'cs_sep/, $entry{'ED'})) {
      $can{'Editors'} .= $bib'cs_sep . &medname_to_canon($n);
    }
    $can{'Editors'} =~ s/^$bib'cs_sep//;
  }

  # Sometimes the SO field is split out into seperate fields, sometimes not.
  # We check the DP and VI fields -- if they exist, assume that SO is split.
  # XXXXX We ought to check to split SO anyway and compare the results.
  #       Alternatively, we could have an option for 1) always use split
  #       fields, 2) always split SO and use the results, 3) what we do now
  #       which is make a good guess.

  if ( (!defined $entry{DP}) || (!defined $entry{VI}) ) {
    &parseSO;
  }

  # split DP into year and month
  if ( !(($entry{Yr}, $entry{Mo}) = $entry{DP} =~ /(\S+)\s+(.*)/) ) {
    $entry{Yr} = $entry{DP};
    delete $entry{Mo};
  }
  delete $entry{SO};
  delete $entry{DP};

  # determine entry type
  if ($entry{BK}) {
    $entry{PB} = $entry{TA};
    delete $entry{TA};
    if ($entry{AU}) {
      $type = 'inbook';
      if ($entry{BK} =~ /^proc\w*\.\s/i || /proceeding/i || /conference/i || /workshop/i) {
        $type = 'inproceedings';
      }
    } else {
      $type = 'proceedings';
    }
  } else {
    $type = 'article';
    # XXXXX We might want to expand this.  Entrez doesn't put conference
    #        notation in the TA field, but instead in the TI field.
    # This next line is an attempt to grab conference proceedings out of the
    # TI field, which is where Entrez puts them.
    if ($entry{TI} =~ s/\.\s+Conference proceedings\.\s+(.*,\s+.*),\s+([A-Z].*),\s+(\d+)\.\s*$//) {
       $type = 'proceedings';
       $can{'Location'} = $1;
       # What to do with the date?
    } elsif ($entry{TA} =~ /^proc\w*\.\s/i || /proceeding/i || /conference/i || /workshop/i) {
      $type = 'inproceedings';
      $entry{BK} = $entry{TA};
      delete $entry{TA};
    } elsif (!$entry{AU}) {
      $type = 'proceedings';
      $entry{PB} = $entry{TA};
      delete $entry{TA};
    }
  }
  $can{'CiteType'} = $type;

  delete $entry{AU};
  delete $entry{ED};

  foreach $field (keys %entry) {
    if (!defined $med_to_can_fields{$field}) {
      &bib'gotwarn("Unknown field: $field");
    } elsif ($med_to_can_fields{$field}) {
      $can{$med_to_can_fields{$field}} = $entry{$field};
    }
  }

  $can{'OrigFormat'} = $version;
  %can;
}

# takes a SO entry and splits it into seperate fields
sub parseSO {
  local($journal, $year, $month, $volume, $pages);

  if (! (($journal, $year, $month, $volume, $pages)
          = $entry{SO} =~ /(.*)\s+(\d\d\d\d)\s*(.*);(.*):(.*)$/) ) {
    return &bib'gotwarn("Couldn't parse SO field: $entry{SO}");
  }
  $entry{TA} = $journal unless $journal =~ /^\s*$/;
  $entry{DP} = $year;
  $entry{DP} .= " $month" unless $month =~ /^\s*$/;
  if (defined $volume) {
    if ( !(($entry{VI}, $entry{IP}) = $volume =~ /(\d*)\s*\((\d*)\)/) ) {
      $entry{VI} = $volume;
    }
  }
  $entry{PG} = $pages unless $pages =~ /^\s*$/;
}

sub medname_to_canon {
  local($name) = @_;
  local($last, $von, $first, $cname);

  ($last, $first) = $name =~ /(.*)\s+([A-Z]*)$/;
  $last = '' unless defined $last;
  $first = '' unless defined $first;
  $first =~ s/([A-Z])/$1. /g;
  $first =~ s/\s+$//;
  $von = '';
  # (the von processing is from name_to_canon in bp-p-utils.pl)
  while ($last =~ /^([a-z]+)\s+/) {
    $von .= " $1";
    substr($last, 0, length($1)+1) = '';
  }
  $von =~ s/^ //;
  
  $cname = join( $bib'cs_sep2, $last, $von, $first, '');
  $cname;
}

######


#######################
# end of package
#######################

1;
