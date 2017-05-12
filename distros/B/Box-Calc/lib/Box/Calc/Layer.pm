package Box::Calc::Layer;
$Box::Calc::Layer::VERSION = '1.0200';
use strict;
use Moose;
use Box::Calc::Row;
use List::Util qw/sum/;
use Log::Any qw($log);
use Data::Dumper;

=head1 NAME

Box::Calc::Layer - A box is packed with multiple layers.

=head1 VERSION

version 1.0200

=head1 SYNOPSIS

 my $row = Box::Calc::Row->new(max_x => 6);
 
=head1 METHODS

=head2 new(params)

Constructor.

B<NOTE:> A layer is automatically created containing a single empty L<Box::Calc::Row>.

=over

=item max_x

The maximimum width of the layer. This is equivalent to the C<x> or longest dimension of the containing box. 

=item max_y

The maximimum depth of the layer. This is equivalent to the C<y> or middle dimension of the containing box. 

=back

=head2 fill_x()

Returns how full the layer is in the C<x> dimension.

=cut

sub fill_x {
    my $self = shift;
    my $value = 0;
    foreach my $row (@{$self->rows}) {
        $value = $row->fill_x if $row->fill_x > $value;
    }
    return sprintf ("%.4f", $value);
}

=head2 fill_y()

Returns how full the layer is in the C<y> dimension.

=cut

sub fill_y {
    my $self = shift;
    my $value = 0;
    foreach my $row (@{$self->rows}) {
        $value += $row->fill_y;
    }
    return sprintf ("%.4f", $value);
}

=head2 fill_z()

Returns how full the layer is in the C<z> dimension.

=cut

sub fill_z {
    my $self = shift;
    my $value = 0;
    foreach my $row (@{$self->rows}) {
        $value = $row->fill_z if $row->fill_z > $value;
    }
    return sprintf ("%.4f", $value);
}

=head2 max_x()

Returns the maximum C<x> dimension of this layer. See C<new> for details.

=cut

has max_x => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 max_y()

Returns the maximum C<y> dimension of this layer. See C<new> for details.

=cut

has max_y => (
    is          => 'ro',
    required    => 1,
    isa         => 'Num',
);

=head2 rows()

Returns an array reference of the list of L<Box::Calc::Row> contained in this layer.

=head2 count_rows()

Returns the number of rows contained in this layer.

=cut

has rows => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Row]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        count_rows => 'count',
    }
);

=head2 create_row()

Adds a new L<Box::Calc::Row> to this layer.

=cut

sub create_row {
    my $self = shift;
    push @{$self->rows}, Box::Calc::Row->new(max_x => $self->max_x);
}

sub BUILD {
    my $self = shift;
    $self->create_row;
}

=head2 calculate_weight()

Calculates and returns the weight of all the rows in this layer.

=cut

sub calculate_weight {
    my $self = shift;
    my $weight = 0;
    foreach my $row (@{$self->rows}) {
        $weight += $row->calculate_weight;
    }
    return $weight;
}

=head2 pack_item(item)

Add a L<Box::Calc::Item> to this layer.

Returns 1 on success or 0 on failure.

=over

=item item

The L<Box::Calc::Item> instance you want to add to this layer.

=back

=cut

sub pack_item {
    my ($self, $item, $count) = @_;
    $count ||= 1;
    if ($count > 99) {
        $log->warn($item->{name}.' is causing infinite recursion in Box::Calc::Layer');
        $log->debug(Dumper($item));
        return 0;
    }
    my $fill_z = $self->fill_z;
    my $fill_y = $self->fill_y;
    if ($item->y > $self->max_y - $fill_y + $self->rows->[-1]->fill_y # item would make the layer too wide
        ) {
        $log->info($item->{name}.' would make the layer too wide, requesting new layer.');
        return 0;
    }
    if ($fill_z > 0 && $item->z > $fill_z * 1.75 && $item->y < $fill_y) { # item would make the layer substantially taller, unless the layer is currently pretty narrow
        $log->info($item->{name}.' would make this layer substantially taller, requesting new layer.');
        return 0;
    }
    if ($self->rows->[-1]->pack_item($item)) {
        return 1;
    }
    else {
        if ($item->y > $self->max_y - $self->fill_y) {
            $log->info($item->{name}.' will not fit in a new row in this layer, requesting new layer.');
            return 0;
        }
        else {
            $self->create_row;
            return $self->pack_item($item, $count + 1);
        }
    }
}

=head2 packing_list(weight, list)

Updates a scalar reference with the weight of the layer and a hash reference of all the items in this layer.

=cut

sub packing_list {
    my ($self, $weight, $list) = @_;
    foreach my $row (@{$self->rows}) {
        $row->packing_list($weight, $list)
    }
}

=head2 packing_instructions()

Returns a description of the layer.

{
 fill_x => 3,
 fill_y => 3,
 fill_z => 1,
 rows => [ ... ],
}

=cut

sub packing_instructions {
    my $self = shift;
    return {
        rows                => [  map { $_->packing_instructions } @{ $self->rows } ],
        fill_x              => $self->fill_x,
        fill_y              => $self->fill_y,
        fill_z              => $self->fill_z,
        calculated_weight   => $self->calculate_weight,
    }
}

sub used_volume {
    my $self = shift;
    return sum map { $_->used_volume } @{ $self->rows };
}


sub volume {
    return $_[0]->fill_x * $_[0]->fill_y * $_[0]->fill_z;
}

no Moose;
__PACKAGE__->meta->make_immutable;
