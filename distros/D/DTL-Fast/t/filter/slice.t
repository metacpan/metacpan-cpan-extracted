#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'array1' => ['a', 'b', 'mpilgrim', 'z', 'example']
    , 'hash1' => {
        'key1' => 'val1'
        , 'key2' => 'val2'
        , 'key3' => 'val3'
        , 'key4' => 'val4'
        , 'key5' => 'val5'
    }
    , 'scalar' => 'This is a text'
});

my $SET = [
    {
        'template' => '{{ array1|slice:"1:3"|join:"," }}',
        'test' => 'b,mpilgrim',
        'title' => 'Array slicing both, python format',
    },
    {
        'template' => '{{ array1|slice:"1:100"|join:"," }}',
        'test' => 'b,mpilgrim,z,example',
        'title' => 'Array slicing both, python format, index is outside the boundaries',
    },
    {
        'template' => '{{ array1|slice:"1:-1"|join:"," }}',
        'test' => 'b,mpilgrim,z',
        'title' => 'Array slicing, negative last, python format',
    },
    {
        'template' => '{{ array1|slice:":3"|join:"," }}',
        'test' => 'a,b,mpilgrim',
        'title' => 'Array slicing, only last, python format',
    },
    {
        'template' => '{{ array1|slice:"3:"|join:"," }}',
        'test' => 'z,example',
        'title' => 'Array slicing, only first, python format',
    },
    {
        'template' => '{{ array1|slice:":"|join:"," }}',
        'test' => 'a,b,mpilgrim,z,example',
        'title' => 'Array slicing, no arguments, python format',
    },
    {
        'template' => '{{ array1|slice:"1..2"|join:"," }}',
        'test' => 'b,mpilgrim',
        'title' => 'Array slicing both, perl format',
    },
    {
        'template' => '{{ array1|slice:"..2"|join:"," }}',
        'test' => 'a,b,mpilgrim',
        'title' => 'Array slicing, only last, perl format',
    },
    {
        'template' => '{{ array1|slice:"3.."|join:"," }}',
        'test' => 'z,example',
        'title' => 'Array slicing, only first, perl format',
    },
    {
        'template' => '{{ array1|slice:".."|join:"," }}',
        'test' => 'a,b,mpilgrim,z,example',
        'title' => 'Array slicing, no arguments, perl format',
    },
    {
        'template' => '{{ array1|slice:":"|join:"," }}',
        'test' => 'a,b,mpilgrim,z,example',
        'title' => 'Array slicing, no arguments, python format',
    },
    {
        'template' => '{{ hash1|slice:"key1,key3,key5"|join:"," }}',
        'test' => 'val1,val3,val5',
        'title' => 'Hash slicing',
    },
    # This is a text
    {
        'template' => '{{ scalar|slice:"1..5" }}',
        'test' => 'his i',
        'title' => 'Scalar slicing: perl format, start and end',
    },
    {
        'template' => '{{ scalar|slice:"1:6" }}',
        'test' => 'his i',
        'title' => 'Scalar slicing: python format, start and end',
    },
    {
        'template' => '{{ scalar|slice:"1.." }}',
        'test' => 'his is a text',
        'title' => 'Scalar slicing: perl format, start only',
    },
    {
        'template' => '{{ scalar|slice:"1:" }}',
        'test' => 'his is a text',
        'title' => 'Scalar slicing: python format, start only',
    },
    {
        'template' => '{{ scalar|slice:"..5" }}',
        'test' => 'This i',
        'title' => 'Scalar slicing: perl format, end only',
    },
    {
        'template' => '{{ scalar|slice:":6" }}',
        'test' => 'This i',
        'title' => 'Scalar slicing: python format, end only',
    },
    {
        'template' => '{{ scalar|slice:".." }}',
        'test' => 'This is a text',
        'title' => 'Scalar slicing: perl format, no limits',
    },
    {
        'template' => '{{ scalar|slice:":" }}',
        'test' => 'This is a text',
        'title' => 'Scalar slicing: python format, no limits',
    },
    {
        'template' => '{{ scalar|slice:"3..100" }}',
        'test' => 's is a text',
        'title' => 'Scalar slicing: perl format, out of boundaries',
    },
    {
        'template' => '{{ scalar|slice:"3:200" }}',
        'test' => 's is a text',
        'title' => 'Scalar slicing: python format, out of boundaries',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
