#!/usr/bin/perl -w

use strict;

my($code, $short, $explanation);
my $mode = 'code';

my $DEBUG = 0;

while (<>) {

  if ( /^\s*<tr>\s*$/i ) {
    ($code, $short, $explanation) = ('', '', '');
  } elsif ( /^\s*<td[^>]*>(\d+)(\s|&nbsp;)*<\/td>\s*$/i ) {
    $code = $1;
    warn "found code $code" if $DEBUG;
    $mode = 'short';
  } elsif ( /^\s*<td[^>]*>(\d+(\s|&nbsp;)*\-\s*\d+)<\/td>\s*$/i ){
    warn "skipping range $1" if $DEBUG;
    until ( ($_=<>) =~ /^\s*<\/tr>\s*$/i ) {
      #nop
    }
    next;
  } elsif ( /^\s*<td[^>]*>(.*)<\/td>\s*$/i ) {
    warn "found one line data" if $DEBUG;
    if ( $mode eq 'short' ) {
      $short = $1;
      $short =~ s/<\/?FONT[^>]*>//gi;
      $short =~ s/&nbsp;/ /g;
      $short =~ s/<\/?a[^>]*>//gi;
      $mode = 'explanation';
    } elsif ( $mode eq 'explanation' ) {
      $explanation = $1;
      $explanation =~ s/<\/?FONT[^>]*>//gi;
      $explanation =~ s/&nbsp;/ /g;
      $mode = 'code';
    } else {
      die "found (one-line) data, but in unknown mode $mode";
    }
  } elsif ( /^\s*<td[^>]*>(.*)$/i ) {
    warn "found multi-line data (mode $mode)" if $DEBUG;
    chop(my $data = $1);
    #$data =~ s/<\/?FONT[^>]*>//g;
    until ( ($_=<>) =~ /^\s*(.*)<\/td>/i ) {
      /^\s*(.*)\s*$/ or die;
      chop($data .= $1);
      warn "found intermediate data $1" if $DEBUG;
    }
    $_ =~ /^\s*(.*)<\/td>/i;
    $data .= $1;
    $data =~ s/<\/?FONT[^>]*>//gi;
    $data =~ s/&nbsp;/ /g;
    $data =~ s/<\/?[BI]>//gi;
    $data =~ s/<\/?BR>/ /gi;
    $data =~ s/<\/?a[^>]*>//gi;
    warn "last line $1 ($_)" if $DEBUG;
    warn "coalesced multi-line data: $data" if $DEBUG;
    if ( $mode eq 'short' ) {
      $short = $data;
      $mode = 'explanation';
    } elsif ( $mode eq 'explanation' ) {
      $explanation = $data;
      $mode = 'code';
    } elsif ( $mode eq 'code' && $data =~ /^(\d+)$/ ) {
      $code = $1;
      warn "found code $code" if $DEBUG;
      $mode = 'short';
    } else {
      die "found (multi-line) data, but in unknown mode $mode or don't know what to do with it: $data";
    }
  
  } elsif ( /^\s*<\/tr>\s*$/i ) {
    #$short =~ s/<\/?FONT[^>]*>//g;
    #$explanation =~ s/<\/?FONT[^>]*>//g;
    #$short =~ s/[\n\r]//;
    #$explanation =~ s/[\n\r]//;

    $short =~ s/"/\\"/gi;
    $explanation =~ s/"/\\"/gi;
    
    warn "end of row, printing hash element (code $code)" if $DEBUG;
    print qq!  "$code" => \[ "$short", "$explanation" \],\n!
      unless $short  =~ /^\s*not\s*used\s*/i;
    $mode = 'code';
  }

}

