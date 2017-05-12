#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'values' => [
        700,
        1.1 * 1024,
        1.2 * 1024 * 1024,
        1.3 * 1024 * 1024 * 1024,
        1.4 * 1024 * 1024 * 1024 * 1024,
        1.5 * 1024 * 1024 * 1024 * 1024 * 1024,
        1.6 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
        1.7 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024 * 1024,
    ],
});

my $SET = [
    {
        'template' => '{{ values.0|filesizeformat }}',
        'test' => '700 B',
        'title' => 'Bytes',
    },
    {
        'template' => '{{ values.1|filesizeformat }}',
        'test' => '1.1 KB',
        'title' => 'Kilobytes',
    },
    {
        'template' => '{{ values.2|filesizeformat }}',
        'test' => '1.2 MB',
        'title' => 'Megabytes',
    },
    {
        'template' => '{{ values.3|filesizeformat }}',
        'test' => '1.3 GB',
        'title' => 'Gigabytes',
    },
    {
        'template' => '{{ values.4|filesizeformat }}',
        'test' => '1.4 TB',
        'title' => 'Terabytes',
    },
    {
        'template' => '{{ values.5|filesizeformat }}',
        'test' => '1.5 PB',
        'title' => 'Petabytes',
    },
    {
        'template' => '{{ values.6|filesizeformat }}',
        'test' => '1.6 EB',
        'title' => 'Exobytes',
    },
    {
        'template' => '{{ values.7|filesizeformat }}',
        'test' => '1.7 ZB',
        'title' => 'Zetabytes',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
