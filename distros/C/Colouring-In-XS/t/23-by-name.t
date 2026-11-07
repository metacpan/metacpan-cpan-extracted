use strict;
use warnings;
use Test::More;

use Colouring::In::XS;

# A method named at run time is not rewritten at compile time, so these calls
# reach the XSUBs behind the ops. They must answer as the ops do.

my $c = Colouring::In::XS->new('#336699');
my $t = Colouring::In::XS->new('rgba(0,0,0,0.25)');

my %expect = (
	toHEX => ['#369', '#000'],
	toHSL => ['hsl(210,50%,40%)', 'hsl(0,0%,0%)'],
	toHSV => ['hsv(210,67%,60%)', 'hsv(0,0%,0%)'],
	toTerm => ['r51g102b153', 'r0g0b0'],
	toOnTerm => ['on_r51g102b153', 'on_r0g0b0'],
	toRGB => ['rgb(51,102,153)', 'rgba(0,0,0,0.25)'],
	toRGBA => ['rgba(51,102,153,1)', 'rgba(0,0,0,0.25)'],
	toCSS => ['#369', 'rgba(0,0,0,0.25)'],
);

for my $name (sort keys %expect) {
	is($c->$name, $expect{$name}[0], "$name by name on an opaque colour");
	is($t->$name, $expect{$name}[1], "$name by name on a transparent colour");
	is($c->$name, $c->can($name)->($c), "$name agrees with the op");
}

my $toCSS = 'toCSS';
is($t->$toCSS(1), 'rgba(0,0,0,0.25)', 'toCSS rounds the alpha to the places given');
is($t->$toCSS(2), 'rgba(0,0,0,0.25)', 'and to two');
is($c->$toCSS(0, 1), '#336699', 'a true second argument asks for the long hex form');
is($c->$toCSS(2), '#369', 'an opaque colour is hex at any rounding');
is($c->$toCSS(0, undef), '#369', 'an undefined second argument is the short form');
is($c->$toCSS(undef, 1), '#336699', 'an undefined rounding is none');

{
	no warnings 'uninitialized';
	my $toRGB = 'toRGB';
	my $odd = bless { colour => [1, 2, 3], alpha => undef }, 'Colouring::In::XS';
	is($odd->toRGB, 'rgb(1,2,3)', 'an alpha that is not a number reads as opaque');
	is($odd->$toRGB, 'rgb(1,2,3)', 'by name too');
}

my $toHEX = 'toHEX';
is($c->$toHEX(1), '#336699', 'toHEX with a true integer is the long form');
is($c->$toHEX(0), '#369', 'with zero the short form');
is($c->$toHEX('1'), '#369', 'a string is not the integer flag');
is($c->$toHEX(1.5), '#369', 'nor is a float');
is($c->$toHEX(undef), '#369', 'nor is undef');

{
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };
	is("$c", '#369', 'an opaque colour stringifies as hex');
	is("$t", 'rgba(0,0,0,0.25)', 'a transparent colour stringifies as rgba');
	is(scalar @warnings, 0, 'stringification warns of nothing') or diag @warnings;
}

done_testing;
