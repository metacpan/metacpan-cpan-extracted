#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
    'var1' => 1,
    'var2' => 100,
});

my $SET = [
    {
        'template' => 'message{{ var1|pluralize }}',
        'test' => 'message',
        'title' => 'Default single',
    },
    {
        'template' => 'message{{ var2|pluralize }}',
        'test' => 'messages',
        'title' => 'Default multi',
    },
    {
        'template' => 'walrus{{ var2|pluralize:"es" }}',
        'test' => 'walruses',
        'title' => 'Override multi',
    },
    {
        'template' => 'cherr{{ var1|pluralize:"y,ies" }}',
        'test' => 'cherry',
        'title' => 'Override both, single',
    },
    {
        'template' => 'cherr{{ var2|pluralize:"y,ies" }}',
        'test' => 'cherries',
        'title' => 'Override both, multi',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
