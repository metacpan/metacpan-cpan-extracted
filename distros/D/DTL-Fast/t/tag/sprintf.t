#!/usr/bin/perl

use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];
my $ssi_dirs = ['./t/ssi'];
$context = new DTL::Fast::Context({
    'tpl' => 'Hi %s, you have got %.02f dollars',
    'var1' => 'Alex',
    'var2' => 3.1415
});

my $SET = [
    {
        'template' => '{% sprintf tpl var1 var2 %}',
        'test' => 'Hi Alex, you have got 3.14 dollars',
        'title' => 'Simple sprintf with formatting. All from context',
    },
    {
        'template' => '{% sprintf tpl "Ivan" 0.42 %}',
        'test' => 'Hi Ivan, you have got 0.42 dollars',
        'title' => 'Simple sprintf with formatting. Static substitutes',
    },
    {
        'template' => '{% sprintf "%s and %d" "Ivan" 0.42 %}',
        'test' => 'Ivan and 0',
        'title' => 'Simple sprintf with formatting. All static',
    },
];


foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
