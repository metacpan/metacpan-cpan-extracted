package Data::Dimensions::Map;
# hold information about units provided by the module

use strict;
use vars qw(%SI_base %SI_units %units %basic %prefixes);

# basic SI units only need prefix scaling...
%SI_base = (
	    m  => {m =>1 },
	    kg => {kg =>1},
	    s  => {s =>1 },
	    A  => {A =>1 },
	    K  => {K =>1 },
	    cd => {cd =>1},
	    mol=> {mol=>1},

	    rad=> {rad=>1},
	    sr => {sr =>1},
	    
	    Hz => {s => -1},
	    N  => {kg => 1, m => 1, s => -2},
	    Pa => {kg => 1, m => -1,s => -2},
	    J  => {kg => 1, m => 2, s => -2},
	    W  => {kg => 1, m => 2, s => -3},

	    coul    => {A => 1, s=> 1},
	    V       => {kg =>1, m=> 2, s=> -3, A => -1},
	    ohm     => {kg =>1, m=> 2, s=> -3, A => -2},
	    S       => {kg =>-1,m=>-2, s=> 3, A => 2},
	    F       => {kg =>-1,m=>-2, s=> 4, A => 2},
	    
	    Wb      => {kg =>1, m=> 2, s=> -2, A => -1},
	    H       => {kg =>1, m=> 2, s=> -2, A => -2},
	    T       => {kg =>1, m=> 1, s=> -2, A => -1},
	    
	    lm      => {cd =>1, m=>-2},
	    
	    Bq       => {s => -1},
	    Gy       => {m => 2, s => -2},
	    );
%SI_units = (
	     %SI_base,
	     meter=> $SI_base{m},
	     kilo=> $SI_base{kg},
	     kilogram=> $SI_base{kg},
	     kilogramme=> $SI_base{kg},
	     sec=> $SI_base{s},
	     second=> $SI_base{s},
	     amp=> $SI_base{A},
	     ampere=> $SI_base{A},
	     kelvin=> $SI_base{K},
	     candela=> $SI_base{cd},
	     mole=> $SI_base{mol},
	     radian => $SI_base{rad},
	     steradian=> $SI_base{sr},
	     sterad=> $SI_base{sr},
	     hertz=> $SI_base{Hz},
	     newton=> $SI_base{N},
	     pascal=> $SI_base{Pa},
	     joule=> $SI_base{J},
	     watt=> $SI_base{W},
	     coulomb=> $SI_base{coul},
	     volt=> $SI_base{V},
	     seimens=> $SI_base{S},
	     farad=> $SI_base{F},
	     weber=> $SI_base{Wb},
	     henry=> $SI_base{H},
	     tesla=> $SI_base{T},
	     lumen=> $SI_base{lm},
	     becquerel=> $SI_base{Bq},
	     gray=> $SI_base{Gy},
	     );

# This should be invoked last...  We know that SI units cannot change
# the scaling of the base value, so we can ignore that here
sub parse_SI {
    my ($hr, $scale) = @_;
    my %temp;

    foreach my $unit (keys %$hr) {
	if (exists $SI_units{$unit}) {
	    foreach (keys %{$SI_units{$unit}}) {
		$temp{$_} += $SI_units{$unit}->{$_} * $hr->{$unit};
	    }
	}
	else  {
	    $temp{$unit} += $hr->{$unit};
	}
    }
    return (\%temp, $scale);
}

%prefixes = (
	     semi=>     0.5,
             demi=>     0.5,
	     yotta=>	1e24,
	     zetta=>	1e21,
	     exa=>	1e18,
	     peta=>	1e15,
	     tera=>	1e12,
	     giga=>	1e9,
	     mega=>	1e6,
	     kilo=>	1e3,
	     hecto=>	1e2,
	     deka=>	1e1,
	     deci=>	1e-1,
	     centi=>	1e-2,
	     milli=>	1e-3,
	     micro=>	1e-6,
	     nano=>	1e-9,
	     pico=>	1e-12,
	     femto=>	1e-15,
	     atto=>	1e-18,
	     zopto=>	1e-21,
	     yocto=>	1e-24,
	     Y=>	1e24,
	     Z=>	1e21,
	     E=>	1e18,
	     P=>	1e15,
	     T=>	1e12,
	     G=>	1e9,
	     M=>	1e6,
	     k=>	1e3,
	     h=>	1e2,
	     da=>	1e1,
	     d=>	1e-1,
	     c=>	1e-2,
	     m=>	1e-3,
	     u=>	1e-6,
	     n=>	1e-9,
	     p=>	1e-12,
	     f=>	1e-15,
	     a=>	1e-18,
	     z=>	1e-21,
	     y=>	1e-24,
	     );

sub parse_prefix {
    my ($hr, $scale) = @_;
    my %temp;
    my $rg = join('|', keys %prefixes);
    my $rx = qr/^($rg)\-(\w+)$/;
    
    foreach (keys %$hr) {
	if ($_ =~ $rx) {
	    $temp{$2} = $hr->{$_};
	    $scale *= $prefixes{$1}**($hr->{$_});
	}
	else {
	    $temp{$_} = $hr->{$_};
	}
    }
    return (\%temp, $scale);
}

# $units{ unit } = [scale, {basic hash}];
%units = (
	  turn       => [ 2 * 3.14159, {rad=>1}],
	  revolution => [ 2 * 3.14159, {rad=>1}],
	  degree => [ 2*3.14159 / 360, {rad=>1}],
	  deg =>    [ 2*3.14159 / 360, {rad=>1}],
	  arcdeg =>    [ 2*3.14159 / 360, {rad=>1}],
	  arcmin =>    [ 2*3.14159 / (360*60), {rad=>1}],
	  arcsec =>    [ 2*3.14159 / (360*60*60), {rad=>1}],
	  minute => [ 60, {s=>1}],
	  min => [ 60, {s=>1}],
	  hour=> [ 60*60, {s=>1}],
	  hr=> [ 60*60, {s=>1}],
	  day => [ 24*60*60, {s=>1}],
	  week=> [ 7*24*60*60, {s=>1}],
	  year=> [ 365*24*60*60, {s=>1}], # non-leap
	  yr=> [ 365*24*60*60, {s=>1}],
	  gram=> [ 1e-3, {kg=>1}],
	  gm=> [1e-3 , {kg=>1}],
	  tonne=> [1e3 , {kg=>1}],
# avoirdupois
	  lb=> [.45359237 , {kg=>1}],
	  pound=> [ .45359237, {kg=>1}],
	  ounce=> [ .45359237/16, {kg=>1}],
	  oz=> [ .45359237/16, {kg=>1}],

	  micron => [ 1e-6, {m=>1}],
	  angstrom=> [ 1e-10, {m=>1}],
# Imperial
	  inch=> [2.54 / 100 , {m=>1}],
	  in => [ 2.54 / 100, {m=>1}],
	  foot=> [ 12*2.54 / 100, {m=>1}],
	  feet=> [12*2.54 / 100 , {m=>1}],
	  ft=> [ 12*2.54 / 100, {m=>1}],
	  yard=> [3*12*2.54 / 100, {m=>1}],
	  yd=> [ 3*12*2.54 / 100, {m=>1}],
	  mile=> [ 5280*12*2.54 / 100, {m=>1}],
	  nmile=> [ 1852, {m=>1}],
	  acre=> [4840 * (3*12*2.54 / 100)**2 , {m=>2}],
	  hectare => [100*100, {m => 2}],
	  
	  cc=> [(1/100)**3 , {m=>3}],
	  liter=> [ 1000*((1/100)**3), {m=>3}],
	  ml => [ (1/100)**3, {m=>3}],

# US Liquid
	  gallon => [231 * (2.54 / 100)**3 , {m=>3}],
	  gal => [ 231 * (2.54 / 100)**3, {m=>3}],
	  quart => [ 231 * (2.54 / 100)**3 / 4, {m=>3}],
	  pint => [ 231 * (2.54 / 100)**3 / 8, {m=>3}],

# UK Liquid
	  brgallon => [277.420 * (2.54 / 100)**3 , {m=>3}],
	  brquart=> [ 277.420 * (2.54 / 100)**3 / 4, {m=>3}],
	  brpint => [ 277.420 * (2.54 / 100)**3 / 8, {m=>3}],

	  cal=> [ 4.1868, {joule=>1}],
	  mho=> [ 1, {ohm=>-1}],

	  baud => [ 1, {bit=>1, s=>-1}],
	  byte => [ 8 ,{bit=>1}],
	  block=> [ 512*8, {bit=>1}],

	  barn => [1e-28 , {m=>2}],
	  amu => [ 1.66044e-27, {kg=>1}],
	  electronvolt => [ 1.6021764e-19, {joule=>1}],
	  erg => [(1/100)**2 * (1/1000) , {m=>2, kg=>1, s=>-2}],
	  fermi=> [1e-15 , {m=>1}],
	  lightyear=> [ 365.25 * 299_792_458 * 60 * 60 * 24, {m=>1}],
	  parsec => [ 3.24 * 365.25 * 299_792_458 * 60 * 60 * 24, {m=>1}],

	  point=> [(1/72) * 2.54 / 100 , {m=>1}],

	  celsius    => [1 , {K=>1}], # although no zero point changes
	  centrigrade=> [1 , {K=>1}],

	  siderealyear=> [ 365.256360417* 24*60*60, {s=>1}],

	  percent => [ 0.01, {}],

# test me baby!
	  __HONK_IF_YOU_PERL => [10, {m=>1, s=>-1}],
	  );

# This is the general scaling and convert to base monster
sub parse_other {
    my ($hr, $scale) = @_;
    my %temp;
    foreach my $unit (keys %$hr) {
	if (exists $units{$unit}) {
	    my $factor = $units{$unit}->[0];
	    my $exp = $hr->{$unit};
	    foreach (keys %{$units{$unit}->[1]}) {
		$temp{$_} += $units{$unit}->[1]->{$_} * $exp;
	    }
	    $scale *= $factor ** $exp;
	}
	else {
	    $temp{$unit} = $hr->{$unit};
	}
    }
    return (\%temp, $scale);
}

1;

__END__

=head1 Data::Units::Map

This package implements the mapping between base and extended units,
including the numerical conversions where appropriate.

=cut
