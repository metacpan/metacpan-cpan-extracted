# -*-perl-*-
#
# thanks to Brad Holden for providing an independent check
# of the Astro::Cosmology code. Since the algorithm is
# essentially taken from the same source it's not completely
# independent, but was written by someone else and
# uses a different integration scheme for the calculations.
#

use strict;
$|++;

use Test;

plan tests => 16;

use PDL;
use PDL::Math;
use POSIX qw();

use Astro::Cosmology;

# time for some actual comments
# This "module" is written so Doug has something to test against
# for his Astro::Cosmology package

my $nstep = 1e6;
my $_tol = 1/$nstep;

# this routine determines whether or not you have flat universe or
# if you have to use the correction when going between the comoving
# distance and the interesting distances (lum, ang, etc.)

sub _not_flat {

  my $matter = shift;
  my $lambda = shift;

  my $tot = $matter+$lambda;

  if (abs(1-$tot) < $_tol) {
    return(0);
  } elsif ($tot > 1) {
    return(-1); # negative curvature
  } else {
    return(1); # positive curvature
  }

}

=pod

=head1 B<d_c>

Inputs

=over 4

=item $z

Input redshift

=item $matter

Omega matter - defaults to 0.3

=item $lambda

Omega lambda - defaults to 0.7

=item $nsteps

Number of integration steps - defaults to 10000

=back

Outputs

=over 4

=item comoving distance in units of the horizon distance

=back

Computation is done via direct integration using PDL's intover.

=cut

sub d_c {

  my $z = shift;
  my $matter = 0.3;
  my $lambda = 0.7;
  my $nsteps = 10000;

  $matter = shift if(@_);
  $lambda = shift if(@_);
  $nsteps = shift if(@_);

  my $curve = 1.0 - ($lambda + $matter);

  # here I do the actual integration, slowly, in PDL

  my $zs = xvals $nsteps;
  $zs *= $z/$nsteps;
  $zs += 0.5*$z/$nsteps;

  # below is the E(z) term from David Hogg's writeup

  my $ezs = $matter*(1+$zs)**3;
  $ezs += $curve*(1+$zs)**2;
  $ezs += $lambda;

  # below is integrand for the comoving distance

  $ezs = sqrt($ezs);
  $ezs = 1.0/$ezs;
  $ezs *= $z/$nsteps;

  return(intover($ezs));
}

=pod

=head1 B<d_m>

Inputs

=over 4

=item $z

Input redshift

=item $matter

Omega matter - defaults to 0.3

=item $lambda

Omega lambda - defaults to 0.7

=item $nsteps

Number of integration steps - defaults to 10000

=back

Outputs

=over 4

=item transverse comoving distance in units of the horizon distance

=back

Calls B<d_c()> to get the comoving distance, then computes curvature.
Uses formula from David Hogg's astro-ph/9905116 paper.

=cut

sub d_m {

  my $z = shift;
  my $matter = 0.3;
  my $lambda = 0.7;
  my $nsteps = 10000;

  $matter = shift if(@_);
  $lambda = shift if(@_);
  $nsteps = shift if(@_);

  # here I have to "correct" the comoving distance depending on the
  # the curvature of the universe.  So, I calculate the curvature,
  # calculate the comoving distance along the line of sight and
  # only then do compute whether the curvature is positive, negatuve
  # or "zero", which means less than the tolerance variable $_tol
  #
  # _not_flat is the routine that checks the curvature, is uses the
  # input lambda and matter, not the computed curvature

  my $curve = 1.0- ($lambda+$matter);
  my $dc = d_c($z,$matter,$lambda,$nsteps);

  if (!_not_flat($matter,$lambda)) {
    return($dc);
  } elsif (_not_flat($matter,$lambda) < 0) {
    # negative curvature
    $curve = abs($curve);
    return(sin($dc*sqrt($curve))/sqrt($curve));
  } else {
    return(sinh($dc*sqrt($curve))/sqrt($curve));
  }

}

=pod

=head1 B<look_back_z>

Inputs

=over 4

=item $z

Input redshift

=item $matter

Omega matter - defaults to 0.3

=item $lambda

Omega lambda - defaults to 0.7

=item $nsteps

Number of integration steps - defaults to 10000

=back

Outputs

=over 4

=item lookback time in units of the Hubble time

=back

Computes by direct integration using PDL's intover routine, like
B<d_c()>

=cut

sub look_back_z {

  my $z = shift;
  my $matter = 0.3;
  my $lambda = 0.7;
  my $nsteps = 10000;

  $matter = shift if(@_);
  $lambda = shift if(@_);
  $nsteps = shift if(@_);

  $nsteps = POSIX::floor($nsteps);

  my $curve = 1.0 - ($lambda + $matter);

  # here I do the actual integration, slowly, in PDL

  my $zs = xvals $nsteps;
  $zs *= $z/$nsteps;
  $zs += 0.5*$z/$nsteps;

  # below is the E(z) term from David Hogg's writeup

  my $ezs = $matter*(1+$zs)**3;
  $ezs += $curve*(1+$zs)**2;
  $ezs += $lambda;
  $ezs = sqrt($ezs);

  # below is integrand for the lookback time

  $ezs *= (1+$zs);
  $ezs = 1.0/$ezs;
  $ezs *= $z/$nsteps;

  return(intover($ezs));
}

=pod

=head1 B<comoving_volume_z>

Inputs

=over 4

=item $z

Input redshift

=item $matter

Omega matter - defaults to 0.3

=item $lambda

Omega lambda - defaults to 0.7

=item $nsteps

Number of integration steps - defaults to 10000

=back

Outputs

=over 4

=item comoving volume in units of the Hubble volume

=back

Computes using an analytical formula from Carrol, Press and Turner, ARA&Ap, 1992, 30, 499

=cut

sub comoving_volume_z {

  my $z = shift;
  my $matter = 0.3;
  my $lambda = 0.7;
  my $nsteps = 10000;

  $matter = shift if(@_);
  $lambda = shift if(@_);
  $nsteps = shift if(@_);

  $nsteps = POSIX::floor($nsteps);

  my $curve = 1.0 - ($lambda + $matter);
  my $sacurve = sqrt(abs($curve));
  my $dm = d_m($z,$matter,$lambda,$nsteps);
  my $vc;

  # this formula is from Carrol, Press and Turner, ARA&Ap, 1992, 30, 499
  # however, it seems odd, as the volume will be negative for negative
  # curvature.

  if (!_not_flat($matter,$lambda)) {

    $vc = $dm**3;
    $vc /= 3.0;

  } elsif (_not_flat($matter,$lambda) < 0) {
    # negative curvature

    $vc = $dm*sqrt(1+$curve*$dm**2) - asin($dm*$sacurve)/$sacurve;
    $vc /= 2*$curve;

  } else {

    $vc = $dm*sqrt(1+$curve*$dm**2) - asinh($dm*$sacurve)/$sacurve;
    $vc /= 2*$curve;

  }

  return($vc);
}

sub print_output {

  my $module_val = shift;
  my $local_val = shift;
  my $name_str = shift;

  print "Module ".$name_str.": ",$module_val,"\n";
  print "Local ".$name_str.": ",$local_val,"\n";

  my $adiff = abs($local_val-$module_val);
  print "Absolute value of difference: ",
    sprintf("%.3g",$adiff),"\n";

  if ($adiff < 1e-5) {
    print "Absolute value of difference within tolerance for $name_str\n";
  } else {
    print "!!**Absolute value of difference exceeds tolerance for $name_str **!!\n";
  }

  ok( $adiff < 1.0e-5 );
}

# Tests Doug's code by comparing the local subroutines to values returned
# by dougs Module.

sub run_test {

  my $z = shift;
  my $om = shift;
  my $ol = shift;
  my $nstep = shift;

  my $ac_obj = Astro::Cosmology->new({Matter=>$om, Lambda=>$ol, H0=>0});
  print $ac_obj,"\n";
  my $m_ld = $ac_obj->lum_dist($z);
  my $m_ad = $ac_obj->adiam_dist($z);
  my $m_lbt = $ac_obj->lookback_time($z);
  my $m_vc = $ac_obj->comov_vol($z);

  my $l_dm = d_m($z,$om,$ol,$nstep);
  my $l_ld = $l_dm*(1+$z);
  my $l_ad = $l_dm/(1+$z);
  my $l_lbt = look_back_z($z,$om,$ol,$nstep);
  my $l_vc = comoving_volume_z($z,$om,$ol,$nstep);

  print_output($m_ld,$l_ld,"luminosity distance");
  print_output($m_ad,$l_ad,"angular diameter distance");
  print_output($m_lbt,$l_lbt,"lookback time");
  print_output($m_vc,$l_vc,"comoving volume");
  print "\n";
}

# Canonical flat universe
run_test(1.235,0.3,0.7,1e6);
# Open universe using best fit values from my thesis
run_test(1.235,0.32,0.0,1e6);
# weird closed universe
run_test(1.235,1.32,0.0,1e6);
# wacky open universe
run_test(1.235,1.32,-1.0,1e6);

