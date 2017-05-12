#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];

$context = DTL::Fast::Context->new({});

$context->set(
    'val1' => [
        'here is < value',
        'here is > value',
        'here is \' value',
        'here is " value',
        'here is & value',
    ]
);


$template = DTL::Fast::Template->new( << '_EOT_' );
checking {{ val1.0 }}
checking {{ val1.1 }}
checking {{ val1.2 }}
checking {{ val1.3 }}
checking {{ val1.4 }}
_EOT_

$test_string = <<'_EOT_';
checking here is &lt; value
checking here is &gt; value
checking here is &#39; value
checking here is &quot; value
checking here is &amp; value
_EOT_

is( $template->render($context), $test_string, 'Variable values auto-protection');

$template = DTL::Fast::Template->new( << '_EOT_' );
{% autoescape off %}checking {{ val1.0 }}
checking {{ val1.1 }}
checking {{ val1.2 }}
checking {{ val1.3 }}
checking {{ val1.4 }}{% endautoescape %}
_EOT_

$test_string = <<'_EOT_';
checking here is < value
checking here is > value
checking here is ' value
checking here is " value
checking here is & value
_EOT_

is( $template->render($context), $test_string, 'Variable values with disabled auto-protection');

$template = DTL::Fast::Template->new( << '_EOT_' );
{% autoescape off %}checking {{ val1.0 }}
checking {{ val1.1 }}
checking {{ val1.2 }}{% autoescape on %}
checking {{ val1.3 }}
checking {{ val1.4 }}{% endautoescape %}{% endautoescape %}
_EOT_

$test_string = <<'_EOT_';
checking here is < value
checking here is > value
checking here is ' value
checking here is &quot; value
checking here is &amp; value
_EOT_

is( $template->render($context), $test_string, 'Variable values with disabled auto-protection and nested enable block');


$template = DTL::Fast::Template->new( << '_EOT_' );
{% for a in val1 %}checking {{ a }}
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
checking here is &lt; value
checking here is &gt; value
checking here is &#39; value
checking here is &quot; value
checking here is &amp; value

_EOT_

is( $template->render($context), $test_string, 'Variable values auto-protection in a tag');

$template = DTL::Fast::Template->new( << '_EOT_' );
{% for a in val1 %}checking {{ a|safe }}
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
checking here is < value
checking here is > value
checking here is ' value
checking here is " value
checking here is & value

_EOT_

is( $template->render($context), $test_string, 'safe variables filter');

$test_string = <<'_EOT_';
Autoescape testing
Escaped:
checking here is &lt; value
checking here is &gt; value
checking here is &#39; value
checking here is &quot; value
checking here is &amp; value

Not escaped:
checking here is < value
checking here is > value
checking here is ' value
checking here is " value
checking here is & value
Not escaped:
checking here is < value
checking here is > value
checking here is ' value
checking here is " value
checking here is & value

Escaped:
checking here is &lt; value
checking here is &gt; value
checking here is &#39; value
checking here is &quot; value
checking here is &amp; value

Not escaped:
checking here is < value
checking here is > value
checking here is ' value
checking here is " value
checking here is & value

Escaped:
checking here is &lt; value
checking here is &gt; value
checking here is &#39; value
checking here is &quot; value
checking here is &amp; value
_EOT_

is( get_template( 'autoescape_top.txt', 'dirs' => $dirs)->render($context), $test_string, 'Autoescape management with inclusions');

done_testing();
