package AnyEvent::DAAP::Server::Track::File::MP3;
use Any::Moose;
use MP3::Info;
use File::Basename;
use HTTP::Response;

extends 'AnyEvent::DAAP::Server::Track';

has file => (
    is  => 'rw',
    isa => 'Str',
    required => 1,
);

__PACKAGE__->meta->make_immutable;

no Any::Moose;

# from Net::DAAP::Server::Track
sub BUILD {
    my $self = shift;
    my $file = $self->file;
    my @stat = stat $file;
    $self->dmap_itemid( $stat[1] ); # the inode should be good enough
    $self->dmap_containeritemid( 0+$self );

    $self->dmap_itemkind( 2 ); # music
    $self->dmap_persistentid( $stat[1] ); # blah, this should be some 64 bit thing
    $self->daap_songbeatsperminute( 0 );

    # All mp3 files have 'info'. If it doesn't, give up, we can't read it.
    if (my $info = MP3::Info::get_mp3info( $file )) {
        $self->daap_songbitrate( $info->{BITRATE} );
        $self->daap_songsamplerate( $info->{FREQUENCY} * 1000 );
        $self->daap_songtime( $info->{SECS} * 1000 );
    }

    # read the tag if we can, fall back to very simple data otherwise.
    my $tag = MP3::Info::get_mp3tag( $file ) || {};
    $self->dmap_itemname( $tag->{TITLE} || basename($file, ".mp3") );
    $self->daap_songalbum( $tag->{ALBUM} );
    $self->daap_songartist( $tag->{ARTIST} );
    $self->daap_songcomment( $tag->{COMMENT} );
    $self->daap_songyear( $tag->{YEAR} || undef );
    my ($number, $count) = split m{/}, ($tag->{TRACKNUM} || "");
    $self->daap_songtrackcount( $count || 0);
    $self->daap_songtracknumber( $number || 0 );

    # from blech:
    # if ($rtag->{TCP} || $rtag->{TCMP}) {
    #     $artist = 'various artists';
    # }
    #
    $self->daap_songcompilation( 0 );
    # $self->daap_songcomposer( );
    $self->daap_songdateadded( $stat[10] );
    $self->daap_songdatemodified( $stat[9] );
    $self->daap_songdisccount( 0 );
    $self->daap_songdiscnumber( 0 );
    $self->daap_songdisabled( 0 );
    $self->daap_songeqpreset( '' );
    $file =~ m{\.(.*?)$};
    $self->daap_songformat( $1 );
    $self->daap_songgenre( '' );
    $self->daap_songgrouping( '' );
    # $self->daap_songdescription( );
    # $self->daap_songrelativevolume( );
    $self->daap_songsize( -s $file );
    $self->daap_songstarttime( 0 );
    $self->daap_songstoptime( 0 );

    $self->daap_songuserrating( 0 );
    $self->daap_songdatakind( 0 );
    # $self->daap_songdataurl( );
    $self->com_apple_itunes_norm_volume( 17502 );

    # $self->daap_songcodectype( 1836082535 ); # mp3?
    # $self->daap_songcodecsubtype( 3 ); # or is this mp3?
}

sub allow_range { 1 }

sub data {
    my ($self, $pos) = @_;

    open my $fh, '<', $self->file or die $!; # TODO error handling
    my $data = do { local $/; <$fh> };
    
    $pos ||= 0;
    return substr($data, $pos);
}

1;
