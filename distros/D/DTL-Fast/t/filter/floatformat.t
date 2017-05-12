#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 1,
    'var2' => 1.1,
    'var3' => 1.01,
    'var4' => 1.08,
});

my $SET = [
    {
        'template' => '{{ var1|floatformat }}',
        'test' => '1',
        'title' => 'Integer without arguments',
    },
    {
        'template' => '{{ var2|floatformat }}',
        'test' => '1.1',
        'title' => 'Float without arguments',
    },
    {
        'template' => '{{ var3|floatformat }}',
        'test' => '1.01',
        'title' => 'Float without arguments',
    },
    {
        'template' => '{{ var4|floatformat }}',
        'test' => '1.08',
        'title' => 'Float without arguments',
    },
    {
        'template' => '{{ var1|floatformat:1 }}',
        'test' => '1.0',
        'title' => 'Integer with 1 digit',
    },
    {
        'template' => '{{ var2|floatformat:1 }}',
        'test' => '1.1',
        'title' => 'Float with 1 digit',
    },
    {
        'template' => '{{ var3|floatformat:1 }}',
        'test' => '1.0',
        'title' => 'Float with 1 digit',
    },
    {
        'template' => '{{ var4|floatformat:1 }}',
        'test' => '1.1',
        'title' => 'Float with 1 digit',
    },
    {
        'template' => '{{ var1|floatformat:2 }}',
        'test' => '1.00',
        'title' => 'Integer with 2 digits',
    },
    {
        'template' => '{{ var2|floatformat:2 }}',
        'test' => '1.10',
        'title' => 'Float with 2 digits',
    },
    {
        'template' => '{{ var3|floatformat:2 }}',
        'test' => '1.01',
        'title' => 'Float with 2 digits',
    },
    {
        'template' => '{{ var4|floatformat:2 }}',
        'test' => '1.08',
        'title' => 'Float with 2 digits',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
