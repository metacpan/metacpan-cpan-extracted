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
        'template' => '{{ "<P>this is a test string <b> extra extra extra extra extra </b></p>"|truncatewords_html:4|safe }}',
        'test' => '<P>this is a test...<b> extra extra extra extra extra </b></p>',
        'title' => 'Truncating',
    },
    {
        'template' => '{{ "<P>this is a test string <b> extra extra extra extra extra </b></p>"|truncatewords_html:10|safe }}',
        'test' => '<P>this is a test string <b> extra extra extra extra extra </b></p>',
        'title' => 'String is shorter than needed for truncting',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
