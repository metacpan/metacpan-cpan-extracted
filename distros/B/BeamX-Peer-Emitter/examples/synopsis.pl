#!/usr/bin/perlperl

use strict;
use warnings;

use 5.10.0;
use Safe::Isa;

sub fmt_msg {
    $_[0]->$_isa( 'Beam::Event' )
      ? sprintf( "received event '%s' from node %s", $_[0]->name, $_[0]->emitter->id )
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

    sub recv {

        my $self = shift;

        say $self->id, ': ', &::fmt_msg;
    }

}

my $n1 = Node->new( id => 'N1' );
my $n2 = Node->new( id => 'N2' );


# standard Beam::Emitter event
$n1->subscribe( 'alert', sub { say 'non-peer: ', &fmt_msg  } );

# explicit peer event
$n1->subscribe( 'alert', sub { $n2->recv( @_ ) }, peer => $n2 );

say "Broadcast Event object:";
$n1->emit( 'alert' );

say "\nSend Event object directly to \$n2";
$n1->send( $n2, 'alert' );

say "\nBroadcast arbitrary args";
$n1->emit_args( 'alert', q[Server's Down!] );

say "\nSend arbitrary args directly to \$n2";
$n1->send_args( $n2, 'alert', q[Let's get coffee!] );
