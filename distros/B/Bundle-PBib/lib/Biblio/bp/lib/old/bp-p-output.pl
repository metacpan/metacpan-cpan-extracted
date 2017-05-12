#
# bibliography package for Perl
#
# output formats
#
# Dana Jacobsen (dana@acm.org)
# 15 November 1995
#
# This is a first cut at this function.  We probably should have some
# generic way of specifying a format, and then read that in.  The user
# should be able to define their preferred format in their .bprc file,
# but we don't have that yet.

package bp_util;

######
# This defines which of the output styles we will use.

$opt_style = 'plain';

sub output {
  local($chars, %record) = @_;
  local($function, $output_text);

  $function = "bp_util'out_$opt_style";
  $output_text = &$function($chars, %record);

  $output_text;
}

######
#
# Plain output format.  Built on the style used by
#
#    <http://www.research.att.com/biblio.html>
#

sub out_plain {
  local($chars, %rec) = @_;
  local(@names, $names);
  local($cpp, $cpgw, $date);
  local($out);
  $out = '';

  # We need to determine what our emphasis characters are.
  # XXX  Is this a reasonable way to handle this?  It might just
  #      grow and grow.  Also, is this generic enough to handle
  #      all sorts of output?
  local($emb, $eme, $boldb, $bolde, $blockb, $blocke)
     = split(/$bib'cs_sep/, $chars);

  ($cpp, $cpgw) = &output_pages($rec{'Pages'}, $rec{'PagesWhole'});
  $date = &output_date($rec{'Month'}, $rec{'Year'});

  if ($rec{'CiteType'} eq 'article') {
    if (defined $rec{'Authors'}) {
      $names = &bp_util'canon_to_name($rec{'Authors'}, 'plain');
      $out .= "$names, ";
    }
    $out .= '"' . $rec{'Title'} . '," ' if defined $rec{'Title'};
    if (defined $rec{'Journal'}) {
      $out .= $emb . $rec{'Journal'} . $eme . ', ';
    } else {
      &bib'gotwarn("No journal name in an article citation");
    }
    if (defined $rec{'Editors'}) {
      $names = &bp_util'canon_to_name($rec{'Editors'}, 'plain');
      $out .= "($names, eds.), ";
    }
    $out .= "vol. $rec{'Volume'}, " if defined $rec{'Volume'};
    $out .= "no. $rec{'Number'}, " if defined $rec{'Number'};
    $out .= 'pp. ' . $rec{'Pages'} . ', ' if defined $rec{'Pages'};
    $out .= $rec{'Publisher'} . ', ' if defined $rec{'Publisher'};
    $out .= $date . ', ' if defined $date;
  } elsif ($rec{'CiteType'} eq 'report') {
    if (defined $rec{'Authors'}) {
      $names = &bp_util'canon_to_name($rec{'Authors'}, 'plain');
      $out .= "$names, ";
    }
    $out .= '"' . $rec{'Title'} . '," ' if defined $rec{'Title'};
    if (defined $rec{'ReportType'} && defined $rec{'ReportNumber'}) {
        $out .= "$rec{'ReportType'} $rec{'ReportNumber'}, ";
    } elsif (defined $rec{'ReportType'}) {
        $out .= "$rec{'ReportType'}, ";
    }
    $out .= "$rec{'Organization'}, " if defined $rec{'Organization'};
    $out .= "$rec{'PubAddress'}, " if defined $rec{'PubAddress'};
    $out .= "pp. $cpp, " if defined $cpp;
    $out .= $date . ', ' if defined $date;
    $out .= "$cpgw pages, " if defined $cpgw;
  } elsif ($rec{'CiteType'} eq 'book') {
    if (defined $rec{'Authors'}) {
      $names = &bp_util'canon_to_name($rec{'Authors'}, 'plain');
      $out .= "$names, ";
    }
    $out .= "$emb$rec{'Title'}$eme, " if defined $rec{'Title'};
    if (defined $rec{'Editors'}) {
      $names = &bp_util'canon_to_name($rec{'Editors'}, 'plain');
      $out .= "($names, eds.), ";
    }
    $out .= "vol. $rec{'Volume'}, " if defined $rec{'Volume'};
    $out .= "pp. $cpp, " if defined $cpp;
    $out .= $rec{'Publisher'} . ', ' if defined $rec{'Publisher'};
    $out .= "$rec{'Edition'} ed., " if defined $rec{'Edition'};
    $out .= $date . ', ' if defined $date;
    $out .= "$cpgw pages, " if defined $cpgw;
  } elsif ($rec{'CiteType'} eq 'inproceedings') {
    if (defined $rec{'Authors'}) {
      $names = &bp_util'canon_to_name($rec{'Authors'}, 'plain');
      $out .= "$names, ";
    }
    $out .= '"' . $rec{'Title'} . '," ' if defined $rec{'Title'};
    if (defined $rec{'SuperTitle'}) {
      $out .= "in $emb$rec{'SuperTitle'}$eme, ";
    } else {
      &bib'gotwarn("No proceedings name in an inproceedings citation");
    }
    if (defined $rec{'Editors'}) {
      $names = &bp_util'canon_to_name($rec{'Editors'}, 'plain');
      $out .= "($names, eds.), ";
    }
    $out .= "($rec{'PubAddress'}), " if defined $rec{'PubAddress'};
    $out .= "pp. $rec{'Pages'}, " if defined $rec{'Pages'};
    $out .= $rec{'Organization'} . ', ' if defined $rec{'Organization'};
    if (defined $rec{'Journal'}) {
      $out .= "published as $emb$rec{'Journal'}$eme, ";
      $out .= "vol. $rec{'Volume'}, " if defined $rec{'Volume'};
      $out .= "no. $rec{'Number'}, " if defined $rec{'Number'};
    }
    $out .= $date . ', ' if defined $date;
#added Pierre van de Laar
  } elsif ($rec{'CiteType'} eq 'inbook'){
    if (defined $rec{'Authors'}) {
      $names = &bp_util'canon_to_name($rec{'Authors'}, 'plain');
      $out .= "$names, ";
    }
    $out .= '"' . $rec{'Title'} . '," ' if defined $rec{'Title'};
    if (defined $rec{'SuperTitle'}) {
      $out .= "in $emb$rec{'SuperTitle'}$eme, ";
    } else {
      &bib'gotwarn("No book name in an inbook citation");
    }
    $out .= "vol. $rec{'Volume'}, " if defined $rec{'Volume'};
    $out .= "no. $rec{'Number'}, " if defined $rec{'Number'};
    if (defined $rec{'Editors'}) {
      $names = &bp_util'canon_to_name($rec{'Editors'}, 'plain');
      $out .= "($names, eds.), ";
    }
    $out .= "($rec{'PubAddress'}), " if defined $rec{'PubAddress'};
    $out .= "pp. $rec{'Pages'}, " if defined $rec{'Pages'};
    $out .= $rec{'Organization'} . ', ' if defined $rec{'Organization'};
    $out .= $date . ', ' if defined $date;
#added Pierre van de Laar
  } else {
    $out = &bp_util'out_minimal($chars, %rec);
  }

  $out =~ s/, $/./;

  if (defined $rec{'Abstract'}) {
    $out .= "\n${blockb} ${boldb}Abstract:  ${bolde}\n";
    $out .= $rec{'Abstract'};
    $out .= "${blocke}\n";
  }
  if (defined $rec{'Keywords'}) {
    $out .= "\n${blockb} ${boldb}Keywords:  ${bolde}\n";
    $out .= $rec{'Keywords'};
    $out .= "${blocke}\n";
  }
  if (defined $rec{'Annotation'}) {
    $out .= "\n${blockb} ${boldb}Annotation:  ${bolde}\n";
    $out .= $rec{'Annotation'};
    $out .= "${blocke}\n";
  }

  # XXXXX Check to see if this is acceptable.  Without this, the
  #       output looks horrid in formats that don't squeeze spaces.
  #       I'm just worried that we might lose information, although
  #       I can't think offhand where we would.
  $out =~ s/\s+/ /g;

  $out;
}

sub out_minimal {
  local($chars, %rec) = @_;
  local(@names, $names);
  local($out);
  $out = '';

  # We need to determine what our emphasis characters are.
  local($emb, $eme) = split(/::/, $chars);
  local($date) = &output_date($rec{'Month'}, $rec{'Year'});

  if (defined $rec{'Authors'}) {
    $names = &bp_util'canon_to_name($rec{'Authors'}, 'plain');
    $out .= $names . ', ';
  }
  $out .= '"' . $rec{'Title'} . '"' . ', ' if defined $rec{'Title'};
  if (defined $rec{'Journal'}) {
    $out .= $emb . $rec{'Journal'} . $eme . ', ';
    if (defined $rec{'Volume'}) {
      if (defined $rec{'Number'}) {
        $out .= $rec{'Volume'} . "($rec{'Number'}), ";
      } else {
        $out .= "v$rec{'Volume'}, ";
      }
    } else {
      $out .= "n$rec{'Number'}, " if defined $rec{'Number'};
    }
  }
  $out .= 'in ' . $emb . $rec{'SuperTitle'} . $eme . ', ' if defined $rec{'SuperTitle'};
  if (defined $rec{'Editors'}) {
    $names = &bp_util'canon_to_name($rec{'Editors'}, 'plain');
    $out .= 'edited by ' . $names . ', ';
  }
  $out .= $rec{'Publisher'} . ', ' if defined $rec{'Publisher'};
  $out .= "$date, " if defined $date;
  $out .= 'pp. ' . $rec{'Pages'} . ', ' if defined $rec{'Pages'};
  $out .= $rec{'PagesWhole'} . ' pages, ' if defined $rec{'PagesWhole'};
  $out =~ s/, $/./;
  $out;
}

sub output_pages {
  local($pg, $pgw) = @_;
  local($cp) = undef;
  local($cw) = undef;

  if (defined $pg) {
    if (defined $pgw) {
      $cp = $pg;
      $cw = $pgw;
    } else {
      if ($pg =~ /-/) {
        $cp = $pg;
      } else {
        $cw = $pg;
      }
    }
  } else {
   $cw = $pgw if defined $pgw;
  }

  ($cp, $cw);
}

sub output_date {
  local($mo, $yr) = @_;
  local($date);

  if (defined $mo) {
    # this routine is in bp-p-utils.
    $mo = &bp_util'output_month($mo, 'short');
    if (defined $yr) {
      $date = "$mo $yr";
    } else {
      $date = $mo;
    }
  } else {
    $date = $yr if defined $yr;
  }

  $date;
}

1;
