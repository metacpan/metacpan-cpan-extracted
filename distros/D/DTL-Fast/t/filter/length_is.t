#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'array1' => [ 'string', 1, undef, 1 ],
    'scalar1' => 'blabla',
});

my $SET = [
    {
        'template' => '{{ array1|length_is:4 }}',
        'test' => '1',
        'title' => 'Correct array length',
    },
    {
        'template' => '{{ scalar1|length_is:6 }}',
        'test' => '1',
        'title' => 'Correct string length',
    },
    {
        'template' => '{{ array1|length_is:5 }}',
        'test' => '0',
        'title' => 'Incorrect array length',
    },
    {
        'template' => '{{ scalar1|length_is:5 }}',
        'test' => '0',
        'title' => 'Incorrect string length',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
