#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];
$context = new DTL::Fast::Context({
    'include' => ['included2.txt']
    , 'with' => {
        'substitution' => 'context text'
    }
    , 'var1' => 'testvar'
});

$test_string = 'this is a simple include context text';
is( get_template('included.txt', 'dirs' => $dirs)->render($context), $test_string, 'Simple include block');

$test_string = 'And this is a simple include context text was nested';
is( get_template('included2.txt', 'dirs' => $dirs)->render($context), $test_string, 'Two levels include');

$test_string = <<'_EOT_';
this is a And this is a simple include context text was nested include
_EOT_
chomp $test_string;
is( get_template('included_dynamic.txt', 'dirs' => $dirs)->render($context), $test_string, 'Include from context value');


$test_string = 'this is a this is a test2 and testvar include context text';
is( get_template('include_with.txt', 'dirs' => $dirs)->render($context), $test_string, 'Include ... with');

done_testing();
