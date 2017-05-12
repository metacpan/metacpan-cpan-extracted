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
    , 'var11' => 1
    , 'var12' => 'string'
    , 'var13' => undef
    , 'var14' => 0
    , 'var15' => ''
    
});

my $SET = [
    {
        'test' => 'true',
        'template' => '{% ifequal 1 var1 %}true{% else %}false{% endifequal %}',
        'title' => 'Static number and var number, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifequal var1 1 %}true{% else %}false{% endifequal %}',
        'title' => 'Static number and var number reversed, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifequal 1 1 %}true{% else %}false{% endifequal %}',
        'title' => 'Static number and static number, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifequal var1 var11 %}true{% else %}false{% endifequal %}',
        'title' => 'Variable number and variable number, true'
    },
    {
        'test' => 'false',
        'template' => '{% ifequal 0 var1 %}true{% else %}false{% endifequal %}',
        'title' => 'Static number and var number, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifequal var1 0 %}true{% else %}false{% endifequal %}',
        'title' => 'Static number and var number reversed, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifequal 1 0 %}true{% else %}false{% endifequal %}',
        'title' => 'Static number and static number, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifequal var1 var14 %}true{% else %}false{% endifequal %}',
        'title' => 'Variable number and variable number, false'
    },
    # strings
    {
        'test' => 'true',
        'template' => '{% ifequal "string" var2 %}true{% else %}false{% endifequal %}',
        'title' => 'Static string and var string, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifequal var2 "string" %}true{% else %}false{% endifequal %}',
        'title' => 'Static string and var string reversed, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifequal "test" "test" %}true{% else %}false{% endifequal %}',
        'title' => 'Static string and static string, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifequal var2 var12 %}true{% else %}false{% endifequal %}',
        'title' => 'Variable string and variable string, true'
    },
    {
        'test' => 'false',
        'template' => '{% ifequal "test" var1 %}true{% else %}false{% endifequal %}',
        'title' => 'Static string and var string, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifequal var1 "test" %}true{% else %}false{% endifequal %}',
        'title' => 'Static string and var string reversed, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifequal "test" "string" %}true{% else %}false{% endifequal %}',
        'title' => 'Static string and static string, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifequal var2 var11 %}true{% else %}false{% endifequal %}',
        'title' => 'Variable string and variable string, false'
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
