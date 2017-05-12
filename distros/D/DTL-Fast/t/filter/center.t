#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => "test1",
    'var2' => 'test2',
    'width1' => 15,
    'width2' => 16,
});

my $SET = [
    {
        'template' => <<'_EOT_',
Static {{ "test"|center:10 }}
_EOT_
        'test' => <<'_EOT_',
Static    test
_EOT_
        'title' => 'Static centering',
    },
    {
        'template' => <<'_EOT_',
Dynamic {{ var1|center:10 }}
_EOT_
        'test' => <<'_EOT_',
Dynamic   test1
_EOT_
        'title' => 'Dynamic centering',
    },
    {
        'template' => <<'_EOT_',
Static {{ "test"|center:width1 }}
_EOT_
        'test' => <<'_EOT_',
Static      test
_EOT_
        'title' => 'Static centering with dynamic width',
    },
    {
        'template' => <<'_EOT_',
Dynamic {{ var2|center:width2 }}
_EOT_
        'test' => <<'_EOT_',
Dynamic      test2
_EOT_
        'title' => 'Dynamic centering with dynamic width',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
