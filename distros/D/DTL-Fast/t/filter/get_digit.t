#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 1234,
    'var2' => 001234,
    'var3' => 0,
});

my $SET = [
    {
        'template' => '{{ var1|get_digit:4 }}',
        'test' => '1',
        'title' => 'Existed digit, last',
    },
    {
        'template' => '{{ var1|get_digit:1 }}',
        'test' => '4',
        'title' => 'Existed digit, first',
    },
    {
        'template' => '{{ var2|get_digit:5 }}',
        'test' => '',
        'title' => 'Omited digit',
    },
    {
        'template' => '{{ var3|get_digit:1 }}',
        'test' => '0',
        'title' => 'Existed digit, zero',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
