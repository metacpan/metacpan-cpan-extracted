use strict;
use warnings;
use FindBin::libs;
use Test::More;
use Test::Backbone::Events::Utils;

my $handler = test_handler();

my $event = 'ns:test-event';
my %triggered;
$handler->on($event,    sub { $triggered{exact}  = \@_ });
$handler->on('ns:all',  sub { $triggered{ns_all} = \@_ });
$handler->on('all',     sub { $triggered{all}    = \@_ });
$handler->on('bad:all', sub { $triggered{bad}    = \@_ });

my @args  = qw(arg1 arg2);
$handler->trigger($event, @args);

is_deeply $triggered{exact},  [@args];
is_deeply $triggered{ns_all}, [$event, @args];
is_deeply $triggered{all},    [$event, @args];
is $triggered{bad}, undef;

done_testing;
