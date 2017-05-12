#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;use utf8;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
});

# @todo some random testing
my $SET = [
    {
        'template' => '{{ "this is a test string"|truncatechars_html:6 }}',
        'test' => 'this i...',
        'title' => 'Non-space ending',
    },
    {
        'template' => '{{ "this is a test string"|truncatechars_html:5 }}',
        'test' => 'this...',
        'title' => 'Space ending',
    },
    {
        'template' => '{{ "<p>this is a test string</p>"|truncatechars_html:6|safe }}',
        'test' => '<p>this i...</p>',
        'title' => 'Non-space ending, with tags',
    },
    {
        'template' => '{{ "<p>this is a test string</p>"|truncatechars_html:5|safe }}',
        'test' => '<p>this...</p>',
        'title' => 'Space ending with tags',
    },
    {
        'template' => '{{ "<p><basdfasdf>this is a test string</p>"|truncatechars_html:6|safe }}',
        'test' => '<p><basdfasdf>this i...</p>',
        'title' => 'Non-space ending, with bad tags',
    },
    {
        'template' => '{{ "<p>this is a test string</basdfasdf></p>"|truncatechars_html:5|safe }}',
        'test' => '<p>this...</basdfasdf></p>',
        'title' => 'Space ending with bad tags',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
