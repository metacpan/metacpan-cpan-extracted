#!perl
# Test of PAL using routines from the PAL test suite

use strict;
use warnings;
use Test::More tests => 133;
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

{ # t_altaz
  my ($az, $azd, $azdd, $el, $eld, $eldd, $pa, $pad, $padd) = palAltaz( 0.7, -0.7, -0.65 );
  delta_within($az, 4.400560746660174, 1e-12, "palAltaz: az");
  delta_within($azd, -0.2015438937145421, 1e-13, "palAltaz: azd");
  delta_within($azdd, -0.4381266949668748, 1e-13, "palAltaz: azdd");
  delta_within($el, 1.026646506651396, 1e-12, "palAltaz: el");
  delta_within($eld, -0.7576920683826450, 1e-13, "palAltaz: eld");
  delta_within($eldd, 0.04922465406857453, 1e-14, "palAltaz: eldd");
  delta_within($pa, 1.707639969653937, 1e-12, "palAltaz: pa");
  delta_within($pad, 0.4717832355365627, 1e-13, "palAltaz: pad");
  delta_within($padd, -0.2957914128185515, 1e-13, "palAltaz: padd");
}

{ # t_fitxy
  my $xye = [
    -23.4, -12.1,   32.0,  -15.3,
     10.9,  23.7,   -3.0,   16.1,
     45.0,  32.5,    8.6,  -17.0,
     15.3,  10.0,  121.7,   -3.8,
  ];

  my $xym = [
    -23.41,  12.12,  32.03,  15.34,
     10.93, -23.72,  -3.01, -16.10,
     44.90, -32.46,   8.55,  17.02,
     15.31, -10.07, 120.92,   3.81,
  ];

  # Fit a 4-coeff linear model to relate two sets of (x,y) coordinates.

  my ($j, $coeffs) = palFitxy(4, $xye, $xym);

  delta_within($coeffs->[0], -7.938263381515947e-3, 1e-12, "palFitxy: 4/0");
  delta_within($coeffs->[1], 1.004640925187200, 1e-12, "palFitxy: 4/1");
  delta_within($coeffs->[2], 3.976948048238268e-4, 1e-12, "palFitxy: 4/2");
  delta_within($coeffs->[3], -2.501031681585021e-2, 1e-12, "palFitxy: 4/3");
  delta_within($coeffs->[4], 3.976948048238268e-4, 1e-12, "palFitxy: 4/4");
  delta_within($coeffs->[5], -1.004640925187200, 1e-12, "palFitxy: 4/5");
  is($j, 0, "palFitxy: 4/j");

  # Same but 6-coeff.

  ($j, $coeffs) = palFitxy(6, $xye, $xym);

  delta_within($coeffs->[0], -2.617232551841476e-2, 1e-12, "palFitxy: 6/0");
  delta_within($coeffs->[1], 1.005634905041421, 1e-12, "palFitxy: 6/1");
  delta_within($coeffs->[2], 2.133045023329208e-3, 1e-12, "palFitxy: 6/2");
  delta_within($coeffs->[3], 3.846993364417779909e-3, 1e-12, "palFitxy: 6/3");
  delta_within($coeffs->[4], 1.301671386431460e-4, 1e-12, "palFitxy: 6/4");
  delta_within($coeffs->[5], -0.9994827065693964, 1e-12, "palFitxy: 6/5");
  is($j, 0, "palFitxy: 6/j");

  # Compute predicted coordinates and residuals.

  my ($xyp, $xrms, $yrms, $rrms) = palPxy($xye, $xym, $coeffs);

  delta_within($xyp->[0], -23.542232946855340, 1e-12, "palPxy: x0");
  delta_within($xyp->[1], -12.11293062297230597, 1e-12, "palPxy: y0");
  delta_within($xyp->[2], 32.217034593616180, 1e-12, "palPxy: x1");
  delta_within($xyp->[3], -15.324048471959370, 1e-12, "palPxy: y1");
  delta_within($xyp->[4], 10.914821358630950, 1e-12, "palPxy: x2");
  delta_within($xyp->[5], 23.712999520015880, 1e-12, "palPxy: y2");
  delta_within($xyp->[6], -3.087475414568693, 1e-12, "palPxy: x3");
  delta_within($xyp->[7], 16.09512676604438414, 1e-12, "palPxy: y3");
  delta_within($xyp->[8], 45.05759626938414666, 1e-12, "palPxy: x4");
  delta_within($xyp->[9], 32.45290015313210889, 1e-12, "palPxy: y4");
  delta_within($xyp->[10], 8.608310538882801, 1e-12, "palPxy: x5");
  delta_within($xyp->[11], -17.006235743411300, 1e-12, "palPxy: y5");
  delta_within($xyp->[12], 15.348618307280820, 1e-12, "palPxy: x6");
  delta_within($xyp->[13], 10.07063070741086835, 1e-12, "palPxy: y6");
  delta_within($xyp->[14], 121.5833272936291482, 1e-12, "palPxy: x7");
  delta_within($xyp->[15], -3.788442308260240, 1e-12, "palPxy: y7");
  delta_within($xrms, 0.1087247110488075, 1e-13, "palPxy: xrms");
  delta_within($yrms, 0.03224481175794666, 1e-13, "palPxy: yrms");
  delta_within($rrms, 0.1134054261398109, 1e-13, "palPxy: rrms");

  # Invert the model.

  ($j, my $bkwds) = palInvf($coeffs);

  delta_within($bkwds->[0], 0.02601750208015891, 1e-12, "palInvf: 0");
  delta_within($bkwds->[1], 0.9943963945040283, 1e-12, "palInvf: 1");
  delta_within($bkwds->[2], 0.002122190075497872, 1e-12, "palInvf: 2");
  delta_within($bkwds->[3], 0.003852372795357474353, 1e-12, "palInvf: 3");
  delta_within($bkwds->[4], 0.0001295047252932767, 1e-12, "palInvf: 4");
  delta_within($bkwds->[5], -1.000517284779212, 1e-12, "palInvf: 5");
  is($j, 0, "palInvf: j");

  # Transform one x, y.

  my ($x2, $y2) = palXy2xy(44.5, 32.5, $coeffs);

  delta_within($x2, 44.793904912083030, 1e-11, "palXy2xy: x");
  delta_within($y2, -32.473548532471330, 1e-11, "palXy2xy: y");

  # Decompose the fit into scales etc.

  my ($xz, $yz, $xs, $ys, $perp, $orient) = palDcmpf($coeffs);
  delta_within($xz, -0.0260175020801628646, 1e-12, "palDcmpf: xz");
  delta_within($yz, -0.003852372795357474353, 1e-12, "palDcmpf: yz");
  delta_within($xs, -1.00563491346569, 1e-12, "palDcmpf: xs");
  delta_within($ys, 0.999484982684761, 1e-12, "palDcmpf: ys");
  delta_within($perp,-0.002004707996156263, 1e-12, "palDcmpf: p");
  delta_within($orient, 3.14046086182333, 1e-12, "palDcmpf: o");
}

{ # t_ecleq
  my ($dr, $dd) = palEcleq(1.234, -0.123, 43210.0);
  delta_within($dr, 1.229910118208851, 1e-5, "palEcleq: dr");
  delta_within($dd, 0.2638461400411088, 1e-5, "palEcleq: dd");
}

{ # t_pcd
  my $disco = 178.585;
  my $x = 0.0123;
  my $y = -0.00987;

  ($x, $y) = palPcd($disco, $x, $y);
  delta_within($x, 0.01284630845735895, 1e-14, "palPcd: x");
  delta_within($y, -0.01030837922553926, 1e-14, "palPcd: y");

  ($x, $y) = palUnpcd($disco, $x, $y);
  delta_within($x, 0.0123, 1e-14, "palUnpcd: x");
  delta_within($y, -0.00987, 1e-14, "palUnpcd: y");

  # Now negative disco round trip
  $disco = -0.3333333;
  $x = 0.0123;
  $y = -0.00987;
  ($x, $y) = palPcd($disco, $x, $y);
  ($x, $y) = palUnpcd($disco, $x, $y);
  delta_within($x, 0.0123, 1e-14, "palUnpcd: x");
  delta_within($y, -0.00987, 1e-14, "palUnpcd: y");
}

{ # t_polmo
  my ($elong, $phi, $daz) = palPolmo(0.7, -0.5, 1.0e-6, -2.0e-6);
  delta_within($elong, 0.7000004837322044, 1.0e-12, "palPolmo: elong");
  delta_within($phi, -0.4999979467222241, 1.0e-12, "palPolmo: phi");
  delta_within($daz, 1.008982781275728e-6, 1.0e-12, "palPolmo: daz");
}
