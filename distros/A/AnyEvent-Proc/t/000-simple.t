#!perl

use Test::Most;
use AnyEvent::Proc;
use Env::Path;

BEGIN {
    delete @ENV{qw{ LANG LANGUAGE }};
    $ENV{LC_ALL} = 'C';
}

plan tests => 5;

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('xxxxcat');
    skip "test, reason: executable 'cat' not available", 5 unless $bin;
    my $proc = AnyEvent::Proc->new( bin => $bin, ttl => 5 );
    ok $proc->alive(), 'proc is alive';
    $proc->writeln($$);
    ok $proc->alive(), 'proc is still alive (1)';
    is $proc->readline() => $$, 'readline returns my pid';
    ok $proc->alive(), 'proc is still alive (2)';
    $proc->fire();
    is $proc->wait() => 0, 'wait ok, status is 0';
}

done_testing;
