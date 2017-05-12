#!perl

use Test::Most;
use AnyEvent::Proc;
use Env::Path;

BEGIN {
    delete @ENV{qw{ LANG LANGUAGE }};
    $ENV{LC_ALL} = 'C';
}

plan tests => 2;

my $ok = \( my $x = 0 );

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('cat');
    skip "test, reason: executable 'cat' not available", 2 unless $bin;
    my $proc =
      AnyEvent::Proc->new( bin => $bin, on_exit => sub { $$ok = 1 }, ttl => 5 );
    $proc->fire();
    is $proc->wait() => 0, 'wait ok, status is 0';
    is $$ok          => 1, 'on_exit handler called';
}

done_testing;
