#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => "< & > ' \""
});

$template = <<'_EOT_';
Escaped: {{ var1 }}
Unescaped: {{ var1|safe }}
Escaped: {{ var1 }}
Unescaped: {{ var1|safe }}
_EOT_

$test_string = <<'_EOT_';
Escaped: &lt; &amp; &gt; &#39; &quot;
Unescaped: < & > ' "
Escaped: &lt; &amp; &gt; &#39; &quot;
Unescaped: < & > ' "
_EOT_

is( DTL::Fast::Template->new( $template )->render($context), $test_string, 'Escaped and unescaped variable rendering');

done_testing();
