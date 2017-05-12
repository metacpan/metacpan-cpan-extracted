#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 123456,
    'var2' => 'Test string',
});

my $SET = [
    {
        'template' => '{{ var1|make_list|join:"," }}',
        'test' => '1,2,3,4,5,6',
        'title' => 'List from number',
    },
    {
        'template' => '{{ var2|make_list|join:"," }}',
        'test' => 'T,e,s,t, ,s,t,r,i,n,g',
        'title' => 'List from string',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
