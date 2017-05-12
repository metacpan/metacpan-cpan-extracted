#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $context, $control);

my $dirs = ['./t/tmpl', './t/tmpl2'];

my $templates = [
    {
        'template' => '{% if val1 < val2 %}first{% elif val2 < val3 %}second{% elsif val3 < val4 %}third{% else %}fourth{% endif %} test',
        'control' => sub{
            my $context = shift;
            my $result = '';
            if( $context->get('val1') < $context->get('val2') )
            {
                $result .= 'first';
            }
            elsif( $context->get('val2') < $context->get('val3') )
            {
                $result .= 'second';
            }
            elsif( $context->get('val3') < $context->get('val4') )
            {
                $result .= 'third';
            }
            else
            {
                $result .= 'fourth';
            }
            $result .= ' test';
            return $result;    
        }
    },
    {
        'template' => '{% if val1 < val2 %}first{% if val2 < val3 %}second{% elsif val3 < val4 %}third{% else %}nested default{% endif %}{% else %}fourth{% if val2 < val3 %}second{% elsif val3 < val4 %}third{% else %}nested default{% endif %}{% endif %} test',
        'control' => sub{
            my $context = shift;
            my $result = '';
            if( $context->get('val1') < $context->get('val2') )
            {
                $result .= 'first';
                if( $context->get('val2') < $context->get('val3') )
                {
                    $result .= 'second';
                }
                elsif( $context->get('val3') < $context->get('val4') )
                {
                    $result .= 'third';
                }
                else
                {
                    $result .= 'nested default';
                }
            }
            else
            {
                $result .= 'fourth';
                if( $context->get('val2') < $context->get('val3') )
                {
                    $result .= 'second';
                }
                elsif( $context->get('val3') < $context->get('val4') )
                {
                    $result .= 'third';
                }
                else
                {
                    $result .= 'nested default';
                }
            }
            $result .= ' test';
            return $result;    
        }
    },
];

my $datasets = [
    {
        'val1' => '1'
        , 'val2' => '2'
        , 'val3' => '3'
        , 'val4' => '4'
    },
    {
        'val1' => '1000'
        , 'val2' => '2'
        , 'val3' => '3'
        , 'val4' => '4'
    },
    {
        'val1' => '1000'
        , 'val2' => '200'
        , 'val3' => '3'
        , 'val4' => '4'
    },
    {
        'val1' => '1000'
        , 'val2' => '200'
        , 'val3' => '30'
        , 'val4' => '4'
    },
    {
        'val1' => '1000'
        , 'val2' => '1000'
        , 'val3' => '1000'
        , 'val4' => '1000'
    },
];

for( my $i = 0; $i < 100; $i++ )
{
    push @$datasets, {
        'val1' => rand(1000)-500,
        'val2' => rand(1000)-500,
        'val3' => rand(1000)-500,
        'val4' => rand(1000)-500,
    };
}

foreach my $tpl (@$templates)
{
    my $template = $tpl->{'template'};
    my $control = $tpl->{'control'};
    
    subtest $template => sub
    {
        foreach my $dataset (@$datasets)
        {
            my @context = ();
            foreach my $key (sort keys %$dataset)
            {
                push @context, sprintf( '%s = %s', $key, $dataset->{$key});
            }
            my $title = '';
            if( scalar @context )
            {
                $title = join('; ', @context);
            }

            $context = new DTL::Fast::Context($dataset);
            is( DTL::Fast::Template->new($template)->render($context), $control->($context), $title);
        }
    };
}




done_testing();
