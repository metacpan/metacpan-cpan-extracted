#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var' => 3.1415926
    , 'var1' => '.02f'
});

my $SET = [
    {
        'template' => '{{ var|stringformat:"s" }}',
        'test' => '3.1415926',
        'title' => 'Pi as string',
    },
    {
        'template' => '{{ var|stringformat:var1 }}',
        'test' => '3.14',
        'title' => 'Pi as float with format from variable',
    },
    {
        'template' => '{{ 1|stringformat:var1 }}',
        'test' => '1.00',
        'title' => '1 as float with format from variable',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
