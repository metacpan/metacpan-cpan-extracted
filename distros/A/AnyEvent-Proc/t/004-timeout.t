#!perl

use Test::Most;
use AnyEvent::Proc;
use Env::Path;

BEGIN {
    delete @ENV{qw{ LANG LANGUAGE }};
    $ENV{LC_ALL} = 'C';
}

plan tests => 4;

my $proc;

my $on_ttl = sub { fail('ttl exceeded') };

SKIP: {
    my ($bin) = Env::Path->PATH->Whence('cat');
    skip "test, reason: executable 'cat' not available", 4 unless $bin;

    $proc = AnyEvent::Proc->new(
        bin           => $bin,
        timeout       => 1,
        ttl           => 5,
        on_ttl_exceed => $on_ttl
    );
    is $proc->wait() => 0, 'timeout';

    $proc = AnyEvent::Proc->new(
        bin           => $bin,
        wtimeout      => 1,
        ttl           => 5,
        on_ttl_exceed => $on_ttl
    );
    is $proc->wait() => 0, 'wtimeout';

    $proc = AnyEvent::Proc->new(
        bin           => $bin,
        rtimeout      => 1,
        ttl           => 5,
        on_ttl_exceed => $on_ttl
    );
    is $proc->wait() => 0, 'rtimeout';

    $proc = AnyEvent::Proc->new(
        bin           => $bin,
        etimeout      => 1,
        ttl           => 5,
        on_ttl_exceed => $on_ttl
    );
    is $proc->wait() => 0, 'etimeout';
}

done_testing;
