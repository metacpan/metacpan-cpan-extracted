use strict; use warnings;

package Song;

use Class::Observable;
our @ISA = 'Class::Observable';

sub new {
    my ( $class, $band, $name ) = @_;
    my $self = bless( {}, $class );
    $self->{band} = $band;
    $self->{name} = $name;
    return $self;
}

sub play {
    my ( $self ) = @_;
    $self->notify_observers( 'start_play' );
    #print "Playing [$self->{name}] by [$self->{band}]\n";
    $self->stop;
}

sub stop {
    my ( $self ) = @_;
    #print "Stopped [$self->{name}] by [$self->{band}]\n";
    $self->notify_observers( 'stop_play' );
}

1;
