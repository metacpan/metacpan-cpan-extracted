=head1 NAME

Chess::Piece - a base class for chess pieces

=head1 SYNOPSIS

    $piece = Chess::Piece->new("e2", "white", "White King's pawn");
    $piece->set_current_square("e4");
    $e4 = $piece->get_current_square();
    $piece->set_description("My Piece");
    $description = $piece->get_description();
    $color = $piece->get_color();
    if (!$piece->moved()) {
	# do something with the unmoved piece
    }
    $piece->set_moved(1);
    if ($piece->threatened()) {
	# do something with the threatened piece
    }
    $piece->set_threatened(1);
    if ($piece->captured()) {
	# do something with the captured piece
    }
    $piece->set_captured(1);

=head1 DESCRIPTION

The Chess module provides a framework for writing chess programs with Perl.

This class represents the parent class for all Chess pieces, and contains
accessors and mutators for all the common properties of chess pieces.
The following is an exhaustive list of the properties of a Chess::Piece:

 * initial square (read-only, specified at construction)
 * color (read-only, specified at construction)
 * current square
 * description
 * a flag indicating whether or not the piece has moved
 * a flag indicating whether or not the piece is threatened
 * a flag indicating whether or not the piece was captured

See L</"METHODS"> for details of the methods which manipulate and return these
properties.

=head1 METHODS

=head2 Construction

=over 4

=item new()

Constructs a new Chess::Piece. Requires a two scalar arguments containing the
initial square this piece is on and the color of the piece. If the program
will use colors other than 'black' and 'white', then subclasses of
Chess::Piece will need to override the L</"can_reach()"> method to take these
colors into account.  Optionally takes a third argument containing a text 
description of the piece. Returns a blessed Chess::Piece object reference 
that can be used to call any of the methods listed in L</"Object methods">. 
The square is not tested for validity, so the program must validate the 
square before calling new().

    $piece = Chess::Piece->new("e2", "white");
    $piece = Chess::Piece->new("e2", "white", "White King's pawn");

See also L</"clone"> to construct a new Chess::Piece from an existing one.

=head2 Class methods

There are no class methods for this class.

=head2 Object methods

=item clone()

Clones an existing Chess::Piece. Requires no arguments. Returns a blessed
Chess::Piece object reference which has data identical to the cloned piece,
but can be manipulated separately.

    $clone = $piece->clone();
    $clone->set_description("Cloned piece");

=item get_initial_square()

Takes no parameters. Returns the initial square property that the piece was 
constructed with.

=item get_current_square()

Takes no parameters. Returns the value of the current square property.

=item set_current_square()

Takes a single scalar parameter containing the current square of this piece.
Sets the current square property to this value. Like L</"new()">, this square
is not tested for validity and should be tested before calling the function.

=item get_description()

Takes no parameters. Returns the value of the description property.

=item set_description()

Takes a single scalar parameter containing a description for the piece.
Sets the description property to this value.

=item get_color()

Takes no parameters. Returns the color property the piece was constructed with.

=item moved()

Takes no parameters. Returns true iff the piece has not been moved (as
determined by a call to L</"set_moved()">).

=item set_moved()

Takes a single scalar parameter containing true or false. Sets the moved flag
if the parameter is true.

=item threatened()

Takes no parameters. Returns true iff the piece is not threatened (as
determined by a call to L</"set_threatened()">).

=item set_threatened()

Takes a single scalar parameter containing true or false. Sets the threatened
flag if the parameter is true.

=item captured()

Takes no parameters. Returns true iff the piece is not captured (as
determined by a call to L</"set_captured()">

=item set_captured()

Takes a single scalar parameter containing true or false. Sets the captured
flag, and also sets the current square property to C<undef>, if the parameter 
is true.

=item can_reach()

Takes a single scalar parameter containing the square to be tested. Returns
true if the piece can reach the given square from its current location, as
determined by a call to the abstract method L</"reachable_squares()">.

=item reachable_squares()

This is an abstract method and must be overridden in all subclasses of
Chess::Piece. Returns a list of squares (in lower-case) that the piece can
reach. This list is used by L</"can_reach()"> and various methods of
L<Chess::Game> to determine legality of moves and other high-level analyses.
Thus, subclasses of Chess::Piece not provided by this framework must return
all squares that B<may be> reached, regardless of the current state of the
board. The L<Chess::Game/"is_move_legal()"> method will then determine if all
conditions for a particular move have been met.

=back

=head1 DIAGNOSTICS

=over 4

=item Missing argument to Chess::Piece::new()

The initial square argument is required. See L</"new()"> for details on how
to call this method.

=item Invalid Chess::Piece reference

The program uses a reference which is undefined, or was obtained without
using L</"new()"> or L</"clone()">. Ensure that the program only obtains
its references from new() or clone() and that the reference refers to a
defined value.

=item Call to abstract method Chess::Piece::reachable_squares()

The L</"reachable_squares()"> function is abstract. Any class which subclasses 
Chess::Piece must provide its own implementation of this method.

=back

=head1 BUGS

Please report any bugs to the author.

=head1 AUTHOR

Brian Richardson <bjr@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2002, 2005 Brian Richardson. All rights reserved. This module
is Free Software. It may be modified and redistributed under the same terms
as Perl itself.

=cut
package Chess::Piece;

use strict;
use Carp;

use constant OBJECT_FIELDS => (
    _firstmoved => undef,
    init_sq => '',
    curr_sq => '',
    player => '',
    description => '',
    flags => 0x0
);

use constant PIECE_MOVED => 0x01;
use constant PIECE_THREATENED => 0x02;
use constant PIECE_CAPTURED => 0x04;

{
    my @_pieces = ( );
    my %object_fields = OBJECT_FIELDS;

    sub _get_piece_ref {
	my ($i) = @_;
	return $_pieces[$i];
    }

    sub new {
	my ($caller, $init_sq, $color, $desc) = @_;
	my $class = ref($caller) || $caller;
	my $obj_data = { %object_fields };
	croak "Missing argument to Chess::Piece::new()" unless ($init_sq && $color);
    	$obj_data->{init_sq} = $init_sq;
	$obj_data->{curr_sq} = $init_sq;
	$obj_data->{player} = lc $color;
	$obj_data->{description} = $desc if ($desc);
	push @_pieces, $obj_data;
	my $i = $#_pieces;
	return bless \$i, $class;
    }

    sub clone {
       	my ($clonee) = @_;
	my $class = ref($clonee) || croak "Invalid Chess::Piece reference";
	my $r_piece = _get_piece_ref($$clonee);
	croak "Invalid Chess::Piece reference" unless $r_piece;
	my $new_piece = { %$r_piece };
	push @_pieces, $new_piece;
	my $i = $#_pieces;
	return bless \$i, $class;
    }

    sub _firstmoved {
	my ($self) = @_;
	my $class = ref($self) || croak "Invalid Chess::Piece reference";
	my $r_piece = _get_piece_ref($$self);
	croak "Invalid Chess::Piece reference" unless $r_piece;
	return $r_piece->{_firstmoved};
    }

    sub _set_firstmoved {
	my ($self, $movenum) = @_;
	my $class = ref($self) || croak "Invalid Chess::Piece reference";
	my $r_piece = _get_piece_ref($$self);
	croak "Invalid Chess::Piece reference" unless $r_piece;
	$r_piece->{_firstmoved} = $movenum;
    }
}

sub get_initial_square {
    my ($self) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    return $r_piece->{init_sq};
}

sub get_current_square {
    my ($self) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    return $r_piece->{curr_sq};
}

sub set_current_square {
    my ($self, $sq) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    $r_piece->{curr_sq} = $sq;
}

sub get_description {
    my ($self) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    return $r_piece->{description};
}

sub set_description {
    my ($self, $desc) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    $r_piece->{description} = $desc;
}

sub get_player {
    my ($self) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless $r_piece;
    return $r_piece->{player};
}

sub moved {
    my ($self) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    return $r_piece->{flags} & PIECE_MOVED;
}

sub set_moved {
    my ($self, $set) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    $r_piece->{flags} |= PIECE_MOVED if ($set);
    $r_piece->{flags} &= ~PIECE_MOVED if (!$set);
}

sub threatened {
    my ($self) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    return $r_piece->{flags} & PIECE_THREATENED;
}

sub set_threatened {
    my ($self, $set) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    $r_piece->{flags} |= PIECE_THREATENED if ($set);
    $r_piece->{flags} &= ~PIECE_THREATENED if (!$set);
}

sub captured {
    my ($self) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    return $r_piece->{flags} & PIECE_CAPTURED;
}

sub set_captured {
    my ($self, $set) = @_;
    croak "Invalid Chess::Piece reference" unless (ref($self));
    my $r_piece = _get_piece_ref($$self);
    croak "Invalid Chess::Piece reference" unless ($r_piece);
    if ($set) {
	$r_piece->{curr_sq} = undef;
	$r_piece->{flags} |= PIECE_CAPTURED;
    }
    else {
	$r_piece->{flags} &= ~PIECE_CAPTURED;
    }
}

sub can_reach {
    my ($self, $sq) = @_;
    my $lsq = lc $sq;
    return grep /^$sq$/, $self->reachable_squares();
}

sub reachable_squares {
    croak "Call to abstract method Chess::Piece::reachable_squares()";
}
