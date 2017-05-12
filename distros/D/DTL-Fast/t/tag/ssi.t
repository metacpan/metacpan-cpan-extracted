#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];
my $ssi_dirs = ['./t/ssi'];
$context = new DTL::Fast::Context({
    'array' => ['one', 'two', 'three']
});

$test_string = 'here this is static {{ template }} as {% for something %} with keys is';
is( get_template('ssi_static.txt', 'dirs' => $dirs, 'ssi_dirs' => $ssi_dirs)->render($context), $test_string, 'SSI static file');

$test_string = 'here this is parsed one two three  template is';
is( get_template('ssi_parsed.txt', 'dirs' => $dirs, 'ssi_dirs' => $ssi_dirs)->render($context), $test_string, 'SSI parsed file');


done_testing();
