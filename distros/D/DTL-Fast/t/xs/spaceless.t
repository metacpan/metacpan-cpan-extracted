#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;use utf8;

use DTL::Fast;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 'no',
    'var2' => 'yes',
});

my $SET = [
    {
        'template' => "",
        'test' => '',
        'title' => 'Empty string',
    },
    {
        'template' => " <",
        'test' => '<',
        'title' => 'Heading space',
    },
    {
        'template' => " < ",
        'test' => '< ',
        'title' => 'Heading space with space in tail',
    },
    {
        'template' => "> ",
        'test' => '>',
        'title' => 'Tailing space',
    },
    {
        'template' => " > ",
        'test' => ' >',
        'title' => 'Tailing space with space in head',
    },
    {
        'template' => " <> ",
        'test' => '<>',
        'title' => 'Both spaces',
    },
    {
        'template' => " <blblba> <blfah>  asdf  </blah> ",
        'test' => '<blblba><blfah>  asdf  </blah>',
        'title' => 'Complex',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::spaceless($data->{'template'}), $data->{'test'}, $data->{'title'});
    
}

done_testing();
