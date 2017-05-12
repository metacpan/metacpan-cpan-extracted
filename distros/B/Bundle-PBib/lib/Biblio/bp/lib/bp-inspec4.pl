#
# bibliography package for Perl
#
# INSPEC style 4 routines
#
# Dana Jacobsen (dana@acm.org)
# 15 January 1996
#
# These routines convert style 4.  See the main INSPEC routines for more
# details on styles.

package bp_inspec4;

$version = "inspec4 (dj 15 jan 96)";

######

&bib'reg_format(
  'inspec4',   # name
  'ip4',       # short name
  'bp_inspec4',# package name
  '8859-1',    # default character set
  'suffix is inspec',
# functions
  'open      is standard',
  'close     is standard',
  'write     is standard',
  'clear',
  'read',
  'options',
  'explode',
  'tocanon',
  'implode   is unsupported',
  'fromcanon is unsupported',
);

######

$glb_last = '';

######

sub options {
  local($opts) = @_;

  print "setting options to $opts\n";
}

######

sub clear {
  $glb_last = '';
}

######

sub read {
  local($file) = @_;
  local($ent) = '';

  # XXXXXX This is bad -- we save up data from the last read in one
  #        variable.  We should at least index it by filename.

  return undef unless defined $glb_last;

  if ($glb_last eq '') {
    # This is our first read on this file.  Throw away any headers.
    while (<$bib'glb_current_fh>) {
      last if /^\s*INSPEC\s/;
    }
    return undef if eof;
    s/\r$//;
    $glb_last = $_;
  }
  while (<$bib'glb_current_fh>) {
    s/\r$//;
    last if /^\s*INSPEC\s/;
    $ent .= $_;
  }
  substr($ent,0,0) = $glb_last;
  if (!eof) {
    $glb_last = $_;
  } else {
    $glb_last = undef;
  }
  $ent;
}

######

sub explode {
  local($rec) = @_;
  local(%entry);
  local(@lines);
  local($line);
  local($fld, $val);

  # Some extra magic is done here to deal with the way this INSPEC format
  # was poorly thought out.  It shoves extra fields into the data section
  # of various common fields, which makes it difficult to parse.

  $rec =~ s/\n ([A-Z])/\n$1/g;
  1 while $rec =~ s/\n\s+([A-Z][\w .]+): ([^\n]+)  ([A-Z][\w .]+): ([^\n]+)/\n$1:   $2\n$3:   $4/;
  1 while $rec =~ s/\n\s+([A-Z][\w .]+): ([^\n]+)\s*\n/\n$1:   $2\n/;
  $rec =~ s/\s*  p\. ([\d-]+)\s*\n/\nPages:   $1\n/;
  $rec =~ s/\s*  ([ivx+\d]+) pp\.\s*\n/\nTotal Pages:   $1\n/;
  $rec =~ s/(\n\s*Publisher:\s+[^\n]+)\n\s+([^\n]+)\n/$1\nPub Address:   $2\n/;
  $rec =~ s/\s*\n\s+/ /g;

  # Parse the first line
  @lines = split(/\n/, $rec);
  $line = shift @lines;
  ($entry{'AN'}) = ($line =~ /^\s*INSPEC\s+(\S+)\s+/);
  foreach $line (@lines) {
    ($fld, $val) = ($line =~ /^\s*([^:]+):\s*(.*)$/);
    $entry{$fld} = $val;
  }
  %entry;
}

######

######

sub tocanon {
  local(%ent) = @_;
  local(%can);
  local($field);
  local(@cname);
  local(@lines);

  $can{'CiteKey'} = $ent{'AN'};
  $can{'classification'} = $ent{'CC'};

  if (defined $ent{'Doc Type'}) {
    local($_) = $ent{'Doc Type'};
    $can{'CiteType'} = 'inproceedings'	if /^Conference Paper$/;
    $can{'CiteType'} = 'proceedings'	if /^Conference Proceedings$/;
    $can{'CiteType'} = 'article'	if /^Journal Paper$/;
    $can{'CiteType'} = 'report'		if /^Report$/;
    $can{'CiteType'} = 'book'		if /^Book$/;
    $can{'CiteType'} = 'inbook'		if /^Book Article$/;
    $can{'CiteType'} = 'misc'		if /^Patent$/;
  }
  if (!defined $can{'CiteType'}) {
    if (defined $ent{'Doc Type'}) {
      &bib'gotwarn("Unrecognized Doc Type: $ent{'Doc Type'}");
    } else {
      &bib'gotwarn("No Doc Type field");
    }
    $can{'CiteType'} = 'misc';
  }

  @cname = ();
  foreach $field (split(/\s*;\s*/, $ent{'Authors'})) {
    push( @cname, &bp_util'name_to_canon($field, 'reverse') );
  }
  $can{'Authors'} = join($bib'cs_sep, @cname) if @cname;

  $can{'AuthorAddress'} = $ent{'Affiliation'} if defined $ent{'Affiliation'};

  @cname = ();
  foreach $field (split(/\s*;\s*/, $ent{'Editors'})) {
    push( @cname, &bp_util'name_to_canon($field, 'reverse') );
  }
  $can{'Editors'} = join($bib'cs_sep, @cname) if @cname;
  
  $can{'Title'}      = $ent{'Title'}       if defined $ent{'Title'};
  $can{'SuperTitle'} = $ent{'Conf. Title'} if defined $ent{'Conf. Title'};

  $can{'Journal'}    = $ent{'Journal'}     if defined $ent{'Journal'};
  $can{'Volume'}     = $ent{'Vol'}         if defined $ent{'Vol'};
  $can{'Number'}     = $ent{'Iss'}         if defined $ent{'Iss'};
  $can{'Pages'}      = $ent{'Pages'}       if defined $ent{'Pages'};
  $can{'Pages'}      = $ent{'Pages'}       if defined $ent{'Pages'};
  $can{'PagesWhole'} = $ent{'Total Pages'} if defined $ent{'Total Pages'};
  local($month, $year) = &bp_util'parsedate($ent{'Date'});
  $can{'Month'}      = $month              if (defined $month) && ($month ne '');
  $can{'Year'}       = $year               if (defined $year) && ($year ne '');
  $can{'ReportNumber'} = $ent{'Report No'} if defined $ent{'Report No'};
  $can{'Organization'} = $ent{'Issued by'} if defined $ent{'Issued by'};
  # Country of Publication
  $can{'Publisher'}  = $ent{'Publisher'}   if defined $ent{'Publisher'};
  $can{'PubAddress'} = $ent{'Pub Address'} if defined $ent{'Pub Address'};
  $can{'ISSN'}       = $ent{'ISSN'}        if defined $ent{'ISSN'};
  $can{'ISBN'}       = $ent{'ISBN'}        if defined $ent{'ISBN'};
  # CODEN
  $can{'CCC'}        = $ent{'CCC'}         if defined $ent{'CCC'};
  $can{'Language'}   = $ent{'Language'}    if defined $ent{'Language'};
  $can{'Subject'}    = $ent{'Treatment'}   if defined $ent{'Treatment'};
  $can{'Abstract'}   = $ent{'Abstract'}    if defined $ent{'Abstract'};
  $can{'classification'} = $ent{'Classification'} if defined $ent{'Classification'};
  $can{'Keywords'}   = $ent{'Thesaurus'}   if defined $ent{'Thesaurus'};
  if (defined $ent{'Free Terms'}) {
    if (defined $can{'Keywords'}) {
      $can{'Keywords'} .= '; ' . $ent{'Free Terms'};
    } else {
      $can{'Keywords'} = $ent{'Free Terms'};
    }
  }
  # Conf. Date
  # Conf. Loc
  # Conf. Sponsor

  # CCETT outlining the main fields of activity
  # Numerical Index
  # Translation of


  $can{'OrigFormat'} = $version;

  %can;
}

#######################
# end of package
#######################

1;
