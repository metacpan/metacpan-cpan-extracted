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

my $SET = [
    {
        'template' => 'here is {% templatetag openblock %} example',
        'test' => 'here is {% example',
        'title' => 'Open block',
    },
    {
        'template' => 'here is {% templatetag closeblock %} example',
        'test' => 'here is %} example',
        'title' => 'Close block',
    },
    {
        'template' => 'here is {% templatetag openblock %} example {% templatetag closeblock %}',
        'test' => 'here is {% example %}',
        'title' => 'Block',
    },
    {
        'template' => 'here is {% templatetag openvariable %} example',
        'test' => 'here is {{ example',
        'title' => 'Open variable',
    },
    {
        'template' => 'here is {% templatetag closevariable %} example',
        'test' => 'here is }} example',
        'title' => 'Close variable',
    },
    {
        'template' => 'here is {% templatetag openvariable %} example {% templatetag closevariable %}',
        'test' => 'here is {{ example }}',
        'title' => 'Variable',
    },
    {
        'template' => 'here is {% templatetag openbrace %} example',
        'test' => 'here is { example',
        'title' => 'Open brace',
    },
    {
        'template' => 'here is {% templatetag closebrace %} example',
        'test' => 'here is } example',
        'title' => 'Close brace',
    },
    {
        'template' => 'here is {% templatetag openbrace %} example {% templatetag closebrace %}',
        'test' => 'here is { example }',
        'title' => 'Braces',
    },
    {
        'template' => 'here is {% templatetag opencomment %} example',
        'test' => 'here is {# example',
        'title' => 'Open comment',
    },
    {
        'template' => 'here is {% templatetag closecomment %} example',
        'test' => 'here is #} example',
        'title' => 'Close comment',
    },
    {
        'template' => 'here is {% templatetag opencomment %} example {% templatetag closecomment %}',
        'test' => 'here is {# example #}',
        'title' => 'Comment',
    },
];


foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
