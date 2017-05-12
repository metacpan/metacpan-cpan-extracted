#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;
use DTL::Fast::Utils qw( time2str_php );

BEGIN {
    no warnings;
    *CORE::GLOBAL::time = sub()
    {
        1420739322
    };
}

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];

$context = DTL::Fast::Context->new({
    'format1' => 'B-y-Y-Z-z'
});


$test_string = DTL::Fast::Utils::time2str_php($context->get('format1'), time);

$template = '{% now format1 %}';
is( DTL::Fast::Template->new($template)->render($context), $test_string, 'Now formatting from variable.');

$template = '{% now format1 as res_format %} a {{res_format}}';
$test_string = ' a '.$test_string;
is( DTL::Fast::Template->new($template)->render($context), $test_string, 'Now formatting from variable with as');

$test_string = DTL::Fast::Utils::time2str_php('Z-z-\B-y-Y', time);

$template = '{% now "Z-z-\B-y-Y" %}';
is( DTL::Fast::Template->new($template)->render($context), $test_string, 'Static now formatting.');

$template = '{% now "Z-z-\B-y-Y" as test_result%} a {{test_result}}';
$test_string = ' a '.$test_string;
is( DTL::Fast::Template->new($template)->render($context), $test_string, 'Static now formatting with as.');


done_testing();
