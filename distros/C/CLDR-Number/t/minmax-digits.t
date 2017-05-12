use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 23;
use CLDR::Number;

my $cldr = CLDR::Number->new;
my $decf = $cldr->decimal_formatter;

is $decf->minimum_integer_digits,  1, 'default (root) min integer digits';
is $decf->minimum_fraction_digits, 0, 'default (root) min fraction digits';
is $decf->maximum_fraction_digits, 3, 'default (root) max fraction digits';

is $decf->format(7.7777), '7.778', 'fraction greater than max';

$decf->minimum_fraction_digits(2);
is $decf->minimum_fraction_digits, 2, 'updated min fraction digits';
is $decf->maximum_fraction_digits, 3, 'max fraction digits remains same';

is $decf->format(5), '5.00', 'fraction less than min';

$decf->maximum_fraction_digits(1);
is $decf->maximum_fraction_digits, 1, 'updated max fraction digits';
is $decf->minimum_fraction_digits, 1, 'min fraction becomes max if max < min';

is $decf->format(5),    '5.0', 'fraction less than min';
is $decf->format(7.77), '7.8', 'fraction greater than max';

$decf->minimum_fraction_digits(3);
is $decf->minimum_fraction_digits, 3, 'updated min fraction digits';
is $decf->maximum_fraction_digits, 3, 'max fraction becomes min if min > max';

is $decf->format(5),      '5.000', 'fraction less than min';
is $decf->format(7.7777), '7.778', 'fraction greater than max';

$decf = $cldr->decimal_formatter(
    minimum_integer_digits  => 2,
    minimum_fraction_digits => 1,
    maximum_fraction_digits => 2,
);

is $decf->minimum_integer_digits,  2, 'set min integer digits on create';
is $decf->minimum_fraction_digits, 1, 'set min fraction digits on create';
is $decf->maximum_fraction_digits, 2, 'set max fraction digits on create';

is $decf->format(5), '05.0', 'integer less than min';

my $curf = $cldr->currency_formatter(locale => 'en', currency_code => 'USD');

is $curf->minimum_fraction_digits, 2, 'default currency min fraction digits';
is $curf->maximum_fraction_digits, 2, 'default currency max fraction digits';

is $curf->format(5),     '$5.00', 'fraction less than min';
is $curf->format(7.777), '$7.78', 'fraction greater than max';
