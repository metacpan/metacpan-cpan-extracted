package Box::Calc::Box;
$Box::Calc::Box::VERSION = '1.0206';
use strict;
use warnings;
use Moose;
use Storable qw(dclone);
with 'Box::Calc::Role::Container';
with 'Box::Calc::Role::Mailable';
use Box::Calc::Layer;
use Data::GUID;
use List::Util qw/sum/;
use Log::Any qw($log);
use Data::Dumper;

=head1 NAME

Box::Calc::Box - The container in which we pack items.

=head1 VERSION

version 1.0206

=head1 SYNOPSIS

 my $box = Box::Calc::Box->new(name => 'Big Box', x => 12, y => 12, z => 18, weight => 20);

=head1 METHODS

=head2 new(params)

Constructor.

B<NOTE:> All boxes automatically have one empty L<Box::Calc::Layer> added to them.

=over

=item params

=over

=item name

An identifying name for your box.

=item x

The interior width of your box.

=item y

The interior length of your box.

=item z

The interior thickness of your box.

=item weight

The weight of your box.

=back

=back

=head2 fill_weight()

Returns the weight of the items in this box.

=cut

has fill_weight => (
    is          => 'rw',
    default     => 0,
    isa         => 'Num',
);

=head2 fill_x()

Returns how full the box is in the C<x> dimension.

=cut

sub fill_x {
    my $self = shift;
    my $value = 0;
    foreach my $layer (@{$self->layers}) {
        $value = $layer->fill_x if $layer->fill_x > $value;
    }
    return sprintf ("%.4f", $value);
}

=head2 fill_y()

Returns how full the box is in the C<y> dimension.

=cut

sub fill_y {
    my $self = shift;
    my $value = 0;
    foreach my $layer (@{$self->layers}) {
        $value = $layer->fill_y if $layer->fill_y > $value;
    }
    return sprintf ("%.4f", $value);
}

=head2 fill_z()

Returns how full the box is in the C<z> dimension.

=cut

sub fill_z {
    my $self = shift;
    my $value = 0;
    foreach my $layer (@{$self->layers}) {
        $value += $layer->fill_z;
    }
    return sprintf ("%.4f", $value);
}

=head2 id()

Returns a generated unique id for this box.

=cut

has id => (
    is          => 'ro',
    default     => sub { Data::GUID->new->as_string },
);

=head2 name()

Returns the name of the box.

=cut

has name => (
    is          => 'ro',
    isa         => 'Str',
    required    => 1,
);

=head2 layers()

Returns an array reference of the L<Box::Calc::Layer>s in this box.

=cut

has layers => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Layer]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        count_layers => 'count',
    }
);

=head2 void_weight()

Returns the weight assigned to the void space left in the box due to void space filler such as packing peanuts. Defaults to 70% of the box weight.

=cut

has void_weight => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my $self = shift;
        return $self->weight * 0.7;
    }
);

=head2 calculate_weight()

Calculates and returns the weight of all the layers in this box, including the weight of this box and any packing filler (see L<void_weight>).

=cut

sub calculate_weight {
    my $self = shift;
    return $self->weight + $self->void_weight + $self->fill_weight;
}

=head2 create_layer()

Adds a new L<Box::Calc::Layer> to this box.

=cut

sub create_layer {
    my $self = shift;
    push @{$self->layers}, Box::Calc::Layer->new( max_x => $self->x, max_y => $self->y, );
}

sub BUILD {
    my $self = shift;
    $self->create_layer;
}

=head2 pack_item(item)

Add a L<Box::Calc::Item> to this box.

Returns 1 on success or 0 on failure.

=over

=item item

The L<Box::Calc::Item> instance you want to add to this box.

=back

=cut

sub pack_item {
    my ($self, $item, $count) = @_;
    $count ||= 1;
    if ($count > 5) {
        $log->warn($item->{name}.' is causing infinite recursion in Box::Calc');
        $log->debug(Dumper($item));
        return 0;
    }
    if ($item->weight + $self->calculate_weight >= $self->max_weight) {
        $log->info($item->{name}.' would make this box weigh too much, requesting new box.');
        return 0;
    }
    # item height > ( box height - box fill + the height of the current layer )
    if ($item->z > $self->z - $self->fill_z + $self->layers->[-1]->fill_z) {
        $log->info($item->{name}.' would make the layer too tall to fit in the box, requesting new box.');
        return 0;
    }
    if ($self->layers->[-1]->pack_item($item)) {
        $self->fill_weight($self->fill_weight + $item->weight);
        return 1;
    }
    else {
        if ($item->z > $self->z - $self->fill_z) {
            $log->info($item->{name}.' is too big to create another layer in this box, requesting another box.');
            return 0;
        }
        else {
            $self->create_layer;
            return $self->pack_item($item, $count + 1);
        }
    }
}

=head2 packing_list()

Returns a scalar with the weight of the box and a hash reference of all the items in this box.

=cut

sub packing_list {
    my $self = shift;
    my $weight = $self->weight;
    my $list = {};
    foreach my $layer (@{$self->layers}) {
        $layer->packing_list(\$weight, $list)
    }
    return ($weight, $list);
}

=head2 packing_instructions()

Returns a description of the box. Example:

 {
  x =>  5,
  y =>  6,
  z =>  3,
  fill_x => 4,
  fill_y => '5.1',
  fill_z => 2,
  name => 'The Big Box',
  layers => [ ... ],
  id => 'xxx',
  weight => '6',
  calculated_weight => '12.35',
 }

=cut

sub packing_instructions {
    my $self = shift;
    return {
        x                   => $self->x,
        y                   => $self->y,
        z                   => $self->z,
        fill_x              => $self->fill_x,
        fill_y              => $self->fill_y,
        fill_z              => $self->fill_z,
        name                => $self->name,
        id                  => $self->id,
        weight              => $self->weight,
        calculated_weight   => $self->calculate_weight,
        used_volume         => $self->used_volume,
        fill_volume         => $self->fill_volume,
        volume              => $self->volume,
        layers              => [map { $_->packing_instructions } @{ $self->layers }],
  };
}

=head2 used_volume

Returns the real used volume for this box.

=cut

sub used_volume {
    my $self = shift;
    return sum map { $_->used_volume } @{ $self->layers };
}

=head2 fill_volume 

Returns the exact volume needed for this box.    

=cut

sub fill_volume {
    return $_[0]->fill_x * $_[0]->fill_y * $_[0]->fill_z;
}

no Moose;
__PACKAGE__->meta->make_immutable;

=for Pod::Coverage BUILD
