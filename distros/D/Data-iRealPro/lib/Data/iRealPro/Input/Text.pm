#! perl

# Data::iRealPro::Input::Text -- parse iRealPro data (text format)

# Author          : Johan Vromans
# Created On      : Tue Sep  6 14:58:26 2016
# Last Modified By: Johan Vromans
# Last Modified On: Tue Nov 13 10:31:13 2018
# Update Count    : 98
# Status          : Unknown, Use with caution!

################ Common stuff ################

use strict;
use warnings;
use Carp;
use utf8;

package Data::iRealPro::Input::Text;

use Data::iRealPro::URI;
use Data::iRealPro::Playlist;
use Data::iRealPro::Song;

my %keymap =
  ( 'C'   =>  0,
    'C#'  =>  1, 'Db' =>  1,
    'D'   =>  2,
    'D#'  =>  3, 'Eb' =>  3,
    'E '  =>  4,
    'F'   =>  5,
    'F#'  =>  6, 'Gb' =>  6,
    'G'   =>  7,
    'G#'  =>  8, 'Ab' =>  8,
    'A'   =>  9,
    'A#'  => 10, 'Bb' => 10,
    'B'   => 11,

    'A-'  =>  0,
    'A#-' =>  1, 'Bb-' =>  1,
    'B-'  =>  2,
    'C-'  =>  3,
    'C#-' =>  4, 'Db-' =>  4,
    'D-'  =>  5,
    'D#-' =>  6, 'Eb-' =>  6,
    'E-'  =>  7,
    'F-'  =>  8,
    'F#-' =>  9, 'Gb-' =>  9,
    'G-'  => 10,
    'G#-' => 11, 'Ab-' => 11,
  );

sub encode {
    my ( $self, $data ) = @_;
    my $variant = "irealpro";
    $self->{transpose} //= 0;

    my $plname;
    if ( $data =~ /^Playlist:\s*(.*)/m ) {
	$plname = $1 unless $1 eq "<NoName>";
    }

    my @songs;
    while ( $data =~ /\A(Song(?: (\d+))?:.*?)^(Song(?: \d+)?:.*)/ms ) {
	warn("Expecting song ", 1+@songs, " but got $2\n")
	  unless $2 == 1 + @songs;
	push( @songs, encode_song( $self, $1 ) );
	$data = $3;
    }
    if ( $data =~ /^Song(?: (\d+))?:.*/ ) {
	warn("Expecting song number ", 1+@songs, " but got number $1\n")
	  if $1 && $1 != 1 + @songs;
	push( @songs, encode_song( $self, $data ) );
    }

    # Build a playlist for the songs...
    my $pl = Data::iRealPro::Playlist->new
      ( variant      => $variant,
	songs        => \@songs,
	$plname ? ( name => $plname ) : (),
      );

    # Build a URI for the playlist...
    my $uri = Data::iRealPro::URI->new
      ( variant      => $variant,
	playlist     => $pl,
	transpose    => $self->{transpose},
      );

    # And deliver.
    return $uri;
}

sub encode_song {
    my ( $self, $data ) = @_;
    my $variant = "irealpro";
    my $tv =
      { variant		=> $variant,
	composer	=> "Composer",
	key		=> 'C',
	style		=> "Rock Ballad",
	actual_key	=> 0,
	actual_repeats	=> 0,
	actual_style	=> "",
	actual_tempo	=> 0,
      };

    if ( $data =~ /^Playlist:\s*(.*)/m ) {
	$tv->{pl_name} = $1 unless $1 eq "<NoName>";
    }

    if ( $data =~ /^Song(?:\s+\d+)?:\s+(.*)\s+\((.*?)\)/m ) {
	$tv->{title} = $1;
	my @t = split( ' ', $2 );
	@t[0,1] = @t[1,0] if @t == 2;
	$tv->{composer} = "@t";
    }

    if ( $data =~ /Style:\s+([^;(\n]*)(?:\s+\(([^)\n]+)\))?(?:;|$)/m ) {
	$tv->{style} = $1;
	$tv->{actual_style} = $2;
    }

    if ( $data =~ /; key:\s+([^;\n]+)/ ) {
	$tv->{key} = $1;
    }
    if ( $data =~ /; actual\s+key:\s+([^;\n]+)/ ) {
	$tv->{actual_key} = $keymap{$1};
	$tv->{_transpose} = ( $tv->{actual_key} - $keymap{$tv->{key}} ) % 12;
    }
    else {
	$tv->{actual_key} = '';
    }

    if ( $data =~ /; tempo:\s+(\d+)/ ) {
	$tv->{actual_tempo} = $1;
    }
    if ( $data =~ /; repeats?:\s+(\d+)/ ) {
	$tv->{actual_repeats} = $1;
    }

    $data =~ s/^.*?\n\n//s;

    # Build the song...
    my $song = Data::iRealPro::Song->new
      ( variant	       => $variant,
	title	       => $tv->{title},
	composer       => $tv->{composer},
	style	       => $tv->{style},
	key	       => $tv->{key},
	actual_key     => $tv->{actual_key},
	actual_tempo   => $tv->{actual_tempo},
	actual_style   => $tv->{actual_style},
	actual_repeats => $tv->{actual_repeats},
	transpose      => $self->{transpose},
	_transpose     => $tv->{_transpose} // 0,
     );
    $song->{data} = yfitaen($data);

    # And deliver.
    return $song;
}

sub yfitaen {
    my ( $t ) = @_;
    my @a = split( /(\<.*?\>)/, $t );
    $t = "";
    while ( @a > 1 ) {
	$t .= yfitaen1(shift(@a)) . shift(@a);
    }
    $t .= yfitaen1(shift(@a)) if @a;
    return $t;
}

sub yfitaen1 {
    my ( $t ) = @_;
    # Indeed, the reverse of neatify. And a bit easier.
    $t =~ s/([[:alnum:]])\s+([[:alnum:]])/$1,$2/g;
    $t =~ s/\s+//g;
    $t =~ s/_/ /g;
    return $t;
}

1;
