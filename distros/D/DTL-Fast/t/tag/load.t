#!/usr/bin/perl -It/tag
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];


$context = DTL::Fast::Context->new();

my $SET = [
    {
        'test' => 'and FooBar was here!',
        'template' => '{% load Foo::Bar %}and {% foobar %}',
        'title' => 'Custom tag loaded and rendered'
    },
    {
        'test' => 'and FooBar was here!',
        'template' => '{% load "Foo::Bar" %}and {% foobar %}',
        'title' => 'Custom tag loaded and rendered'
    },
];

foreach my $data (@$SET)
{
    $template = DTL::Fast::Template->new( $data->{'template'} );
    is( $template->render($context), $data->{'test'}, $data->{'title'});
    
    if( $data->{'debug'} )
    {
        print Dumper($template);
        exit;
    }
    
}



done_testing();
