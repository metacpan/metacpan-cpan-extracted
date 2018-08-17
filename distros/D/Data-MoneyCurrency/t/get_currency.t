#!perl -T

use strict;
use warnings;
use utf8;
use Test::More;
use Test::Exception;
use Data::MoneyCurrency qw(get_currency);
use Data::Dumper;

binmode STDOUT, ":encoding(UTF-8)";
binmode STDERR, ":encoding(UTF-8)";
binmode Test::More->builder->output, ":encoding(UTF-8)";
binmode Test::More->builder->failure_output, ":encoding(UTF-8)"; 
binmode Test::More->builder->todo_output, ":encoding(UTF-8)";

local $Data::Dumper::Sortkeys = 1;

{
    my $got = get_currency(currency => 'usd');
    my $expected = {
        'alternate_symbols' => ['US$'],
        'decimal_mark' => '.',
        'disambiguate_symbol' => 'US$',
        'html_entity' => '$',
        'iso_code' => 'USD',
        'iso_numeric' => '840',
        'name' => 'United States Dollar',
        'priority' => 1,
        'smallest_denomination' => 1,
        'subunit' => 'Cent',
        'subunit_to_unit' => 100,
        'symbol' => '$',
        'symbol_first' => 1,
        'thousands_separator' => ',',
    };
    is_deeply($got, $expected, "get_currency usd")
        or diag(Data::Dumper->Dump([$got, $expected], ['got', 'expected']));

    $got = get_currency(country => 'us');
    is_deeply($got, $expected, "get_currency us")
        or diag(Data::Dumper->Dump([$got, $expected], ['got', 'expected']));
}

{
    my $got = get_currency(currency => 'azn');
    my $expected = {
        'alternate_symbols' => ['m', 'man'],
        'decimal_mark' => '.',
        'html_entity' => '',
        'iso_code' => 'AZN',
        'iso_numeric' => '944',
        'name' => 'Azerbaijani Manat',
        'priority' => 100,
        'smallest_denomination' => 1,

	# escape this one, just to make it clear this is a character string
        'subunit' => "Q\x{0259}pik",

        'subunit_to_unit' => 100,
        'symbol' => '₼',
        'symbol_first' => 1,
        'thousands_separator' => ',',
    };
    is_deeply($got, $expected, "get_currency 'azn' which has non-ascii characters")
        or diag(Data::Dumper->Dump([$got, $expected], ['got', 'expected']));
    
    $got = get_currency(country => 'az');
    is_deeply($got, $expected, "get_currency 'az' which has non-ascii characters")
        or diag(Data::Dumper->Dump([$got, $expected], ['got', 'expected']));
}

{
    my $got = get_currency(currency => "blablabla");
    is($got, undef, "get_currency(currency => 'blablabla') returns undef");
}

{
    my $got = get_currency(country => "blablabla");
    is($got, undef, "get_currency(country => 'blablabla') returns undef");
}

throws_ok {
    get_currency();
} qr/no arguments/, "get_currency() throws exception";

throws_ok {
    get_currency(country => 'us', currency => 'eur');
} qr/both/, "get_currency with both country and currency throws exception";

throws_ok {
    get_currency(currency => 'eur', foo => 'bar');
} qr/only accepts/, "get_currency doesn't accept foo";
done_testing();
