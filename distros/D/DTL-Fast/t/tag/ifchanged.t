#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $context, $control);

my $dirs = ['./t/tmpl', './t/tmpl2'];

$context = DTL::Fast::Context->new({
    'array1' => [0, 0, 1, 1, 1, 2, 2, 2, 2, 3],
    'array2' => ['str1', 'str1', 'str2', 'str2', 'str3', 'str2', 'str2'],
    'array3' => [[0, 1], [0, 2], [0, 3], [0, 4], [1, 5], [1, 6], [1, 7], [1, 8], [2, 9], [2, 10]],
});

my $templates = [
    {
        'title' => 'Simple change, numbers',
        'template' => <<'_EOT_',
{% for val in array1 %}{% ifchanged val %}Changed to {% endifchanged %}{{ val }} {% endfor %}
_EOT_
        'control' => <<'_EOT_',
Changed to 0 0 Changed to 1 1 1 Changed to 2 2 2 2 Changed to 3 
_EOT_
    },
    {
        'title' => 'Simple change, numbers, content watching',
        'template' => <<'_EOT_',
{% for val in array1 %}{% ifchanged %}Changed to {% endifchanged %}{{ val }} {% endfor %}
_EOT_
        'control' => <<'_EOT_',
Changed to 0 0 1 1 1 2 2 2 2 3 
_EOT_
    },
    {
        'title' => 'Simple change, numbers, content watching, changes',
        'template' => <<'_EOT_',
{% for val in array1 %}{% ifchanged %}Changed to {{ val }} {% else %}{{ val }} {% endifchanged %}{% endfor %}
_EOT_
        'control' => <<'_EOT_',
Changed to 0 0 Changed to 1 1 1 Changed to 2 2 2 2 Changed to 3 
_EOT_
    },
    {
        'title' => 'Simple change with else, numbers',
        'template' => <<'_EOT_',
{% for val in array1 %}{% ifchanged val %}Changed to {% else %}unchanged {% endifchanged %}{{ val }} {% endfor %}
_EOT_
        'control' => <<'_EOT_',
Changed to 0 unchanged 0 Changed to 1 unchanged 1 unchanged 1 Changed to 2 unchanged 2 unchanged 2 unchanged 2 Changed to 3 
_EOT_
    },
    {
        'title' => 'Simple change, strings',
        'template' => <<'_EOT_',
{% for val in array2 %}{% ifchanged val %}Changed to {% endifchanged %}{{ val }} {% endfor %}
_EOT_
        'control' => <<'_EOT_',
Changed to str1 str1 Changed to str2 str2 Changed to str3 Changed to str2 str2 
_EOT_
    },
    {
        'title' => 'Simple change with else, strings',
        'template' => <<'_EOT_',
{% for val in array2 %}{% ifchanged val %}Changed to {% else %}unchanged {% endifchanged %}{{ val }} {% endfor %}
_EOT_
        'control' => <<'_EOT_',
Changed to str1 unchanged str1 Changed to str2 unchanged str2 Changed to str3 Changed to str2 unchanged str2 
_EOT_
    },
    {
        'title' => 'Simple change with else, strings, content watching',
        'template' => <<'_EOT_',
{% for val in array2 %}{% ifchanged %}Changed to {{ val }} {% else %}unchanged {{ val }} {% endifchanged %}{% endfor %}
_EOT_
        'control' => <<'_EOT_',
Changed to str1 unchanged str1 Changed to str2 unchanged str2 Changed to str3 Changed to str2 unchanged str2 
_EOT_
    },
    {
        'title' => 'Complex for loop',
        'template' => <<'_EOT_',
{% for a, b in array3 %}{% ifchanged a %}Changed to {{ a }}
{% endifchanged %}{{ a }} - {{ b }}
{% endfor %}
_EOT_
        'control' => <<'_EOT_',
Changed to 0
0 - 1
0 - 2
0 - 3
0 - 4
Changed to 1
1 - 5
1 - 6
1 - 7
1 - 8
Changed to 2
2 - 9
2 - 10

_EOT_
    },
    
];


foreach my $tpl (@$templates)
{
    my $template = $tpl->{'template'};
    my $control = $tpl->{'control'};
    my $title = $tpl->{'title'};
    
    my $tpl = DTL::Fast::Template->new($template);
    is( $tpl->render($context), $control, $title);
}

done_testing();
