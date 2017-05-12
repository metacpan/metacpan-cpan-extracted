#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'scalar1' => <<'_EOT_',
This
is
a

test

_EOT_
});

my $SET = [
    {
        'template' => <<'_EOT_',
{{ scalar1|linenumbers }}
_EOT_
        'test' => <<'_EOT_',
1. This
2. is
3. a
4. 
5. test
6. 

_EOT_
        'title' => 'Simple line numbering',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
