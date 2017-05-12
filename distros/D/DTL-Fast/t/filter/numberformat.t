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
        'template' => '{{ 1|numberformat }}',
        'test' => '1',
        'title' => 'One digit int number',
    },
    {
        'template' => '{{ 12|numberformat }}',
        'test' => '12',
        'title' => 'Two digits int number',
    },
    {
        'template' => '{{ 123|numberformat }}',
        'test' => '123',
        'title' => 'Three digits int number',
    },
    {
        'template' => '{{ 1234|numberformat }}',
        'test' => '1 234',
        'title' => '4 digits int number',
    },
    {
        'template' => '{{ 12345|numberformat }}',
        'test' => '12 345',
        'title' => '5 digits int number',
    },
    {
        'template' => '{{ 123456|numberformat }}',
        'test' => '123 456',
        'title' => '6 digits int number',
    },
    {
        'template' => '{{ 1234567|numberformat }}',
        'test' => '1 234 567',
        'title' => '7 digits int number',
    },
    {
        'template' => '{{ 12345678|numberformat }}',
        'test' => '12 345 678',
        'title' => '8 digits int number',
    },
# float number
    {
        'template' => '{{ 1.0456|numberformat }}',
        'test' => '1.0456',
        'title' => 'One digit float number',
    },
    {
        'template' => '{{ 12.0456|numberformat }}',
        'test' => '12.0456',
        'title' => 'Two digits float number',
    },
    {
        'template' => '{{ 123.0456|numberformat }}',
        'test' => '123.0456',
        'title' => 'Three digits float number',
    },
    {
        'template' => '{{ 1234.0456|numberformat }}',
        'test' => '1 234.0456',
        'title' => '4 digits float number',
    },
    {
        'template' => '{{ 12345.0456|numberformat }}',
        'test' => '12 345.0456',
        'title' => '5 digits float number',
    },
    {
        'template' => '{{ 123456.0456|numberformat }}',
        'test' => '123 456.0456',
        'title' => '6 digits float number',
    },
    {
        'template' => '{{ 1234567.0456|numberformat }}',
        'test' => '1 234 567.0456',
        'title' => '7 digits float number',
    },
    {
        'template' => '{{ 12345678.0456|numberformat }}',
        'test' => '12 345 678.0456',
        'title' => '8 digits float number',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
