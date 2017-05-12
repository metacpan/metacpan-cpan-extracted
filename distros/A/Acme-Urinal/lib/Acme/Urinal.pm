package Acme::Urinal;
use strict;
use warnings;

use Carp;

our $VERSION = '1.0';

=head1 NAME

Acme::Urinal - assign resources using the same algorithm used by men choosing which urinal to use

=head1 SYNOPSIS

  use Acme::Urinal;

  my $urinals = Acme::Urinal->new(8);

  say $urinal->pick_one; # prints 1
  say $urinal->pick_one; # prints 3
  say $urinal->pick_one; # prints 5
  say $urinal->pick_one; # prints 7
  say $urinal->pick_one; # prints 2
  say $urinal->pick_one; # prints 4
  say $urinal->pick_one; # prints 6
  say $urinal->pick_one; # prints 0
  say $urinal->pick_one; # prints nothing, triggers an uninit warning

  $urinal->leave(3);
  $urinal->leave(4);
  say $urinal->pick_one; # prints 4

  $urinal->leave(2);
  $urinal->leave(1);
  say $urinal->pick_one; # prints 1


=head1 DESCRIPTION

When men use a bathroom with multiple urinals. The way the urinal to use is
chosen is nearly deterministic. This module allocates resources in a way that
emulates this process.

Basically, a L<Acme::Urinal> object keeps track of a list of resources. You can
then request these resources be allocated and used by asking for one using the
L</pick_one> method. It will return the next resource according to the
algorithm. Once finished suing that resource, you may return it using the
L</leave> method.

Each resource is chosen according to the following rules:

=over

=item 1.

If possible, the lowest index resource that has a free resource on either side
is chosen.

=item 2.

Failing that, the lowest index resource with a lesser neighbor free is chosen.

=item 3.

Failing that, the lowest index resource with a greater neighbor free is chosen.

=item 4.

Failing that, the lowest index resource that is not at either end is chosen
(because those end ones usually tend to be the less preferable low urinal).

=item 5.

Finally, the lowest index resource that is available is chosen.

=back

=head1 METHODS

=head2 new

  my $urinal = Acme::Urinal->new($count);
  my $urinal = Acme::Urinal->new(\@resources);

Constructs a new Acme::Urinal object. If the argument is a positive integer, it
is the same as if an array reference were passed like this:

  [ 0 .. $count ]

If an array reference is passed, the object will use that array as the list of
resources. The array will be copied, so changes to the original, won't change
the one used by Acme::Urinal.

Anything else should cause an error.

=cut

sub new {
    my ($class, $resources) = @_;

    if (ref $resources) {
        return bless [ map { [ 0, $_ ] } @$resources ], $class;
    }
    elsif ($resources > 0) {
        return bless [ map { [ 0, $_ ] } 0 .. ($resources - 1) ], $class;
    }
    else {
        croak "incorrect argument";
    }
}

=head2 pick_one

  my $index = Acme::Urinal->pick_one;
  my ($index, $resource, $comfort_level) = Acme::Urinal->pick_one;

This will choose an available resource from those available using the algorithm
described in the L</DESCRIPTION>. If no resource is available, the return will
be C<undef> or an empty list.

In scalar context, the index of the resource is returned. In list context, a
three-element list is returned where the first element is the index, the second
is the resource that was allocated, and the third is the comfort level with
which the resource was allocated. The higher the level, the better the
allocation was (the earlier the rule from the L</DESCRIPTION> that was used to
make the allocation). Currently, the comfort level will be between 1 and 5.

=cut

sub pick_one {
    my ($self) = @_;

    my $choice_score = 0;
    my $best_choice;
    for my $i (0 .. $#$self) {
        my ($in_use, $resource) = @{ $self->[$i] };

        next if $in_use;

        if ($choice_score < 5 and $i > 0 and $i < $#$self and not($self->[$i - 1][0]) and not($self->[$i + 1][0])) {
            $choice_score = 5;
            $best_choice = $i;
            last;
        }

        elsif ($choice_score < 4 and $i > 0 and not $self->[$i - 1][0]) {
            $choice_score = 4;
            $best_choice = $i;
        }

        elsif ($choice_score < 3 and $i < $#$self and not $self->[$i + 1][0]) {
            $choice_score = 3;
            $best_choice = $i;
        }

        elsif ($choice_score < 2 and $i > 0 and $i < $#$self) {
            $choice_score = 2;
            $best_choice = $i
        }

        elsif ($choice_score < 1) {
            $choice_score = 1;
            $best_choice = $i;
        }
    }

    if (defined $best_choice) {
        $self->[$best_choice][0] = 1;

        if (wantarray) {
            return ($best_choice, $self->[$best_choice][1], $choice_score);
        }
        else {
            return $best_choice;
        }
    }

    return;
}

=head2 pick

  my $resource = $self->pick($index);
  my ($resource, $comfort_level) = $self->pick($index);

Allows you to violate the usual algorithm to pick a urinal explicitly. In scalar
context it returns the resource picked. In list context, it returns that and the
comfort level your pick has. If the resource picked is already in use, an
exception will be thrown.

=cut

sub pick {
    my ($self, $i) = @_;

    if ($self->[$i][0]) {
        croak "The resource at index $i is already in use.";
    }

    if (wantarray) {
        my @r = $self->look($i);
        $self->[$i][0] = 1;
        return @r;
    }
    else {
        my $r = $self->look($i);
        $self->[$i][0] = 1;
        return $r;
    }
}

=head2 look

  my $resource = $self->look($index);
  my ($resource, $comfort_level) = $self->look($index);

In most algorithms, this would be called "peek," but peeking in urinals is, at
best, awkward and, at worst, likely to get you beat up.

This is the same as L</pick>, but does not actually allocate. Also, the
C<$comfort_level> returned will be C<0> if the resource is currently in use.

=cut

sub look {
    my ($self, $i) = @_;

    if (wantarray) {
        my $choice_score = 0;
        if (not $self->[$i][0]) {
            if ($i > 0 and $i < $#$self and not $self->[$i - 1][0] and not $self->[$i + 1][0]) {
                $choice_score = 5;
            }

            elsif ($i > 0 and not $self->[$i - 1][0]) {
                $choice_score = 4;
            }

            elsif ($i < $#$self and not $self->[$i + 1][0]) {
                $choice_score = 3;
            }

            elsif ($i > 0 and $i < $#$self) {
                $choice_score = 2;
            }

            else {
                $choice_score = 1;
            }
        }

        return ($self->[$i][1], $choice_score);
    }
    else {
        return $self->[$i][1];
    }
}

=head2 leave

  $self->leave($index);

Frees up the resource at the given index. Throws an exception if the resource is
not currently in use.

=cut

sub leave {
    my ($self, $i) = @_;

    if (not $self->[$i][0]) {
        croak "The resource at index $i is not currently in use.";
    }

    $self->[$i][0] = 0;
    return;
}

=head1 AUTHOR

Andrew Sterling Hanenkamp C<< hanenkamp@cpan.or >>

=head1 COPYRIGHT & LICENSE

Copyright 2014 Andrew Sterling Hanenkamp.

This is free software and may be copied and distributed under the same terms as
Perl itself.

=cut

1;
