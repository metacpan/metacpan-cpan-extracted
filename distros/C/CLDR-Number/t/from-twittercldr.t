use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 22;
use CLDR::Number;

my $cldr = CLDR::Number->new;

# Tests adapted from:
# TwitterCldr (twitter-cldr-rb)
# https://github.com/twitter/twitter-cldr-rb/tree/master/spec/formatters/numbers

# number_formatter_spec.rb
my $decf = $cldr->decimal_formatter(locale => 'sv');
is $decf->format(12),      '12',       'format a basic integer';
is $decf->format(12.0),    '12',       'format a basic decimal';
is $decf->format(1337),    '1 337',    'formats an integer larger than 999';
is $decf->format(1337.37), '1 337,37', 'formats a decimal larger than 999.9';
$decf->maximum_fraction_digits(0); is $decf->format(12.1),  '12',   'formats with precision of 0';
$decf->maximum_fraction_digits(1); is $decf->format(12.25), '12,2', 'half-even rounding and formats with precision of 1';

# decimal_formatter_spec.rb
$decf->locale('sv');
is $decf->format(12.0),  '12',    'format positive decimals correctly';
is $decf->format(-12.0), '−12',   'format negative decimals correctly';
$decf->minimum_fraction_digits(3);
is $decf->format(-12), '−12,000', 'respect the minimum_fraction_digits attribute';

# percent_formatter_spec.rb
my $perf = $cldr->percent_formatter(locale => 'da');
is $perf->format(0.12),  '12 %',      'format the number correctly';
is $perf->format(-0.12), '-12 %',     'format negative numbers correctly';
$perf->minimum_fraction_digits(3);
is $perf->format(-0.12), '-12,000 %', 'respect the minimum_fraction_digits attribute';

# currency_formatter_spec.rb
my $curf = $cldr->currency_formatter(locale => 'ko', currency_code => 'USD');
is $curf->format(12),  'US$12.00',  'handles positive numbers';
is $curf->format(-12), '-US$12.00', 'handles negative numbers';
$curf->locale('ms');
$curf->currency_sign('S/.');       is $curf->format(12), 'S/. 12.00',  'use the specified currency symbol when specified';
$curf->currency_code('XYZ');       is $curf->format(12), 'XYZ 12.00',  'use the currency code as the symbol if the currency code cannot be identified';
$curf->currency_code('THB');       is $curf->format(12), 'THB 12.00',  'use the currency symbol for the corresponding currency code';
$curf->currency_code('TND');       is $curf->format(12), 'TND 12.000', 'use the currency-specific default minimum fraction digits';
$curf->currency_code('CAD');       is $curf->format(12), 'CAD 12.00',  'use the currency-specific default minimum fraction digits';
$curf->minimum_fraction_digits(3); is $curf->format(12), 'CAD 12.000', 'overrides the default minimum fraction digits';

$curf->currency_code('CHF');
$curf->rounding_increment(0.05);  # TODO: should this be 5?
is $curf->format(12.03), 'CHF 12.05', 'use the currency rounding for the currency code';
is $curf->format(12.02), 'CHF 12.00', 'use the currency rounding for the currency code';
