package AuthRealmTestAppCompat::Controller::Root;
use warnings;
use strict;
use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

use Test::More;
use Test::Exception;

sub moose : Local {
    my ( $self, $c ) = @_;

    while ( my ($user, $info) = each %$AuthRealmTestAppCompat::members ) {

        my $ok = eval {
            $c->authenticate(
                { username => $user, password => $info->{password} },
                'members'
            ),
        };

        ok( !$@,                "Test did not die: $@" );
        ok( $ok,                "user $user authentication" );
    }

    $c->res->body( "ok" );
}

1;

