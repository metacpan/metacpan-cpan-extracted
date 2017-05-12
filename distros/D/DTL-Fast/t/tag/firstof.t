#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];


$context = DTL::Fast::Context->new({
    'var1' => 1
    , 'var2' => 'string'
    , 'var3' => undef
    , 'var4' => 0
    , 'var5' => ''
    , 'var6' => 'this > escaped'
});

my $SET = [
    {
        'test' => '1',
        'template' => '{% firstof 0 undef "" var1 var2 var3 %}',
        'title' => 'Firstof: number'
    },
    {
        'test' => 'string',
        'template' => '{% firstof 0 undef "" var2 var2 var3 %}',
        'title' => 'Firstof: string'
    },
    {
        'test' => 'string',
        'template' => '{% firstof var3 0 undef "" var2 var2 var3 %}',
        'title' => 'Firstof: undef'
    },
    {
        'test' => 'string',
        'template' => '{% firstof var3 var4 0 undef "" var2 var2 var3 %}',
        'title' => 'Firstof: zero'
    },
    {
        'test' => 'string',
        'template' => '{% firstof var3 var4 var5 undef "" var2 var2 var3 %}',
        'title' => 'Firstof: empty string'
    },
    {
        'test' => 'this &gt; escaped',
        'template' => '{% firstof var3 var4 var5 undef "" var6 var2 var3 %}',
        'title' => 'Firstof: escaped variable'
    },
    {
        'test' => 'this &lt; escaped',
        'template' => '{% firstof var3 var4 var5 undef "this < escaped" var6 var2 var3 %}',
        'title' => 'Firstof: escaped static value'
    },
    {
        'test' => 'this > escaped',
        'template' => '{% firstof var3 var4 var5 undef "" var6|safe var2 var3 %}',
        'title' => 'Firstof: escaped variable with safe'
    },
    {
        'test' => 'this < escaped',
        'template' => '{% firstof var3 var4 var5 undef "this < escaped"|safe var6 var2 var3 %}',
        'title' => 'Firstof: escaped static value with safe'
    },
    {
        'test' => 'this > escaped',
        'template' => '{% autoescape off %}{% firstof var3 var4 var5 undef "" var6 var2 var3 %}{% endautoescape %}',
        'title' => 'Firstof: escaped variable with autoescape off'
    },
    {
        'test' => 'this < escaped',
        'template' => '{% autoescape off %}{% firstof var3 var4 var5 undef "this < escaped" var6 var2 var3 %}{% endautoescape %}',
        'title' => 'Firstof: escaped static value with autoescape off'
    },
];

foreach my $data (@$SET)
{
    $template = DTL::Fast::Template->new( $data->{'template'} );
    is( $template->render($context), $data->{'test'}, $data->{'title'});
}



done_testing();
