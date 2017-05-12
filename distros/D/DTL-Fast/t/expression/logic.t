#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;use utf8;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
});

my @DATA = (
    {
        'var' =>  \1,
        , 'positive' => '1'
        , 'negative' => '0'
        , 'title' => 'True value'
    }
    , {
        'var' =>  \0,
        , 'positive' => '0'
        , 'negative' => '1'
        , 'title' => 'False value'
    }
    , {
        'var' =>  1,
        , 'positive' => '1'
        , 'negative' => '0'
        , 'title' => 'Non-zero value'
    }
    , {
        'var' =>  0,
        , 'positive' => '0'
        , 'negative' => '1'
        , 'title' => 'Zero'
    }
    , {
        'var' =>  undef,
        , 'positive' => '0'
        , 'negative' => '1'
        , 'title' => 'Undefinded value'
    }
    , {
        'var' =>  'string',
        , 'positive' => '1'
        , 'negative' => '0'
        , 'title' => 'Non-empty string'
    }
    , {
        'var' =>  '',
        , 'positive' => '0'
        , 'negative' => '1'
        , 'title' => 'Empty string'
    }
    , {
        'var' =>  [],
        , 'positive' => '0'
        , 'negative' => '1'
        , 'title' => 'Empty arrray'
    }
    , {
        'var' =>  {},
        , 'positive' => '0'
        , 'negative' => '1'
        , 'title' => 'Empty hash'
    }
    , {
        'var' =>  [1],
        , 'positive' => '1'
        , 'negative' => '0'
        , 'title' => 'Non-empty array'
    }
    , {
        'var' =>  {'a' => 'b'},
        , 'positive' => '1'
        , 'negative' => '0'
        , 'title' => 'Non-empty hash'
    }
);

my %TPL = (
    '1' => [  # one parameter test
        {
            'template' => '{% if var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s', lc($var->{'title'});
            }
        },
        # and constant 1
        {
            'template' => '{% if var and 1 %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} && 1 ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s and 1', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var and 1 %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} && 1 ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s and 1', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if 1 and var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return 1 && $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '1 and %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if 1 and not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return 1 && $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '1 and not %s', lc($var->{'title'});
            }
        },
        # or constant
        {
            'template' => '{% if var or 1 %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} || 1 ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s or 1', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var or 1 %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} || 1 ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s or 1', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if 1 or var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return 1 || $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '1 or %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if 1 or not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return 1 || $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '1 or not %s', lc($var->{'title'});
            }
        },
        ############## end of constant 1

        # and constant "string"
        {
            'template' => '{% if var and "string" %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} && "string" ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s and "string"', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var and "string" %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} && "string" ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s and "string"', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if "string" and var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return "string" && $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '"string" and %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if "string" and not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return "string" && $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '"string" and not %s', lc($var->{'title'});
            }
        },
        # or constant
        {
            'template' => '{% if var or "string" %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} || "string" ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s or "string"', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var or "string" %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} || "string" ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s or "string"', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if "string" or var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return "string" || $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '"string" or %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if "string" or not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return "string" || $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '"string" or not %s', lc($var->{'title'});
            }
        },
        ############## end of constant "string"

        # and constant undef
        {
            'template' => '{% if var and undef %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return ($var->{'positive'} && undef ) ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s and undef', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var and undef %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return ($var->{'negative'} && undef) ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s and undef', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if undef and var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return (undef && $var->{'positive'}) ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'undef and %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if undef and not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return (undef && $var->{'negative'}) ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'undef and not %s', lc($var->{'title'});
            }
        },
        # or constant
        {
            'template' => '{% if var or undef %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return ($var->{'positive'} || undef) ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s or undef', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var or undef %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return ($var->{'negative'} || undef) ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s or undef', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if undef or var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return (undef || $var->{'positive'}) ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'undef or %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if undef or not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return (undef || $var->{'negative'}) ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'undef or not %s', lc($var->{'title'});
            }
        },
        ############## end of constant undef

        # and constant ""
        {
            'template' => '{% if var and "" %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} && "" ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s and ""', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var and "" %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} && "" ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s and ""', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if "" and var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return "" && $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '"" and %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if "" and not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return "" && $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '"" and not %s', lc($var->{'title'});
            }
        },
        # or constant
        {
            'template' => '{% if var or "" %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} || "" ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s or ""', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var or "" %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} || "" ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s or ""', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if "" or var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return "" || $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '"" or %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if "" or not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return "" || $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '"" or not %s', lc($var->{'title'});
            }
        },
        ############## end of constant ""

        # and constant 0
        {
            'template' => '{% if var and 0 %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} && 0 ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s and 0', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var and 0 %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} && 0 ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s and 0', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if 0 and var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return 0 && $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '0 and %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if 0 and not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return 0 && $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '0 and not %s', lc($var->{'title'});
            }
        },
        # or constant
        {
            'template' => '{% if var or 0 %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'positive'} || 0 ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '%s or 0', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if not var or 0 %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return $var->{'negative'} || 0 ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf 'not %s or 0', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if 0 or var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return 0 || $var->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '0 or %s', lc($var->{'title'});
            }
        },
        {
            'template' => '{% if 0 or not var %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my $var = shift;
                return 0 || $var->{'negative'} ? 1: 0;
            }
            , 'title' => sub
            {
                my $var = shift;
                return sprintf '0 or not %s', lc($var->{'title'});
            }
        },
        ############## end of constant 0
        
    ],
    2 => [
        {
            'template' => '{% if varx and vary %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my ($varx, $vary) = @_;
                return $varx->{'positive'} && $vary->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my ($varx, $vary) = @_;
                return sprintf '%s and %s', lc($varx->{'title'}), lc($vary->{'title'});
            }
        },
        {
            'template' => '{% if varx or vary %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my ($varx, $vary) = @_;
                return $varx->{'positive'} || $vary->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my ($varx, $vary) = @_;
                return sprintf '%s or %s', lc($varx->{'title'}), lc($vary->{'title'});
            }
        },
        {
            'template' => '{% if varx and not vary %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my ($varx, $vary) = @_;
                return $varx->{'positive'} && !$vary->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my ($varx, $vary) = @_;
                return sprintf '%s and not %s', lc($varx->{'title'}), lc($vary->{'title'});
            }
        },
        {
            'template' => '{% if varx or not vary %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my ($varx, $vary) = @_;
                return $varx->{'positive'} || !$vary->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my ($varx, $vary) = @_;
                return sprintf '%s or not %s', lc($varx->{'title'}), lc($vary->{'title'});
            }
        },
        {
            'template' => '{% if not varx and vary %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my ($varx, $vary) = @_;
                return !$varx->{'positive'} && $vary->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my ($varx, $vary) = @_;
                return sprintf 'not %s and %s', lc($varx->{'title'}), lc($vary->{'title'});
            }
        },
        {
            'template' => '{% if not varx or vary %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my ($varx, $vary) = @_;
                return !$varx->{'positive'} || $vary->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my ($varx, $vary) = @_;
                return sprintf 'not %s or %s', lc($varx->{'title'}), lc($vary->{'title'});
            }
        },
        {
            'template' => '{% if not varx and not vary %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my ($varx, $vary) = @_;
                return !$varx->{'positive'} && !$vary->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my ($varx, $vary) = @_;
                return sprintf 'not %s and %s', lc($varx->{'title'}), lc($vary->{'title'});
            }
        },
        {
            'template' => '{% if not varx or not vary %}1{% else %}0{% endif %}'
            , 'validate' => sub{
                my ($varx, $vary) = @_;
                return !$varx->{'positive'} || !$vary->{'positive'} ? 1: 0;
            }
            , 'title' => sub
            {
                my ($varx, $vary) = @_;
                return sprintf 'not %s or not %s', lc($varx->{'title'}), lc($vary->{'title'});
            }
        },
    ]
);

subtest 'One parameter tests' => sub{
    foreach my $tpl (@{$TPL{1}})
    {
        my $template = DTL::Fast::Template->new($tpl->{'template'});
        foreach my $data (@DATA)
        {
            $context->set('var' => $data->{'var'});
            is( $template->render($context), $tpl->{'validate'}->($data), $tpl->{'title'}->($data) );
        }
    }
};

subtest 'Two parameters tests' => sub{
    foreach my $tpl (@{$TPL{2}})
    {
        my $template = DTL::Fast::Template->new($tpl->{'template'});
        foreach my $datax (@DATA)
        {
            foreach my $datay (@DATA)
            {
                $context->set(
                    'varx' => $datax->{'var'},
                    'vary' => $datay->{'var'},
                );
                is( $template->render($context), $tpl->{'validate'}->($datax, $datay), $tpl->{'title'}->($datax, $datay) );
            }
        }
    }
};

$template = '{% if superandvar and superorvar %}true{%endif%}';
is( DTL::Fast::Template->new($template)->render({
        'superandvar' => 1,
        'superorvar' => 1
    }), 'true', 'Variable names with and/or' );

   
$template = '{% if 0 and var.supervar / 0 %}true{%else%}false{%endif%}';
$test_string = "false";
is( DTL::Fast::Template->new($template)->render(), $test_string, 'and operator second argument rendering suppression' );
   
$template = '{% if 1 or var.supervar / 0 %}true{%else%}false{%endif%}';
$test_string = "true";
is( DTL::Fast::Template->new($template)->render(), $test_string, 'or operator second argument rendering supression' );
   
$template = '{% if 1 and var.supervar / 0 %}true{%else%}false{%endif%}';
$test_string = "false";
eval{
    DTL::Fast::Template->new($template)->render();
};
ok($@, 'and operator second argument rendering: '.$@);

$template = '{% if 0 or var.supervar / 0 %}true{%else%}false{%endif%}';
$test_string = "false";
eval{
    DTL::Fast::Template->new($template)->render();
};
ok($@, 'and operator second argument rendering: '.$@);
    
done_testing();
