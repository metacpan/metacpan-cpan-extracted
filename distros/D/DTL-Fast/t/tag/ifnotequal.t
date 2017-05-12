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
        'test' => 'false',
        'template' => '{% ifnotequal 1 var1 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static number and var number, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifnotequal var1 1 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static number and var number reversed, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifnotequal 1 1 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static number and static number, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifnotequal var1 var11 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Variable number and variable number, false'
    },
    {
        'test' => 'true',
        'template' => '{% ifnotequal 0 var1 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static number and var number, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifnotequal var1 0 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static number and var number reversed, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifnotequal 1 0 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static number and static number, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifnotequal var1 var14 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Variable number and variable number, true'
    },
    # strings
    {
        'test' => 'false',
        'template' => '{% ifnotequal "string" var2 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static string and var string, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifnotequal var2 "string" %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static string and var string reversed, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifnotequal "test" "test" %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static string and static string, false'
    },
    {
        'test' => 'false',
        'template' => '{% ifnotequal var2 var12 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Variable string and variable string, false'
    },
    {
        'test' => 'true',
        'template' => '{% ifnotequal "test" var1 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static string and var string, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifnotequal var1 "test" %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static string and var string reversed, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifnotequal "test" "string" %}true{% else %}false{% endifnotequal %}',
        'title' => 'Static string and static string, true'
    },
    {
        'test' => 'true',
        'template' => '{% ifnotequal var2 var11 %}true{% else %}false{% endifnotequal %}',
        'title' => 'Variable string and variable string, true'
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
