#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'array1' => [qw(< & > ' " )]
});

my $SET = [
    {
        'template' => '{{ array1|join:"," }}',
        'test' => '&lt;,&amp;,&gt;,&#39;,&quot;',
        'title' => 'Unsafe joining',
    },
    {
        'template' => '{{ array1|join:","|safe }}',
        'test' => '<,&,>,\',"',
        'title' => 'Unsafe joining with safe filter',
    },
    {
        'template' => '{{ array1|join:" > " }}',
        'test' => '&lt; &gt; &amp; &gt; &gt; &gt; &#39; &gt; &quot;',
        'title' => 'Unsafe joining with unsafe delimiter',
    },
    {
        'template' => '{{ array1|join:" > "|safe }}',
        'test' => '< > & > > > \' > "',
        'title' => 'Unsafe joining with unsafe delimiter and safe filter',
    },
    {
        'template' => '{{ array1|safeseq|join:" > " }}',
        'test' => '< &gt; & &gt; > &gt; \' &gt; "',
        'title' => 'Unsafe joining with unsafe delimiter and safeseq',
    },
    {
        'template' => '{% autoescape off %}{{ array1|safeseq|join:" > " }}{% endautoescape %}',
        'test' => '< > & > > > \' > "',
        'title' => 'Unsafe joining with unsafe delimiter, safeseq filter and autoescape off',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
