#!perl

use Test::Most;
use AnyEvent::Proc;
use Env::Path;

BEGIN {
    delete @ENV{qw{ LANG LANGUAGE }};
    $ENV{LC_ALL} = 'C';
}

plan tests => 2;

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('cat');
    skip "test, reason: executable 'cat' not available", 1 unless $bin;
    my $ok   = 0;
    my $proc = AnyEvent::Proc->new(
        bin           => $bin,
        ttl           => 1,
        on_ttl_exceed => sub { $ok = 1 }
    );
    is $proc->wait() => 0, 'wait ok, status is 0';
    is $ok           => 1, 'ttl exceeded';
}

done_testing;
