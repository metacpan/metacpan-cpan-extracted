#!/usr/bin/env perl

use FindBin ();
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";
use App::Toot::Test;

my $class = 'App::Toot';
use_ok( $class );

my $status;
App::Toot::Test::override(
    package => 'Mastodon::Client',
    name    => 'post_status',
    subref  => sub {
        my $self = shift;
        $status  = shift;
    },
);

HAPPY_PATH: {
    note( 'happy path' );

    my $status_expected = 'test';
    my $obj = bless { status => $status_expected,
                      client => bless {}, 'Mastodon::Client',
                    }, $class;

    $obj->run();

    is( $status, $status_expected, 'post_status received the expected status' );
}

done_testing();
