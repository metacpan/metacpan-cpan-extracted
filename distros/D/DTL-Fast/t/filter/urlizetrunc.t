#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'list' => [
        'this is http://www.example.com/ text',
        'this is http://www.example.com/, text',
        'this is http://www.example.com/?param1=arg1&param2=arg2, text',
        'this is http://www.example.com/?param1=arg1&param2=arg2#anch, text',
        'this is https://www.google.ru/search?newwindow=1&q=%D1%82%D0%B5%D1%81%D1%82%D0%BE%D0%B2%D1%8B%D0%B9%20%D0%BF%D0%BE%D0%B8%D1%81%D0%BA, text',
        'this is www.example.com/?param1=arg1&param2=arg2#anch, text',
        'this is example.com/?param1=arg1&param2=arg2#anch, text',
        'this is example.com, text',
        'this is example.com, and test@example.com text',
    ]
});

my $SET = [
    {
        'template' => '{{ list.0|urlizetrunc:10 }}',
        'test' => 'this is <a href="http://www.example.com/" rel="nofollow">http://www...</a> text',
        'title' => 'Domain name',
    },
    {
        'template' => '{{ list.1|urlizetrunc:10 }}',
        'test' => 'this is <a href="http://www.example.com/" rel="nofollow">http://www...</a>, text',
        'title' => 'Domain name with comma',
    },
    {
        'template' => '{{ list.2|urlizetrunc:10 }}',
        'test' => 'this is <a href="http://www.example.com/?param1=arg1&param2=arg2" rel="nofollow">http://www...</a>, text',
        'title' => 'Domain name with comma and params',
    },
    {
        'template' => '{{ list.3|urlizetrunc:10 }}',
        'test' => 'this is <a href="http://www.example.com/?param1=arg1&param2=arg2#anch" rel="nofollow">http://www...</a>, text',
        'title' => 'Domain name with params and anchor',
    },
    {
        'template' => '{{ list.4|urlizetrunc:10 }}',
        'test' => 'this is <a href="https://www.google.ru/search?newwindow=1&q=%D1%82%D0%B5%D1%81%D1%82%D0%BE%D0%B2%D1%8B%D0%B9%20%D0%BF%D0%BE%D0%B8%D1%81%D0%BA" rel="nofollow">https://ww...</a>, text',
        'title' => 'With UTF8 cyrillic params',
    },
    {
        'template' => '{{ list.5|urlizetrunc:10 }}',
        'test' => 'this is <a href="http://www.example.com/?param1=arg1&param2=arg2#anch" rel="nofollow">www.exampl...</a>, text',
        'title' => 'Without protocol',
    },
    {
        'template' => '{{ list.6|urlizetrunc:10 }}',
        'test' => 'this is <a href="http://example.com/?param1=arg1&param2=arg2#anch" rel="nofollow">example.co...</a>, text',
        'title' => 'Without protocol and www',
    },
    {
        'template' => '{{ list.7|urlizetrunc:10 }}',
        'test' => 'this is <a href="http://example.com" rel="nofollow">example.co...</a>, text',
        'title' => 'Just domain name',
    },
    {
        'template' => '{{ list.8|urlizetrunc:10 }}',
        'test' => 'this is <a href="http://example.com" rel="nofollow">example.co...</a>, and <a href="mailto:test@example.com" rel="nofollow">test@examp...</a> text',
        'title' => 'Domain name and email',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
}

done_testing();
