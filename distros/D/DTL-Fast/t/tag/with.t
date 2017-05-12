#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

#local $SIG{__WARN__} = sub {};

my $dirs = ['./t/tmpl', './t/tmpl2'];
my $ssi_dirs = ['./t/ssi'];
$context = new DTL::Fast::Context({
    'array' => ['one', 'two', 'three'],
    'hash' => {
        'key1' => 'val1',
        'key2' => 'val2',
        'key3' => 'val3',
        'key4' => 'val4',
    },
    'var2' => 100,
    'var3' => 350
});

my $SET = [
    {
        'template' => <<'_EOT_',
{% with hash.key3 as var3 %}
{{ var3 }}
{% endwith %}
_EOT_
        'test' => <<'_EOT_',

val3

_EOT_
        'title' => 'Legacy aliasing',
    },
    {
        'template' => <<'_EOT_',
{% with var3=hash.key3 var2="blabla" %}
{{ var3 }} {{ var2 }}
{% endwith %}
_EOT_
        'test' => <<'_EOT_',

val3 blabla

_EOT_
        'title' => 'Modern aliasing',
    },
    {
        'template' => <<'_EOT_',
{% with var3=hash.key3 var2="blabla" %}
{{ var3 }} {{ var2 }}
{% endwith %}
{{ var3 }} {{ var2 }}
_EOT_
        'test' => <<'_EOT_',

val3 blabla

350 100
_EOT_
        'title' => 'Context safety',
    },
    {
        'template' => <<'_EOT_',
{% with 
    var3 = hash.key3 
    var2  =    "blabla" 
%}
{{ var3 }} {{ var2 }}
{% endwith %}
{{ var3 }} {{ var2 }}
_EOT_
        'test' => <<'_EOT_',

val3 blabla

350 100
_EOT_
        'title' => 'Context safety with spaces between keys and vals',
    },
    {
        'template' => <<'_EOT_',
{% with a="aaa"|default:123 %}{{ a }}{% endwith %}{{ "ccc"|default:"ddd" }}
_EOT_
        'test' => <<'_EOT_',
aaaccc
_EOT_
        'title' => 'With with default',
    },
    {
        'template' => <<'_EOT_',
{% with a=""|default:123 %}{{ a }}{% endwith %}{{ "ccc"|default:"ddd" }}
_EOT_
        'test' => <<'_EOT_',
123ccc
_EOT_
        'title' => 'With with default, used',
    },
    {
        'template' => <<'_EOT_',
{% with a=""|default:"somestring" %}{{ a }}{% endwith %}{{ "ccc"|default:"ddd" }}
_EOT_
        'test' => <<'_EOT_',
somestringccc
_EOT_
        'title' => 'With with default, used, string substitution',
    },
    
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}


done_testing();
