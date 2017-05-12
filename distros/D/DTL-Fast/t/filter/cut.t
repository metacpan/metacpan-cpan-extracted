#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => "test1 string at",
    'var2' => 'est',
});

my $SET = [
    {
        'template' => <<'_EOT_',
Static {{ "test string at all"|cut:"string" }}
_EOT_
        'test' => <<'_EOT_',
Static test  at all
_EOT_
        'title' => 'Static removing',
    },
    {
        'template' => <<'_EOT_',
Dynamic {{ var1|cut:"test" }}
_EOT_
        'test' => <<'_EOT_',
Dynamic 1 string at
_EOT_
        'title' => 'Dynamic removing',
    },
    {
        'template' => <<'_EOT_',
Static {{ "test string"|cut:var2 }}
_EOT_
        'test' => <<'_EOT_',
Static t string
_EOT_
        'title' => 'Static removing with dynamic pattern',
    },
    {
        'template' => <<'_EOT_',
Dynamic {{ var1|cut:var2 }}
_EOT_
        'test' => <<'_EOT_',
Dynamic t1 string at
_EOT_
        'title' => 'Dynamic removing with dynamic pattern',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
