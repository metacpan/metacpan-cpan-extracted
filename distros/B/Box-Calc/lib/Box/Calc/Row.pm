package Box::Calc::Row;
$Box::Calc::Row::VERSION = '1.0206';
use strict;
use Moose;
use Box::Calc::Item;
use List::Util qw/sum/;
use Log::Any qw($log);

=head1 NAME

Box::Calc::Row - The smallest organizational unit in a box.

=head1 VERSION

version 1.0206

=head1 SYNOPSIS

 my $row = Box::Calc::Row->new(max_x => 6);
 
=head1 METHODS

=head2 new(params)

Constructor.

=over

=item max_x

The maximimum width of the row. This is equivalent to the C<x> or longest dimension of the containing box. 

=back

=head2 fill_weight()

Returns the weight of the items in this row.

=cut

has fill_weight => (
    is          => 'rw',
    default     => 0,
    isa         => 'Num',
);

=head2 fill_x()

Returns how full the row is in the C<x> dimension.

=cut

has fill_x => (
    is          => 'rw',
    default     => 0,
    isa         => 'Num',
);

=head2 fill_y()

Returns how full the row is in the C<y> dimension.

=cut

has fill_y => (
    is          => 'rw',
    default     => 0,
    isa         => 'Num',
);

=head2 fill_z()

Returns how full the row is in the C<z> dimension.

=cut

has fill_z => (
    is          => 'rw',
    default     => 0,
    isa         => 'Num',
);

=head2 max_x()

Returns the maximum C<x> dimension of this row. See C<new> for details.

=cut

has max_x => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 items()

Returns an array reference of items contained in this row.

=head2 count_items()

Returns the number of items contained in this row.

=cut

has items => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Item]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        count_items => 'count',
    }
);

=head2 calculate_weight()

Calculates the weight of all the items in this row, and returns that value.

=cut

sub calculate_weight {
    my $self = shift;
    return $self->fill_weight;
}

=head2 pack_item(item)

Places an item into the row, and updates all the relevant statistics about the row.

Returns 1 on success or 0 on failure.

=over

=item item

A L<Box::Calc::Item> instance.

=back

=cut

sub pack_item {
    my ($self, $item) = @_;
    if ($item->x > $self->max_x - $self->fill_x) {
        $log->info('No room in row for '.$item->{name}.', requesting new row.');
        return 0;
    }
    push @{$self->items}, $item;
    $self->fill_weight($self->fill_weight + $item->weight);
    $self->fill_x($self->fill_x + $item->x);
    $self->fill_y($item->y) if $item->y > $self->fill_y;
    $self->fill_z($item->z) if $item->z > $self->fill_z;
    return 1;
}


=head2 packing_list(weight, list)

Updates a scalar reference with the weight of the row and a hash reference of all the items in this row.

=cut

sub packing_list {
    my ($self, $weight, $list) = @_;
    foreach my $item (@{$self->items}) {
        ${$weight} += $item->weight;
        $list->{$item->name}++;
    }
}

=head2 packing_instructions()

Returns a hash reference of items contained in this row via the C<describe> method, and other important info about the row. Example:

 {
   items => [ ... ],
   x     => 3,
   y     => 2,
   z     => 2
 }

=cut

sub packing_instructions {
    my $self = shift;
    return {
        items               => [map { $_->describe } @{ $self->items }], 
        fill_x              => $self->fill_x,
        fill_y              => $self->fill_y,
        fill_z              => $self->fill_z,
        calculated_weight   => $self->calculate_weight,
    };
}


=head2 used_volume

Returns the real used volume for this row.

=head2 volume 

Returns the exact volume needed for this row.    

=cut

sub used_volume {
    my $self = shift;
    return sum map { $_->volume } @{ $self->items };
}

sub volume {
    return $_[0]->fill_x * $_[0]->fill_y * $_[0]->fill_z;
}

no Moose;
__PACKAGE__->meta->make_immutable;
