#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
});

my $SET = [
    {
        'template' => '{{ "this is a text with some sexy words"|wordwrap:10 }}',
        'test' => <<'_EOT_',
this is a
text with
some sexy
words
_EOT_
        'title' => '10 characters',
    },
    {
        'template' => '{{ "this is a text with some sexy words"|wordwrap:9 }}',
        'test' => <<'_EOT_',
this is a
text with
some sexy
words
_EOT_
        'title' => '9 characters',
    },
    {
        'template' => '{{ "this is a text with some sexy words"|wordwrap:8 }}',
        'test' => <<'_EOT_',
this is
a text
with
some
sexy
words
_EOT_
        'title' => '8 characters',
    },
    {
        'template' => '{{ "this is a text withsome sexy words"|wordwrap:8 }}',
        'test' => <<'_EOT_',
this is
a text
withsome
sexy
words
_EOT_
        'title' => '8 characters and long word',
    },
];

foreach my $data (@$SET)
{
    my $test = $data->{'test'};
    chomp $test;
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $test, $data->{'title'});
}

done_testing();
