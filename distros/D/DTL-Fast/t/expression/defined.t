#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast::Expression;
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

my $dirs = ['./t/tmpl', './t/tmpl2'];

$context = DTL::Fast::Context->new({});

# undef behaviour testing
# @todo other operators checking
$context->set(
    'var1' => 1,
    'var2' => 'string',
    'var3' => 0,
    'var4' => '',
    'var5' => undef
);

my $SET = [
    {
        'test' => 'bingo',
        'template' => '{% if defined var1 %}bingo{% endif %}',
        'title' => 'Positive number checking with defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if defined var2 %}bingo{% endif %}',
        'title' => 'Non-empty string checking with defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if defined var3 %}bingo{% endif %}',
        'title' => 'Zero number checking with defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if defined var4 %}bingo{% endif %}',
        'title' => 'Empty string checking with defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if defined var5 %}bingo{% endif %}bingo',
        'title' => 'Undef variable checking with defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if not defined var1 %}bingo{% endif %}bingo',
        'title' => 'Positive number checking with not defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if not defined var2 %}bingo{% endif %}bingo',
        'title' => 'Non-empty string checking with not defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if not defined var3 %}bingo{% endif %}bingo',
        'title' => 'Zero number checking with not defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if not defined var4 %}bingo{% endif %}bingo',
        'title' => 'Empty string checking with not defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if not defined var5 %}bingo{% endif %}',
        'title' => 'Undef variable checking with not defined'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var1 != undef %}bingo{% endif %}',
        'title' => 'Positive number checking with != undef'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var2 != undef %}bingo{% endif %}',
        'title' => 'Non-empty string checking with != undef'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var3 != undef %}bingo{% endif %}',
        'title' => 'Zero number checking with != undef'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var4 != undef %}bingo{% endif %}',
        'title' => 'Empty string checking with != undef'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var5 != undef %}bingo{% endif %}bingo',
        'title' => 'Undef variable checking with != undef'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var1 != None %}bingo{% endif %}',
        'title' => 'Positive number checking with != None'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var2 != None %}bingo{% endif %}',
        'title' => 'Non-empty string checking with != None'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var3 != None %}bingo{% endif %}',
        'title' => 'Zero number checking with != None'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var4 != None %}bingo{% endif %}',
        'title' => 'Empty string checking with != None'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var5 != None %}bingo{% endif %}bingo',
        'title' => 'Undef variable checking with != None'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var1 != var5 %}bingo{% endif %}',
        'title' => 'Positive number variable compared with undef variable'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var2 != var5 %}bingo{% endif %}',
        'title' => 'Non-empty string variable compared with undef variable'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var3 != var5 %}bingo{% endif %}',
        'title' => 'Zero variable compared with undef variable'
    },
    {
        'test' => 'bingo',
        'template' => '{% if var4 != var5 %}bingo{% endif %}',
        'title' => 'Empty string variable compared with undef variable'
    },
];

foreach my $data (@$SET)
{
    $template = DTL::Fast::Template->new( $data->{'template'} );
    is( $template->render($context), $data->{'test'}, $data->{'title'});
}


done_testing();
