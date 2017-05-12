#
# bibliography package for Perl
#
# University of California Library -- Melvyl
#
# Dana Jacobsen (dana@acm.org)
# 8 November 1995
#
#        This has not been tested yet.
#

package bp_melvyl;

$version = "melvyl (dj 8 nov 95)";

######

&bib'reg_format(
  'melvyl',     # name
  'mel',        # short name
  'bp_melvyl',  # package name
  'none',       # default character set
  'suffix is mel',
# our functions
  'options is standard',
  'open is standard',
  'close is standard',
  'read is standard',
  'write is standard',
  'clear is standard',
  'explode',
  'implode is unsupported',
  'tocanon',
  'fromcanon is unsupported',
);

######

sub explode {
  local($_) = @_;
  local(%entry) = ();
  local($val);

  local($field) = undef;
  local(@lines) = split(/\n/);

  foreach (@lines) {
    if (/^\s/) {
      return &bib'goterror("Melvyl explode--Problems parsing entry") unless defined $field;
      s/^\s+/ /;
      $entry{$field} .= $_;
      next;
    }
    next unless /^[A-Z][A-Z]\s/;
    last if /^ZZ\s*$/;
    ($field, $val) = /^([A-Z]+)\s+(.*)/;
    $val =~ s/\s+$//;
    if (defined $entry{$field}) {
      $entry{$field} .= $bib'cs_sep . $val;
    } else {
      $entry{$field} = $val;
    }
  }

  %entry;
}

######


sub implode {
  local(%entry) = @_;
  return &bib'goterror("melvyl implode isn't supported.");
}

######

sub tocanon {
  local(%entry) = @_;
  local(%can);
  local($mon, $yr);

  # DT
  if (defined $entry{'DT'}) {
    if ($entry{'DT'} =~ /^ARTICLE/) {
      $can{'CiteType'} = 'article';
    } elsif ($entry{'DT'} =~ /^CONFERENCE PAPER/) {
      $can{'CiteType'} = 'inproceedings';
    } elsif ($entry{'DT'} =~ /^BOOK/) {
      $can{'CiteType'} = 'book';
    } elsif ($entry{'DT'} =~ /^GOVERNMENT DOCUMENT/) {
      $can{'CiteType'} = 'report';
    } else {
      $can{'CiteType'} = 'misc';
    }
  } else {
     &bib'gotwarn("missing type tag");
    $can{'CiteType'} = 'misc';
  }

  # PA
  if (defined $entry{'PA'}) {
    $can{'Authors'} = '';
    foreach $n (split(/$bib'cs_sep/, $entry{'PA'})) {
      $can{'Authors'} .= $bib'cs_sep . &melname_to_canon($n);
    }
    $can{'Authors'} =~ s/^$bib'cs_sep//;
  }

  $can{'Keywords'} = $entry{'SU'}  if defined $entry{'SU'};

  ($mon, $yr) = &bp_util'parsedate($entry{'DP'});
  $can{'Month'}         = $mon if $mon !~ /^\s*$/;
  $can{'Year'}          = $yr  if defined $yr;

  $can{'AuthorAddress'} = $entry{'AA'}  if defined $entry{'AA'};
  $can{'PubAddress'}    = $entry{'PL'}  if defined $entry{'PL'};
  $can{'Title'}         = $entry{'AT'}  if defined $entry{'AT'};
  $can{'Journal'}       = $entry{'JT'}  if defined $entry{'JT'};
  $can{'Language'}      = $entry{'LA'}  if defined $entry{'LA'};
  $can{'Publisher'}     = $entry{'PU'}  if defined $entry{'PU'};
  $can{'Volume'}        = $entry{'VO'}  if defined $entry{'VO'};
  $can{'Number'}        = $entry{'NR'}  if defined $entry{'NR'};
  $can{'Series'}        = $entry{'SE'}  if defined $entry{'SE'};

  if (defined $entry{'MT'}) {
    if (defined $entry{'AT'}) {
      $can{'SuperTitle'} = $entry{'MT'};
    } else {
      $can{'Title'} = $entry{'MT'};
    }
  }
  if ($can{'CiteType'} =~ /article/) {
    $can{'Pages'}         = $entry{'PG'}  if defined $entry{'PG'};
  } else {
    $can{'PagesWhole'}    = $entry{'PG'}  if defined $entry{'PG'};
  }

  $can{'OrigFormat'} = $version;
  %can;
}

sub melname_to_canon {
  local($name) = @_;
  local($last, $first, $cname);

  if (    ( defined $entry{'DB'} && ($entry{'DB'} =~ /MEDLINE/) )
       || ( (!/,/) && (/[A-Z]+$/) )
     ) {
    # medline
    ($last, $first) = $name =~ /^(.*)\s+([A-Z]+)$/;
    if (defined $first) {
      $first =~ s/([A-Z])/$1. /g;
      $first =~ s/\s+$//;
    }
  } else {
    ($last, $first) = $name =~ /^(.*),(.*)$/;
  }

  $cname = $last . $bib'cs_sep2 . $bib'cs_sep2 . $first . $bib'cs_sep2;
  $cname;
}

######


#######################
# end of package
#######################

1;
