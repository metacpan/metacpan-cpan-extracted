#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 1,
    , 'var2' => 'string'
    , 'var3' => 0
    , 'var4' => ''
    , 'var5' => undef
    
});

my $SET = [
    {
        'template' => '{{ var1|yesno }}',
        'test' => 'yes',
        'title' => 'Default yes, number',
    },
    {
        'template' => '{{ var2|yesno }}',
        'test' => 'yes',
        'title' => 'Default yes, string',
    },
    {
        'template' => '{{ var3|yesno }}',
        'test' => 'no',
        'title' => 'Default no, number',
    },
    {
        'template' => '{{ var4|yesno }}',
        'test' => 'no',
        'title' => 'Default no, string',
    },
    {
        'template' => '{{ var5|yesno }}',
        'test' => 'maybe',
        'title' => 'Default maybe',
    },
    {
        'template' => '{{ var1|yesno:"да,нет,м.б." }}',
        'test' => 'да',
        'title' => 'Custom yes, number',
    },
    {
        'template' => '{{ var2|yesno:"да,нет,м.б." }}',
        'test' => 'да',
        'title' => 'Custom yes, string',
    },
    {
        'template' => '{{ var3|yesno:"да,нет,м.б." }}',
        'test' => 'нет',
        'title' => 'Custom no, number',
    },
    {
        'template' => '{{ var4|yesno:"да,нет,м.б." }}',
        'test' => 'нет',
        'title' => 'Custom no, string',
    },
    {
        'template' => '{{ var5|yesno:"да,нет,м.б." }}',
        'test' => 'м.б.',
        'title' => 'Custom maybe',
    },
];

foreach my $data (@$SET)
{
    my $test = $data->{'test'};
    chomp $test;
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $test, $data->{'title'});
}

done_testing();
