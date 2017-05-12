use strict;
use warnings;

use Test::More 0.88;

BEGIN {
    plan skip_all => "no /dev/random and /dev/urandom" unless -e "/dev/random" and -e "/dev/urandom";
}

use Errno;
use ok 'Crypt::Random::Source::Strong::devrandom';
use ok 'Crypt::Random::Source::Weak::devurandom';

{
    ok( Crypt::Random::Source::Strong::devrandom->available, "/dev/random is available" );

    my $p = Crypt::Random::Source::Strong::devrandom->new;

    isa_ok( $p, "Crypt::Random::Source::Strong" );
    isa_ok( $p, "Crypt::Random::Source::Base::RandomDevice" );
    isa_ok( $p, "Crypt::Random::Source::Base::Handle" );
    isa_ok( $p, "Crypt::Random::Source::Strong::devrandom" );

    $p->blocking(0);

    ok( $p->is_strong, "it's a strong source" );

    can_ok( $p, "get" );

    if ( length( my $buf = $p->get(100) ) ) { # blocking
        cmp_ok( length($buf), '<=', 100, "got up to 100 bytes" );

        # this test should fail around every few universes or so ;-)
        cmp_ok( $buf, 'ne', $p->get(length($buf)), "random data differs" );
    } else {
        ok( $!{EWOULDBLOCK} || $!{EAGAIN}, "would have blocked" )
            or diag "errno is $! (" . ($! + 0) . ')';
    }

    can_ok($p, "seed");
}

{
    ok( Crypt::Random::Source::Weak::devurandom->available, "/dev/random is available" );

    my $p = Crypt::Random::Source::Weak::devurandom->new;

    isa_ok( $p, "Crypt::Random::Source::Weak" );
    isa_ok( $p, "Crypt::Random::Source::Base::RandomDevice" );
    isa_ok( $p, "Crypt::Random::Source::Base::Handle" );
    isa_ok( $p, "Crypt::Random::Source::Weak::devurandom" );

    ok( !$p->is_strong, "it's a weak source" );

    can_ok( $p, "get" );

    my $buf = $p->get(100);

    is( length($buf), 100, "got 100 bytes" );

    # this test should fail around every few universes or so ;-)
    cmp_ok( $buf, 'ne', $p->get(length($buf)), "random data differs" );

    can_ok($p, "seed");
}

done_testing;
# ex: set sw=4 et:
