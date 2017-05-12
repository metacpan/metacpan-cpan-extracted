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
{% filter escape|escape %}checking {{ val1.0|safe }}
checking {{ val1.1|safe }}
checking {{ val1.2|safe }}
checking {{ val1.3|safe }}
checking {{ val1.4|safe }}{% endfilter %}
_EOT_

$test_string = <<'_EOT_';
checking here is &amp;lt; value
checking here is &amp;gt; value
checking here is &amp;#39; value
checking here is &amp;quot; value
checking here is &amp;amp; value
_EOT_

is( $template->render($context), $test_string, 'Piped filters');

$template = DTL::Fast::Template->new( << '_EOT_' );
checking {{ val1.0 }}
{% filter escape %}checking {{ val1.1 }}
checking {{ val1.2 }}
checking {{ val1.3|safe }}{% endfilter %}
checking {{ val1.4 }}
_EOT_

$test_string = <<'_EOT_';
checking here is &lt; value
checking here is &amp;gt; value
checking here is &amp;#39; value
checking here is &quot; value
checking here is &amp; value
_EOT_

is( $template->render($context), $test_string, 'Variable values auto-protection, double escape');

$template = DTL::Fast::Template->new( << '_EOT_' );
{% autoescape off %}checking {{ val1.0 }}
{% filter escape %}checking {{ val1.1 }}
checking {{ val1.2 }}
checking {{ val1.3 }}{% endfilter %}
checking {{ val1.4 }}{% endautoescape %}
_EOT_

$test_string = <<'_EOT_';
checking here is < value
checking here is &gt; value
checking here is &#39; value
checking here is &quot; value
checking here is & value
_EOT_

$template = DTL::Fast::Template->new( << '_EOT_' );
This is html <p>test values</p>
{% filter escape %}checking <script>script escaping</script>{% endfilter %}
checking <div>html again</div>
_EOT_

$test_string = <<'_EOT_';
This is html <p>test values</p>
checking &lt;script&gt;script escaping&lt;/script&gt;
checking <div>html again</div>
_EOT_

is( $template->render($context), $test_string, 'Variable values with disabled auto-protection, block escaping');

done_testing();
