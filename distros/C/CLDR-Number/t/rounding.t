use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 37;
use CLDR::Number;

my $cldr = CLDR::Number->new;
my $decf = $cldr->decimal_formatter(locale => 'fr');

$decf->maximum_fraction_digits(1);
is $decf->format(0.05),   '0';
is $decf->format(0.051),  '0,1';
is $decf->format(0.149),  '0,1';
is $decf->format(0.15),   '0,2';
is $decf->format(0.25),   '0,2';
is $decf->format(0.251),  '0,3';
is $decf->format(0.349),  '0,3';
is $decf->format(0.35),   '0,4';
is $decf->format(-0.05),  '-0';
is $decf->format(-0.051), '-0,1';
is $decf->format(-0.149), '-0,1';
is $decf->format(-0.15),  '-0,2';
is $decf->format(-0.25),  '-0,2';
is $decf->format(-0.251), '-0,3';
is $decf->format(-0.349), '-0,3';
is $decf->format(-0.35),  '-0,4';

$decf->rounding_increment(0.05);
is $decf->format(0.00),  '0';
is $decf->format(0.01),  '0';
is $decf->format(0.02),  '0';
is $decf->format(0.024), '0';
is $decf->format(0.025), '0,05';
is $decf->format(0.03),  '0,05';
is $decf->format(0.04),  '0,05';
is $decf->format(0.05),  '0,05';
is $decf->format(0.06),  '0,05';
is $decf->format(0.07),  '0,05';
is $decf->format(0.074), '0,05';
is $decf->format(0.075), '0,1';
is $decf->format(0.08),  '0,1';
is $decf->format(0.09),  '0,1';
is $decf->format(0.10),  '0,1';
is $decf->format(-0.10), '-0,1';

$decf->rounding_increment(10);
is $decf->format(4),   '0';
is $decf->format(5),   '10';
is $decf->format(10),  '10';
is $decf->format(-10), '-10';

$decf = $cldr->decimal_formatter(rounding_increment => 5);
is $decf->rounding_increment, 5, 'set rounding increment on create';
