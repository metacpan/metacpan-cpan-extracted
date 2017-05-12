# Benchmark BSD::Socket::Splice by comparing to setsockopt()
# and $s->setsockopt().  The xs module must be faster.

use strict;
use warnings;
use Time::HiRes;
use Benchmark qw(:hireswallclock :all);
use IO::Socket;
use constant SO_SPLICE => 0x1023;
use BSD::Socket::Splice qw(setsplice getsplice);

use Test::More tests => 2;

my $sl = IO::Socket::INET->new(
    Proto => "tcp",
    Listen => 5,
    LocalAddr => "127.0.0.1",
) or die "socket listen failed: $!";

my $s = IO::Socket::INET->new(
    Proto => "tcp",
    PeerAddr => $sl->sockhost(),
    PeerPort => $sl->sockport(),
) or die "socket connect failed: $!";

my $ss = IO::Socket::INET->new(
    Proto => "tcp",
    PeerAddr => $sl->sockhost(),
    PeerPort => $sl->sockport(),
) or die "socket splice connect failed: $!";

sub do_handleopt {
    $s->setsockopt(SOL_SOCKET, SO_SPLICE, pack('i', $ss->fileno()))
	or die "sethandleopt splice: $!";
    $s->setsockopt(SOL_SOCKET, SO_SPLICE, pack('i', -1))
	or die "sethandleopt unsplice: $!";
    defined($s->getsockopt(SOL_SOCKET, SO_SPLICE))
	or die "gethandleopt: $!";
}

sub do_sockopt {
    setsockopt($s, SOL_SOCKET, SO_SPLICE, pack('i', $ss->fileno()))
	or die "setsockopt splice: $!";
    setsockopt($s, SOL_SOCKET, SO_SPLICE, pack('i', -1))
	or die "setsockopt unsplice: $!";
    defined(getsockopt($s, SOL_SOCKET, SO_SPLICE))
	or die "getsockopt: $!";
}

sub do_splice {
    setsplice($s, $ss)
	or die "setsplice splice: $!";
    setsplice($s)
	or die "setsplice unsplice: $!";
    defined(getsplice($s))
	or die "getsplice: $!";
}

my $count = -3;
my $result = timethese($count, {
    handleopt => \&do_handleopt,
    sockopt   => \&do_sockopt,
    splice    => \&do_splice,
});

cmpthese($result);

sub user {
	return $_[0][1] / $_[0]->iters;
}

cmp_ok(user($result->{splice}), '<', user($result->{sockopt}),
    "BSD::Socket::Splice setsplice faster than CORE setsockopt");
cmp_ok(user($result->{splice}), '<', user($result->{handleopt}),
    "BSD::Socket::Splice setsplice faster than IO::Socket setsockopt");
