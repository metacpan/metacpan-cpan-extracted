package AnyEvent::DAAP::Server::Track;
use Any::Moose;
use Net::DAAP::DMAP;

# from Net::DAAP::Server::Track
our @Attributes = qw(
    dmap_itemid dmap_itemname dmap_itemkind dmap_persistentid
    daap_songalbum daap_songartist daap_songbitrate
    daap_songbeatsperminute daap_songcomment daap_songcompilation
    daap_songcomposer daap_songdateadded daap_songdatemodified
    daap_songdisccount daap_songdiscnumber daap_songdisabled
    daap_songeqpreset daap_songformat daap_songgenre
    daap_songdescription daap_songrelativevolume daap_songsamplerate
    daap_songsize daap_songstarttime daap_songstoptime daap_songtime
    daap_songtrackcount daap_songtracknumber daap_songuserrating
    daap_songyear daap_songdatakind daap_songdataurl
    com_apple_itunes_norm_volume
    daap_songgrouping daap_songcodectype daap_songcodecsubtype
    com_apple_itunes_itms_songid com_apple_itunes_itms_artistid
    com_apple_itunes_itms_playlistid com_apple_itunes_itms_composerid
    com_apple_itunes_itms_genreid
    dmap_containeritemid
);

has dmap_itemid => (
    is  => 'rw',
    isa => 'Int',
    default => sub { 0+$_[0] & 0xFFFFFF },
);

has $_, is => 'rw' for @Attributes;

__PACKAGE__->meta->make_immutable;

no Any::Moose;

sub _dmap_field {
    my ($self, $name) = @_;
    $name =~ s/[.-]/_/g;
    return $self->{$name};
}

sub allow_range { 0 }

sub stream {
    my ($self, $connection, $req) = @_;
    my ($response, $pos) = $self->parse_request($req);
    $self->write_data($connection, $response, $pos);
}

sub parse_request {
    my ($self, $req) = @_;

    my $pos;

    if (my $range = $req->header('Range')) {
        # To make things simple, assume Range: header is sent only as Range: bytes={start}-
        if ($range =~ /^bytes=(\d+)-/) {
            $pos = $1;
        } elsif ($range) {
            warn qq(Cannot handle range: '$range');
        }
    }

    my ($code, $message) = $pos ? ( 206, 'Partial Content' ) : ( 200, 'OK' );
    my $res = HTTP::Response->new($code, $message, [ Connection => 'close' ]);
    $res->header(Content_Range => "bytes $pos-/*") if $pos;
    $res->header(Accept_Ranges => 'bytes') if $self->allow_range;

    return ($res, $pos);
}

sub write_data {
    my ($self, $connection, $res, $pos) = @_;

    my $data = $self->data($pos);
    $res->content($data);
    $res->content_length(length $data);
    $self->push_response($connection, $res);
}

sub data {
    my ($self, $pos) = @_;
    die 'implement $self->data() or override $self->write_data()';
    # return $data;
}

sub push_response {
    my ($self, $connection, $res) = @_;
    $connection->handle->push_write(
        'HTTP/1.1 ' . $res->as_string("\r\n")
    );
    $connection->handle->push_shutdown;
}

1;

__END__

=head1 NAME

AnyEvent::DAAP::Server::Track - Base class of daap tracks

=head1 DESCRIPTION

This class abstractly represents one track.
Usually you will want to use L<AnyEvent::DAAP::Server::Track::File::MP3> for local mp3 files.

=head1 METHODS

=over 4

=item my $data = $track->data([ $pos ]);

Abstract method. Should return track's music data immediately.
If $track allows ranged request, the $pos parameter may be supplied. If so, $track should
return data from the position at $pos byte.

=item my $bool = $track->allow_range;

Override this to return true if this track allows ranged request (i.e. skip/pause). Defaults to return 0.

=item $track->write_data($connection, $res, $pos);

Override this method if you want to send data to clients asynchronously.

$connection argument is an L<AnyEvent::DAAP::Server::Connection>.
$connection->handle is an L<AnyEvent::Handle> so call $connection->handle->push_write() this to send data.

$res argument is partially filled L<HTTP::Response>, without $res->content and $res->content_length.

$pos argument is requested start-position of music data or undef.

After writing all data, you should send $connection->handle->push_shutdown().

=item $track->daap_***, $track->dmap_***

Read L<AnyEvent::DAAP::Server::Track::File::MP3>'s source to grab what these mean.

=back

=head1 AUTHOR

motemen E<lt>motemen@gmail.comE<gt>

=head1 SEE ALSO

L<AnyEvent::DAAP::Server::Track::File::MP3>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
