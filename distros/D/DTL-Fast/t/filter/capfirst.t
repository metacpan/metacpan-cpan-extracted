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
    'var1' => "this is not 'sparta'!",
    'var2' => 'this is not "sparta"!',
});

my $SET = [
    {
        'template' => <<'_EOT_',
Static {{ "this is not 'sparta'!"|capfirst }}
_EOT_
        'test' => <<'_EOT_',
Static This is not &#39;sparta&#39;!
_EOT_
        'title' => 'Static uppercase',
    },
    {
        'template' => <<'_EOT_',
Dynamic {{ var1|capfirst }}
_EOT_
        'test' => <<'_EOT_',
Dynamic This is not &#39;sparta&#39;!
_EOT_
        'title' => 'Dynamic uppercase',
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
Dynamic {{ "привет"|capfirst }}
_EOT_
        'test' => <<'_EOT_',
Dynamic Привет
_EOT_
        'title' => 'Locale-specific uppercase',
    },
    ];

    foreach my $data (@$SET)
    {
        is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
        
    }
};


done_testing();
