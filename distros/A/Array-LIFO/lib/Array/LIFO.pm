package Array::LIFO;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Last-in, First-out array

our $VERSION = '0.0202';

use Moose;
use namespace::autoclean;



has max_size => (
    is      => 'ro',
    isa     => 'Int',
    default => -1,
);

has sum => (
    is  => 'rw',
    isa => 'Int',
);

has average => (
    is  => 'rw',
    isa => 'Num',
);

has stack => (
    is      => 'ro',
    isa     => 'ArrayRef[Item]',
    traits  => [ 'Array' ],
    default => sub { [] },
    handles => {
        add    => 'unshift',
        remove => 'shift',
        size   => 'count',
    },
    trigger => sub {
        my $self = shift;

        if ( $self->{max_size} > 0 ) {
            my $array = $self->{stack};
            while ( @{ $array } > $self->{max_size} ) {
                shift @{ $array };
            }
        }

        my $size = $self->size;

        my $sum = 0;
        for my $q ( @{ $self->stack } ) {
            if ( $q =~ /^-?\d+\.?\d*$/ ) {
                $sum += $q;
            }
        }

        $self->sum($sum);
        if ( $sum > 0 ) {
            $self->average( $sum / $size );
        }
        else {
            $self->average(0);
        }
    },
);

around add => sub {
    my $orig = shift;
    my $self = shift;
    $self->$orig(@_);
    my $last = $self->{stack}[0];
    $last;
};

sub peek {
    my $self = shift;
    my $element = shift || 0;
    return $self->stack->[$element];
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Array::LIFO - Last-in, First-out array

=head1 VERSION

version 0.0202

=head1 SYNOPSIS

  use Array::LIFO;
  my $ar = Array::LIFO->new( max_size => 12 );
  $ar->add(20);
  $ar->add(18);
  $ar->add(22);
  print $ar->size, "\n";
  print $ar->average, "\n";
  print $ar->sum, "\n";
  print $ar->peek, "\n";
  $ar->remove;
  print "@{ $ar->stack }\n";

=head1 DESCRIPTION

An C<Array::LIFO> allows the declaration of an array with last-in, first-out
operation.  That is, a "stack."

=head1 NAME

Array::LIFO - Last-in, First-out array

=head1 METHODS

=head2 new

  $x = Array::LIFO->new;
  $x = Array::LIFO->new( max_size => $m );

=over 4

=item max_size (optional)

Numeric value of how large the array is allowed to get.  When it reaches
max_size, new items are not added.

If no value is passed, there is no max size.

=back

=head2 add

    $ar->add($x);

You can add any type of item to the array.  If the element is not a number it
will be ignored by the C<sum()> and C<average()> calculations.

=head2 remove

    $ar->remove;

Remove the last item on the array.

=head2 size

    $size = $ar->size;

How many elements are in the array.

=head2 max_size

    $max = $ar->max_size;

The maximum size the array is allow to be.

=head2 sum

    $sum = $ar->sum;

The sum of all numeric elements in the array.

=head2 average

    $avg = $ar->average;

The average of all numeric elements in the array.

=head2 peek

    $last = $ar->peek;
    $element = $ar->peek($index);

Return an element of the array given by the index argument.  If no index is
provided, the last element added to the stack is returned.

=head1 SEE ALSO

L<Array::FIFO>

=head1 AUTHOR

Gene Boggs <gene@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
