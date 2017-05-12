#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => "this is not 'sparta'!",
    'var2' => 'this is not "sparta"!',
});

my $SET = [
    {
        'template' => <<'_EOT_',
Static {{ "this is not 'sparta'!"|safe|addslashes }}
_EOT_
        'test' => <<'_EOT_',
Static this is not \'sparta\'!
_EOT_
        'title' => 'Static single quote',
    },
    {
        'template' => <<'_EOT_',
Static {{ 'this is not "sparta"!'|safe|addslashes }}
_EOT_
        'test' => <<'_EOT_',
Static this is not \"sparta\"!
_EOT_
        'title' => 'Static double quote',
    },
    {
        'template' => <<'_EOT_',
Static {{ var1|safe|addslashes }}
_EOT_
        'test' => <<'_EOT_',
Static this is not \'sparta\'!
_EOT_
        'title' => 'Dynamic single quote',
    },
    {
        'template' => <<'_EOT_',
Static {{ var2|safe|addslashes }}
_EOT_
        'test' => <<'_EOT_',
Static this is not \"sparta\"!
_EOT_
        'title' => 'Dynamic double quote',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
