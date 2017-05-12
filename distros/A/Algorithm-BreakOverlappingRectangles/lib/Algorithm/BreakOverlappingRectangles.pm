package Algorithm::BreakOverlappingRectangles;

use strict;
use warnings;

BEGIN {
  our $VERSION = '0.01';

  require XSLoader;
  XSLoader::load('Algorithm::BreakOverlappingRectangles', $VERSION);
}


use constant X0 => 0;
use constant Y0 => 1;
use constant X1 => 2;
use constant Y1 => 3;

our $verbose = 0;

use constant NVSIZE => length pack F => 1.0;
use constant IDOFFSET => NVSIZE * 4;

sub new {
    my $class = shift;
    my $self = { rects => [],
                 name2id => {},
                 names => [],
                 n => 0 };
    bless $self, $class;
}

sub add_rectangle {
    my ($self, $x0, $y0, $x1, $y1, @names) = @_;

    ($x0, $x1) = ($x1, $x0) if $x0 > $x1;
    ($y0, $y1) = ($y1, $y0) if $y0 > $y1;

    my @ids;
    for (@names) {
        my $id = $self->{name2id}{$_};
        unless (defined $id) {
            $id = $self->{name2id}{$_} = @{$self->{names}};
            push @{$self->{names}}, $_;
        }
        push @ids, $id;
    }

    push @{$self->{rects}}, pack 'F4L*' => $x0, $y0, $x1, $y1, @ids;
    delete $self->{broken};
    ++($self->{n});
}

sub _do_break {
    my $self = shift;
    _break_rectangles $self->{rects};
    $self->{broken} = 1;
    $self->{iter} = 0;
}

* _brute_force_break = \&_brute_force_break_xs;

sub dump {
    my $self = shift;
    $self->_do_break unless $self->{broken};
    for (@{$self->{rects}}) {
        my ($x0, $y0, $x1, $y1, @ids) = unpack 'F4L*' => $_;
        my @names = map $self->{names}[$_], @ids;
        # my @names = @ids;
        print "[$x0 $y0 $x1 $y1 | @names]\n";
    }

    print "$self->{n} rectangles broken into ".(scalar @{$self->{rects}})."\n";

}

sub dump_stats {
    my $self = shift;
    $self->_do_break unless $self->{broken};
    print "$self->{n} rectangles broken into ".(scalar @{$self->{rects}})."\n";
}

sub get_rectangles {
    my $self = shift;
    $self->_do_break unless $self->{broken};
    my $names = $self->{names};
    map {
        my @a = unpack "F4I*" => $_;
        $a[$_] = $names->[$a[$_]] for (4..$#a);
        \@a;
    } @{$self->{rects}}
}


sub get_rectangles_as_array_ref {
    my $self = shift;
    tie my @iter, 'Algorithm::BreakOverlappingRectangles::Iterator', $self;
    return \@iter;
}

package Algorithm::BreakOverlappingRectangles::Iterator;

use base 'Tie::Array';

sub TIEARRAY {
    my ($class, $abor) = @_;
    my $self = bless \$abor, $class;
}

sub FETCH {
    my ($self, $index) = @_;
    my $abor = $$self;
    $abor->_do_break unless $abor->{broken};
    my $r = $abor->{rects}[$index];
    if (defined $r) {
        # print ".";
        my $names = $abor->{names};
        my ($x0, $y0, $x1, $y1, @ids) = unpack 'F4I*' => $r;
        return [$x0, $y0, $x1, $y1, map($names->[$_], @ids)];
    }
    ()
}

sub EXISTS {
    my ($self, $index) = @_;
    my $abor = $$self;
    $abor->_do_break unless $abor->{broken};
    my $rects = $abor->{rects};
    return (@$rects > $index);
}

sub FETCHSIZE {
    my ($self) = @_;
    my $abor = $$self;
    $abor->_do_break unless $abor->{broken};
    my $rects = $abor->{rects};
    return scalar(@$rects);
}

sub PUSH {
    my $self = shift;
    $self->[0] = 0;
    my $abor = $$self;
    $abor->add_rectangle(@$_) for (@_);
    1;
}


1;

__END__

=head1 NAME

Algorithm::BreakOverlappingRectangles - Break overlapping rectangles into non overlapping ones

=head1 SYNOPSIS

  use Algorithm::BreakOverlappingRectangles;

  my $bor = Algorithm::BreakOverlappingRectangles->new;

                     # id => X0, Y0, X1, Y1
  $bor->add_rectangle( A =>  0,  4,  7, 10);
  $bor->add_rectangle( B =>  3,  2,  9,  6);
  $bor->add_rectangle( C =>  5,  0, 11,  8);

  # that's:
  #
  #   Y
  #   ^
  #   |
  #  11
  #  10 +------+
  #   9 |      |
  #   8 |  A +-+---+
  #   7 |    |     |
  #   6 |  +-+---+ |
  #   5 |  |     | |
  #   4 +--+  B  | |
  #   3    |     | |
  #   2    +-+---+ |
  #   1      |  C  |
  #   0      +-----+
  #   |
  #   +-01234567891111--> X
  #               0123
  #

  $bor->dump;

  # prints:
  #
  # [0 4 3 10 | A]
  # [3 4 5 6 | A B]
  # [3 6 5 8 | A]
  # [7 2 9 4 | B C]
  # [3 2 5 4 | B]
  # [5 4 7 6 | A B C]
  # [3 8 7 10 | A]
  # [5 6 7 8 | A C]
  # [7 4 9 6 | B C]
  # [5 2 7 4 | B C]
  # [9 0 11 4 | C]
  # [9 4 11 6 | C]
  # [7 6 11 8 | C]
  # [5 0 9 2 | C]
  #
  # that's:
  #
  #   Y
  #   ^
  #   |
  #  11
  #  10 +----+-+
  #   9 |    | |
  #   8 |    +-+---+
  #   7 |    | |   |
  #   6 +--+-+-+-+-+
  #   5 |  | | | | |
  #   4 +--+-+-+ | |
  #   3    | | | | |
  #   2    +-+-+-+-+
  #   1      |     |
  #   0      +-----+
  #   |
  #   +-01234567891111--> X
  #               0123
  #

  # or alternatively:
  my $rect = $bor->get_rectangles_as_array_ref;
  print "[@$_]\n" for (@$rect);


=head1 DESCRIPTION

Given a set of rectangles that can overlap, break them in a set of non
overlapping ones.

This module is highly optimized and can handle big sets efficiently.


=head2 API

The following methods are provided:

=over 4

=item Algorithm::BreakOverlappingRectangles->new()

Creates a new object.

=item $bor->add_rectangle($x0, $y0, $x1, $y1, @names)

Adds a new rectangle to the set.

C<$x0, $y0, $x1, $y1> are the coordinates of the extremes. C<@names>
can be anything you like and will be attached to the output rectangles
contained inside this one.

=item $bor->get_rectangles()

Returns the set of non-overlapping rectangles. Every entry is an array
of the form C<[$x0, $y0, $x1, $y1, @names]>.

=item $bor->get_rectangles_as_array_ref()

Returns an array ref (actually a tied one) containing the broken
rectangles.

Rectangles are stored inside Algorithm::BreakOverlappingRectangles
objects as packed data to reduce memory comsumption, but calling the
C<get_rectangles> method expands them and so can eat lots of memory
when the number of rectangles is high. This alternative method returns
a reference to a tied array that unpacks the rectangles on the fly.

For instance:

  my $r = $abor->get_rectangles_as_array_ref;
  for (@$r) {
    print "@$_\n";
  }

=back


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Salvador FandiE<ntilde>o (sfandino@yahoo.com)

Copyright (C) 2008 by Qindel Formacion y Servicios S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
