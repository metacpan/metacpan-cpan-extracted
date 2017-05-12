#!perl
# Test of PAL using routines from the PAL test suite

use strict;
use warnings;
use Test::More tests => 65;
use Test::Number::Delta;

BEGIN {
  use_ok "Astro::PAL";
}

print "# Refraction\n";

{ # t_refco
  my $tk = 10.0 + 273.15;
  my $phpa = 800.0;
  my $rh = 0.9;
  my $wl = 0.4;

  my ($refa, $refb) = Astro::PAL::palRefcoq( $tk, $phpa, $rh, $wl );

  delta_within( $refa, 0.2264949956241415009e-3, 1e-15, "palRefcoq: refa" );
  delta_within( $refb, -0.2598658261729343970e-6, 1e-18, "palRefcoq: refb" );

}

{ # t_ref

  my $ref = Astro::PAL::palRefro( 1.4, 3456.7, 280, 678.9, 0.9, 0.55,
                                  -0.3, 0.006, 1e-9 );

  delta_within( $ref, 0.00106715763018568, 1e-12, "palRefro: optical" );

  $ref = Astro::PAL::palRefro( 1.4, 3456.7, 280, 678.9, 0.9, 1000,
                               -0.3, 0.006, 1e-9 );

  delta_within( $ref, 0.001296416185295403, 1e-12, "palRefro: radio" );

  my ($refa, $refb) = Astro::PAL::palRefcoq( 275.9, 709.3, 0.9, 101 );

  delta_within( $refa, 2.324736903790639e-4, 1e-12, "palRefcoq: a/r" );
  delta_within( $refb, -2.442884551059e-7, 1e-15, "palRefcoq: b/r" );

  ($refa, $refb) = Astro::PAL::palRefco( 2111.1, 275.9, 709.3, 0.9, 101,
                                         -1.03, 0.0067, 1e-12 );

  delta_within( $refa, 2.324673985217244e-4, 1e-12, "palRefco: a/r" );
  delta_within( $refb, -2.265040682496e-7, 1e-15, "palRefco: b/r" );

  ($refa, $refb) = Astro::PAL::palRefcoq( 275.9, 709.3, 0.9, 0.77 );

  delta_within( $refa, 2.007406521596588e-4, 1e-12, "palRefcoq: a" );
  delta_within( $refb, -2.264210092590e-7, 1e-15, "palRefcoq: b" );

  ($refa, $refb) = Astro::PAL::palRefco( 2111.1, 275.9, 709.3, 0.9, 0.77,
                                         -1.03, 0.0067, 1e-12 );

  delta_within( $refa, 2.007202720084551e-4, 1e-12, "palRefco: a" );
  delta_within( $refb, -2.223037748876e-7, 1e-15, "palRefco: b" );

  my ($refa2, $refb2) = Astro::PAL::palAtmdsp( 275.9, 709.3, 0.9, 0.77,
                                            $refa, $refb, 0.5 );

  delta_within( $refa2, 2.034523658888048e-4, 1e-12, "palAtmdsp: a" );
  delta_within( $refb2, -2.250855362179e-7, 1e-15, "palAtmdsp: b" );

  my @vu = Astro::PAL::palDcs2c( 0.345, 0.456 );
  my @vr = Astro::PAL::palRefv( \@vu, $refa, $refb );

  delta_within( $vr[0], 0.8447487047790478, 1e-12, "palRefv: x1" );
  delta_within( $vr[1], 0.3035794890562339, 1e-12, "palRefv: y1" );
  delta_within( $vr[2], 0.4407256738589851, 1e-12, "palRefv: z1" );

  @vu = Astro::PAL::palDcs2c( 3.7, 0.03 );
  @vr = Astro::PAL::palRefv( \@vu, $refa, $refb );

  delta_within( $vr[0], -0.8476187691681673, 1e-12, "palRefv: x2" );
  delta_within( $vr[1], -0.5295354802804889, 1e-12, "palRefv: y2" );
  delta_within( $vr[2], 0.0322914582168426, 1e-12, "palRefv: z2" );

  my $zr = Astro::PAL::palRefz( 0.567, $refa, $refb );
  delta_within( $zr, 0.566872285910534, 1e-12, "palRefz: hi el" );

  $zr = Astro::PAL::palRefz( 1.55, $refa, $refb );
  delta_within( $zr, 1.545697350690958, 1e-12, "palRefz: lo el" );
}

{ # t_aop

  my $date = 51000.1;
  my $dut = 25.0;
  my $elongm = 2.1;
  my $phim = 0.5;
  my $hm = 3000.0;
  my $xp = -0.5e-6;
  my $yp = 1.0e-6;
  my $tdk = 280.0;
  my $pmb = 550.0;
  my $rh = 0.6;
  my $tlr = 0.006;

  {
    # Loop must retain some previous context
    my $dap = -0.1234;
    my $rap;
    my $wl;

    for my $i (1..3) {

      if ( $i == 1 ) {
        $rap = 2.7;
        $wl = 0.45;
      } elsif ( $i == 2 ) {
        $rap = 2.345;
      } else {
        $wl = 1.0e6;
      }

      my ($aob, $zob, $hob, $dob, $rob ) = Astro::PAL::palAop ( $rap,
                $dap, $date, $dut, $elongm, $phim, $hm, $xp, $yp,
                $tdk, $pmb, $rh, $wl, $tlr );

      if ( $i == 1 ) {
        delta_within( $aob, 1.812817787123283034, 1e-10, "palAop: lo aob");
        delta_within( $zob, 1.393860816635714034, 1e-8, "palAop: lo zob");
        delta_within( $hob, -1.297808009092456683, 1e-8, "palAop: lo hob");
        delta_within( $dob, -0.122967060534561, 1e-8, "palAop: lo dob");
        delta_within( $rob, 2.699270287872084, 1e-8, "palAop: lo rob");

      } elsif ( $i == 2 ) {
        delta_within( $aob, 2.019928026670621442, 1e-10, "palAop: aob/o");
        delta_within( $zob, 1.101316172427482466, 1e-10, "palAop: zob/o");
        delta_within( $hob, -0.9432923558497740862, 1e-10, "palAop: hob/o");
        delta_within( $dob, -0.1232144708194224, 1e-10, "palAop: dob/o");
        delta_within( $rob, 2.344754634629428, 1e-10, "palAop: rob/o");

      } else {
        delta_within( $aob, 2.019928026670621442, 1e-10, "palAop: aob/r");
        delta_within( $zob, 1.101267532198003760, 1e-10, "palAop: zob/r");
        delta_within( $hob, -0.9432533138143315937, 1e-10, "palAop: hob/r");
        delta_within( $dob, -0.1231850665614878, 1e-10, "palAop: dob/r");
        delta_within( $rob, 2.344715592593984, 1e-10, "palAop: rob/r");

      }
    }
  }

  $date = 48000.3;
  my $wl = 0.45;

  my @aoprms = Astro::PAL::palAoppa ( $date, $dut, $elongm, $phim, $hm, $xp, $yp, $tdk,
                                      $pmb, $rh, $wl, $tlr );
  delta_within( $aoprms[0], 0.4999993892136306, 1e-13, "palAoppa: 0");
  delta_within( $aoprms[1], 0.4794250025886467, 1e-13, "palAoppa: 1");
  delta_within( $aoprms[2], 0.8775828547167932, 1e-13, "palAoppa: 2");
  delta_within( $aoprms[3], 1.363180872136126e-6, 1e-13, "palAoppa: 3");
  delta_within( $aoprms[4], 3000.0, 1e-10, "palAoppa: 4");
  delta_within( $aoprms[5], 280.0, 1e-11, "palAoppa: 5");
  delta_within( $aoprms[6], 550.0, 1e-11, "palAoppa : 6");
  delta_within( $aoprms[7], 0.6, 1e-13, "palAoppa : 7");
  delta_within( $aoprms[8], 0.45, 1e-13, "palAoppa : 8");
  delta_within( $aoprms[9], 0.006, 1e-15, "palAoppa : 9");
  delta_within( $aoprms[10], 0.0001562803328459898, 1e-13, "palAoppa: 10" );
  delta_within( $aoprms[11], -1.792293660141e-7, 1e-13, "palAoppa: 11" );
  delta_within( $aoprms[12], 2.101874231495843, 1e-13, "palAoppa: 12" );
  delta_within( $aoprms[13], 7.601916802079765, 1e-8, "palAoppa: 13" );

  my ($rap, $dap) = Astro::PAL::palOap ( "r", 1.6, -1.01, $date, $dut, $elongm, $phim,
           $hm, $xp, $yp, $tdk, $pmb, $rh, $wl, $tlr );
  delta_within( $rap, 1.601197569844787, 1e-10, "palOap: rr");
  delta_within( $dap, -1.012528566544262, 1e-10, "palOap: rd");

  ($rap, $dap) = Astro::PAL::palOap ( "h", -1.234, 2.34, $date, $dut, $elongm, $phim,
           $hm, $xp, $yp, $tdk, $pmb, $rh, $wl, $tlr );
  delta_within( $rap, 5.693087688154886463, 1e-10, "palOap: hr");
  delta_within( $dap, 0.8010281167405444, 1e-10, "palOap: hd");

  ($rap, $dap) = Astro::PAL::palOap ( "a", 6.1, 1.1, $date, $dut, $elongm, $phim,
           $hm, $xp, $yp, $tdk, $pmb, $rh, $wl, $tlr );
  delta_within( $rap, 5.894305175192448940, 1e-10, "palOap: ar");
  delta_within( $dap, 1.406150707974922, 1e-10, "palOap: ad");

  ($rap, $dap) = Astro::PAL::palOapqk ( "r", 2.1, -0.345, \@aoprms);
  delta_within( $rap, 2.10023962776202, 1e-10, "palOapqk: rr");
  delta_within( $dap, -0.3452428692888919, 1e-10, "palOapqk: rd");

  ($rap, $dap) = palOapqk ( "h", -0.01, 1.03, \@aoprms );
  delta_within( $rap, 1.328731933634564995, 1e-10, "palOapqk: hr");
  delta_within( $dap, 1.030091538647746, 1e-10, "palOapqk: hd");

  ($rap, $dap) = Astro::PAL::palOapqk ( "a", 4.321, 0.987, \@aoprms );
  delta_within( $rap, 0.4375507112075065923, 1e-10, "palOapqk: ar");
  delta_within( $dap, -0.01520898480744436, 1e-10, "palOapqk: ad");

  @aoprms = Astro::PAL::palAoppat ( $date + Astro::PAL::DS2R, @aoprms );

  delta_within( $aoprms[13], 7.602374979243502, 1e-8, "palAoppat");

}
