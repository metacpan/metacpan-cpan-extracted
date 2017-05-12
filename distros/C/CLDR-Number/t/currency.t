use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 25;
use Test::Exception;
use CLDR::Number;

my ($cldr, $curf, $decf);

$cldr = CLDR::Number->new;
$curf = $cldr->currency_formatter;
throws_ok { $curf->format(1.99) } qr{Missing required attribute: currency_code};

{
    # currency decimal is no longer used by any locale, so we manually add it here
    # to test the feature in case it’s reintroduced in the future
    local $CLDR::Number::Data::Base::DATA->{sv}{symbol}{currency_decimal} = ':';

    $cldr = CLDR::Number->new(locale => 'sv');
    is $cldr->decimal_sign, ',', 'Swedish decimal from format generator';

    $decf = $cldr->decimal_formatter;
    is $decf->decimal_sign, ',', 'Swedish decimal from decimal formatter';
    is $decf->format(1.99), '1,99', 'formatted Swedish decimal';

    $curf = $cldr->currency_formatter(currency_code => 'SEK');
    is $curf->decimal_sign, ':', 'Swedish currency decimal from currency formatter';
    is $curf->format(1.99), '1:99 kr', 'formatted Swedish currency';
}

$curf = $cldr->currency_formatter(
    locale        => 'en-AU',
    currency_code => 'AUD',
);

is $curf->format(10), '$10.00', 'en-AU with AUD uses currency sign $ instead of A$';

$curf = $cldr->currency_formatter(
    locale                  => 'en',
    currency_code           => 'USD',
    maximum_fraction_digits => 0,
);

is $curf->maximum_fraction_digits, 0, 'max frac digits spared by currency code';
is $curf->format(10), '$10',          'max frac digits spared by currency code';

$curf = $cldr->currency_formatter(
    locale        => 'en',
    currency_code => 'USD',
    pattern       => '¤00',
);

is $curf->pattern,   '¤00', 'pattern spared by locale on create';
is $curf->format(5), '$05', 'pattern spared by locale on create';

$curf = $cldr->currency_formatter(
    currency_code => 'USD',
    currency_sign => '!!!',
    pattern       => '¤ 0',
);

is $curf->currency_sign, '!!!',   'sign spared by currency code on create';
is $curf->format(1),     '!!! 1', 'sign spared by currency code on create';

$curf->currency_sign('X');
$curf->pattern('0¤'); is $curf->format(1), '1 X', 'space pre-currency (L)';
$curf->pattern('¤0'); is $curf->format(1), 'X 1', 'space post-currency (L)';
$curf->currency_sign('€');
$curf->pattern('0¤'); is $curf->format(1), '1€', 'no space pr-currency (Sc)';
$curf->pattern('¤0'); is $curf->format(1), '€1', 'no space post-currency (Sc)';
$curf->currency_sign('±');
$curf->pattern('0¤'); is $curf->format(1), '1±', 'no space pre-currency (Sm)';
$curf->pattern('¤0'); is $curf->format(1), '±1', 'no space post-currency (Sm)';
$curf->currency_sign('.');
$curf->pattern('0¤'); is $curf->format(1), '1 .', 'space pre-currency (P)';
$curf->pattern('¤0'); is $curf->format(1), '. 1', 'space post-currency (P)';
$curf->currency_sign('X$');
$curf->pattern('0¤'); is $curf->format(1), '1 X$', 'space pre-currency (L)';
$curf->pattern('¤0'); is $curf->format(1), 'X$1', 'no space post-currency (Sc)';
$curf->currency_sign('$X');
$curf->pattern('0¤'); is $curf->format(1), '1$X', 'no space pre-currency (Sc)';
$curf->pattern('¤0'); is $curf->format(1), '$X 1', 'space post-currency (L)';
