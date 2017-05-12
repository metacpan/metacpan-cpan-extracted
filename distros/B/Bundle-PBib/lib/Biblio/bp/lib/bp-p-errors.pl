#
# bibliography package for Perl
#
# Error routines
#
# Dana Jacobsen (dana@acm.org)
# 12 January 1995 (last modified on 17 November 1995)

#
# ignore (0)  don't even record them
# delay  (1)  record them for later
# print  (2)  print immediately (implies report for warns or errors)
# exit   (3)  print and exit (implies report for warns or errors)
#
# totals      returns totals with no other action.
# report      prints all accumulated warns/errors, and clears their strings.
# clear       clears all our strings and totals
#
# All the commands return a list containing 4 elements:
#   num_warns   the number of warnings since the last clear
#   num_errors  the number of errors since the last clear
#   str_warns   the accumulated warning string we have.
#   str_errors  the accumulated error string we have.
#
# (actually, the strings are cleared upon calling report or clear, and the one
#  in question is cleared with a print or exit, so we would no longer actually
#  have the strings any more)
#
# If $glb_error_saveline is set, then the delay strings also include the
# location information.  This is useful if you have delay on for more than
# one record.
#
# The values returned are the values previous to the effect of this command.
# In other words, although a call to bib'errors('clear') will clear out all
# our totals and strings, it will return to you the old totals and strings.
# So you could call clear, but check the return values for any special
# situations.  Note that the strings are cleared upon clear, report, or
# print/exit, but the strings are returned to you.  Unless you did a clear,
# you probably don't need to worry about it.
#

# Example:
#
# &bib'errors('print', 'exit');
# ...do a bunch of normal processing...
# ...getting ready for interesting stuff...
# &bib'errors('delay', 'exit');
# foreach (@records) {
#    ...do a bunch of stuff on each record, accumulating all our warnings...
#    # print out all the warnings for this record with our new citekey
#    &bib'errors('report',undef," ($citekey)");  
# }

sub errors {
  local($wlev, $elev, $header) = @_;
  local(@ret);

  &panic("errors called with no arguments") unless defined $wlev;

  # check sanity of arguments given
  if ($wlev !~ /^(ignore|delay|print|exit|report|totals|clear)$/) {
    return &bib'error("Unknown first argument to errors routine");
  }
  if (defined $elev) {
    if ($elev !~ /^(ignore|delay|print|exit)$/) {
      return &bib'error("Unknown second argument to errors routine");
    }
  } else {
    $elev = '';
  }

  @ret = ($glb_num_warns, $glb_num_errors, $glb_str_warns, $glb_str_errors);

  return @ret  if $wlev eq 'totals';

  if ($wlev eq 'clear') {
    $glb_num_errors = 0;
    $glb_num_warns  = 0;
    $glb_str_errors = undef;
    $glb_str_warns  = undef;
    return @ret;
  }

  $glb_warn_level = 0  if ($wlev eq 'ignore');
  $glb_warn_level = 1  if ($wlev eq 'delay');
  $glb_warn_level = 2  if ($wlev eq 'print');
  $glb_warn_level = 3  if ($wlev eq 'exit');

  # Setting the error level to ignore is a Bad Thing.  I suppose there may
  # be cases (debugging, etc.) where we just may want it.  We can't really
  # warn them, since they just told us to shut up...

  $glb_error_level = 0  if ($elev eq 'ignore');
  $glb_error_level = 1  if ($elev eq 'delay');
  $glb_error_level = 2  if ($elev eq 'print');
  $glb_error_level = 3  if ($elev eq 'exit');

  if ( ($wlev =~ /^(report|print|exit)$/) && (defined $glb_str_warns) ) {
    $header = '' unless defined $header;
    foreach $warn ( split(/\n/, $glb_str_warns) ) {
      print STDERR "bp warning$header: $warn\n";
    }
    $glb_str_warns = undef;
  }
 
  if ( ($elev =~ /^(report|print|exit)$/) && (defined $glb_str_errors) ) {
    $header = '' unless defined $header;
    foreach $error ( split(/\n/, $glb_str_errors) ) {
      print STDERR "bp error$header: $error\n";
    }
    $glb_str_errors = undef;
  }

  @ret;
}

#
# This must return undef, so programs can use 'return &goterror("ack!")'
#
sub goterror {
  local($error, $linenum) = @_;

  &panic("Error, but no error message") unless defined $error;

  $glb_num_errors++;
  return undef if $glb_error_level == 0;

  if (defined $linenum) {
    # $linenum = $linenum;
  } elsif (defined $glb_vloc) {
    $linenum = $glb_vloc;
  } elsif (defined $glb_Ifilename) {
    $linenum = sprintf("record %4d", $glb_filelocmap{$glb_Ifilename});
  } else {
    $linenum = 'main';
  }

  die          "bp error ($linenum): $error\n" if $glb_error_level == 3;
  print STDERR "bp error ($linenum): $error\n" if $glb_error_level == 2;
  if ($glb_error_level == 1) {
    $glb_str_errors .= "($linenum): " if $glb_error_saveline;
    $glb_str_errors .= "$error\n"
  }

  undef;
}

sub gotwarn {
  local($warn, $linenum) = @_;

  &panic("Warning, but no warning message") unless defined $warn;

  $glb_num_warns++;
  return undef if $glb_warn_level == 0;

  if (defined $linenum) {
    # $linenum = $linenum;
  } elsif (defined $glb_vloc) {
    $linenum = $glb_vloc;
  } elsif (defined $glb_Ifilename) {
    $linenum = sprintf("record %4d", $glb_filelocmap{$glb_Ifilename});
  } else {
    $linenum = 'main';
  }

  die          "bp warning ($linenum): $warn\n" if $glb_warn_level == 3;
  print STDERR "bp warning ($linenum): $warn\n" if $glb_warn_level == 2;
  if ($glb_warn_level == 1) {
    $glb_str_warns .= "($linenum): " if $glb_error_saveline;
    $glb_str_warns .= "$warn\n";
  }

  undef;
}

1;
