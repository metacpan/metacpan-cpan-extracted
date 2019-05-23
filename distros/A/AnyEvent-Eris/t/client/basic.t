use strict;
use warnings;
use Test::More tests => 4;
use Test::Fatal;
use AnyEvent;

BEGIN { use_ok('AnyEvent::eris::Client') }

subtest 'New without MessageHandler' => sub {
    no strict 'refs';
    no warnings qw<redefine once>;
    local *{'AE::log'} = sub ($$;@) {
        my ( $type, $error ) = @_;
        ::is( $type, 'fatal', 'Fatal error' );
        ::like(
            $error,
            qr/You must provide a MessageHandler/,
            'Must have MessageHandler when creating Client',
        );

        die;
    };

    ok(
        exception { AnyEvent::eris::Client->new() },
        'Exception thrown',
    );
};

subtest 'New with non-code MessageHandler' => sub {
    no strict 'refs';
    no warnings qw<redefine once>;
    local *{'AE::log'} = sub ($$;@) {
        my ( $type, $error ) = @_;
        ::is( $type, 'fatal', 'Fatal error' );
        ::like(
            $error,
            qr/You need to specify a subroutine reference to the 'MessageHandler' parameter/,
            'MessageHandler must be callback',
        );

        die;
    };

    ok(
        exception {
            AnyEvent::eris::Client->new(
                MessageHandler => 1,
            );
        },
        'Exception thrown',
    );
};

subtest 'New with code MessageHandler' => sub {
    my $client;
    is(
        exception {
            $client = AnyEvent::eris::Client->new(
                MessageHandler => sub {1},
            );
        },
        undef,
        'Successfully created Client',
    );

    isa_ok( $client, 'AnyEvent::eris::Client' );
};
