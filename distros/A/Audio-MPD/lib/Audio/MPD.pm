#
# This file is part of Audio-MPD
#
# This software is copyright (c) 2007 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.008;
use warnings;
use strict;

package Audio::MPD;
# ABSTRACT: class to talk to MPD (Music Player Daemon) servers
$Audio::MPD::VERSION = '2.004';
use Audio::MPD::Common::Item;
use Audio::MPD::Common::Stats;
use Audio::MPD::Common::Status;
use Audio::MPD::Common::Output;
use Encode;
use IO::Socket::IP;
use Moose;
use MooseX::Has::Sugar;
use MooseX::SemiAffordanceAccessor;

use Audio::MPD::Collection;
use Audio::MPD::Playlist;
use Audio::MPD::Types;



has conntype   => ( ro, isa=>'CONNTYPE', default=>'once'  );
has host       => ( ro, lazy_build );
has password   => ( rw, lazy_build, trigger=>sub { $_[0]->ping } );
has port       => ( ro, lazy_build );

has collection => ( ro, lazy_build, isa=>'Audio::MPD::Collection' );
has playlist   => ( ro, lazy_build, isa=>'Audio::MPD::Playlist'   );
has version    => ( rw );

has _socket    => ( rw, isa=>'IO::Socket' );


#--
# initializer & lazy builders


sub BUILD {
    my $self = shift;

    # create the connection if conntype is set to $REUSE
    $self->_connect_to_mpd_server if $self->conntype eq 'reuse';

    # try to issue a ping to test connection - this can die.
    $self->ping;
}

#
# my ($passwd, $host, $port) = _parse_env_var();
#
# parse MPD_HOST environment variable, and extract its components. the
# canonical format of MPD_HOST is passwd@host:port.
#
sub _parse_env_var {
    return (undef, undef, undef) unless defined $ENV{MPD_HOST};
    return ($1, $2, $3)    if $ENV{MPD_HOST} =~ /^([^@]+)\@([^:@]+):(\d+)$/; # passwd@host:port
    return ($1, $2, undef) if $ENV{MPD_HOST} =~ /^([^@]+)\@([^:@]+)$/;       # passwd@host
    return (undef, $1, $2) if $ENV{MPD_HOST} =~ /^([^:@]+):(\d+)$/;          # host:port
    return (undef, $ENV{MPD_HOST}, undef);
}

sub _build_host     { return ( _parse_env_var() )[1] || 'localhost'; }
sub _build_port     { return $ENV{MPD_PORT}     || ( _parse_env_var() )[2] || 6600; }
sub _build_password { return $ENV{MPD_PASSWORD} || ( _parse_env_var() )[0] || '';   }

sub _build_collection { Audio::MPD::Collection->new( _mpd => $_[0] ); }
sub _build_playlist   { Audio::MPD::Playlist  ->new( _mpd => $_[0] ); }


#--
# Private methods


#
# $mpd->_connect_to_mpd_server;
#
# This method connects to the mpd server. It can die on several conditions:
#  - if the server cannot be reached,
#  - if it's not an mpd server,
#  - or if the password is incorrect,
#
sub _connect_to_mpd_server {
    my ($self) = @_;

    # try to connect to mpd.
    my $socket;

    if ($self->host =~ m{^/}) {
        eval q{use IO::Socket::UNIX qw(); 1}
            or die "Could not load IO::Socket::UNIX: $@\n";
        $socket = IO::Socket::UNIX->new($self->host)
            or die "Could not create socket: $!\n";
    }
    else {
        $socket = IO::Socket::IP->new(
            PeerAddr => $self->host,
            PeerPort => $self->port,
        )
        or die "Could not create socket: $!\n";
    }

    # parse version information.
    my $line = $socket->getline;
    chomp $line;
    die "Not a mpd server - welcome string was: [$line]\n"
        if $line !~ /^OK MPD (.+)$/;
    $self->set_version($1);

    # send password.
    if ( $self->password ) {
        $socket->print( 'password ' . encode('utf-8', $self->password) . "\n" );
        $line = $socket->getline;
        die $line if $line =~ s/^ACK //;
    }

    # save socket
    $self->_set_socket($socket);
}


#
# my @result = $mpd->_send_command( $command );
#
# This method is central to the module. It is responsible for interacting with
# mpd by sending the $command and reading output - that will be returned as an
# array of chomped lines (status line will not be returned).
#
# This method can die on several conditions:
#  - if the server cannot be reached,
#  - if it's not an mpd server,
#  - if the password is incorrect,
#  - or if the command is an invalid mpd command.
# In the latter case, the mpd error message will be returned.
#
sub _send_command {
    my ($self, $command) = @_;

    $self->_connect_to_mpd_server if $self->conntype eq 'once';
    my $socket = $self->_socket;

    # ok, now we're connected - let's issue the command.
    $socket->print( encode('utf-8', $command) );
    my @output;
    while (defined ( my $line = $socket->getline ) ) {
        chomp $line;
        die $line if $line =~ s/^ACK //; # oops - error.
        last if $line =~ /^OK/;          # end of output.
        push @output, decode('utf-8', $line);
    }

    # close the socket.
    $socket->close if $self->conntype eq 'once';

    return @output;
}


#
# my @items = $mpd->_cooked_command_as_items( $command );
#
# Lots of Audio::MPD methods are using _send_command() and then parse the
# output as a collection of AMC::Item. This method is meant to factorize
# this code, and will parse the raw output of _send_command() in a cooked
# list of items.
#
sub _cooked_command_as_items {
    my ($self, $command) = @_;

    my @lines = $self->_send_command($command);
    my (@items, %param);

    # parse lines in reverse order since "file:" or "directory:" lines
    # come first. therefore, let's first store every other parameter,
    # and the last line will trigger the object creation.
    # of course, since we want to preserve the playlist order, this means
    # that we're going to unshift the objects instead of push.
    foreach my $line (reverse @lines) {
        my ($k,$v) = split /:\s/, $line, 2;
        $param{$k} = $v;
        next unless $k eq 'file' || $k eq 'directory' || $k eq 'playlist'; # last param of item
        unshift @items, Audio::MPD::Common::Item->new(%param);
        %param = ();
    }

    return @items;
}


#
# my %hash = $mpd->_cooked_command_as_kv( $command );
#
# Lots of Audio::MPD methods are using _send_command() and then parse the
# output to get a list of key / value (with the colon ":" acting as separator).
# This method is meant to factorize this code, and will parse the raw output
# of _send_command() in a cooked hash.
#
sub _cooked_command_as_kv {
    my ($self, $command) = @_;
    my %hash =
        map { split(/:\s/, $_, 2) }
        $self->_send_command($command);
    return %hash;
}

#
# my @list = $mpd->_cooked_command_strip_first_field( $command );
#
# Lots of Audio::MPD methods are using _send_command() and then parse the
# output to remove the first field (with the colon ":" acting as separator).
# This method is meant to factorize this code, and will parse the raw output
# of _send_command() in a cooked list of strings.
#
sub _cooked_command_strip_first_field {
    my ($self, $command) = @_;

    my @list =
        map { ( split(/:\s+/, $_, 2) )[1] }
        $self->_send_command($command);
    return @list;
}


#--
# Public methods

# -- MPD interaction: general commands


sub ping {
    my ($self) = @_;
    $self->_send_command( "ping\n" );
}




# sub version {} # implemented as an accessor.




sub kill {
    my ($self) = @_;
    $self->_send_command("kill\n");
}




# implemented by password trigger (from moose)



sub updatedb {
    my ($self, $path) = @_;
    $path ||= '';
    $self->_send_command("update $path\n");
}



sub urlhandlers {
    my ($self) = @_;
    return $self->_cooked_command_strip_first_field("urlhandlers\n");
}


# -- MPD interaction: handling volume & output


sub volume {
    my ($self, $volume) = @_;

    if ($volume =~ /^(-|\+)(\d+)/ )  {
        my $current = $self->status->volume;
        $volume = $1 eq '+' ? $current + $2 : $current - $2;
    }
    $self->_send_command("setvol $volume\n");
}



sub outputs {
    my ($self) = @_;

    my @lines = $self->_send_command("outputs\n");
    my (@outputs, %param);

    # parse lines in reverse order since "id" lines come first
    foreach my $line (reverse @lines) {
        my ($k,$v) = split /:\s/, $line, 2;
        $k =~ s/^output//;
        $param{$k} = $v;
        next unless $k eq 'id'; # last output param
        unshift @outputs, Audio::MPD::Common::Output->new(%param);
        %param = ();
    }

    return @outputs;
}



sub output_enable {
    my ($self, $output) = @_;
    $self->_send_command("enableoutput $output\n");
}



sub output_disable {
    my ($self, $output) = @_;
    $self->_send_command("disableoutput $output\n");
}



# -- MPD interaction: retrieving info from current state


sub stats {
    my ($self) = @_;
    my %kv = $self->_cooked_command_as_kv( "stats\n" );
    return Audio::MPD::Common::Stats->new(\%kv);
}



sub status {
    my ($self) = @_;
    my %kv = $self->_cooked_command_as_kv( "status\n" );
    my $status = Audio::MPD::Common::Status->new( \%kv );
    return $status;
}



sub current {
    my ($self) = @_;
    my ($item) = $self->_cooked_command_as_items("currentsong\n");
    return $item;
}



sub song {
    my ($self, $song) = @_;
    return $self->current unless defined $song;
    my ($item) = $self->_cooked_command_as_items("playlistinfo $song\n");
    return $item;
}



sub songid {
    my ($self, $songid) = @_;
    return $self->current unless defined $songid;
    my ($item) = $self->_cooked_command_as_items("playlistid $songid\n");
    return $item;
}


# -- MPD interaction: altering settings



sub repeat {
    my ($self, $mode) = @_;

    $mode = not $self->status->repeat
        unless defined $mode; # toggle if no param
    $mode = $mode ? 1 : 0;               # force integer
    $self->_send_command("repeat $mode\n");
}



sub random {
    my ($self, $mode) = @_;

    $mode = not $self->status->random
        unless defined $mode; # toggle if no param
    $mode = $mode ? 1 : 0;               # force integer
    $self->_send_command("random $mode\n");
}



sub fade {
    my ($self, $value) = @_;
    $value ||= 0;
    $self->_send_command("crossfade $value\n");
}


# -- MPD interaction: controlling playback


sub play {
    my ($self, $number) = @_;
    $number = '' unless defined $number;
    $self->_send_command("play $number\n");
}



sub playid {
    my ($self, $number) = @_;
    $number ||= '';
    $self->_send_command("playid $number\n");
}



sub pause {
    my ($self, $state) = @_;
    $state ||= ''; # default is to toggle
    $self->_send_command("pause $state\n");
}



sub stop {
    my ($self) = @_;
    $self->_send_command("stop\n");
}



sub next {
    my ($self) = @_;
    $self->_send_command("next\n");
}



sub prev {
    my($self) = shift;
    $self->_send_command("previous\n");
}



sub seek {
    my ($self, $time, $song) = @_;
    $time ||= 0; $time = int $time;
    $song = $self->status->song if not defined $song; # seek in current song
    $self->_send_command( "seek $song $time\n" );
}



sub seekid {
    my ($self, $time, $song) = @_;
    $time ||= 0; $time = int $time;
    $song = $self->status->songid if not defined $song; # seek in current song
    $self->_send_command( "seekid $song $time\n" );
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Audio::MPD - class to talk to MPD (Music Player Daemon) servers

=head1 VERSION

version 2.004

=head1 SYNOPSIS

    use Audio::MPD;

    my $mpd = Audio::MPD->new;
    $mpd->play;
    sleep 10;
    $mpd->next;

=head1 DESCRIPTION

L<Audio::MPD> gives a clear object-oriented interface for talking to and
controlling MPD (Music Player Daemon) servers. A connection to the MPD
server is established as soon as a new L<Audio::MPD> object is created.

Since mpd is still in 0.x versions, L<Audio::MPD> sticks to latest mpd
(0.15 as time of writing) protocol & behaviour, and does B<not> try to
maintain backward compatibility.

Note that the module will by default connect to mpd before sending any
command, and will disconnect after the command has been issued. This
scheme is far from optimal, but allows us not to care about timeout
disconnections. Because of that, the C<idle> command (new in mpd 0.14)
is B<not> (and will not) be supported in L<Audio::MPD>. This will be
implemented in L<POE::Component::Client::MPD>.

B</!\> Note that L<Audio::MPD> is using high-level, blocking sockets.
This means that if the mpd server is slow, or hangs for whatever reason,
or even crash abruptly, the program will be hung forever in this sub.
The L<POE::Component::Client::MPD> module is way safer - you're advised
to use it instead of L<Audio::MPD>. Or you can try to set C<conntype> to
C<$REUSE> (see L<Audio::MPD> constructor for more details), but you
would be then on your own to deal with disconnections.

=head2 Searching the collection

To search the collection, use the C<collection()> accessor, returning the
associated L<Audio::MPD::Collection> object. You will then be able to call:

    $mpd->collection->all_songs;

See L<Audio::MPD::Collection> documentation for more details on available
methods.

=head2 Handling the playlist

To update the playlist, use the C<playlist()> accessor, returning the
associated L<Audio::MPD::Playlist> object. You will then be able to call:

    $mpd->playlist->clear;

See L<Audio::MPD::Playlist> documentation for more details on available
methods.

=head1 ATTRIBUTES

=head2 host

The hostname where MPD is running. Defaults to environment var
C<MPD_HOST>, then to 'localhost'. Note that C<MPD_HOST> can be of
the form C<password@host:port> (each of C<password@> or C<:port> can
be omitted).

=head2 port

The port that MPD server listens to. Defaults to environment var
C<MPD_PORT>, then to parsed C<MPD_HOST> (cf above), then to 6600.

=head2 password

The password to access special MPD functions. Defaults to environment
var C<MPD_PASSWORD>, then to parsed C<MPD_HOST> (cf above), then to
empty string.

=head2 conntype

Change how the connection to mpd server is handled. It should be of a
C<CONNTYPE> type (cf L<Audio::MPD::Types>). Use either the C<reuse>
string to reuse the same connection or C<once> to open a new connection
per command (default).

=head1 METHODS

=head2 new

    my $mpd = Audio::MPD->new( \%opts );

This is the constructor for L<Audio::MPD>. One can specify any of the
attributes (cf above).

=head1 CONTROLLING THE SERVER

=head2 ping

    $mpd->ping;

Sends a ping command to the mpd server.

=head2 version

    my $version = $mpd->version;

Return mpd's version number as advertised during connection. Note that
mpd returns B<protocol> version when connected. This protocol version
can differ from the real mpd version. eg, mpd version 0.13.2 is
"speaking" and thus advertising version 0.13.0.

=head2 kill

    $mpd->kill;

Send a message to the MPD server telling it to shut down.

=head2 set_password

    $mpd->set_password( [$password] );

Change password used to communicate with MPD server to C<$password>.
Empty string is assumed if C<$password> is not supplied.

=head2 updatedb

    $mpd->updatedb( [$path] );

Force mpd to recan its collection. If C<$path> (relative to MPD's music
directory) is supplied, MPD will only scan it - otherwise, MPD will
rescan its whole collection.

=head2 urlhandlers

    my @handlers = $mpd->urlhandlers;

Return an array of supported URL schemes.

=head1 HANDLING VOLUME & OUTPUT

=head2 volume

    $mpd->volume( [+][-]$volume );

Sets the audio output volume percentage to absolute C<$volume>.  If
C<$volume> is prefixed by '+' or '-' then the volume is changed
relatively by that value.

=head2 outputs

    my @outputs = $mpd->outputs( );

Return a list of C<Audio::MPD::Common::Outputs> with all outputs
available within MPD.

=head2 output_enable

    $mpd->output_enable( $output );

Enable the specified audio output. C<$output> is the ID of the audio
output.

=head2 output_disable

    $mpd->output_disable( $output );

Disable the specified audio output. C<$output> is the ID of the audio
output.

=head1 RETRIEVING INFO FROM CURRENT STATE

=head2 stats

    my $stats = $mpd->stats;

Return an L<Audio::MPD::Common::Stats> object with the current statistics
of MPD. See the associated pod for more information.

=head2 status

    my $status = $mpd->status;

Return an L<Audio::MPD::Common::Status> object with various information on
current MPD server settings. See the associated pod for more information.

=head2 current

    my $song = $mpd->current;

Return an L<Audio::MPD::Common::Item::Song> representing the song currently
playing.

=head2 song

    my $song = $mpd->song( [$song] );

Return an L<Audio::MPD::Common::Item::Song> representing the song number
C<$song>. If C<$song> is not supplied, returns the current song.

=head2 songid

    my $song = $mpd->songid( [$songid] );

Return an L<Audio::MPD::Common::Item::Song> representing the song with id
C<$songid>. If C<$songid> is not supplied, returns the current song.

=head1 ALTERING MPD SETTINGS

=head2 repeat

    $mpd->repeat( [$repeat] );

Set the repeat mode to C<$repeat> (1 or 0). If C<$repeat> is not
specified then the repeat mode is toggled.

=head2 random

    $mpd->random( [$random] );

Set the random mode to C<$random> (1 or 0). If C<$random> is not
specified then the random mode is toggled.

=head2 fade

    $mpd->fade( [$seconds] );

Enable crossfading and set the duration of crossfade between songs.  If
C<$seconds> is not specified or $seconds is 0, then crossfading is
disabled.

=head1 CONTROLLING PLAYBACK

=head2 play

    $mpd->play( [$song] );

Begin playing playlist at song number C<$song>. If no argument supplied,
resume playing.

=head2 playid

    $mpd->playid( [$songid] );

Begin playing playlist at song ID C<$songid>. If no argument supplied,
resume playing.

=head2 pause

    $mpd->pause( [$state] );

Pause playback. If C<$state> is 0 then the current track is unpaused,
if C<$state> is 1 then the current track is paused.

Note that if C<$state> is not given, pause state will be toggled.

=head2 stop

    $mpd->stop;

Stop playback.

=head2 next

    $mpd->next;

Play next song in playlist.

=head2 prev

    $mpd->prev;

Play previous song in playlist.

=head2 seek

    $mpd->seek( $time, [$song]);

Seek to C<$time> seconds in song number C<$song>. If C<$song> number is
not specified then the perl module will try and seek to C<$time> in the
current song.

=head2 seekid

    $mpd->seekid( $time, $songid );

Seek to C<$time> seconds in song ID C<$songid>. If C<$song> number is
not specified then the perl module will try and seek to C<$time> in the
current song.

=for Pod::Coverage BUILD

=head1 SEE ALSO

You can find more information on the mpd project on its homepage at
L<http://www.musicpd.org>.wikia.com>.

Original code (2005) by Tue Abrahamsen C<< <tue.abrahamsen@gmail.com> >>,
documented in 2006 by Nicholas J. Humfrey C<< <njh@aelius.com> >>.

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://metacpan.org/release/Audio-MPD>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Audio-MPD>

=item * Mailing-list

L<http://groups.google.com/group/audio-mpd>

=item * Git repository

L<http://github.com/jquelin/audio-mpd.git>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Audio-MPD>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Audio-MPD>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
