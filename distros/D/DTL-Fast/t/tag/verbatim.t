#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

local $SIG{__WARN__} = sub {};

my $dirs = ['./t/tmpl', './t/tmpl2'];
my $ssi_dirs = ['./t/ssi'];
$context = new DTL::Fast::Context({
    'array' => ['one', 'two', 'three'],
    'var1' => 1234,
    'slug' => 'дрель',
});

my $SET = [
    {
        'template' => 'here {{ var1 }} {% verbatim %} {{ var1 }} {% endverbatim %} example',
        'test' => 'here 1234  {{ var1 }}  example',
        'title' => 'Simple verbatim rendering',
    },
    {
        'template' => 'here {{ var1 }} {% verbatim %} {{ var1 }} {% endverbatim %} {{ slug }} {% endverbatim %} example',
        'test' => 'here 1234  {{ var1 }}  дрель  example',
        'title' => 'Premature closed verbatim rendering',
    },
    {
        'template' => 'here {{ var1 }} {% verbatim myblock %} {{ var1 }} {% endverbatim %} {{ slug }} {% endverbatim myblock %} example',
        'test' => 'here 1234  {{ var1 }} {% endverbatim %} {{ slug }}  example',
        'title' => 'Named verbatim block rendering',
    },
    {
        'template' => 'here {{ var1 }} {%verbatim %} {{ var1 }} {% endverbatim%} {{ slug }} {% endverbatim %} example',
        'test' => 'here 1234  {{ var1 }}  дрель  example',
        'title' => 'Premature closed verbatim rendering, spaceless',
    },
    {
        'template' => 'here {{ var1 }} {%verbatim myblock %} {{ var1 }} {% endverbatim %} {{ slug }} {% endverbatim   myblock%} example',
        'test' => 'here 1234  {{ var1 }} {% endverbatim %} {{ slug }}  example',
        'title' => 'Named verbatim block rendering, spaceless',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
