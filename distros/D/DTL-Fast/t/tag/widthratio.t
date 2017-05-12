#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

local $SIG{__WARN__} = sub {};

my $dirs = ['./t/tmpl', './t/tmpl2'];
my $ssi_dirs = ['./t/ssi'];
$context = new DTL::Fast::Context({
    'array' => ['one', 'two', 'three'],
    'var1' => 88,
    'var2' => 100,
    'var3' => 350
});

my $SET = [
    {
        'template' => 'rendering {% widthratio var1 var2 var3 %} example',
        'test' => 'rendering 308 example',
        'title' => 'Widthration example',
    },
    {
        'template' => 'rendering {% widthratio 44 var2 var3 %} example',
        'test' => 'rendering 154 example',
        'title' => 'Widthration example with static value',
    },
    {
        'template' => 'rendering {% widthratio var1 var2 var3 as var4 %} example {{ var4 }}',
        'test' => 'rendering  example 308',
        'title' => 'Widthration example with as key',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
