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
        'template' => '{{ array1|length }}',
        'test' => '4',
        'title' => 'Array length',
    },
    {
        'template' => '{{ scalar1|length }}',
        'test' => '6',
        'title' => 'String value',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
