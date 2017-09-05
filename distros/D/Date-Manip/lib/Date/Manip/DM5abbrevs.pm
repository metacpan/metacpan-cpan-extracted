package Date::Manip::DM5abbrevs;
# Copyright (c) 2003-2017 Sullivan Beck. All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

########################################################################
########################################################################

=pod

=head1 NAME

Date::Manip::DM5abbrevs - A list of all timezone abbreviations

=head1 SYNPOSIS

This module is not intended to be used directly. Date::Manip 5.xx
will load it as needed.

This module contains all of the time zone abbreviations from
Date::Manip 6.xx copied backwards to 5.xx to provide slightly
better support for time zones.

Note that this is only a bandaid fix, and does not add proper
time zone handling to version 5.xx .

=cut

require 5.000;

use strict;
use warnings;

our($VERSION);
$VERSION='6.60';

END {
   my $tmp;
   $tmp = \$Date::Manip::DM5::Abbrevs;
}

$Date::Manip::DM5::Abbrevs = join(' ',qw(
      idlw   -1200
      nt     -1100
      sat    -0400
      cldt   -0300
      at     -0200
      utc    +0000
      mewt   +0100
      mez    +0100
      fwt    +0100
      gb     +0100
      swt    +0100
      mesz   +0200
      fst    +0200
      metdst +0200
      eetdst +0300
      eetedt +0300
      bt     +0300
      it     +0330
      zp4    +0400
      zp5    +0500
      ist    +0530
      zp6    +0600
      awst   +0800
      rok    +0900
      aest   +1000
      acdt   +1030
      cadt   +1030
      aedt   +1100
      eadt   +1100
      nzt    +1200
      idle   +1200

      a      -0100
      acdt   +1030
      acst   +0930
      addt   -0200
      adt    -0300
      aedt   +1100
      aest   +1000
      ahdt   -0900
      ahst   -1000
      akdt   -0800
      akst   -0900
      apt    -0900
      ast    -0400
      awdt   +0900
      awst   +0800
      awt    -0300
      b      -0200
      bdst   +0200
      bdt    -1000
      bst    +0100
      c      -0300
      cast   +0300
      cat    +0200
      cddt   -0400
      cdt    -0500
      cemt   +0300
      cest   +0200
      cet    +0100
      chst   +1000
      cmt    +0155
      cpt    -0500
      cst    -0600
      cwt    -0500
      d      -0400
      e      -0500
      eat    +0300
      eddt   -0300
      edt    -0400
      eest   +0300
      eet    +0200
      ept    -0400
      est    -0500
      ewt    -0400
      f      -0600
      g      -0700
      gmt    +0000
      gmt+1  +0100
      gmt+10 +1000
      gmt+11 +1100
      gmt+12 +1200
      gmt+2  +0200
      gmt+3  +0300
      gmt+4  +0400
      gmt+5  +0500
      gmt+6  +0600
      gmt+7  +0700
      gmt+8  +0800
      gmt+9  +0900
      gmt-1  -0100
      gmt-10 -1000
      gmt-11 -1100
      gmt-12 -1200
      gmt-13 -1300
      gmt-14 -1400
      gmt-2  -0200
      gmt-3  -0300
      gmt-4  -0400
      gmt-5  -0500
      gmt-6  -0600
      gmt-7  -0700
      gmt-8  -0800
      gmt-9  -0900
      gst    +1000
      h      -0800
      hdt    -0900
      hkst   +0900
      hkt    +0800
      hst    -1000
      i      -0900
      iddt   +0400
      idt    +0300
      ist    +0100
      jdt    +1000
      jst    +0900
      k      -1000
      kdt    +1000
      kst    +0900
      l      -1100
      m      -1200
      mddt   -0500
      mdt    -0600
      mest   +0200
      met    +0100
      mmt    +0454
      mpt    -0600
      msd    +0400
      msk    +0300
      mst    -0700
      mwt    -0600
      n      +0100
      nddt   -0130
      ndt    -0230
      npt    -1000
      nst    -0330
      nwt    -1000
      nzdt   +1300
      nzmt   +1130
      nzst   +1200
      o      +0200
      p      +0300
      pddt   -0600
      pdt    -0700
      pkst   +0600
      pkt    +0500
      ppmt   -0449
      ppt    -0700
      pst    -0800
      pwt    -0700
      q      +0400
      qmt    -0514
      r      +0500
      s      +0600
      sast   +0200
      sdmt   -0440
      smt    +0216
      sst    -1100
      t      +0700
      tmt    +0139
      u      +0800
      ut     +0000
      utc    +0000
      v      +0900
      w      +1000
      wast   +0200
      wat    +0100
      wemt   +0200
      west   +0100
      wet    +0000
      wib    +0700
      wit    +0900
      wita   +0800
      wmt    +0124
      x      +1100
      y      +1200
      yddt   -0700
      ydt    -0800
      ypt    -0800
      yst    -0900
      ywt    -0800
      z      +0000
));

=pod

=head1 TIMEZONES

The following timezones are defined:

      A      -0100
      ACDT   +1030
      ACST   +0930
      ADDT   -0200
      ADT    -0300
      AEDT   +1100
      AEST   +1000
      AHDT   -0900
      AHST   -1000
      AKDT   -0800
      AKST   -0900
      APT    -0900
      AST    -0400
      AT     -0200
      AWDT   +0900
      AWST   +0800
      AWT    -0300
      B      -0200
      BDST   +0200
      BDT    -1000
      BST    +0100
      BT     +0300
      C      -0300
      CADT   +1030
      CAST   +0300
      CAT    +0200
      CDDT   -0400
      CDT    -0500
      CEMT   +0300
      CEST   +0200
      CET    +0100
      CHST   +1000
      CLDT   -0300
      CMT    +0155
      CPT    -0500
      CST    -0600
      CWT    -0500
      D      -0400
      E      -0500
      EADT   +1100
      EAT    +0300
      EDDT   -0300
      EDT    -0400
      EEST   +0300
      EET    +0200
      EETDST +0300
      EETEDT +0300
      EPT    -0400
      EST    -0500
      EWT    -0400
      F      -0600
      FST    +0200
      FWT    +0100
      G      -0700
      GB     +0100
      GMT    +0000
      GMT+1  +0100
      GMT+10 +1000
      GMT+11 +1100
      GMT+12 +1200
      GMT+2  +0200
      GMT+3  +0300
      GMT+4  +0400
      GMT+5  +0500
      GMT+6  +0600
      GMT+7  +0700
      GMT+8  +0800
      GMT+9  +0900
      GMT-1  -0100
      GMT-10 -1000
      GMT-11 -1100
      GMT-12 -1200
      GMT-13 -1300
      GMT-14 -1400
      GMT-2  -0200
      GMT-3  -0300
      GMT-4  -0400
      GMT-5  -0500
      GMT-6  -0600
      GMT-7  -0700
      GMT-8  -0800
      GMT-9  -0900
      GST    +1000
      H      -0800
      HDT    -0900
      HKST   +0900
      HKT    +0800
      HST    -1000
      I      -0900
      IDDT   +0400
      IDLE   +1200
      IDLW   -1200
      IDT    +0300
      IST    +0100
      IT     +0330
      JDT    +1000
      JST    +0900
      K      -1000
      KDT    +1000
      KST    +0900
      L      -1100
      M      -1200
      MDDT   -0500
      MDT    -0600
      MEST   +0200
      MESZ   +0200
      MET    +0100
      METDST +0200
      MEWT   +0100
      MEZ    +0100
      MMT    +0454
      MPT    -0600
      MSD    +0400
      MSK    +0300
      MST    -0700
      MWT    -0600
      N      +0100
      NDDT   -0130
      NDT    -0230
      NPT    -1000
      NST    -0330
      NT     -1100
      NWT    -1000
      NZDT   +1300
      NZMT   +1130
      NZST   +1200
      NZT    +1200
      O      +0200
      P      +0300
      PDDT   -0600
      PDT    -0700
      PKST   +0600
      PKT    +0500
      PPMT   -0449
      PPT    -0700
      PST    -0800
      PWT    -0700
      Q      +0400
      QMT    -0514
      R      +0500
      ROK    +0900
      S      +0600
      SAST   +0200
      SAT    -0400
      SDMT   -0440
      SMT    +0216
      SST    -1100
      SWT    +0100
      T      +0700
      TMT    +0139
      U      +0800
      UT     +0000
      UTC    +0000
      V      +0900
      W      +1000
      WAST   +0200
      WAT    +0100
      WEMT   +0200
      WEST   +0100
      WET    +0000
      WIB    +0700
      WIT    +0900
      WITA   +0800
      WMT    +0124
      X      +1100
      Y      +1200
      YDDT   -0700
      YDT    -0800
      YPT    -0800
      YST    -0900
      YWT    -0800
      Z      +0000
      ZP4    +0400
      ZP5    +0500
      ZP6    +0600


=head1 LICENSE

This script is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

Sullivan Beck (sbeck@cpan.org)

=cut

1;
