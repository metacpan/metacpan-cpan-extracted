use utf8;
use strict;
use warnings;
use open qw( :encoding(UTF-8) :std );
use Test::More tests => 59;
use CLDR::Number::Format::Currency;

# Tests using locales and currencies supported by Shutterstock

while (my $line = <DATA>) {
    chomp $line;
    my ($currency, $locale, $expected) = split /\t/, $line;
    my $curf = CLDR::Number::Format::Currency->new(
        locale        => $locale,
        currency_code => $currency,
    );
    is $curf->format(1000), $expected, "1000 $currency in $locale";
}

__DATA__
AUD	en-AU	$1,000.00
BRL	en-BR	R$1,000.00
BRL	pt-BR	R$1.000,00
CAD	en-CA	$1,000.00
CAD	fr-CA	1 000,00 $
CHF	de-CH	CHF 1'000.00
CHF	en-CH	CHF 1.000,00
CHF	fr-CH	CHF 1 000.00
CHF	it-CH	CHF 1'000.00
DKK	da-DK	1.000,00 kr.
DKK	en-DK	1.000,00 kr.
EUR	cs-CZ	1 000,00 €
EUR	de-AT	€ 1 000,00
EUR	de-BE	1.000,00 €
EUR	de-DE	1.000,00 €
EUR	en-AT	€ 1.000,00
EUR	en-BE	1.000,00 €
EUR	en-DE	1.000,00 €
EUR	en-ES	€1,000.00
EUR	en-FR	€1,000.00
EUR	en-IT	€1,000.00
EUR	en-NL	€ 1.000,00
EUR	en-PL	€1,000.00
EUR	es-ES	1000,00 €
EUR	fi-FI	1 000,00 €
EUR	fr-BE	1.000,00 €
EUR	fr-FR	1 000,00 €
EUR	hu-HU	1 000,00 EUR
EUR	it-IT	1.000,00 €
EUR	nl-BE	1.000,00 €
EUR	nl-NL	€ 1.000,00
EUR	pl-PL	1000,00 €
EUR	sv-FI	1 000,00 €
GBP	en-GB	£1,000.00
JPY	en-JP	¥1,000.00
JPY	ja-JP	￥1,000.00
KRW	en-KR	₩1,000.00
KRW	ko-KR	₩1,000.00
NOK	en-NO	NOK 1,000.00
NOK	nb-NO	kr 1 000,00
SEK	en-SE	1 000,00 kr
SEK	sv-SE	1 000,00 kr
USD	en-BR	$1,000.00
USD	en-CA	US$1,000.00
USD	en-IN	US$ 1,000.00
USD	en-KR	$1,000.00
USD	en-MX	$1,000.00
USD	en-RU	$1,000.00
USD	en-TR	$1,000.00
USD	en-US	$1,000.00
USD	en-ZA	US$1 000,00
USD	es-MX	USD 1,000.00
USD	fr-CA	1 000,00 $ US
USD	ko-KR	US$1,000.00
USD	pt-BR	US$1.000,00
USD	ru-RU	1 000,00 $
USD	th-TH	US$1,000.00
USD	tr-TR	1.000,00 $
USD	zh-CN	US$1,000.00
