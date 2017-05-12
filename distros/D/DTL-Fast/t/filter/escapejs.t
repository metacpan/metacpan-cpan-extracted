#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => <<'_EOT_',
this
is
'multi	-	line'
"string"
_EOT_
    'var2' => <<'_EOT_',
this
is
'multi	-	line'
"string"
_EOT_
});

my $SET = [
    {
        'template' => '{{ var1|escapejs }}',
        'test' => 'this\nis\n\'multi\t-\tline\'\n\"string\"\n',
        'title' => 'Newlines, tabs and quotes',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
