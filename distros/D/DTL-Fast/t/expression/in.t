#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast::Expression;
use DTL::Fast::Context;
use Data::Dumper;

my $exp;

# @todo Tests for hash values
# @todo Tests for array values
# @todo Tests for objecs with methods: div, mul, plus, minus, not, compare

my $SET_TEST = [
    {
        'val1' => 'testvalue'
        , 'val2' => ['testvalue', 1, 42]
        , 'title' => 'Array contains scalar'
        , 'control' => 1
    },
    {
        'val1' => 'testvalue'
        , 'val2' => ['testvalue1', 1, 42]
        , 'title' => 'Array not contains scalar'
        , 'control' => 0
    },
    {
        'val1' => 'testvalue'
        , 'val2' => {'testvalue' => 1, 42 => 18}
        , 'title' => 'Hash contains scalar key'
        , 'control' => 1
    },
    {
        'val1' => 'testvalue'
        , 'val2' => {'testvalue1' => 1, 42 => 20}
        , 'title' => 'Hash does not contains scalar key'
        , 'control' => 0
    },
    {
        'val1' => 'testvalue'
        , 'val2' => 'this contains testvalue'
        , 'title' => 'Substring contains string'
        , 'control' => 1
    },
    {
        'val1' => 'testvalue'
        , 'val2' => 'this contains not testvalu'
        , 'title' => 'Substring does not contains string'
        , 'control' => 0
    },
];

my $samples = 
[   
    {
        'template' => 'val1 in val2',
        'control' => sub { my $context = shift; return $context->{'control'}},
    },
    {
        'template' => 'val1 not in val2',
        'control' => sub { my $context = shift; return !$context->{'control'}},
    },
];
    
foreach my $sample (@$samples)
{
    $exp = new DTL::Fast::Expression($sample->{'template'});

    subtest $sample->{'template'} => sub
    {
        foreach my $context (@$SET_TEST)
        {
            is( 
                $exp->render(new DTL::Fast::Context($context))
                , $sample->{'control'}->($context)
                , $context->{'title'}
            );
        }
    }
}

#use Data::Dumper;print Dumper($exp);

done_testing();
