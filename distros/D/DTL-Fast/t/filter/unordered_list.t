#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;use utf8;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

local $SIG{__WARN__} = sub {};

$context = new DTL::Fast::Context({
    'array1' => [
        'one >'
        , 'two <'
        , 'three &'
        , 'four "'
    ]
    , 'array2' => [
        'five'
        , 'six'
        , 'seven'
        , [
            'eight'
            , 'nine'
            , 'ten'
        ]
    ]
});

push @{$context->get('array2')}, $context->get('array2');

# @todo some random testing
my $SET = [
    {
        'template' => '{{ array1|unordered_list }}',
        'test' => <<'_EOT_',
	<li>one &gt;</li>
	<li>two &lt;</li>
	<li>three &amp;</li>
	<li>four &quot;</li>
_EOT_
        'title' => 'Simple list with escaped elements',
    },
    {
        'template' => '{{ array1|safeseq|unordered_list }}',
        'test' => <<'_EOT_',
	<li>one ></li>
	<li>two <</li>
	<li>three &</li>
	<li>four "</li>
_EOT_
        'title' => 'Simple list with safeseq',
    },
    {
        'template' => '{{ array1|safeseq|unordered_list|escape }}',
        'test' => <<'_EOT_',
	&lt;li&gt;one &gt;&lt;/li&gt;
	&lt;li&gt;two &lt;&lt;/li&gt;
	&lt;li&gt;three &amp;&lt;/li&gt;
	&lt;li&gt;four &quot;&lt;/li&gt;
_EOT_
        'title' => 'Simple list with safeseq and escape',
    },
    {
        'template' => '{{ array2|safeseq|unordered_list }}',
        'test' => <<'_EOT_',
	<li>five</li>
	<li>six</li>
	<li>seven</li>
	<ul>
		<li>eight</li>
		<li>nine</li>
		<li>ten</li>
	</ul>
_EOT_
        'title' => 'Nested lists with safeseq',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
