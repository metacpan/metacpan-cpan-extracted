#!/usr/bin/env perl

use FindBin ();
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";
use App::Toot::Test;

my $class = 'App::Toot::Config';
use_ok( $class );

use constant {
    EXPECTED_CONFIG => {
        default => {
            instance      => 'masto.don.test',
            username      => 'test',
            client_id     => '12345',
            client_secret => '67890',
            access_token  => 'abcde'
        },
    },
};

App::Toot::Test::override(
    package => 'App::Toot::Config',
    name    => '_load_and_verify',
    subref  => sub { return EXPECTED_CONFIG() },
);

HAPPY_PATH: {
    note( 'happy path' );

    my $section = 'default';
    my $config = $class->load($section);

    is_deeply( $config, EXPECTED_CONFIG()->{$section}, 'expected config section is returned' );
}

done_testing();

