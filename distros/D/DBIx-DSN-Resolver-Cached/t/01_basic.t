use strict;
use Test::More;

BEGIN {
    my $dummy;
    sub get_dummy {
        $dummy;
    }
    sub set_dummy {
        $dummy = shift;
    }
    *CORE::GLOBAL::gethostbyname = sub {
        die "DUMMY" if get_dummy();
        CORE::gethostbyname(@_);
    };
}

use DBIx::DSN::Resolver::Cached;

my ($name,$aliases,$addrtype,$length,@addrs)= gethostbyname("google.com");

if( !$name or $length == 1 ) {
    plan skip_all => 'couldnot resolv google.com';
}
else {
    plan tests => 23;
}

my $r = DBIx::DSN::Resolver::Cached->new(
    ttl => 30,
);
ok($r);

like $r->resolv("dbi:mysql:database=mytbl;host=google.com"),
    qr/^dbi:mysql:database=mytbl;host=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/;

set_dummy(1);

my @dsn;
for ( 1..20 ) {
    my $d = $r->resolv("dbi:mysql:database=mytbl;host=google.com");
    ok($d);
    push @dsn, $d;
}
my %dsn;
$dsn{$_} = 1 for @dsn;
is( scalar keys %dsn, scalar @addrs);


