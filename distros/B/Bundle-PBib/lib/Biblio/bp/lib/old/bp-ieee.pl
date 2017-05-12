#
# bibliography package for Perl
#
# IEEE catalog, from gopher://info.computer.org/11/Computer%20Society%20Press%20Catalog
#
# Dana Jacobsen (dana@acm.org)
# 17 January 1995  (last modified: 16 November 1995)
#

package bp_ieee;

$version = "ieee (dj 16 nov 95)";

######

&bib'reg_format(
  'ieee',    # name
  'iee',     # short name
  'bp_ieee', # package name
  'none',    # default character set
# our functions
  'options   is standard',
  'open      is standard',
  'close     is standard',
  'read',
  'write     is standard',
  'clear     is standard',
  'explode',
  'implode',
  'tocanon',
  'fromcanon is unsupported',
);

######

sub read {
  local($file) = @_;
  local($ent);

  &bib'debugs("reading $file<$glb_current_fmt>", 32, 'module');

  while (<$bib'glb_current_fh>) {
    s/\r$//;    # zap the stupid ^M's that are on each line.
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

  $entry{'title'} = '';
  while ($entry{'title'} =~ /^\s*$/) {
    $entry{'title'} = shift @values;
  }

  foreach (@values) {
    /^by (.*)/                 && do { $entry{'author'} = $1; next; };
    /^edited by (.*)/          && do { $entry{'editor'} = $1; next; };
    /^edited (.*)/             && do { $entry{'editor'} = $1; next; };
    /^Copyright (\d+)/         && do { $entry{'copyright'} = $1; next; };
    /^Computer S.*#\s*(.*)/    && do { $entry{'cs-cn'} = $1; next; };
    /^U\.S\. List Price: (.*)/ && do { $entry{'price'} = $1; next; };
    /^U\.S\. Memb.*: (.*)/     && do { $entry{'memprice'} = $1; next; };
    /^Non-U\.S\. List.*: (.*)/ && do { $entry{'nusprice'} = $1; next; };
    /^Non-U\.S\. Memb.*: (.*)/ && do { $entry{'nusmemprice'} = $1; next; };
    /^Category: (.*)/          && do { $entry{'category'} = $1; next; };
    /^ISBN #(.*)/              && do { $entry{'isbn'} = $1; next; };
    /^ISSN #(.*)/              && do { $entry{'issn'} = $1; next; };
    /^IEEE Catalog #\s*(.*)/   && do { $entry{'ieee-cn'} = $1; next; };
    /^(.*) pages\s*$/          && do { $entry{'pages'} = $1; next; };
    &bib'gotwarn("unknown line: $_");
  }
  # only one massage to do:
  if ( (defined $entry{'author'}) && ($entry{'author'} =~ /edited by (.*)/) ) {
    $entry{'editor'} = $1;
    $entry{'author'} =~ s/\s*\/?\s*edited by .*//;
  }

  %entry;
}

######


sub implode {
  local(%entry) = @_;
  local($ent);

  $ent = $entry{'title'} . "\n";

  $ent .= "by $entry{'author'}\n"               if defined $entry{'author'};
  $ent .= "edited by $entry{'editor'}\n"        if defined $entry{'editor'};
  $ent .= "$entry{'pages'} pages\n"             if defined $entry{'pages'};
  $ent .= "Copyright $entry{'copyright'}\n"     if defined $entry{'copyright'};
  $ent .= "Computer Society Catalog #$entry{'cs-cn'}\n"    if defined $entry{'cs-cn'};
  $ent .= "U.S. List Price: $entry{'price'}\n"  if defined $entry{'price'};
  $ent .= "U.S. Member Price: $entry{'memprice'}\n"        if defined $entry{'memprice'};
  $ent .= "Non-U.S. List Price: $entry{'nusprice'}\n"      if defined $entry{'nusprice'};
  $ent .= "Non-U.S. Member Price: $entry{'nusmemprice'}\n" if defined $entry{'nusmemprice'};
  $ent .= "ISBN #$entry{'isbn'}\n"              if defined $entry{'isbn'};
  $ent .= "ISSN #$entry{'issn'}\n"              if defined $entry{'issn'};
  $ent .= "IEEE Catalog # $entry{'ieee-cn'}\n"  if defined $entry{'ieee-cn'};
  $ent .= "Category: $entry{'category'}\n"      if defined $entry{'category'};

  $ent;
}

######

sub tocanon {
  local(%rec) = @_;
  local(%can);

  $can{'Title'} = $rec{'title'};
  $can{'PagesWhole'} = $rec{'pages'} if defined $rec{'pages'};
  $can{'Year'} = $rec{'copyright'} if defined $rec{'copyright'};
  $can{'Price'} = $rec{'price'} if defined $rec{'price'};
  $can{'ISBN'} = $rec{'isbn'} if defined $rec{'isbn'};
  $can{'ISSN'} = $rec{'issn'} if defined $rec{'issn'};
  $can{'Authors'} = &bp_util'mname_to_canon($rec{'author'}) if defined $rec{'author'};
  $can{'Editors'} = &bp_util'mname_to_canon($rec{'editor'}) if defined $rec{'editor'};

  if (!defined $rec{'category'}) {
    $can{'CiteType'} = 'misc';
  } elsif ($rec{'category'} eq 'Book') {
    $can{'CiteType'} = 'book';
  } elsif ($rec{'category'} eq 'Proceedings') {
    $can{'CiteType'} = 'proceedings';
  } elsif ($rec{'category'} eq 'Standard') {
    $can{'CiteType'} = 'report';
    $can{'ReportType'} = 'Standard';
  } elsif ($rec{'category'} eq 'Category') {
    # special category marker.
    return undef;
  } else {
    $can{'CiteType'} = 'misc';  # XXXXX avmaterial?
  }

  $can{'Publisher'} = 'IEEE Computer Society Press';
  $can{'OrigFormat'} = $version;

  %can;
}

######


#######################
# end of package
#######################

1;
