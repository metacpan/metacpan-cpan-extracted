#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 'no',
    'var2' => 'yes',
});

my $SET = [
    {
        'template' => "{% if var1 == 'yes' %}passed{% endif %}",
        'test' => '',
        'title' => 'Simple comparision, negative',
    },
    {
        'template' => "{% if var2 == 'yes' %}passed{% endif %}",
        'test' => 'passed',
        'title' => 'Simple comparision, positive',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
