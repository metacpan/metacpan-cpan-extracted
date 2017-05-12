package DCOP::Amarok::Playlist;

use 5.008001;
use strict;
use warnings;

require DCOP::Amarok;

our @ISA = qw(DCOP::Amarok);

our $VERSION = '0.009';

=head1 NAME

DCOP::Amarok::Playlist - Perl extension to speak to an amaroK player object via system's DCOP.

=head1 SYNOPSIS

	use DCOP::Amarok::Playlist;
	$playlist = DCOP::Amarok::Playlist->new();

	$playlist->togglePlaylist();
	print $playlist->getActiveIndex();

=head1 DESCRIPTION

This module is a quick hack to get an interface between perl and Kde's DCOP,
since Kde3.4's perl bindings are disabled. This suite talks to 'dcop'.
DCOP::Amarok::Playlist talks directly to the playlist object of amaroK.

=head1 EXPORT

None by default.

=head1 METHODS

=item new()

Constructor. No arguments needed. If the program will be run remotely, the
need for 'user => "myusername"' arises.

=cut

sub new() {
	my $proto  = shift;
	my $class  = ref( $proto ) || $proto;
	my %params = @_;
	my $self   = $class->SUPER::new( %params, control => "playlist" );
	bless( $self, $class );
	return $self;
}

=item interfaces()

Returns a list of the interfaces.

=cut

sub interfaces() {
	my $self = shift;
	return $self->run( "interfaces" );
}

=item functions()

Returns a list of the functions.

=cut

sub functions() {
	my $self = shift;
	return $self->run( "functions" );
}

=item getActiveIndex()

Returns the number of the active index.

=cut

sub getActiveIndex() {
	my $self = shift;
	return $self->run( "getActiveIndex" );
}

=item getTotalTrackCount()

Returns the total number of tracks in the playlist.

=cut

sub getTotalTrackCount() {
	my $self = shift;
	return $self->run( "getTotalTrackCount" );
}

=item saveCurrentPlaylist()

Makes the object save the present list.
Returns the path.

=cut

sub saveCurrentPlaylist() {
	my $self = shift;
	return $self->run( "saveCurrentPlaylist" );
}

=item addMedia($URL)

Adds new media.

=cut

sub addMedia() {
	my $self = shift;
	while ( @_ ) {
		$self->run( "addMedia", "$_" );
	}
}

=item addMediaList()

Adds new media.

=cut

sub addMediaList() {
	my $self = shift;
	$self->run( "addMediaList", @_ );
}

=item clearPlaylist()


=cut

sub clearPlaylist() {
	my $self = shift;
	$self->run( "clearPlaylist" );
}

=item playByIndex($index)

Plays the song in the $index position.

=cut

sub playByIndex() {
	my $self  = shift;
	my $index = shift;
	$self->run( "playByIndex", "$index" );
}

=item playMedia($uri)

Play a specific object. 

=cut

sub playMedia() {
	my $self = shift;
	my $url  = shift;
	$self->run( "playMedia", "$url" );
}

=item popupMessage($msg)

Pops up $msg in screen.
TODO: $msg has to escape white spaces with '\'.
		e.g.   "Hi\\\ there";
		e.g2.	 'I\ am\ here'

=cut

sub popupMessage() {
	my $self = shift;
	my $msg  = shift;
	$self->run( "popupMessage", "$msg" );
}

=item removeCurrentTrack()

Removes current track from playlist

=cut

sub removeCurrentTrack() {
	my $self = shift;
	$self->run( "removeCurrentTrack" );
}

=item repopulate()

Repopulate playlist.

=cut

sub repopulate() {
	my $self = shift;
	$self->run( "repopulate" );
}

=item saveM3uRelative($path)

Saves the M3U file with a relavtive path.

=cut

sub saveM3uRelative() {
	my $self = shift;
	my $path = shift;
	$self->run( "saveM3u", "$path", "1" );
}

=item saveM3uAbsolute($path)

Saves the M3U file with an absolut path.

=cut

sub saveM3uAbsolute() {
	my $self = shift;
	my $path = shift;
	$self->run( "saveM3u", "$path", "0" );
}

=item setStopAfterCurrent()

Enable StopAfterCurrent track.

=cut

sub setStopAfterCurrent() {
	my $self = shift;
	$self->run( "setStopAfterCurrent", "1" );
}

=item notStopAfterCurrent()

Disable StopAfterCurrent track.

=cut

sub notStopAfterCurrent() {
	my $self = shift;
	$self->run( "setStopAfterCurrent", "0" );
}

=item shortStatusMessage($msg)

Display $msg in the status bar.

=cut

sub shortStatusMessage() {
	my $self = shift;
	my $msg  = shift;
	$self->run( "shortStatusMessage", "$msg" );
}

=item shufflePlaylist()

Shuffle playlist.

=cut

sub shufflePlaylist() {
	my $self = shift;
	$self->run( "shufflePlaylist" );
}

=item togglePlaylist()

Show/Hide playlist.

=cut

sub togglePlaylist() {
	my $self = shift;
	$self->run( "togglePlaylist" );
}

1;

__END__

=head1 AUTHOR

Juan C. Muller, E<lt>jcmuller@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Juan C. Muller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

