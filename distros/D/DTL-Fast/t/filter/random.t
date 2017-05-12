#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'array1' => [1],
    'array2' => ['string'],
});

# @todo some random testing
my $SET = [
    {
        'template' => '{{ array1|random }}',
        'test' => '1',
        'title' => 'Random number',
    },
    {
        'template' => '{{ array2|random }}',
        'test' => 'string',
        'title' => 'Random string',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
