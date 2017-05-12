use strict;
use warnings;
use Errno;
use IO::Socket;
use BSD::Socket::Splice qw(setsplice getsplice geterror);

use Test::More tests => 15;

my $sl = IO::Socket::INET->new(
    Proto => "tcp",
    Listen => 1,
    LocalAddr => "127.0.0.1",
) or die "server listen failed: $!";

my $rc = IO::Socket::INET->new(
    Proto => "tcp",
    PeerAddr => $sl->sockhost(),
    PeerPort => $sl->sockport(),
) or die "relay connect failed: $!";

my $rl = IO::Socket::INET->new(
    Proto => "tcp",
    Listen => 1,
    LocalAddr => "127.0.0.1",
) or die "relay listen failed: $!";

my $cc = IO::Socket::INET->new(
    Proto => "tcp",
    PeerAddr => $rl->sockhost(),
    PeerPort => $rl->sockport(),
) or die "client connect failed: $!";

my $ra = $rl->accept() or die "relay accept failed: $!";
my $sa = $sl->accept() or die "server accept failed: $!";

ok(defined(setsplice($ra, $rc)), "relay setsplice")
    or diag "relay setsplice failed: $!";
$cc->print("foo\n") or die "client print failed: $!";
is($sa->getline(), "foo\n", "server getline");
is(getsplice($ra), 4, "relay getsplice");
is(geterror($ra), 0, "relay geterror");

ok(defined(setsplice($ra)), "relay unsplice")
    or diag "relay unsplice failed: $!";

ok(defined(setsplice($ra, $rc, 4)), "relay setsplice max")
    or diag "relay setsplice max failed: $!";
$cc->print("foo\nbar\n") or die "client print max failed: $!";
# XXX ignore the short splice problem
is($sa->getline(), "foo\n", "server getline max");
is(getsplice($ra), 4, "relay getsplice max");
is(geterror($ra), Errno::EFBIG, "relay max geterror");
is($ra->getline(), "bar\n", "relay getline max");

ok(defined(setsplice($ra, $rc, undef, .1)), "relay setsplice idle")
    or diag "relay setsplice idle failed: $!";
$cc->print("foo\n") or die "client print before idle failed: $!";
sleep 1;
$cc->print("bar\n") or die "client print after idle failed: $!";
is($sa->getline(), "foo\n", "server getline idle");
is(getsplice($ra), 4, "relay getsplice idle");
is(geterror($ra), Errno::ETIMEDOUT, "relay idle geterror");
is($ra->getline(), "bar\n", "relay getline idle");
