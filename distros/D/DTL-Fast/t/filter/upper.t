#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
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
});

my $SET = [
    {
        'template' => <<'_EOT_',
Static {{ "tESt"|upper }}
_EOT_
        'test' => <<'_EOT_',
Static TEST
_EOT_
        'title' => 'Static uppercasing',
    },
    {
        'template' => <<'_EOT_',
Dynamic {{ var1|upper }}
_EOT_
        'test' => <<'_EOT_',
Dynamic TEST1
_EOT_
        'title' => 'Dynamic uppercasing',
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
Dynamic {{ "Ïðèâåò"|upper }}
_EOT_
        'test' => <<'_EOT_',
Dynamic ÏÐÈÂÅÒ
_EOT_
        'title' => 'Locale specific uppercasing',
    },
    ];

    foreach my $data (@$SET)
    {
        is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
        
    }
};

done_testing();
