package TestApp::Controller::Root;
use base 'Catalyst::Controller';
use Test::More;

TestApp::Controller::Root->config( namespace => '' );

# apologies to Woody Allen
sub sleeper : Local {
    my ( $self, $c, $l ) = @_;
    $l ||= 0;

    # sleep() may cause alarm() to fail on Win32,
    # so mimic the idea
    my $finish = time() + $l;
    while ( $finish > time() ) {
        1;
    }

    $c->response->output('ok');

    $self->clear($c);
}

sub foo : Global {
    my ( $self, $c ) = @_;

    can_ok( $c, 'alarm' );

    ok( $c->timeout( action => [ 'sleeper', [2] ], timeout => 1 ),
        "sleeper with args" );

    $self->clear($c);

    ok( $c->timeout(
            { action => [ qw/TestApp sleeper/, [2] ], timeout => 1 }
        ),
        "sleeper with everything"
    );

    $self->clear($c);

    # force global alarm to go off
    $c->forward( 'sleeper', [ $c->config->{alarm}->{global} ] );

    ok( $c->alarm->on, "global alarm sounded" );

    $self->clear($c);

}

sub clear {
    my ( $self, $c ) = @_;
    if ( @{ $c->error } ) {

        #warn ".......... found error ...........\n";

        my @e = @{ $c->error };
        if ( grep {m/Alarm/} @e ) {

            #$c->clear_errors;  # newer Cat versions have this
            $c->error(0);
        }
    }
    else {
        $c->log->debug("no error")
            if $c->debug;
    }

    1;
}

1;
