#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];

local $SIG{__WARN__} = sub {};

$context = DTL::Fast::Context->new({
    'array' => [1..5]
    , 'var2' => 'Second variable'
    , 'hash1' => {
        'var' => 'Hash variable'
    }
    , 'var3' => 'Third variable'
    , 'array2' => ['Array variable']
    , 'array3' => [1..7]
    , 'escape1' => 'this <'
    , 'escape2' => 'this >'
    , 'escape3' => 'this &'
    , 'escape4' => 'this \''
    , 'escape5' => 'this "'
});

$test_string = <<'_EOT_';
This is one-pass cycle val1 example
This is one-pass depricated cycle val4 example
_EOT_

is( get_template( 'cycle_simple.txt', 'dirs' => $dirs)->render($context), $test_string, 'Simple cycle. Current and depricated versions.');

$test_string = <<'_EOT_';
This is cycle val1 example, step 1
This is cycle Second variable example, step 2
This is cycle Hash variable example, step 3
This is cycle val1 example, step 4
This is cycle Second variable example, step 5

This is depricated cycle val4 example, step 1
This is depricated cycle Third variable example, step 2
This is depricated cycle Array variable example, step 3
This is depricated cycle val4 example, step 4
This is depricated cycle Third variable example, step 5
_EOT_

is( get_template( 'cycle_for.txt', 'dirs' => $dirs)->render($context), $test_string, 'Cycle inside for with repeats. Current and depricated versions.');

$test_string = <<'_EOT_';
This is cycle val1 example, step 1, pushed val1
This is cycle Second variable example, step 2, pushed Second variable
This is cycle Hash variable example, step 3, pushed Hash variable
This is cycle val1 example, step 4, pushed val1
This is cycle Second variable example, step 5, pushed Second variable

This is depricated cycle val4 example, step 1, pushed val4
This is depricated cycle Third variable example, step 2, pushed Third variable
This is depricated cycle Array variable example, step 3, pushed Array variable
This is depricated cycle val4 example, step 4, pushed val4
This is depricated cycle Third variable example, step 5, pushed Third variable
_EOT_

is( get_template( 'cycle_as.txt', 'dirs' => $dirs)->render($context), $test_string, 'Cycle inside for with repeats and populating context. Current and depricated versions.');

$test_string = <<'_EOT_';
This is cycle  example, step 1, pushed val1
This is cycle  example, step 2, pushed Second variable
This is cycle  example, step 3, pushed Hash variable
This is cycle  example, step 4, pushed val1
This is cycle  example, step 5, pushed Second variable

This is depricated cycle  example, step 1, pushed val4
This is depricated cycle  example, step 2, pushed Third variable
This is depricated cycle  example, step 3, pushed Array variable
This is depricated cycle  example, step 4, pushed val4
This is depricated cycle  example, step 5, pushed Third variable
_EOT_

is( get_template( 'cycle_as_silent.txt', 'dirs' => $dirs)->render($context), $test_string, 'Silent cycle inside for with repeats and populating context. Current and depricated versions.');

$test_string = <<'_EOT_';
Here this &lt; escaped
Here static &lt; value escaped
Here this &gt; escaped
Here this &amp; escaped
Here this &#39; escaped
Here this &quot; escaped
Here this &lt; escaped
_EOT_

is( get_template( 'cycle_escape.txt', 'dirs' => $dirs)->render($context), $test_string, 'Cycle escaping control.');

$test_string = <<'_EOT_';
Here this &lt; escaped
Here static &lt; value escaped
Here static < value escaped
Here this > escaped
Here this &amp; escaped
Here this ' escaped
Here this &quot; escaped
_EOT_

$template = get_template( 'cycle_escape_safe.txt', 'dirs' => $dirs);
is( $template->render($context), $test_string, 'Cycle escaping control with safe.');

$test_string = <<'_EOT_';
Here this < escaped
Here static < value escaped
Here static &lt; value escaped
Here this > escaped
Here this & escaped
Here this ' escaped
Here this " escaped
_EOT_

is( get_template( 'cycle_escape_autoescape.txt', 'dirs' => $dirs)->render($context), $test_string, 'Cycle escaping control with autoescape off.');


done_testing();
