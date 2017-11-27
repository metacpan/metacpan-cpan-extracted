#! perl

# Author          : Johan Vromans
# Created On      : Wed Aug 22 22:33:31 2007
# Last Modified By: Johan Vromans
# Last Modified On: Sun Jan 18 15:51:41 2015
# Update Count    : 31
# Status          : Unknown, Use with caution!

package App::Music::PlayTab::Chord;

use strict;
use warnings;

our $VERSION = "1.010";

use App::Music::PlayTab::Note;
use Carp;

sub new {
    my $pkg = shift;
    bless {}, $pkg;
}

sub parse {
    my ($self, $chord) = @_;

    $self = $self->new unless ref($self);
    delete $self->{bass};
    delete $self->{high};
    $self->{_unparsed} = $chord;
    $chord = lc($chord);
    $self->{_debug} = $chord =~ s/^\?//;
    my $key = $chord;
    my $mod = '';

    # Separate the chord key from the modifications.
    if ( $chord =~ /(^[a-g*](\#|b|s(?!us)|es|is)?)(.*)/ ) {
	$key = $1;
	$mod = $3;
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

    $mod =~ s/^-/min/;		# Minor triad
    $mod =~ s/^\+/aug/;		# Augmented triad
    $mod =~ s/^0/dim/;		# Diminished

    # Then other modifications.
    while ( $mod ne '' ) {

	if ( $mod =~ /^[() ._](.*)/ ) {	# syntactic sugar
	    $mod = $+;
	    next;
	}
	if ( $mod =~ /^maj7?(.*)/ ) {	# Maj7
	    $mod = $+;
	    vec($chflags,7,1) = 1;
	    $chmods[7] = 1;
	    next;
	}
	if ( $mod =~ /^(min|m)7(.*)/ ) { # Minor triad + 7
	    $mod = $+;
	    vec($chflags,7,1) = 1;
	    $chmods[7] = 0;
	    vec($chflags,3,1) = 1;
	    $chmods[3] = -1;
	    next;
	}
	if ( $mod =~ /^(min|m)(.*)/ ) {	# Minor triad
	    $mod = $+;
	    vec($chflags,3,1) = 1;
	    $chmods[3] = -1;
	    next;
	}
	if ( $mod =~ /^sus2(.*)/ ) {	# Suspended second
	    $mod = $+;
	    vec($chflags,3,1) = 0;
	    undef $chmods[3];
	    next;
	}
	if ( $mod =~ /^sus4?(.*)/ ) {	# Suspended fourth
	    $mod = $+;
	    vec($chflags,4,1) = 1;	# does it?
	    undef $chmods[3];
	    $chmods[4] = 0;
	    next;
	}
	if ( $mod =~ /^aug(.*)/ ) {		# Augmented
	    $mod = $+;
	    vec($chflags,5,1) = 1;
	    $chmods[5] = 1;
	    next;
	}
	if ( $mod =~ /^(o|dim)(.*)/ ) {	# Diminished
	    $mod = $+;
	    vec($chflags,3,1) = 1;
	    vec($chflags,5,1) = 1;
	    vec($chflags,7,1) = 1;
	    $chmods[3] = -1;
	    $chmods[5] = -1;
	    $chmods[7] = -1;
	    next;
	}
	if ( $mod =~ /^%(.*)/ ) {	# half-diminished 7
	    $mod = $+;
	    $chflags = '';
	    vec($chflags,3,1) = 1;
	    vec($chflags,5,1) = 1;
	    vec($chflags,7,1) = 1;
	    $chmods[3] = -1;
	    $chmods[5] = -1;
	    $chmods[7] = 0;
	    next;
	}
	if ( $mod =~ /^([\#b])?(2|5|6|7|9|10|11|13)(.*)/ ) { # addition
	    $mod = $+;
	    # 13th implies 11th implies 9th implies 7th...
	    if ( $2 > 7 && !(vec($chflags,7,1)) ) {
		vec($chflags,7,1) = 1;
		$chmods[7] = 0;
	    }
	    if ( $2 > 10 && !(vec($chflags,9,1)) ) {
		vec($chflags,9,1) = 1;
		$chmods[9] = 0;
	    }
	    if ( $2 > 11 && !(vec($chflags,11,1)) ) {
		vec($chflags,11,1) = 1;
		$chmods[11] = 1;
	    }
	    vec($chflags,$2,1) = 1;
	    $chmods[$2] = 0;
	    if ( defined $1 ) {
		$chmods[$2] = ($1 eq '#') ? 1 : -1;
	    }
	    next;
	}
	if ( $mod =~ /^no\s*(\d+)(st|nd|rd|th)?(.*)/ ) {
	    $mod = $+;
	    vec($chflags,$1,1) = 1;
	    undef $chmods[$1];
	    next;
	}

	# High add-ons.
	if ( $mod =~ /^\\([^\/]+)(.*)/ ) {
	    my @ch = split(/\\/, $1);
	    $mod = $2;
	    foreach my $c ( @ch ) {
		my $p = eval { __PACKAGE__->new->parse($c) };
		croak("Unrecognized add of chord: ".$self->{_unparsed})
		  unless defined $p;
		$self->{high} ||= [];
		push(@{$self->{high}}, $p);
	    }
	    last;
	}

	# Power chords.
	if ( $mod =~ /^\/(.+)/ ) {
	    my @ch = split(/\//, $1);
	    foreach my $c ( @ch ) {
		my $p = eval { __PACKAGE__->new->parse($c) };
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

    # Traditional chords do not include a duration.
    $self->{duration} = 0;

    $self;
}

sub transpose {
    my ($self, $xp) = @_;
    return $self unless $xp;
    $self->{key}->transpose($xp);
    if ( $self->{bass} ) {
	$_->transpose($xp) for @{$self->{bass}};
    }
    if ( $self->{high} ) {
	$_->transpose($xp) for @{$self->{high}};
    }
    $self;
}

sub name {
    my ($self) = @_;
    my $res = $self->{key}->name;

    my @v = @{$self->{vec}};
    my $v = "@v ";
    shift (@v);

    if ( $v =~ s/^0 (2 )?4 (6|7|8) / / ) {
	$res .= $2 == 8 ? '+' : '';
	$v = ' 6' . $v if $2 == 6;
	$v = ' 2' . $v if defined $1;
    }
    elsif ( $v =~ s/^0 3 6 9 / / ) {
	$res .= 'o';
    }
    elsif ( $v =~ s/^0 (2 )?3 (6|7|8) / / ) {
	if ( $2 == 6 ) {
	    $res .= ( $v =~ s/^ 10 // ) ? '%' : 'o';
	}
	else {
	    $res .= 'm';
	}
	$v = ' 8' . $v if $2 == 8;
	$v = ' 2' . $v if defined $1;
    }
    $v =~ s/^0 5 7 / 5 7 /;
    $v =~ s/ 10 14 18 (21) / $1 /;		# 13
    $v =~ s/ 10 14 18 (20|22) / 10 $1 /;	#  7#13 7b13
    $v =~ s/ 10 14 (17) / $1 /;			# 11
    $v =~ s/ 10 14 (18) / 10 $1 /;		#  7#11
    $v =~ s/ 10 (14) / $1 /;			#  9
    $v =~ s/ 10 (15) / 10 $1 /;			#  7#9
    $v =~ s/ 11 14 18 (21|22) / $1 11 /;	# 13#5
    $v =~ s/ 11 14 (17|18) / $1 11 /;		# 11#5
    $v =~ s/ 11 (14|15) / $1 11 /;		#  9#5
    if ( $v =~ s/ 10 / / ) {
	$res .= '7';
    }
    elsif ( $v =~ s/^( \d| 10|) 11 / $1/ ) {
	$res .= 'maj7';
    }
    if ( $v =~ s/ 5 7 / / ) {
	$res .= 'sus4';
    }
    elsif ( $v =~ s/^0 7 / / ) {
	$res .= 'sus2';
    }
    elsif ( $v =~ s/^0 4 / / ) {
	$res .= 'no5';
    }
    my $res1 = $res;		# for debug

    chop ($v);
    $v =~ s/^ //;
    @v = split(' ', $v);
    foreach ( @v ) {
	$res .= '('.('1','b2','2','b3','3','4','b5','5','#5','6','7','#7','8','b9','9','#9','b11','11','#11','12','b13','13')[$_].')';
    }
    my $res0 = $res;
    $res =~ s/^([^\(]*[^\d])?\((\d+)\)([^\d][^\(]*|)$/$1$2$3/;
    $res =~ s/7?(6|\(6\))(9|\(9\))/6.9/;
    $res =~ s/(4|\(4\))(5|\(5\))/sus4/;
    $res =~ s/(1|\(1\))(5|\(5\))/sus2/;

    $res = join("\\", $res, map { $_->name } @{$self->{high}})
      if $self->{high};
    $res = join("/", $res, map { $_->name } @{$self->{bass}})
      if $self->{bass};

    warn("=> Chord ", $self->{_unparsed}, ": ", $self->{key}->key,
	 " (", $self->{key}->name, ") [ @{$self->{vec}} ] ->",
	 " $res1 [ $v ] -> $res0 -> $res\n")
      if $self->{_debug};

    return $res;
}

sub duration {
    my ($self) = @_;
    $self->{duration};
}

sub duration_base {
    my ($self) = @_;
    16;
}

sub bass {
    my ( $self ) = @_;
    $self->{bass};
}

sub is_rest {
    shift->{_isrest};
}

1;

__END__

=head1 NAME

App::Music::PlayTab::Chord - Parse chord names.

=head1 DESCRIPTION

This is an internal module for the App::Music::PlayTab application.
