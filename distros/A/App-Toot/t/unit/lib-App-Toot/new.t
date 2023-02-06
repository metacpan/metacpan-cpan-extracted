#!/usr/bin/env perl

use FindBin ();
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";
use App::Toot::Test;

my $class = 'App::Toot';
use_ok( $class );

use constant {
    EXPECTED_ARGS => {
        config => 'test',
        status => 'test',
    },
    EXPECTED_CONFIG => {
        instance      => 'masto.don.test',
        username      => 'test',
        client_id     => '12345',
        client_secret => '67890',
        access_token  => 'abcde'
    },
};

App::Toot::Test::override(
    package => 'Mastodon::Client',
    name    => 'new',
    subref  => sub { return bless {}, 'Mastodon::Client' },
);

App::Toot::Test::override(
    package => 'App::Toot::Config',
    name    => 'load',
    subref  => sub { return EXPECTED_CONFIG },
);

CONSTRUCTOR: {
    note( 'constructor' );

    my $obj = $class->new( EXPECTED_ARGS );
    isa_ok( $obj, $class );

    foreach my $method (qw{ run }) {
        ok( $obj->can($method), "An object of class '$class' can '$method'" );
    }

    foreach my $key (qw{ config status client }) {
        ok( defined $obj->{$key}, "An object of class '$class' has '$key'" );
    }

    is_deeply( $obj->{'config'}, EXPECTED_CONFIG, 'object contains expected config' );
    is( $obj->{'status'}, EXPECTED_ARGS()->{'status'}, 'object contains expected status' );
    is( ref $obj->{'client'}, 'Mastodon::Client', 'object contains expected client' );
}

MISSING_ARGS: {
    note( 'missing args' );

    my $args = EXPECTED_ARGS;
    foreach my $arg ( sort keys %$args ) {
        my $exception = "$arg is required";
        my $value = delete $args->{$arg};
        dies_ok { $class->new($args) } "dies if $arg is missing";
        like $@, qr/$exception/, "exception indicates $exception";
        $args->{$arg} = $value;
    }
}

done_testing();
