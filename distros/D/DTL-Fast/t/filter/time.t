#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => time,
    'var2' => '%B-%y-%Y-%Z-%z',
});

my $var = DTL::Fast::Utils::time2str($context->get('var2'), 1420569840);
my $var1 = DTL::Fast::Utils::time2str($context->get('var2'), $context->get('var1'));

my $SET = [
    {
        'template' => <<'_EOT_',
Static {{ 1420569840|time:"%B-%y-%Y-%Z-%z" }}
_EOT_
        'test' => "Static $var\n",
        'title' => 'Static formatting',
    },
    {
        'template' => <<'_EOT_',
Dynamic {{ var1|time:var2 }}
_EOT_
        'test' => "Dynamic $var1\n",
        'title' => 'Dynamic formatting',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
