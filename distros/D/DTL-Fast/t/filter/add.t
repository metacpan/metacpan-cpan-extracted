#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'sep' => ',',
    , 'array1' => ['one', 'two', 'three']
    , 'array2' => ['four', 'five', 'six']
    , 'hash1' => { 'seven' => 'eight', 'nine' => 'ten'}
    , 'hash2' => { 'elleven' => 'twelve', 'thirteen' => 'fourteen'}
    , 'text1' => 'alfa'
    , 'text2' => 'beta'
    , 'number1' => 42
    , 'number2' => 69
});

is( DTL::Fast::Template->new( 'Hello, {{ array1|join:sep }}!' )->render($context), 'Hello, one,two,three!', 'Join with context separator');
is( DTL::Fast::Template->new( 'Hello, {{ array1|add:array2|join:sep }}!' )->render($context), 'Hello, one,two,three,four,five,six!', 'Array + array and join with context separator');
is( DTL::Fast::Template->new( 'Hello, {{ array1|add:text1|join:sep }}!' )->render($context), 'Hello, one,two,three,alfa!', 'Array + text and join with context separator');
is( DTL::Fast::Template->new( 'Hello, {{ array1|add:text1|add:number1|join:sep }}!' )->render($context), 'Hello, one,two,three,alfa,42!', 'Array + text + number and join with context separator');
is( DTL::Fast::Template->new( 'Hello, {{ text1|add:text2 }}!' )->render($context), 'Hello, alfabeta!', 'Text + text');
is( DTL::Fast::Template->new( 'Hello, {{ text1|add:text2 }}!' )->render($context), 'Hello, alfabeta!', 'Text + text, again');
is( DTL::Fast::Template->new( 'Hello, {{ text1|add:text2|add:number1 }}!' )->render($context), 'Hello, alfabeta42!', 'Text + text + number');
is( DTL::Fast::Template->new( 'Hello, {{ number1|add:number2 }}!' )->render($context), 'Hello, 111!', 'Number + number');

# unmodified hash keeps it's order
my $hash1 = $context->get('hash1');
my $hash1_joined = join( ',', %$hash1 );
my $hash2 = $context->get('hash2');
my $hash2_joined = join( ',', %$hash2 );

is( DTL::Fast::Template->new( 'Hello, {{ array1|add:hash1|join:sep }}!' )->render($context), "Hello, one,two,three,$hash1_joined!", 'Array + Hash joined with context sep');

# @todo checking hash merging. It works, but keys order is randomized

eval{
    DTL::Fast::Template->new( 'Hello, {{ hash1|add:array1|join:sep }}!' )->render($context);
};
if( $@ ){
    ok( 1, sprintf('Odd number hash joining error control: %s', $@));
}
else
{
    ok( 0, 'Odd number hash joining error control');
}

$context->set('tpl' => DTL::Fast::Template->new( 'Hash join {{ hash|join:array.0 }}'));
eval{
    DTL::Fast::Template->new( 'Hello, {{ hash1|add:text1|join:sep }}!' )->render($context);
};
if( $@ ){
    ok( 1, sprintf( 'Scalar to hash joining control: %s', $@));
}
else
{
    ok( 0, 'Scalar to hash joining control');
}


done_testing();
