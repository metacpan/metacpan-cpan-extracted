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
        'test' => '0',
        'template' => '{% firstofdefined 0 undef "" var1 var2 var3 %}',
        'title' => 'Firstofdefined: static number'
    },
    {
        'test' => '',
        'template' => '{% firstofdefined undef "" var1 var2 var3 %}',
        'title' => 'Firstofdefined: static empty string',
    },
    {
        'test' => '1',
        'template' => '{% firstofdefined undef var3 var1 var3 %}',
        'title' => 'Firstofdefined: numeric variable'
    },
    {
        'test' => 'string',
        'template' => '{% firstofdefined undef var3 var2 var3 %}',
        'title' => 'Firstofdefined: non-empty string variable'
    },
    {
        'test' => '0',
        'template' => '{% firstofdefined undef var3 var4 var3 %}',
        'title' => 'Firstofdefined: zero variable'
    },
    {
        'test' => '',
        'template' => '{% firstofdefined undef var3 var5 var3 %}',
        'title' => 'Firstofdefined: empty string variable'
    },

    {
        'test' => 'this &gt; escaped',
        'template' => '{% firstofdefined var3 var6 var4 var5 undef "" var6 var2 var3 %}',
        'title' => 'Firstofdefined: escaped variable'
    },
    {
        'test' => 'this &lt; escaped',
        'template' => '{% firstofdefined var3 "this < escaped" var4 var5 undef var6 var2 var3 %}',
        'title' => 'Firstofdefined: escaped static value'
    },
    {
        'test' => 'this > escaped',
        'template' => '{% firstofdefined var3 var6|safe var4 var5 undef "" var2 var3 %}',
        'title' => 'Firstofdefined: escaped variable with safe'
    },
    {
        'test' => 'this < escaped',
        'template' => '{% firstofdefined var3 "this < escaped"|safe var4 var5 undef var6 var2 var3 %}',
        'title' => 'Firstofdefined: escaped static value with safe'
    },
    {
        'test' => 'this > escaped',
        'template' => '{% autoescape off %}{% firstofdefined var3 var6 var4 var5 undef "" var6 var2 var3 %}{% endautoescape %}',
        'title' => 'Firstofdefined: escaped variable with autoescape off'
    },
    {
        'test' => 'this < escaped',
        'template' => '{% autoescape off %}{% firstofdefined var3 "this < escaped" var4 var5 undef  var6 var2 var3 %}{% endautoescape %}',
        'title' => 'Firstofdefined: escaped static value with autoescape off'
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
