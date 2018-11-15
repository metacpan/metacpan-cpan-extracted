#! perl

# Data::iRealPro::Output::Forum -- produce iRealPro forum posting

################ Common stuff ################

use strict;
use warnings;
use Carp;
use utf8;

package Data::iRealPro::Output::Forum;

use parent qw( Data::iRealPro::Output::Base );

use Data::iRealPro::URI;
use Data::iRealPro::Playlist;
use Encode qw( encode_utf8 );
use HTML::Entities;

my $regtest = $ENV{IRP_REGTEST};

sub options {
    my $self = shift;
    [ @{ $self->SUPER::options }, qw( split ) ];
}

sub process {
    my ( $self, $u, $options ) = @_;

    my $html = "";
    $self->{output} //= $options->{output} || "-";
    $self->{split}  //= $options->{split};

    unless ( $self->{split} ) {

	if ( $u->{transpose} ) {
	    foreach my $song ( @{ $u->{playlist}->{songs} } ) {
		# Do not change key to actual.
		local $song->{_transpose} = 0;

		$song->{key} = $song->xpose($song->{key} // "C");
		if ( $song->{actual_key} ne '' ) {
		    $song->{actual_key} =
		      ( $song->{actual_key} + $song->{transpose} ) % 12;
		}
		$song->tokenize;
		$song->{data} = $song->{dataxp} if $song->{dataxp};
	    }
	}

	$html .= to_html($u);
    }
    else {
	foreach my $song ( @{ $u->{playlist}->{songs} } ) {
	    # Do not change key to actual.
	    local $song->{_transpose} = 0;

	    if ( $song->{transpose} ) {
		$song->{key} = $song->xpose($song->{key} // "C");
		if ( $song->{actual_key} ne '' ) {
		    $song->{actual_key} =
		      ( $song->{actual_key} + $song->{transpose} ) % 12;
		}
		$song->tokenize;
		$song->{data} = $song->{dataxp} if $song->{dataxp};
	    }

	    # Make a playlist with just this song.
	    my $pls = Data::iRealPro::Playlist->new( song => $song );

	    # Make an URI for this playlist.
	    my $uri = Data::iRealPro::URI->new( playlist => $pls );

	    # Write it out.
	    $html .= to_html($uri);
	}
    }

    if ( ref( $self->{output} ) ) {
	${ $self->{output} } = $html;
    }
    else {
	my $fd;
	if ( $self->{output} eq "-" ) {
	    $fd = \*STDOUT;
	}
	else {
	    open( $fd, ">:utf8", $self->{output} )
	      or croak( "Cannot create ", $self->{output}, " [$!]\n" );
	}
	print $fd $html;
    }
}

sub to_html {
    my ( $u ) = @_;

    my $pl = $u->{playlist};
    my $html = "";

    if ( $pl->{name} || @{ $pl->{songs} } > 1 ) {
	$html .= "[URL=\"irealb://" . _esc($pl->as_string) .
	  "\"]All songs[/URL]";
	$html .= " - " . _html($pl->{name})
	  if $pl->{name};
	$html .= "\n";

	$html .= "[LIST=1]\n";
	foreach my $s ( @{ $pl->{songs} } ) {
	    my @c = split(' ', $s->{composer});
	    my $c = @c == 2 ? "$c[1] $c[0]" : $s->{composer};
	    $html .= "[*][URL=\"irealb://" .
	      _esc($s->as_string) .
		"\"]". _html($s->{title}) .
		    "[/URL] - " .
		      _html($c) .
			"\n";
	}
	$html .= "[/LIST]\n";
    }
    else {
	my $s = $pl->{songs}->[0];
	my @c = split(' ', $s->{composer});
	my $c = @c == 2 ? "$c[1] $c[0]" : $s->{composer};
	$html .= "[URL=\"irealb://" . _esc($s->as_string) .
	  "\"]" . _html($s->{title}) .
	    "[/URL] - " .
	      _html($c) .
		"\n";
    }

    return $html;
}

sub _esc {
    goto \&Data::iRealPro::URI::esc;
}

sub _html {
    encode_entities($_[0]);
}

1;
