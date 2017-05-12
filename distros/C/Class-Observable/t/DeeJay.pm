package DeeJay;

# $Id: DeeJay.pm,v 1.3 2004/10/16 16:48:50 cwinters Exp $

use strict;

sub new {
    my ( $class, $playlist, $log ) = @_;
    $playlist ||= [];
    return bless( {
        playlist  => $playlist,
        num_songs => scalar @{ $playlist },
        $log      => $log,
    }, $class );
}

sub start_party {
    my ( $self ) = @_;
    $self->{log} &&
        $self->{log}->( "Let's get this party started!" );
    $self->{current_song} = 0;
    $self->{playlist}[0]->play;
}

sub end_party {
    my ( $self ) = @_;
    $self->{log} &&
        $self->{log}->( "Party's over, time to go home" );
}

sub update {
    my ( $self, $song, $action ) = @_;
    $self->{log} &&
        $self->{log}->( "Caught update [$action] from [$song->{band}]" );
    $self->{update}++;
    return unless ( $action eq 'stop_play' );
    $self->{update_stop}++;
    $self->{current_song}++;
    if ( $self->{current_song} == $self->{num_songs} ) {
        return $self->end_party;
    }
    $self->{playlist}[ $self->{current_song} ]->play;
}

sub num_updates      { return $_[0]->{update} }
sub num_updates_stop { return $_[0]->{update_stop} }

sub DESTROY {
    my ( $self ) = @_;
    $self->{log} &&
        $self->{log}->( "DeeJay retiring" );
}

1;

package DeeJay::Selfish;

# This DJ only responds to his/her own songs

use strict;

sub new {
    my ( $class, $my_name, $log ) = @_;
    return bless({
        name        => $my_name,
        update      => 0,
        update_self => 0,
        log         => $log,
    }, $class );
}

sub update {
    my ( $self, $song ) = @_;
    $self->{update}++;
    $self->{log} &&
        $self->{log}->( "I am '$self->{name}' song is '$song->{band}'" );
    $self->{update_self}++ if ( $song->{band} eq $self->{name} );
}

sub num_updates      { return $_[0]->{update} }
sub num_updates_self { return $_[0]->{update_self} }

package DeeJay::Helper;

use strict;

sub new {
    my ( $class, $log ) = @_;
    return bless({
        log => $log,
    }, $class );
}

sub update {
    my ( $self, $song ) = @_;
    $self->{update}++;
}

sub num_updates { return $_[0]->{update} }

1;
