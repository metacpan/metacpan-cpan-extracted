#!perl

use strict;
use warnings;

use 5.10.0;

use Test::More;

use Safe::Isa;

sub fmt_msg {
    $_[0]->$_isa( 'Beam::Event' )
      ? sprintf( "event '%s' from node %s", $_[0]->name, $_[0]->emitter->id )
      : join( ' ', @_ );
}

package Node {

    use Safe::Isa;
    use Moo;
    with 'BeamX::Peer::Emitter';

    has id => (
        is       => 'ro',
        required => 1,
    );

    has recvd => (
        is      => 'ro',
        default => sub { [] },
        lazy    => 1,
        clearer => 1
    );

    sub recv {

        my $self = shift;
        push @{ $self->recvd }, &::fmt_msg;
    }

}

my @broadcast;

my $n1 = Node->new( id => 'N1' );
my $n2 = Node->new( id => 'N2' );


# standard Beam::Emitter event
$n1->subscribe( 'alert', sub { push @broadcast, &fmt_msg }  );

# explicit peer event
$n1->subscribe( 'alert', sub { $n2->recv( @_ ) }, peer => $n2 );

subtest "Emit" => sub {
    @broadcast = ();
    $n2->clear_recvd;

    $n1->emit( 'alert' );

    is_deeply(
        \@broadcast,
        [q<event 'alert' from node N1>],
        "non-peer receipt"
    );

    is_deeply( $n2->recvd, [q<event 'alert' from node N1>],
        "n2 receipt" );

};

subtest "Send" => sub {
    @broadcast = ();
    $n2->clear_recvd;

    $n1->send( $n2, 'alert' );

    is_deeply( \@broadcast, [], "non-peer: no receipt" );

    is_deeply( $n2->recvd, [q<event 'alert' from node N1>],
        "n2 receipt" );

};

subtest "Emit args" => sub {

    @broadcast = ();
    $n2->clear_recvd;

    $n1->emit_args( 'alert', q[Server's Down!] );

    is_deeply(
        \@broadcast,
        [q<Server's Down!>],
        "non-peer receipt"
    );

    is_deeply( $n2->recvd, [q<Server's Down!>], "n2 receipt" );
};

subtest "Send args" => sub {

    @broadcast = ();
    $n2->clear_recvd;

    $n1->send_args( $n2, 'alert', q[Let's get coffee!] );
    is_deeply( \@broadcast, [], "non-peer: no receipt" );
    is_deeply( $n2->recvd, [q<Let's get coffee!>], "n2 receipt" );

};

done_testing;
