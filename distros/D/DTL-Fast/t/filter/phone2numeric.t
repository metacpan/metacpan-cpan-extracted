#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 123456,
    'var2' => '800-COLLECT',
});

my $SET = [
    {
        'template' => '{{ var1|phone2numeric }}',
        'test' => '123456',
        'title' => 'Numers as is',
    },
    {
        'template' => '{{ var2|phone2numeric }}',
        'test' => '800-2655328',
        'title' => 'Django example 800-COLLECT',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
