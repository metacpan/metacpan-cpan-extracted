#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;use utf8;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use POSIX ('locale_h');

setlocale(LC_COLLATE, 'ru_RU.UTF-8');

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
});

# @todo some random testing
my $SET = [
    {
        'template' => '{{ "THIS IS A TEST"|title }}',
        'test' => 'This Is A Test',
        'title' => 'Titling text',
    },
    # { # doesn't work some places
        # 'template' => '{{ "это тестовый текст"|title }}',
        # 'test' => 'Это Тестовый Текст',
        # 'title' => 'Utf8 cyrillic titling',
    # },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
