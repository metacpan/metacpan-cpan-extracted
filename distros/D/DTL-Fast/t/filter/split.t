#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;use utf8;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use POSIX ('locale_h');

setlocale(LC_COLLATE, 'ru_RU.UTF-8');
setlocale(LC_CTYPE, 'ru_RU.UTF-8');

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    var1 => 'This is a test  string'
});

# @todo some random testing
my $SET = [
    {
        'template' => '{{ var1|split:"\s+"|join:"," }}',
        'test' => 'This,is,a,test,string',
        'title' => 'Splitting test',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
