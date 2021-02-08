use strict; use warnings;

package DeeJay;

sub new {
    my ( $class, $playlist ) = @_;
    $playlist ||= [];
    my $self = bless( {}, $class );
    $self->{playlist} = $playlist;
    $self->{num_songs} = scalar @{ $playlist };
    return $self;
}

sub start_party {
    my ( $self ) = @_;
    #print "Let's get this party started!\n";
    $self->{current_song} = 0;
    $self->{playlist}[0]->play;
}

sub end_party {
    my ( $self ) = @_;
    #print "Party's over, time to go home\n";
}

sub update {
    my ( $self, $song, $action ) = @_;
    #print "Caught update [$action] from [$song->{band}]\n";
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

package DeeJay::Selfish;

# This DJ only responds to his/her own songs

sub new {
    my ( $class, $my_name ) = @_;
    return bless( { name        => $my_name,
                    update      => 0,
                    update_self => 0 }, $class );
}

sub update {
    my ( $self, $song ) = @_;
    $self->{update}++;
    #print "I am [$self->{name}] song is [$song->{band}]\n";
    $self->{update_self}++ if ( $song->{band} eq $self->{name} );
}

sub num_updates      { return $_[0]->{update} }
sub num_updates_self { return $_[0]->{update_self} }

package DeeJay::Helper;

sub new { return bless( {}, $_[0] ) }

sub update {
    my ( $self, $song ) = @_;
    $self->{update}++;
}

sub num_updates { return $_[0]->{update} }

1;
