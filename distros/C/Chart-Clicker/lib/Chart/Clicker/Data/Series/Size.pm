package Chart::Clicker::Data::Series::Size;
$Chart::Clicker::Data::Series::Size::VERSION = '2.90';
use Moose;

extends 'Chart::Clicker::Data::Series';

# ABSTRACT: Chart data with additional attributes for Size charts

use List::Util qw(min max);


has 'sizes' => (
    traits => [ 'Array' ],
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [] },
    handles => {
        'add_to_sizes' => 'push',
        'size_count' => 'count',
        'get_size' => 'get'
    }
);


has max_size => (
    is => 'ro',
    isa => 'Num',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return max(@{ $self->sizes });
    }
);


has min_size => (
    is => 'ro',
    isa => 'Num',
    lazy => 1,
    default => sub {
        my ($self) = @_;
        return min(@{ $self->sizes });
    }
);

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=pod

=head1 NAME

Chart::Clicker::Data::Series::Size - Chart data with additional attributes for Size charts

=head1 VERSION

version 2.90

=head1 SYNOPSIS

  use Chart::Clicker::Data::Series::Size;

  my @keys = ();
  my @values = ();
  my @sizes = ();

  my $series = Chart::Clicker::Data::Series::Size->new({
    keys    => \@keys,
    values  => \@values,
    sizes   => \@sizes
  });

=head1 DESCRIPTION

Chart::Clicker::Data::Series::Size is an extension of the Series class
that provides storage for a third variable called the size.  This is useful
for the Bubble renderer.

=head1 ATTRIBUTES

=head2 sizes

Set/Get the sizes for this series.

=head2 max_size

Gets the largest value from this Series' C<sizes>.

=head2 min_size

Gets the smallest value from this Series' C<sizes>.

=head1 METHODS

=head2 add_to_sizes

Adds a size to this series.

=head2 get_size

Get a size by it's index.

=head2 size_count

Gets the count of sizes in this series.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Cory G Watson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
