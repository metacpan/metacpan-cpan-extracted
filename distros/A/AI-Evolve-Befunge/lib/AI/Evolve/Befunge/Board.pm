package AI::Evolve::Befunge::Board;
use strict;
use warnings;
use Carp;

use AI::Evolve::Befunge::Util qw(code_print);
use AI::Evolve::Befunge::Critter;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors( qw{ size dimensions } );

=head1 NAME

    AI::Evolve::Befunge::Board - board game object


=head1 SYNOPSIS

    my $board = AI::Evolve::Befunge::Board->new(Size => $vector);
    $board->set_value($vector, $value);
    $board->clear();


=head1 DESCRIPTION

This module tracks board-game state for AI::Evolve::Befunge.  It is only used
for board-game-style physics, like tic tac toe, othello, go, chess, etc.
Non-boardgame applications do not use a Board object.


=head1 CONSTRUCTOR

=head2 new

    AI::Evolve::Befunge::Board->new(Size => $vector);
    AI::Evolve::Befunge::Board->new(Size => $number, Dimensions => $number);

Creates a new Board object.  You need to specify the board-size somehow, either
by providing a Language::Befunge::Vector object, or by specifying the size of
the side of a hypercube and the number of dimensions it exists in (2 is the
most likely number of dimensions).  If the Size argument is numeric, the
Dimensions argument is required, and a size vector will be generated
internally.

=cut

# FIXME: fully vectorize this, and make this module dimensionality-independent
# (maybe just use another laheyspace for the storage object)

sub new {
    my $self = bless({}, shift);
    my %args = @_;
    my $usage = "\nUsage: ...Board->new(Dimensions => 4, Size => 8) or ...Board->new(Size => \$vector)";
    croak($usage) unless exists $args{Size};
    if(ref($args{Size})) {
        if(exists($args{Dimensions})) {
            croak "Dimensions argument doesn't match the number of dimensions in the vector"
                unless $args{Size}->get_dims() == $args{Dimensions};
        } else {
            $args{Dimensions} = $args{Size}->get_dims();
        }
    } else {
        if(exists($args{Dimensions})) {
            $args{Size} = Language::Befunge::Vector->new(
                map { $args{Size} } (1..$args{Dimensions}));
        } else {
            croak "No Dimensions argument given, and Size isn't a vector";
        }
    }

    $$self{size}       = $args{Size};
    $$self{dimensions} = $args{Dimensions};

    foreach my $dim (0..$$self{size}->get_dims()-1) {
        croak("Size[$dim] must be at least 1!")
            unless $$self{size}->get_component($dim) >= 1;
        if($dim >= 2) {
            croak("This module isn't smart enough to handle more than 2 dimensions yet")
                unless $$self{size}->get_component($dim) == 1;
        }
    }
    $$self{sizex} = $$self{size}->get_component(0);
    $$self{sizey} = $$self{size}->get_component(1);

    $$self{b} = [];
    for(0..$$self{sizey}-1) {
        push(@{$$self{b}}, [ map { 0 } (1..$$self{sizex})]);
    }
    return $self;
}


=head1 METHODS

=head2 clear

    $board->clear();

Clear the board - set all spaces to 0.

=cut

sub clear {
    my $self = shift;
    $$self{b} = [];
    for(0..$$self{sizey}-1) {
        push(@{$$self{b}}, [ map { 0 } (0..$$self{sizex}-1)]);
    }
}


=head2 as_string

    my $string = $board->as_string();

Returns an ascii-art display of the current board state.  The return value
looks like this (without indentation):

    .ox
    .x.
    oxo

=cut

sub as_string {
    my $self = shift;
    my @char = ('.', 'x', 'o');
    my $code = join("\n", map { join('', map { $char[$_] } (@{$$self{b}[$_]}))} (0..$$self{sizey}-1));
    return "$code\n";
}


=head2 as_binary_string

    my $binary = $board->as_binary_string();

Returns an ascii-art display of the current board state.  It looks the same as
->as_string(), above, except that the values it uses are binary values 0, 1,
and 2, rather than plaintext descriptive tokens.  This is suitable for passing
to Language::Befunge::LaheySpace::Generic's ->store() method.

=cut

sub as_binary_string {
    my $self = shift;
    my $code = join("\n",
        map { join('', map { chr($_) } (@{$$self{b}[$_]}))} (0..$$self{sizey}-1));
    return "$code\n";
}


=head2 output

    $board->output();

Prints the return value of the ->as_string() method to the console, decorated
with row and column indexes.  The output looks like this (without indentation):

       012
     0 .ox
     1 .x.
     2 oxo

=cut

sub output {
    my $self = shift;
    code_print($self->as_string(),$$self{sizex},$$self{sizey});
}


=head2 fetch_value

    $board->fetch_value($vector);

Returns the value of the board space specified by the vector argument.  This
is typically a numeric value; 0 means the space is unoccupied, otherwise the
value is typically the player number who owns the space, or the piece-type (for
games which have multiple types of pieces), or whatever.

=cut

sub fetch_value {
    my ($self, $v) = @_;
    croak("need a vector argument") unless ref($v) eq 'Language::Befunge::Vector';
    my ($x, $y, @overflow) = $v->get_all_components();
    croak "fetch_value: x value '$x' out of range!" if $x < 0 or $x >= $$self{sizex};
    croak "fetch_value: y value '$y' out of range!" if $y < 0 or $y >= $$self{sizey};
    return $$self{b}[$y][$x];
}


=head2 set_value

    $board->fetch_value($vector, $value);

Set the value of the board space specified by the vector argument.

=cut

sub set_value {
    my ($self, $v, $val) = @_;
    croak("need a vector argument") unless ref($v) eq 'Language::Befunge::Vector';
    my ($x, $y, @overflow) = $v->get_all_components();
    croak "set_value: x value '$x' out of range!" if $x < 0 or $x >= $$self{sizex};
    croak "set_value: y value '$y' out of range!" if $y < 0 or $y >= $$self{sizey};
    croak "undef value!" unless defined $val;
    croak "data '$val' out of range!" unless $val >= 0 && $val < 3;
    $$self{b}[$y][$x] = $val;
}


=head2 copy

    my $new_board = $board->copy();

Create a new copy of the board.

=cut

sub copy {
    my ($self) = @_;
    my $new = ref($self)->new(Size => $$self{size});
    my $min = Language::Befunge::Vector->new_zeroes($$self{dimensions});
    my $max = Language::Befunge::Vector->new(map { $_ - 1 } ($$self{size}->get_all_components));
    for(my $this = $min->copy; defined $this; $this = $this->rasterize($min,$max)) {
        $new->set_value($this,$self->fetch_value($this));
    }
    return $new;
}

1;
