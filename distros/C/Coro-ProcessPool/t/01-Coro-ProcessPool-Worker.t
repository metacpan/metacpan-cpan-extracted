use strict;
use warnings;
use Test::More;
use Coro;
use Coro::AnyEvent;

BAIL_OUT 'MSWin32 is not supported' if $^O eq 'MSWin32';

BEGIN { use AnyEvent::Impl::Perl }

my $class = 'Coro::ProcessPool::Worker';

my $doubler = sub {
    my $x = shift;
    return $x * 2;
};

use_ok($class) or BAIL_OUT;

note 'process_task';
{
    my $success = [$class->process_task($doubler, [21])];
    is_deeply($success, [0, 42], 'code ref-based task produces expected result');

    my $croaker = sub { die "TEST MESSAGE" };
    my $failure = [$class->process_task($croaker, [])];
    is($failure->[0], 1, 'error generates correct code');
    like($failure->[1], qr/TEST MESSAGE/, 'stack trace includes error message');

    my $result = [$class->process_task('t::TestTask', [])];
    is_deeply($result, [0, 42], 'class-based task produces expected result');
};

done_testing;
