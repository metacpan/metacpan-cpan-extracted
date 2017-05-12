#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;
use utf8;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'list' => [
        'http://www.example.com/',
        'http://example.com/testpage.txt?param1=val1',
    ]
});

my $SET = [
    {
        'template' => '{{ list.0|urlencode }}',
        'test' => 'http%3A%2F%2Fwww.example.com%2F',
        'title' => 'Domain name',
    },
    {
        'template' => '{{ list.1|urlencode }}',
        'test' => 'http%3A%2F%2Fexample.com%2Ftestpage.txt%3Fparam1%3Dval1',
        'title' => 'Domain name with arguments',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
