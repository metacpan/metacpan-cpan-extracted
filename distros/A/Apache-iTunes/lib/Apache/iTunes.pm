package Apache::iTunes;
use strict;

use vars qw($VERSION);

use Apache::Constants qw(:common);
use Apache::Util qw(unescape_uri);;
use Mac::iTunes;
use Text::Template;

$VERSION = 0.12;

=head1 NAME

Apache::iTunes - control iTunes from mod_perl

=head1 SYNOPSIS

	<Location /iTunes>
		SetHandler perl-script
		PerlHandler Apache::iTunes
		PerlModule Mac::iTunes
		PerlInitHandler Apache::StatINC
		PerlSetEnv APACHE_ITUNES_HTML /web/iTunes.html
		PerlSetEnv APACHE_ITUNES_URL http://10.0.1.2:8080/iTunes/
		PerlSetEnv APACHE_ITUNES 1
	</Location>

=head1 DESCRIPTION

THIS IS ALPHA SOFTWARE.

This module is currently unmaintained. If you want to take over
the care and feeding, write to modules@perl.org.


I am still developing Mac::iTunes, and this module depends
mostly on that.  This handler does most of the stuff I need
it to do, so further development depends on what people
ask for or contribute. :)

=head2 URLs

After the base URL to the iTunes handler, you can add
commands in the path info.  Only the first command matters.

=over 4

=item /play, /pause, /stop, /next, /previous

Does just what it says, just like the iTunes controller.

=item /back_track

Restarts the current track

=item /volume/<number 0-100>

Sets the volume to a value between 0 and 100.  Numbers below
0 are taken as 0, and those above 100 are taken as 100.

=item /playlist/<playlist>

Changes the playlist view to <playlist> if it exists.

=item /track/<number>/<playlist>

CURRENTLY BROKEN!

Plays track number <number> in <playlist>.

=back

=head2 Template Variables

This module uses Text::Template because I expect people to
hack it for their own templating system (please send back
modifications!).

=over 4

=item $base

The base URL (from APACHE_ITUNES_URL environment variable)

=item $current

The current track name

=item $playlist

The current playlist

=item @playlists

A list of the playlists

=item @tracks

A list of tracks in the current playlist (in $playlist)

=item $version

The version of Apache::iTunes

=back

=head2 Environment variables

=over 4

=item APACHE_ITUNES_URL

The URL to the mod_perl handler so it can reference itself.

=item APACHE_ITUNES_HTML

The location of the template file.

=back

=head1 TO DO

* even though this is mod_perl, Mac::iTunes is still pretty slow.
when i get to the optimization stage, Mac::iTunes will get faster
and so will this.

=head1 SOURCE AVAILABILITY

This source is in GitHub

	https://github.com/CPAN-Adopt-Me/Apache-iTunes

=head1 AUTHOR

This module is currently unmaintained. If you want to take over
the care and feeding, write to modules@perl.org.

brian d foy, C<< <bdfoy@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2002-2007, brian d foy, All Rights Reserved.

You may redistribute this under the same terms as Perl itself.

=cut

# share these among all mod_perl children and from
# request to request
use vars qw( $Playlist $Controller %Commands %Set $Volume );

$Playlist      = 'Library';
$Controller    = Mac::iTunes->new()->controller;
%Commands      = map { $_, 1 }
	qw( play stop pause back_track next previous );
%Set           = map { $_, 1 }
	qw( playlist );
$Volume        = $Controller->volume;

sub handler
	{
	my $r = shift;

	my( undef, $command, @path_info )= split m|/|, ( $r->path_info || '' );
	$command = '' unless $command; # silence warning
	@path_info = map { unescape_uri( $_ ) } @path_info;

	my %params = $r->args;

	if( exists $Commands{ $command } )
		{
		$Controller->$command;
		}
	elsif( $command eq 'playlist' and defined $path_info[0]
		and $Controller->playlist_exists( $path_info[0] ) )
		{
		$Controller->set_playlist( $path_info[0] );
		$Playlist = $path_info[0];
		}
	elsif( $command eq 'track' )
		{
		my $number = int( $path_info[0] || 0 );
		$path_info[1] = $Playlist unless $path_info[1];
		my $Playlist = $path_info[1]
			if $Controller->playlist_exists( $path_info[1] );
		$Controller->play_track( $number, $Playlist );
		}
	elsif( $command eq 'volume' )
		{
		my $volume = $path_info[0];
		$volume = $volume > 100 ? 100 : $volume < 0 ? 0 : $volume;
		$Volume = $Controller->volume( $volume );
		}

	my %var;

	$var{version}   = $VERSION;
	$var{base}      = $ENV{APACHE_ITUNES_URL};
	$var{state}     = $Controller->player_state;
	$var{current}   = $Controller->current_track_name;
	$var{playlist}  = $Playlist;
	$var{playlists} = $Controller->get_playlists;
	$var{tracks}    = $Controller->get_track_names_in_playlist( $Playlist );

	my $html = Text::Template::fill_in_file(
		$ENV{APACHE_ITUNES_HTML}, HASH => \%var );

	$r->content_type( 'text/html' );
	$r->send_http_header;
	$r->print( $html );
	return OK;
	}

"See why 1984 won't be like 1984";
