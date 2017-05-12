#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];
$context = new DTL::Fast::Context({
    'array' => ['value0','value1','value2']
    , 'complex_array' => [
        ['value00','value01','value02'],
        ['value10','value11','value12'],
        ['value20','value21','value22'],
    ]
    , 'complex_array_redundant' => [
        ['value00','value01','value02','value03'],
        ['value10','value11','value12','value13'],
        ['value20','value21','value22','value23'],
    ]
    , 'hash' => {
        'key1' => 'val1',
        'key2' => 'val2',
        'key3' => 'val3',
        'key4' => 'val4',
    }
    , 'one_item_array' => ['test']
    , 'empty_array' => []
    , 'empty_hash' => {}
});

$template = <<'_EOT_';
{% for val in array %}This is a {{ val }}
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
This is a value0
This is a value1
This is a value2

_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Array rendering');

$template = <<'_EOT_';
{% for val in array reversed %}This is a {{ val }}
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
This is a value2
This is a value1
This is a value0

_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Array rendering reversed');

$template = <<'_EOT_';
{% for val in array %}This is a {{ val }}-{{ forloop.counter }}-{{ forloop.counter0 }}-{{ forloop.revcounter }}-{{ forloop.revcounter0 }}-{{ forloop.first }}-{{ forloop.last }}-{{ forloop.odd }}-{{ forloop.odd0 }}-{{ forloop.even }}-{{ forloop.even0 }}
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
This is a value0-1-0-3-2-1-0-1-0-0-1
This is a value1-2-1-2-1-0-0-0-1-1-0
This is a value2-3-2-1-0-0-1-1-0-0-1

_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Array rendering with forloop values');

$template = <<'_EOT_';
{% for a,b ,c in complex_array %}This is a {{ a }}-{{ b }}-{{ c }}
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
This is a value00-value01-value02
This is a value10-value11-value12
This is a value20-value21-value22

_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Array of arrays rendering');

$template = <<'_EOT_';
{% for a,b ,c in complex_array_redundant %}This is a {{ a }}-{{ b }}-{{ c }}
{% endfor %}
_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Array of arrays with redundancy rendering');


$template = <<'_EOT_';
{% for a,b ,c in complex_array_redundant %}This is a {{ a }}-{{ b }}-{{ c }}
{% for a in array %}This is a {{ a }}-{{ forloop.counter }}-{{ forloop.parentloop.counter }}
{% endfor %}Still {{ a }}-{{ b }}-{{ c }}
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
This is a value00-value01-value02
This is a value0-1-1
This is a value1-2-1
This is a value2-3-1
Still value00-value01-value02
This is a value10-value11-value12
This is a value0-1-2
This is a value1-2-2
This is a value2-3-2
Still value10-value11-value12
This is a value20-value21-value22
This is a value0-1-3
This is a value1-2-3
This is a value2-3-3
Still value20-value21-value22

_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Nested iterations');

$template = <<'_EOT_';
{% for a,b ,c in empty_array %}This is a {{ a }}-{{ b }}-{{ c }}
{% empty %}Nothing in this array
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
Nothing in this array

_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Nothing block on empty array');


$template = <<'_EOT_';
{% for a,b in empty_hash %}This is a {{ a }}-{{ b }}-{{ c }}
{% empty %}Nothing in this hash
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
Nothing in this hash

_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Nothing block on empty hash');


$template = <<'_EOT_';
{% for a, b in hash %}This is a {{ a }}-{{ b }}
{% endfor %}
_EOT_

# can't make static example, because of hash keys randomising
$test_string = '';
my $hash = $context->{'ns'}->[0]->{'hash'};
foreach my $key (keys %$hash)
{
    $test_string .= "This is a $key-$hash->{$key}\n";
}
$test_string .= "\n";

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Hash rendering');

# issue #72
$template = <<'_EOT_';
{% for val in one_item_array %}This is a {{ val }}-{{ forloop.counter }}-{{ forloop.counter0 }}-{{ forloop.revcounter }}-{{ forloop.revcounter0 }}-{{ forloop.first }}-{{ forloop.last }}-{{ forloop.odd }}-{{ forloop.odd0 }}-{{ forloop.even }}-{{ forloop.even0 }}
{% endfor %}
_EOT_

$test_string = <<'_EOT_';
This is a test-1-0-1-0-1-1-1-0-0-1

_EOT_

is( DTL::Fast::Template->new($template, 'dirs' => $dirs)->render($context), $test_string, 'Array rendering with forloop values');


# @todo reversed hash rendering



done_testing();
