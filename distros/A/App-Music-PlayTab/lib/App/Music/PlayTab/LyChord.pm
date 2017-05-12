#! perl

# Author          : Johan Vromans
# Created On      : Tue Jan 15 15:59:16 2008
# Last Modified By: Johan Vromans
# Last Modified On: Wed Oct  5 12:00:16 2011
# Update Count    : 10
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::LyChord;

use strict;
use warnings;

our $VERSION = "1.006";

use App::Music::PlayTab::Note;
use Carp;
use base qw(App::Music::PlayTab::Chord);

sub parse {
    my ($self, $chord) = @_;

    $self = $self->new unless ref($self);

    $self->{_unparsed} = $chord;
    $self->{_debug} = 1 if $chord =~ s/^\?//;
    $self->{_isrest} = 0;
    delete( $self->{bass} );

    my $key = $chord;
    my $mod = '';

    # Catch rests.
    if ( $chord =~ /(^[rs])(\d+\.*)?/ ) {
	$self->{_isrest} = 1;
	if ( defined $2 ) {
	    my ($dur, $xt) = $2 =~ /^(\d+)(\.*)$/;
	    $dur = $self->duration_base / $dur;
	    $dur *= 1.5 foreach split(//, $xt);
	    $self->{duration} = $dur;
	}
	return $self;
    }

    # Treat power chords as modifications.
    $chord =~ s;^([[a-g](?:es|is)?(\d+\.*)?)/;$1:/;;

    # Separate the chord key from the modifications.
    if ( $chord =~ /(^[a-g](?:es|is)?)(\d+\.*)?(?::(.*))?/ ) {
	$key = $1;
	$mod = $3;
	if ( defined $2 ) {
	    my ($dur, $xt) = $2 =~ /^(\d+)(\.*)$/;
	    $dur = $self->duration_base / $dur;
	    $dur *= 1.5 foreach split(//, $xt);
	    $self->{duration} = $dur;
	}
    }

    # Parse key.
    eval { $self->{key} = App::Music::PlayTab::Note->parse($key) };
    croak("Unrecognized pitch in chord: ".$self->{_unparsed})
      unless defined $self->{key};

    # Encodings: a bit is set in $chflags for every note in the chord.
    # The corresponding element of $chmods is 0 (natural), -1
    # (lowered), 1 (raised) or undef (suppressed).

    my $chflags = '';
    my @chmods = (0) x 14;

    # Assume major triad.
    vec($chflags,3,1) = 1;
    vec($chflags,5,1) = 1;
    $chmods[3] = 0;
    $chmods[5] = 0;

    # Then other modifications.
    while ( $mod && $mod ne '' ) {

	if ( $mod =~ /^maj7?(?:\.?(.*))?/ ) {	# Maj7
	    $mod = $+;
	    vec($chflags,7,1) = 1;
	    $chmods[7] = 1;
	    next;
	}
	if ( $mod =~ /^m(?:in)?7(?:\.?(.*))?/ ) {	# Minor triad 7
	    $mod = $+;
	    vec($chflags,7,1) = 1;
	    $chmods[7] = 0;
	    vec($chflags,3,1) = 1;
	    $chmods[3] = -1;
	    next;
	}
	if ( $mod =~ /^m(?:\.?(.*))?/ ) {	# Minor triad
	    $mod = $+;
	    vec($chflags,3,1) = 1;
	    $chmods[3] = -1;
	    next;
	}

	# Transform 7sus4 into something we can parse.
	$mod =~ s/^(\d+)sus(\d?)/sus$2.$1/;

	if ( $mod =~ /^sus2(?:\.(.*))?/ ) {	# Suspended second
	    $mod = $+;
	    vec($chflags,3,1) = 0;
	    undef $chmods[3];
	    next;
	}
	if ( $mod =~ /^sus4?(?:\.(.*))?/ ) {	# Suspended fourth
	    $mod = $+;
	    vec($chflags,4,1) = 1;	# does it?
	    undef $chmods[3];
	    $chmods[4] = 0;
	    next;
	}
	if ( $mod =~ /^aug(?:\.?(.*))?/ ) {		# Augmented
	    $mod = $+;
	    vec($chflags,5,1) = 1;
	    $chmods[5] = 1;
	    next;
	}
	if ( $mod =~ /^dim(?:\.?(.*))?/ ) {	# Diminished
	    $mod = $+;
	    vec($chflags,3,1) = 1;
	    vec($chflags,5,1) = 1;
	    vec($chflags,7,1) = 1;
	    $chmods[3] = -1;
	    $chmods[5] = -1;
	    $chmods[7] = -1;
	    next;
	}
#	if ( $mod =~ /^%(.*)/ ) {	# half-diminished 7
#	    $mod = $+;
#	    $chflags = '';
#	    vec($chflags,3,1) = 1;
#	    vec($chflags,5,1) = 1;
#	    vec($chflags,7,1) = 1;
#	    $chmods[3] = -1;
#	    $chmods[5] = -1;
#	    $chmods[7] = 0;
#	    next;
#	}
	if ( $mod =~ /^(2|5|6|7|9|10|11|13)([-+])?(?:\.(.*))?/ ) { # addition
	    $mod = $3;
	    # 13th implies 11th implies 9th implies 7th...
	    if ( $1 > 7 && !(vec($chflags,7,1)) ) {
		vec($chflags,7,1) = 1;
		$chmods[7] = 0;
	    }
	    if ( $1 > 10 && !(vec($chflags,9,1)) ) {
		vec($chflags,9,1) = 1;
		$chmods[9] = 0;
	    }
	    if ( $1 > 11 && !(vec($chflags,11,1)) ) {
		vec($chflags,11,1) = 1;
		$chmods[11] = 1;
	    }
	    vec($chflags,$1,1) = 1;
	    $chmods[$1] = 0;
	    if ( defined $2 ) {
		$chmods[$1] = ($2 eq '+') ? 1 : -1;
	    }
	    next;
	}
	if ( $mod =~ /^\^(\d+)(?:\.(.*))?/ ) {
	    $mod = $2;
	    vec($chflags,$1,1) = 1;
	    undef $chmods[$1];
	    next;
	}

	# Power chords.
	if ( $mod =~ /^\/(.+)/ ) {
	    my @ch = split(/\//, $1);
	    foreach my $c ( @ch ) {
	#	my $p = eval { App::Music::PlayTab::Note->parse($c) };
		my $p = eval { App::Music::PlayTab::Chord->parse($c) };
		croak("Unrecognized bass of chord: ".$self->{_unparsed})
		  unless defined $p;
		$self->{bass} ||= [];
		push(@{$self->{bass}}, $p);
	    }
	    last;
	}
	croak("Unrecognized modification of chord: ".$self->{_unparsed});
    }

    my @vec = (0);
    for ( 1..13 ) {
	next unless vec($chflags,$_,1);
	next unless defined $chmods[$_];
	push (@vec, (0,0,2,4,5,7,9,10,12,14,16,17,19,21)[$_]+$chmods[$_]);
    }

    $self->{vec} = [@vec];

    warn("=> Chord ", $self->{_unparsed}, ": ", $self->{key}->key,
	 " (", $self->{key}->name, ") [ @vec ]\n")
      if $self->{_debug};

    $self;
}

1;

__END__

=head1 NAME

App::Music::PlayTab::LyChord - Parse LilyPond chords.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
