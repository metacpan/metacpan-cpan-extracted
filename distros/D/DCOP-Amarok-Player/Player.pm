package DCOP::Amarok::Player;

use 5.008001;
use strict;
use warnings;
use Carp;
require DCOP::Amarok;

our @ISA = qw(DCOP::Amarok);

our $VERSION = '0.037';

=head1 NAME

DCOP::Amarok::Player - Perl extension to speak to an amaroK player object via system's DCOP.

=head1 SYNOPSIS

	use DCOP::Amarok::Player;
	$player = DCOP::Amarok::Player->new();

	$player->playPause();
	print $player->getRandom();

=head1 DESCRIPTION

This module is a quick hack to get an interface between perl and Kde's DCOP,
since Kde3.4's perl bindings are disabled. This suite talks to 'dcop'.
DCOP::Amarok::Player talks directly to the player object of amaroK.

=head1 EXPORT

None by default.

=head1 METHODS

=cut

=item new()

Constructor. No arguments needed. If the program will be run remotely, the
need for 'user => "myusername"' arises.

=cut

sub new() {
	my $proto  = shift;
	my $class  = ref( $proto ) || $proto;
	my %params = @_;
	my $self   = $class->SUPER::new( %params, control => "player" );
	bless( $self, $class );
	return $self;
}

=item album()

Returns the album name of currently playing song.

=cut

sub album() {
	my $self = shift;
	return $self->run( "album" );
}

=item artist()

Returns the artist performing currently playing song.

=cut

sub artist() {
	my $self = shift;
	return $self->run( "artist" );
}

=item title()

Returns the title of currently playing song.

=cut

sub title() {
	my $self = shift;
	return $self->run( "title" );
}

=item playPause()

=cut

sub playPause() {
	my $self = shift;
	$self->run( "playPause" );
}

=item play()


=cut

sub play() {
	my $self = shift;
	$self->run( "play" );
}

=item pause()

=cut

sub pause() {
	my $self = shift;
	$self->run( "pause" );
}

=item stop()

=cut

sub stop() {
	my $self = shift;
	$self->run( "stop" );
}

=item next()

=cut

sub next() {
	my $self = shift;
	$self->run( "next" );
}

=item prev()

=cut

sub prev() {
	my $self = shift;
	$self->run( "prev" );
}

=item getRandom()

Returns the status of the Shuffle play mode.

=cut

sub getRandom() {
	my $self = shift;
	return $self->run( "randomModeStatus" );
}

=item toggleRandom()

Toggles the Random play mode. Returns the new state.

=cut

sub toggleRandom() {

	# returns new status of randomness
	my $self = shift;
	chomp( $_ = $self->getRandom() );
	if ( $_ =~ /true/ ) {
		$self->run( "enableRandomMode", "0" );
	} else {
		$self->run( "enableRandomMode", "1" );
	}
	return $self->getRandom();
}

=item mute()

=cut

sub mute() {
	my $self = shift;
	$self->run( "mute" );
}

=item volumeUp()

=cut

sub volumeUp() {
	my $self = shift;
	$self->run( "volumeUp" );
}

=item volumeDown()

=cut

sub volumeDown() {
	my $self = shift;
	$self->run( "volumeDown" );
}

=item getVolume()

Returns the volume level.

=cut

sub getVolume() {
	my $self = shift;
	return $self->run( "getVolume" );
}

=item status()

Returns the playing status of amaroK.
0: Stopped, 1: Paused, 2: Playing

=cut

sub status() {
	my $self = shift;
	return $self->run( "status" );
}

=item track()

Returns the track number of the song that is currently being played.

=cut

sub track() {
	my $self = shift;
	return $self->run( "track" );
}

=item totalTime()

Returns in MM:SS the total playing time of the song that is currently being played.

=cut

sub totalTime() {
	my $self = shift;
	return $self->run( "totalTime" );
}

=item currentTime()

Returns in MM:SS the elapsed time of the song that is currently being played.

=cut

sub currentTime() {
	my $self = shift;
	return $self->run( "currentTime" );
}

=item totaltimesecs()

Returns in seconds the total playing time of the song that is currently being played.

=cut

sub trackTotalTime() {
	my $self = shift;
	return $self->run( "trackTotalTime" );
}

=item trackCurrentTime()

Returns in seconds the elapsed time of the song that is currently being played.

=cut

sub trackCurrentTime() {
	my $self = shift;
	return $self->run( "trackCurrentTime" );
}

sub _mins() {
	my $self    = shift;
	my $totsecs = shift;
	my $secs    = $totsecs % 60;
	my $mins    = ( $totsecs - $secs ) / 60;
	$secs = '0' . $secs if ( $secs < 10 );
	return "${mins}:${secs}";
}

=item fwd()

Fast forwards 5 seconds the song.

=cut

sub fwd() {
	my $self = shift;
	$self->run( "seekRelative", "+5" );
}

=item rew()

Rewinds 5 seconds the song.

=cut

sub rew() {
	my $self = shift;
	$self->run( "seekRelative", "-5" );
}

=item lyrics()

Returns the lyrics of the song that is currently being played.

=cut

sub lyrics() {
	my $self = shift;
	return $self->run( "lyrics" );
}

=item interfaces()

Returns the interfaces registered with amaroK.

=cut

sub interfaces() {
	my $self = shift;
	return $self->run( "interfaces" );
}

=item functions()

Returns functions available to amaroK.

=cut

sub functions() {
	my $self = shift;
	return $self->run( "functions" );
}

=item dynamicModeStatus()

Returns status.

=cut

sub dynamicModeStatus() {
	my $self = shift;
	return $self->run( "dynamicModeStatus" );
}

=item equalizerEnabled()

Returns whether it is enabled or not.

=cut

sub equalizerEnabled() {
	my  $self = shift;
	return ->run( "equalizerEnabled" );
}

=item isPlaying()


=cut

sub isPlaying() {
	my  $self = shift;
	return $self->run( "isPlaying" );
}

=item randomModeStatus()

=cut

sub randomModeStatus() {
	my  $self = shift;
	return $self->run( "randomModeStatus" );
}

=item repeatPlaylistStatus()

=cut


sub repeatPlaylistStatus() {
	my  $self = shift;
	return $self->run( "repeatPlaylistStatus" );
}

=item repeatTrackStatus()



=cut

sub repeatTrackStatus() {
	my  $self = shift;
	return $self->run( "repeatTrackStatus" );
}

=item sampleRate()



=cut

sub sampleRate() {
	my  $self = shift;
	return $self->run( "sampleRate" );
}

=item score()



=cut

sub score() {
	my  $self = shift;
	return $self->run( "score" );
}

=item trackPlayCounter()



=cut

sub trackPlayCounter() {
	my  $self = shift;
	return $self->run( "trackPlayCounter" );
}

=item bitrate()



=cut


sub bitrate() {
	my  $self = shift;
	return $self->run( "bitrate" );
}

=item comment()



=cut

sub comment() {
	my  $self = shift;
	return $self->run( "comment" );
}

=item coverImage()

Returns the encoded image url.

=cut

sub coverImage() {
	my  $self = shift;
	return $self->run( "coverImage" );
}

=item encodedURL()

Returns the encoded URL of the currently playing track.

=cut

sub encodedURL() {
	my  $self = shift;
	return $self->run( "encodedURL" );
}

=item engine()

Returns which engine is being used.

=cut

sub engine() {
	my $self = shift;
	return $self->run( "engine" );
}

=item genre()



=cut

sub genre() {
	my $self = shift;
	return $self->run( "genre" );
}

=item lyricsByPath()



=cut

sub lyricsByPath() {
	my $self = shift;
	my $path = shift;
	return $self->run( "lyricsByPath", "$path" );
}

=item nowPlaying()

Returns the title.

=cut

sub nowPlaying() {
	my $self = shift;
	return $self->run( "nowPlaying" );
}

=item path()



=cut

sub path() {
	my $self = shift;
	return $self->run( "path" );
}

=item setContextStyle($style)

=cut

sub setContextStyle() {
	my $self  = shift;
	my $style = shift;
	return $self->run( "setContextStyle", "$style" );
}

=item type()

=cut

sub type() {
	my $self = shift;
	return $self->run( "type" );
}

=item year()



=cut

sub year() {
	my $self = shift;
	return $self->run( "year" );
}

=item configEqualizer()



=cut

sub configEqualizer() {
	my $self = shift;
	$self->run( "configEqualizer" );
}

=item enableDynamicMode($enable)

Bool.

=cut

sub enableDynamicMode() {
	my $self = shift;
	my $enable = shift;
	$self->run( "enableDynamicMode", "$enable" );
}

=item enableOSD($enable)

Bool.

=cut

sub enableOSD() {
	my $self = shift;
	my $enable = shift;
	$self->run( "enableOSD", "$enable" );
}

=item enableRepeatPlaylist($enable)

Bool.

=cut

sub enableRepeatPlaylist() {
	my $self = shift;
	my $enable = shift;
	$self->run( "enableRepeatPlaylist", "$enable" );
}

=item enableRandomMode($enable)

Bool.

=cut

sub enableRandomMode() {
	my $self = shift;
	my $enable = shift;
	$self->run( "enableRandomMode", "$enable" );
}

=item enableRepeatTrack($enable)

Bool.

=cut

sub enableRepeatTrack() {
	my $self = shift;
	my $enable = shift;
	$self->run( "enableRepeatTrack", "$enable" );
}

=item mediaDeviceMount()



=cut

sub mediaDeviceMount() {
	my $self = shift;
	$self->run( "mediaDeviceMount" );
}

=item mediaDeviceUmount()



=cut

sub mediaDeviceUmount() {
	my $self = shift;
	$self->run( "mediaDeviceUmount" );
}

=item queueForTransfer()



=cut

sub queueForTransfer() {
	my $self = shift;
	my $url = shift;
	$self->run( "queueForTransfer", "$url" );
}

=item seek($secs)



=cut

sub seek() {
	my $self = shift;
	my $secs = shift;
	$self->run( "seek", "$secs" );
}

=item seekRelative($secs)



=cut

sub seekRelative() {
	my $self = shift;
	my $location = shift;
	$self->run( "seekRelative", "$location" );
}

=item setEqualizer(@args)

11 values.

=cut

sub setEqualizer() {
	my $self = shift;
	$self->run( "setEqualizer", @_ ) or croak("Arguments must be 11.");
}

=item setEqualizerEnabled($enable)

Bool.

=cut

sub setEqualizerEnabled() {
	my $self = shift;
	my $enable = shift;
	$self->run( "setEqualizerEnabled", "$enable" );
}

=item setEqualizerPreset($url)



=cut

sub setEqualizerPreset() {
	my $self = shift;
	my $url  = shift;
	$self->run( "setEqualizerPreset", "$url" );
}

=item setLyricsByPath($url, $lyrics)



=cut

sub setLyricsByPath() {
	my $self = shift;
	my ($url, $lyrics) = @_;
	$self->run( "setLyricsByPath", "$url", "$lyrics" );
}

=item setScore($score)



=cut

sub setScore() {
	my $self = shift;
	my $score = shift;
	$self->run( "setScore", "$score" );
}

=item setScoreByPath($url, $score)



=cut

sub setScoreByPath() {
	my $self = shift;
	my ($url, $score) = @_;
	$self->run( "setScoreByPath", "$url", "$score" );
}

=item setVolume($volume)

=cut


sub setVolume() {
	my $self = shift;
	my $volume = shift;
	$self->run( "setVolume", "$volume" );
}

=item showBrowser($enable)

=cut


sub showBrowser() {
	my $self = shift;
	my $show = shift;
	$self->run( "showBrowser", "$show" );
}

=item showOSD()

=cut


sub showOSD() {
	my $self = shift;
	$self->run( "showOSD" );
}

=item transferDeviceFiles()



=cut

sub transferDeviceFiles() {
	my $self = shift;
	$self->run( "transferDeviceFiles" );
}

=item transferCliArgs(@args)

=cut

sub transferCliArgs() {
	my $self = shift;
	$self->run( "transferCliArgs", join(" ", @_)  );
}

*elapsedsecs   = \&trackCurrentTime,
*elapsed       = \&currentTime,
*totaltimesecs = \&trackTotalTime,
*totaltime     = \&totalTime,
*vol           = \&getVolume,
*volUp         = \&volumeUp,
*volDn         = \&volumeDown;

=item elapsedsecs()

Provided for backwards compatibility. Use trackCurrentTime().

=item elapsed()

Provided for backwards compatibility. Use currentTime().

=item totaltimesecs()

Provided for backwards compatibility. Use trackTotalTime().

=item totaltime()

Provided for backwards compatibility. Use totalTime().

=cut

=item vol()

Provided for backwards compatibility. Use getVolume().

=item volUp()

Provided for backwards compatibility. Use volumeUp().

=item volDn()

Provided for backwards compatibility. Use volumeDown().

=cut

1;
__END__

=head1 AUTHOR

Juan C. Muller, E<lt>jcmuller@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Juan C. Muller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
