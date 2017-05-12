#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
no warnings;
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

use locale;
use POSIX qw(locale_h);
my $locale = "Russian_Russia.1251";
setlocale(LC_COLLATE, $locale);
setlocale(LC_CTYPE, $locale);

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => "tEsT1",
    'var2' => 'Test2',
    'var3' => 'Привет',
});

my $SET = [
    {
        'template' => <<'_EOT_',
Static {{ "tESt"|lower }}
_EOT_
        'test' => <<'_EOT_',
Static test
_EOT_
        'title' => 'Static lowercasing',
    },
    {
        'template' => <<'_EOT_',
Dynamic {{ var1|lower }}
_EOT_
        'test' => <<'_EOT_',
Dynamic test1
_EOT_
        'title' => 'Dynamic lowercasing',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

SKIP: { 
    skip "Skips locale-specific test because there is no ru_RU.CP1251 locale installed", 1
        if setlocale(LC_COLLATE) ne $locale or setlocale(LC_CTYPE) ne $locale;
        
    $SET = [
    {
        'template' => <<'_EOT_',
Dynamic {{ "Привет"|lower }}
_EOT_
        'test' => <<'_EOT_',
Dynamic привет
_EOT_
        'title' => 'Locale-specific lowercasing',
    },
    ];

    foreach my $data (@$SET)
    {
        is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
        
    }
};

done_testing();
