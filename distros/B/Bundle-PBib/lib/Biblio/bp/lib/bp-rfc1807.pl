#
# bibliography package for Perl
#
# RFC1807 routines
#
# Dana Jacobsen (dana@acm.org)
# 17 November 1995
#
# See <http://www.ecst.csuchico.edu/~jacobsd/bib/formats/rfc1807.html>
#  or <http://www.cis.ohio-state.edu/htbin/rfc/rfc1807.html>
#
# This has not been extensively tested.
#

package bp_rfc1807;

$version = "rfc1807 (dj 17 nov 95)";

######

&bib'reg_format(
  'rfc1807',    # name
  'rfc',        # short name
  'bp_rfc1807', # package name
  '8859-1',     # default character set
  'suffix is rfc1807',
# functions
  'open      is standard',
  'close     is standard',
  'write     is standard',
  'clear     is standard',
  'read      is standard',
  'options',
  'explode',
  'implode',
  'tocanon',
  'fromcanon',
);

######

# Are we restricting ourselves to just RFC1357 fields?
$opt_1357 = 0;

######

sub options {
  local($opts) = @_;

  print "setting options to $opts\n";
}

######

sub explode {
  local($rec) = @_;
  local(%entry);
  local(@lines);
  local($fld, $val);

  # There are easier ways to split the fields up, but each of them
  # have some problem (loses duplicate fields, splits in wrong place, etc.)

  substr($rec, 0, 0) = "\n";
  @lines = split(/\n\s*([-\w]+)\s*::\s*/, $rec);
  shift @lines;
  while (@lines) {
    ($fld, $val) = splice(@lines, 0, 2);
    $fld =~ tr/a-z/A-Z/;
    if (defined $entry{$fld}) {
      $entry{$fld} .= $bib'cs_sep . $val;
    } else {
      $entry{$fld} = $val;
    }
  }
  # simple validation
  if (    (!defined $entry{'BIB-VERSION'})
       || (!defined $entry{'ID'})
       || (!defined $entry{'END'}) ) {
    &bib'gotwarn("Missing mandatory fields");
  } else {
    $entry{'END'} =~ s/\s+$//;
    #chop($entry{'END'});
  }
  %entry;
}

######

@order = (
'BIB-VERSION',
'ID',
'ENTRY',
'ORGANIZATION',
'TITLE',
'TYPE',
'REVISION',
'WITHDRAW',
'AUTHOR',
'CORP-AUTHOR',
'CONTACT',
'DATE',
'PAGES',
'COPYRIGHT',
'HANDLE',
'OTHER_ACCESS',
'RETRIEVAL',
'KEYWORD',
'CR-CATEGORY',
'PERIOD',
'SERIES',
'MONITORING',
'FUNDING',
'CONTRACT',
'GRANT',
'LANGUAGE',
'NOTES',
'ABSTRACT',
'END',
);

sub implode {
  local(%entry) = @_;
  local($ent) = '';
  local($head) = '';

  foreach $field ( @order ) {
    next unless defined $entry{$field};
    # this splits those multi-valued fields back into multi-line.
    # XXXXX Should do nice things with AUTHOR and CONTACT fields
    #       (they should alternate).
    $head = sprintf("%12s::", $field);
    $entry{$field} =~ s/$bib'cs_sep/\n$head /go;
    $ent .= "$head $entry{$field}\n";
    delete $entry{$field};
  }
  # get all the unknown fields
  foreach $field (sort keys %entry) {
    &bib'gotwarn("rfc1807 implode: unknown tag: $field");
  }
  $ent;
}

######

sub tocanon {
  local(%ent) = @_;
  local(%can);

  $can{'CiteType'} = 'report';
  # BIB-VERSION
  if ( (defined $ent{'ID'}) && ($ent{'ID'} =~ /\/\/(.*)$/) ) {
    $can{'ReportNumber'} = $1;
  } else {
    &bib'gotwarn("Could not find or parse ID field");
    #$can{'Key'} = $ent{'ID'} if defined $ent{'ID'};
  }
  $can{'entry'} = $ent{'ENTRY'} if defined $ent{'ENTRY'};
  $can{'Organization'} = $ent{'ORGANIZATION'} if defined $ent{'ORGANIZATION'};
  $can{'Title'} = $ent{'TITLE'} if defined $ent{'TITLE'};
  $can{'ReportType'} = $ent{'TYPE'} if defined $ent{'TYPE'};
  # REVISION
  # WITHDRAW (1807)
  if (defined $ent{'AUTHOR'}) {
    local($n, @auths, @edits);
    foreach $n (split(/$bib'cs_sep/o, $ent{'AUTHOR'})) {
      if ($n =~ s/\s*\(ed\.\)\s*$//) {
        push(@edits, &bp_util'name_to_canon($n, 'reverse') );
      } else {
        push(@auths, &bp_util'name_to_canon($n, 'reverse') );
      }
    }
    $can{'Authors'} = join( $bib'cs_sep, @auths ) if @auths;
    $can{'Editors'} = join( $bib'cs_sep, @edits ) if @edits;
  }
  $can{'CorpAuthor'} = $ent{'CORP-AUTHOR'}  if defined $ent{'CORP-AUTHOR'};
  # XXXXX What if we have a mismatch between author and contact?  Ouch!
  $can{'AuthorAddress'} = $ent{'CONTACT'}  if defined $ent{'CONTACT'};
  if (defined $ent{'DATE'}) {
    ($can{'Month'}, $can{'Year'}) = &bp_util'parsedate($ent{'DATE'});
    #delete $can{'Month'} unless defined $can{'Month'} && $can{'Month'} =~ /\S/;
    #delete $can{'Year'}  unless defined $can{'Year'}  && $can{'Year'}  =~ /\S/;
  }
  $can{'PagesWhole'} = $ent{'PAGES'} if defined $ent{'PAGES'};
  $can{'Copyright'} = $ent{'COPYRIGHT'} if defined $ent{'COPYRIGHT'};
  # HANDLE (1807)
  # OTHER_ACCESS (1807)
  $can{'Source'} = $ent{'RETRIEVAL'} if defined $ent{'RETRIEVAL'};
  # (1807)
  $can{'Keywords'} = $ent{'KEYWORD'} if defined $ent{'KEYWORD'};
  $can{'ACMCRNumber'} = $ent{'CR-CATEGORY'} if defined $ent{'CR-CATEGORY'};
  # PERIOD
  $can{'Series'} = $ent{'SERIES'} if defined $ent{'SERIES'};
  # FUNDING
  # MONITORING
  # CONTRACT
  # GRANT
  $can{'Language'} = $ent{'LANGUAGE'} if defined $ent{'LANGUAGE'};
  $can{'Note'} = $ent{'NOTES'} if defined $ent{'NOTES'};
  $can{'Abstract'} = $ent{'ABSTRACT'} if defined $ent{'ABSTRACT'};

  if ( (!defined $ent{'END'}) || (!defined $ent{'ID'}) ) {
    &bib'gotwarn("Missing mandatory ID and/or END tags");
  } else {
    if ($ent{'ID'} ne $ent{'END'}) {
      &bib'gotwarn("ID tag does not match END tag");
    }
  }
    
  $can{'OrigFormat'} = $version;

  %can;
}

######

# XXXXX This is bogus!  It barely makes records.
#       If you're feeling nice, write one that's correct and mail it to me!

sub fromcanon {
  local(%can) = @_;
  local(%rec);

  $rec{'BIB-VERSION'} = "CS-TR-v2.1";
  if ( (defined $can{'Key'}) && ($can{'Key'} =~ /^XBP\/\//) ) {
    $rec{'ID'} = $can{'Key'};
  } else {
    if (defined $can{'ReportNumber'}) {
      $can{'CiteKey'} = $can{'ReportNumber'};
    } else {
      $can{'CiteKey'} = &bp_util'genkey(%can) unless defined $can{'CiteKey'};
    }
    $can{'CiteKey'} = &bp_util'regkey($can{'CiteKey'});
    $rec{'ID'} = "XBP//" . $can{'CiteKey'};
  }
  if (defined $can{'entry'}) {
    $rec{'ENTRY'} = $can{'entry'};
  } else {
    local(@lt) = localtime(time);
    local($lm) = ('jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug',
                  'sep', 'oct', 'nov', 'dec')[$lt[4]];
    $lm = &bp_util'output_month($lm, 'long');
    local($ly) = $lt[5];
    if ($ly > 60  &&  $ly < 1500) {
      $ly = "19$ly";
    } elsif ($ly < 61  && $ly < 1500) {
      $ly = "20$ly";
    }
    $rec{'ENTRY'} = "$lm $lt[3], $ly";
  }
  if (defined $can{'School'}) {
    $rec{'ORGANIZATION'} = $can{'School'};
  } elsif (defined $can{'Organization'}) {
    $rec{'ORGANIZATION'} = $can{'Organization'};
  } elsif (defined $can{'Institution'}) {
    $rec{'ORGANIZATION'} = $can{'Institution'};
  }
  $rec{'TITLE'}      = $can{'Title'}        if defined $can{'Title'};
  # TYPE
  # REVISION
  # WITHDRAW
  if (defined $can{'Authors'}) {
    $rec{'AUTHOR'} = join($bib'cs_sep, &bp_util'canon_to_name($can{'Authors'}, 'plain'));
  }
  if (defined $can{'Editors'}) {
    local(@editors) = &bp_util'canon_to_name($can{'Editors'}, 'plain');
    grep($_ .= ' (ed.)', @editors);
    if (defined $rec{'AUTHOR'}) {
      $rec{'AUTHOR'} = join($bib'cs_sep, $rec{'AUTHOR'}, @editors);
    } else {
      $rec{'AUTHOR'} = join($bib'cs_sep, @editors);
    }
  }
  $rec{'CORP-AUTHOR'} = &bp_util'canon_to_name($can{'CorpAuthor'}, 'plain')
                                            if defined $can{'CorpAuthor'};
  $rec{'CONTACT'}     = $can{'AuthorAddress'} if defined $can{'AuthorAddress'};
  $rec{'DATE'} = &bp_util'output_date($can{'Month'}, $can{'Year'}, 'long');
  delete $rec{'DATE'} unless $rec{'DATE'} =~ /\S/;
  if (defined $can{'PagesWhole'}) {
    $rec{'PAGES'} = $can{'PagesWhole'};
  } elsif (defined $can{'Pages'}) {
    $rec{'PAGES'} = $can{'Pages'};
  }
  $rec{'COPYRIGHT'}   = $can{'Copyright'}   if defined $can{'Copyright'};
  # HANDLE
  # OTHER_ACCESS
  $rec{'RETRIEVAL'}   = $can{'Source'}      if defined $can{'Source'};
  $rec{'KEYWORD'}     = $can{'Keywords'}    if defined $can{'Keywords'};
  $rec{'CR-CATEGORY'} = $can{'ACMCRNumber'} if defined $can{'ACMCRNumber'};
  # PERIOD
  $rec{'SERIES'}      = $can{'Series'}      if defined $can{'Series'};
  # FUNDING
  # CONTRACT
  # MONITORING
  # GRANT
  $rec{'LANGUAGE'}    = $can{'Language'}    if defined $can{'Language'};
  $rec{'NOTES'}       = $can{'Note'}        if defined $can{'Note'};
  $rec{'ABSTRACT'}    = $can{'Abstract'}    if defined $can{'Abstract'};
  $rec{'END'}         = $rec{'ID'};

  %rec;
}

######

sub clear {
}


#######################
# end of package
#######################

1;
