#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'username' => ['Ivan', 'Sergey', 'Alexandr']
    , 'sep' => ','
    , 'array' => [':']
    , 'hash' => {
        'sep' => '/'
    }
});

is( DTL::Fast::Template->new( 'Hello, {{ username|join:" // " }}!' )->render($context), 'Hello, Ivan // Sergey // Alexandr!', 'Join with static separator');
is( DTL::Fast::Template->new( 'Hello, {{ username|join:sep }}!' )->render($context), 'Hello, Ivan,Sergey,Alexandr!', 'Join with scalar separator from context');
is( DTL::Fast::Template->new( 'Hello, {{ username|join:array.0 }}!' )->render($context), 'Hello, Ivan:Sergey:Alexandr!', 'Join with separator from context array element');
is( DTL::Fast::Template->new( 'Hello, {{ username|join:hash.sep }}!' )->render($context), 'Hello, Ivan/Sergey/Alexandr!', 'Join with separator from context hash element');

is( DTL::Fast::Template->new( 'Hash join {{ hash|join:array.0 }}')->render($context), 'Hash join sep:/', 'Hash joining with separator from context');

eval{
    DTL::Fast::Template->new( 'Scalar joining {{ sep|join:"//" }}')->render($context);
};
if( $@ ){
    ok( 1, sprintf('Scalar joining error control: %s', $@));
}
else
{
    ok( 0, 'Scalar joining error control');
}

$context->set('tpl' => DTL::Fast::Template->new( 'Hash join {{ hash|join:array.0 }}'));
eval{
    DTL::Fast::Template->new( 'Scalar joining {{ tpl|join:"//" }}')->render($context);
};
if( $@ ){
    ok( 1, sprintf( 'Object joining error control: %s', $@));
}
else
{
    ok( 0, 'Object joining error control');
}


done_testing();
