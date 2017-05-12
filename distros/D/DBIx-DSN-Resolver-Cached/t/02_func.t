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
    plan tests => 3;
}

like dsn_resolver("dbi:mysql:database=mytbl;host=google.com"),
    qr/^dbi:mysql:database=mytbl;host=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/;

set_dummy(1);
like dsn_resolver("dbi:mysql:database=mytbl;host=google.com"),
    qr/^dbi:mysql:database=mytbl;host=[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/, 'cached';


local $DBIx::DSN::Resolver::Cached::RESOLVER = DBIx::DSN::Resolver::Cached->new();
eval {
    dsn_resolver("dbi:mysql:database=mytbl;host=google.com");
};
like $@, qr/DUMMY/;
