#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => '<p>this <span>is <b>a</B> regular</sPAn> <p style="blabla">text with tags</p></p>',
    'var2' => '<p>this <span>is <b>a</B> regular</sPAn> <P style="blabla">text with tags</p></P>',
});

# @todo some random testing
my $SET = [
    {
        'template' => '{{ var1|striptags }}',
        'test' => 'this is a regular text with tags',
        'title' => 'Example 1',
    },
    {
        'template' => '{{ var2|striptags }}',
        'test' => 'this is a regular text with tags',
        'title' => 'Example 2',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
