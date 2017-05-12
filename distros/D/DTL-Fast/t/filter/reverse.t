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

$template = 'Normal: {{ username|join:"," }}';
$test_string = 'Normal: Ivan,Sergey,Alexandr';

is( DTL::Fast::Template->new( $template )->render($context), $test_string, 'Direct join');

$template = 'Reversed: {{ username|reverse|join:"," }}';
$test_string = 'Reversed: Alexandr,Sergey,Ivan';

is( DTL::Fast::Template->new( $template )->render($context), $test_string, 'Reversed join');

$template = 'Reversed: {{ "test string"|reverse }}';
$test_string = 'Reversed: gnirts tset';

is( DTL::Fast::Template->new( $template )->render($context), $test_string, 'Reversed scalar');

done_testing();
