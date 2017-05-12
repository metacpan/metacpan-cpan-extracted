#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'array1' => [ 'string', 1, undef ],
    'array2' => [ 1, undef ],
});

my $SET = [
    {
        'template' => '{{ array1|first }}',
        'test' => 'string',
        'title' => 'String value',
    },
    {
        'template' => '{{ array2|first }}',
        'test' => '1',
        'title' => 'Numeric value',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
