use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 6;
use CLDR::Number;

my ($cldr, $decf, $perf, $curf);

$cldr = CLDR::Number->new(locale => 'en');
$decf = $cldr->decimal_formatter;
$perf = $cldr->percent_formatter;
$curf = $cldr->currency_formatter(currency_code => 'EUR');

is $decf->range(1, 5),       '1–5',         'range of numbers (en)';
is $perf->range(0.01, 0.05), '1%–5%',       'range of percents (en)';
is $curf->range(1, 5),       '€1.00–€5.00', 'range of prices (en)';

$cldr = CLDR::Number->new(locale => 'es-CO');
$decf = $cldr->decimal_formatter;
$perf = $cldr->percent_formatter;
$curf = $cldr->currency_formatter(currency_code => 'COP');

is $decf->range(1, 5),       'de 1 a 5',           'range of numbers (es-CO)';
is $perf->range(0.01, 0.05), 'de 1% a 5%',         'range of percents (es-CO)';
is $curf->range(1, 5),       'de $ 1,00 a $ 5,00', 'range of prices (es-CO)';
