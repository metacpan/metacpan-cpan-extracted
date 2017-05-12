#!/usr/bin/perl
use strict; use warnings FATAL => 'all';
use Test::More;

use DTL::Fast qw(get_template);
use DTL::Fast::Context;
use Data::Dumper;

my( $template, $test_string, $context);

$context = new DTL::Fast::Context({
});

BEGIN {
    no warnings;
    *CORE::GLOBAL::time = sub()
    {
        1420739322
    };
}

# @todo some random testing
my $SET = [
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+30),
        'test' => '',
        'title' => 'Less than a minute',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+90),
        'test' => '1 minute',
        'title' => 'Minute',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+350),
        'test' => '5 minutes',
        'title' => 'Minutes',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+60*60*1+10),
        'test' => '1 hour',
        'title' => 'Minute',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+60*60*7+10),
        'test' => '7 hours',
        'title' => 'Hours',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+60*60*7+60*23+10),
        'test' => '7 hours, 23 minutes',
        'title' => 'Hours and minutes',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+24*60*60*1 + 60*60*7+60*23+10),
        'test' => '1 day, 7 hours',
        'title' => 'Day and hours',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+24*60*60*1 + 60*23+10),
        'test' => '1 day, 23 minutes',
        'title' => 'Day and minutes',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+24*60*60*8 ),
        'test' => '1 week, 1 day',
        'title' => 'Week and day',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+24*60*60*32 ),
        'test' => '1 month, 2 days',
        'title' => 'Month and days',
    },
    {
        'template' => sprintf('{{ %s|timeuntil }}', time+24*60*60*366 ),
        'test' => '1 year, 1 day',
        'title' => 'Year and day',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+30),
        'test' => '',
        'title' => 'Less than a minute',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+90),
        'test' => '1 minute',
        'title' => 'Minute',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+350),
        'test' => '5 minutes',
        'title' => 'Minutes',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+60*60*1+10),
        'test' => '1 hour',
        'title' => 'Minute',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+60*60*7+10),
        'test' => '7 hours',
        'title' => 'Hours',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+60*60*7+60*23+10),
        'test' => '7 hours, 23 minutes',
        'title' => 'Hours and minutes',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+24*60*60*1 + 60*60*7+60*23+10),
        'test' => '1 day, 7 hours',
        'title' => 'Day and hours',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+24*60*60*1 + 60*23+10),
        'test' => '1 day, 23 minutes',
        'title' => 'Day and minutes',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+24*60*60*8 ),
        'test' => '1 week, 1 day',
        'title' => 'Week and day',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+24*60*60*32 ),
        'test' => '1 month, 2 days',
        'title' => 'Month and days',
    },
    {
        'template' => sprintf('{{ %s|timeuntil:1420739322 }}', 1420739322+24*60*60*366 ),
        'test' => '1 year, 1 day',
        'title' => 'Year and day',
    },
];

foreach my $data (@$SET)
{
    is( DTL::Fast::Template->new($data->{'template'})->render($context), $data->{'test'}, $data->{'title'});
    
}

done_testing();
