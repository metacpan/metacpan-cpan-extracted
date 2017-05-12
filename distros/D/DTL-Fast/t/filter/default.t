#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => "test string",
    'var2' => 123,
    'var3' => '',
    'var4' => 0,
    'var5' => undef
});

my $SET = [
    {
        'template' => <<'_EOT_',
{{ "test string"|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
test string
_EOT_
        'title' => 'Static true string',
    },
    {
        'template' => <<'_EOT_',
{{ 123|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
123
_EOT_
        'title' => 'Static true number',
    },
    {
        'template' => <<'_EOT_',
{{ 0|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
default value
_EOT_
        'title' => 'Static false number',
    },
    {
        'template' => <<'_EOT_',
{{ ""|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
default value
_EOT_
        'title' => 'Static empty string',
    },

    {
        'template' => <<'_EOT_',
{{ var1|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
test string
_EOT_
        'title' => 'Dynamic true string',
    },
    {
        'template' => <<'_EOT_',
{{ var2|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
123
_EOT_
        'title' => 'Dynamic true number',
    },
    {
        'template' => <<'_EOT_',
{{ var3|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
default value
_EOT_
        'title' => 'Dynamic empty string',
    },
    {
        'template' => <<'_EOT_',
{{ var4|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
default value
_EOT_
        'title' => 'Dynamic false number',
    },
    {
        'template' => <<'_EOT_',
{{ var5|default:'default value' }}
_EOT_
        'test' => <<'_EOT_',
default value
_EOT_
        'title' => 'Dynamic undef value',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
