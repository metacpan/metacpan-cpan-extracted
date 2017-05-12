package Box::Calc;
$Box::Calc::VERSION = '1.0200';
use strict;
use Moose;
use Box::Calc::BoxType;
use Box::Calc::Item;
use Box::Calc::Box;
use List::MoreUtils qw(natatime);
use List::Util qw(max);
use Ouch;
use Log::Any qw($log);

=head1 NAME

Box::Calc - Packing Algorithm

=head1 VERSION

version 1.0200

=head1 SYNOPSIS

 use Box::Calc;
 
 my $box_calc = Box::Calc->new;
 
 # define the possible box types
 $box_calc->add_box_type( x => 12, y => 12, z => 18, weight => 16, name => 'big box' );
 $box_calc->add_box_type( x => 4, y => 6, z => 8, weight => 6, name => 'small box' );

 # define the items you want to put into boxes
 $box_calc->add_item( 3,  { x => 6, y => 3, z => 3, weight => 12, name => 'soda' });
 $box_calc->add_item( 1,  { x => 3.3, y => 3, z => 4, weight => 4.5, name => 'apple' });
 $box_calc->add_item( 2,  { x => 8, y => 2.5, z => 2.5, weight => 14, name => 'water bottle' });

 # figure out what you need to pack this stuff
 $box_calc->pack_items;
 
 # how many boxes do you need
 my $box_count = $box_calc->count_boxes; # 2
 
 # interrogate the boxes
 my $box = $box_calc->get_box(-1); # the last box
 my $weight = $box->calculate_weight;
 
 # get a packing list
 my $packing_list = $box_calc->packing_list;
  
=head1 DESCRIPTION

Box::Calc helps you determine what can fit into a box for shipping or storage purposes. It will try to use the smallest box possible of the box types. If every item won't fit into your largest box, then it will span the boxes letting you know how many boxes you'll need.

Once it's done packing the boxes, you can get a packing list for each box, as well as the weight of each box.

=head2 How The Algorithm Works

Box::Calc is intended to pack boxes in the simplest way possible. Here's what it does:

=over

=item 1

Sort all the items by volume.

=item 2

Eliminate all boxes that won't fit the largest items.

=item 3

Choose the smallest box still available.

=item 4

Place the items in a row starting with the largest items.

=item 5

When the row runs out of space, add another.

=item 6

When you run out of space to add rows, add a layer.

=item 7

When you run out of layers either start over with a bigger box, or if there are no bigger boxes span to a second box.

=item 8

Repeat from step 3 until all items are packed into boxes.

=back

=head2 Motivation

At The Game Crafter (L<http://www.thegamecrafter.com>) we ship a lot of games and game pieces. We tried using a more complicated system for figuring out which size box to use, or how many boxes would be needed in a spanning situation. The problem was that those algorithms made the boxes pack so tightly that our staff spent a lot more time putting the boxes together. This algorithm is relatively dumb, but dumb in a good way. The boxes are easy and fast to pack. By releasing this, we hope it can help those who are either using too complicated a system, or no system at all for figuring out how many boxes they need for shipping/storing materials. 

=head2 Tips

When adding items, be sure to use the outer most dimensions of oddly shaped items, otherwise they may not fit the box.

When adding box types, be sure to use the inside dimensions of the box. If you plan to line the box with padding, then subtract the padding from the dimensions, and also add the padding to the weight of the box.

What units you use (inches, centimeters, ounces, pounds, grams, kilograms, etc) don't matter as long as you use them consistently. 

=head1 METHODS

=head2 new()

Constructor.

=head2 box_types()

Returns an array reference of the L<Box::Calc::BoxType>s registered.

=head2 count_box_types()

Returns the number of L<Box::Calc::BoxType>s registered.

=head2 get_box_type(index)

Returns a specific L<Box::Calc::BoxType> from the list of C<box_types>

=over

=item index

An array index. For example this would return the last box type added:

 $box_calc->get_box_type(-1)

=back

=cut

has box_types => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::BoxType]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        push_box_types  => 'push',
        count_box_types => 'count',
        get_box_type    => 'get',
    }
);

=head2 add_box_type(params)

Adds a new L<Box::Calc::BoxType> to the list of C<box_types>. Returns the newly created L<Box::Calc::BoxType> instance.

=over

=item params

The list of constructor parameters for L<Box::Calc::BoxType>.

B<NOTE:> You can optionally include an argument of "categories" and a box type will be created for each category so you don't have to do it manually.

=back

=cut

sub add_box_type {
    my $self = shift;
    my $args;
    if (ref $_[0] eq 'HASH') {
        $args = shift;
    }
    else {
        $args = { @_ };
    }
    my $categories = delete $args->{categories};
    if (defined $categories) {
        foreach my $category (@{$categories}) {
            my %copy = %{$args};
            $copy{category} = $category;
            $self->push_box_types(Box::Calc::BoxType->new(%copy));
        }
    }
    else {
        $self->push_box_types(Box::Calc::BoxType->new($args));
    }
    return $self->get_box_type(-1);
}


=head2 box_type_categories()

Returns an array reference of categories associated with the box types.

=cut

has box_type_categories => (
    is      => 'rw',
    lazy    => 1,
    isa     => 'ArrayRef',
    default => sub {
        my $self = shift;
        my %categories = ();
        foreach my $box_type (@{$self->box_types}) {
            next if $box_type->category eq '';
            $categories{$box_type->category} = 1;
        }
        return [sort keys %categories];
    },
);


=head2 sort_box_types_by_volume()

Sorts the list of C<box_types> by volume and then returns an array reference of that list.

=over

=item types

Optional. Array ref of box types. Will call C<box_types> if not passed in.

=back

=cut

sub sort_box_types_by_volume {
    my $self = shift;
    my $types = shift || $self->box_types;
    my @sorted = sort { ($a->volume) <=> ($b->volume ) } @{$types};
    return \@sorted;
}

=head2 determine_viable_box_types(category)

Given the list of C<items> and the list of C<box_types> this method rules out box types that cannot hold the largest item, and returns the list of box types that will work sorted by volume. 

=over

=item category

Optional. If this is specified, it will match this category name to the categories attached to the boxes and only provide a list of boxes that match that category.

=back

=cut

sub determine_viable_box_types {
    my ($self, $category) = @_;
    my ($item_x, $item_y, $item_z) = sort {$b <=> $a} @{$self->find_max_dimensions_of_items};
    my @viable;
    foreach my $box_type (@{$self->sort_box_types_by_volume}) {
        if (defined $category) {
            next unless $category eq $box_type->category;
        }
        my ($box_type_x, $box_type_y, $box_type_z) = @{$box_type->dimensions};
        if ($item_x <= $box_type_x && $item_y <= $box_type_y && $item_z <= $box_type_z) {
            push @viable, $box_type;
        }
    }
    unless (scalar @viable) {
        $log->fatal('There are no box types that can fit the items.');
        ouch 'no viable box types', 'There are no box types that can fit the items. ('.join(', ', $item_x, $item_y, $item_z).')', [$item_x, $item_y, $item_z];
    }
    return \@viable;
}

=head2 items()

Returns an array reference of the L<Box::Calc::Item>s registered.

=head2 count_items()

Returns the number of L<Box::Calc::Item>s registered.

=head2 get_item(index)

Returns a specific L<Box::Calc::Item>.

=over

=item index

The array index of the item as it was registered.

=back

=cut

has items => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Item]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        push_items  => 'push',
        count_items => 'count',
        get_item    => 'get',
    }
);

=head2 add_item(quantity, params)

Registers a new item. Returns the new item registered.

=over

=item quantity

How many copies of this item should be included in the package?

=item params

The constructor parameters for the L<Box::Calc::Item>.

=back

=cut

sub add_item {
    my ($self, $quantity, @params) = @_;
    my $item = Box::Calc::Item->new(@params);
    for (1..$quantity) {
        $self->push_items($item);
    }
    return $self->get_item(-1);
}

=head2 load(payload)

Allows the loading of an entire dataset.

=over

=item payload

A hash reference containing the output of the C<dump> method, with two exceptions:

=over

=item *

You can create a C<categories> element that is an array ref in each box type rather than creating duplicate box types for each category.

=item *

You can create a C<quantity> element in each item rather than creating duplicate items to represent the quantity.

=back

=back

=cut

sub load {
    my ($self, $payload) = @_;
    # note that we copy the box type and item to avoid modifying the original
    foreach my $type (@{$payload->{box_types}}) {
        $self->add_box_type(%{$type});
    }
    foreach my $item (@{$payload->{items}}) {
        $self->add_item($item->{quantity} || 1, %{$item});
    }
}

=head2 dump()

=cut

sub dump {
    my ($self) = @_;
    my $payload = {};
    foreach my $type (@{$self->box_types}) {
        push @{$payload->{box_types}}, $type->describe;
    }
    foreach my $item (@{$self->items}) {
        push @{$payload->{items}}, $item->describe;
    }
    return $payload;
}


=head2 sort_items_by_volume()

Returns an array reference of the list of C<items> registered sorted by volume.

=over

=item items

Optional. An array reference of items. Will call C<items> if not passed in.

=back

=cut

sub sort_items_by_volume {
    my $self = shift;
    my $items = shift || $self->items;
    my @sorted = sort { ($a->volume) <=> ($b->volume ) } @{$items};
    return \@sorted;
}

=head2 sort_items_by_zxy()

Returns an array reference of the list of C<items> registered sorted by z, then x, then y, ascending.

=over

=item items

Optional. An array reference of items. Will call C<items> if not passed in.

=back

=cut

sub sort_items_by_zxy {
    my $self = shift;
    my $items = shift || $self->items;
    my @sorted = sort {
                    $a->z <=> $b->z
                 || $a->x <=> $b->x
                 || $a->y <=> $b->y
                 } @{$items};
    return \@sorted;
}

=head2 sort_items_by_z_desc_A()

Returns an array reference of the list of C<items> registered sorted by z DESC, then area DESC

=over

=item items

Optional. An array reference of items. Will call C<items> if not passed in.

=back

=cut

sub sort_items_by_z_desc_A {
    my $self = shift;
    my $items = shift || $self->items;
    my @sorted = map  { $_->[1] }
                 sort {
                    $b->[0]->{z} <=> $a->[0]->{z}
                 || $b->[0]->{A} <=> $a->[0]->{A}
                 }
                 ##Fetch Z and calculate A
                 map  { [ { z=>$_->z, A=>$_->x*$_->y }, $_ ] } @{$items};
    return \@sorted;
}

=head2 sort_items_by_zA()

Returns an array reference of the list of C<items> registered sorted by z ASC, then area DESC

=over

=item items

Optional. An array reference of items. Will call C<items> if not passed in.

=back

=cut

sub sort_items_by_zA {
    my $self = shift;
    my $items = shift || $self->items;
    my @sorted = map  { $_->[1] }
                 sort {
                    $a->[0]->{z} <=> $b->[0]->{z}
                 || $b->[0]->{A} <=> $a->[0]->{A}
                 }
                 ##Fetch Z and calculate A
                 map  { [ { z=>$_->z, A=>$_->x*$_->y }, $_ ] } @{$items};
    return \@sorted;
}

=head2 sort_items_by_Az()

=over

=item items

Optional. An array reference of items. Will call C<items> if not passed in.

=back

Returns an array reference of the list of C<items> registered sorted by A DESC, then z ASC

=cut

sub sort_items_by_Az {
    my $self = shift;
    my $items = shift || $self->items;
    my @sorted = map  { $_->[1] }
                 sort {
                    $b->[0]->{A} <=> $a->[0]->{A}
                 || $a->[0]->{z} <=> $b->[0]->{z}
                 }
                 ##Fetch Z and calculate A
                 map  { [ { z=>$_->z, A=>$_->x*$_->y }, $_ ] } @{$items};
    return \@sorted;
}

=head2 find_max_dimensions_of_items()

Given the registered C<items>, returns the max C<x>, C<y>, and C<z> of all items registered as an array reference.

=cut

has find_max_dimensions_of_items => (
    is      => 'rw',
    lazy    => 1,
    isa     => 'ArrayRef',
    clearer => 'clear_max_dimensions_of_items',
    default => sub {
        my $self = shift;
        my $x = 0;
        my $y = 0;
        my $z = 0;
        foreach my $item (@{$self->items}) {
            my ($ex, $ey, $ez) = @{$item->dimensions};
            $x = $ex if $ex > $x;
            $y = $ey if $ey > $y;
            $z = $ez if $ez > $z;
        }
        return [$x, $y, $z];
    }
);

=head2 boxes()

Returns an array reference of the list of L<Box::Calc::Box>es needed to pack up the items.

B<NOTE:> This will be empty until you call C<pack_items>.

=head2 count_boxes()

Returns the number of boxes needed to pack up the items.

=head2 get_box(index)

Fetches a specific box from the list of <boxes>.

=over

=item index

The array index of the box you wish to fetc.

=back

=cut

has boxes => (
    is => 'rw',
    isa => 'ArrayRef[Box::Calc::Box]',
    default   => sub { [] },
    traits  => ['Array'],
    handles => {
        push_boxes  => 'push',
        count_boxes => 'count',
        get_box    => 'get',
    }
);

=head2 reset_boxes()

Deletes the list of C<boxes>.

If you wish to rerun the packing you should use this to delete the list of C<boxes> first. This is handy if you needed to add an extra item or extra box type after you already ran C<pack_items>.

=cut

sub reset_boxes {
    my $self = shift;
    $self->boxes([]);
}

=head2 reset_items()

Deletes the list of C<items>.

For the sake of speed you may wish to reuse a L<Box::Calc> instance with the box types already pre-loaded. In that case you'll want to use this method to remove the items you've already registered. You'll probably also want to call C<reset_boxes>.

=cut

sub reset_items {
    my $self = shift;
    $self->items([]);
    $self->clear_max_dimensions_of_items;
}

sub make_box {
    my ($self, $box_type) = @_;
    return Box::Calc::Box->new(
        swap_xy             => 1,
        mail_service_name   => $box_type->mail_service_name,
        x                   => $box_type->x,
        y                   => $box_type->y,
        z                   => $box_type->z,
        weight              => $box_type->weight,
        max_weight          => $box_type->max_weight,
        name                => $box_type->name,
        outer_x             => $box_type->outer_x,
        outer_y             => $box_type->outer_y,
        outer_z             => $box_type->outer_z,
    );
}

=head2 find_tallest_z ( [ items ] )

Determines the median of z across all items in the list.

=over

=item items

An array reference of items. Optional. Defaults to C<items>.

=back

=cut

sub find_tallest_z {
    my $self = shift;
    my $items = shift || $self->items;
    return max map { $_->z } @{$items};
}


=head2 stack_like_items( options )

Stacks all like-sized items into stacks of C<stack_height> for denser packing. Could be used as an optimizer before running C<pack_items>. 

=over

=item options

A hash.

=over

=item items

Optional. If not specified, will be the C<items> list.

=item stack_height

Optional. If not specified, will be determined by calling C<find_tallest_z>.

=back

=back

=cut

sub stack_like_items {
    my ($self, %options) = @_;
    my $items = $options{items} || $self->items;
    my $stack_height = $options{stack_height} || $self->find_tallest_z($items);
    my %like;
    foreach my $item (@{$items}) {
        push @{$like{$item->extent}}, $item;
    }
    my @stacks;
    foreach my $kind (values %like) {
        if (scalar @{$kind} == 1) {
            push @stacks, $kind->[0];
        }
        else {
            my $items_per_stack = int($stack_height / $kind->[0]->z) || 1;
            my $iterator = natatime($items_per_stack, @{$kind});
            while (my @items = $iterator->()) {
                my $count = scalar @items;
                if ($count == 1) {
                    push @stacks, $items[0];
                }
                else {
                    my $item = $items[0];
                    push @stacks, Box::Calc::Item->new(
                        x       => $item->x,
                        y       => $item->y,
                        z       => $item->z * $count, 
                        weight  => $item->weight * $count,
                        name    => 'Stack of '.$count.' '.$item->name,
                        no_sort => 1,
                    );
                }
            }
        }
    }
    return \@stacks;
}

=head2 pack_items(options)

Uses the list of C<box_types> and the list of C<items> to create the list of boxes to be packed. This method populates the C<boxes> list.

=over

=item options

A hash.

=over

=item items

Optional. If omitted the items list will be populated with whatever the current B<best> general purpose preprocessed item list is. Currently that is C<sort_items_by_zA>.

=item category

Optional. If this is specified, it will match this category name to the categories attached to the boxes and only pack in boxes that match that category.

=back

=back

=cut

sub pack_items {
    my ($self, %options) = @_;
    my $category = $options{category};
    my $items = $options{items} || $self->sort_items_by_zA;
    my $item_count = scalar(@{$items});
    my @box_types = @{$self->determine_viable_box_types($category)};
    my $countdown = scalar(@box_types);
    BOXTYPE: foreach my $box_type (@box_types) {
        $log->info("Box Type: ".$box_type->name);
        $countdown--;
        my $box = $self->make_box($box_type);
        ITEM: foreach my $item (@{$items}) {
            $log->info("Item: ".$item->name);
            
            # swap the item's x & y if it will make the item fit tighter 
            if ($item->x > 0 && $item->y > 0) {
                $log->debug("Item's dimensions are not 0.");
                if ($box->x >= $item->y && $box->y >= $item->x) { # see if the item would still fit in the box if it swapped
                    $log->debug('Item would still fit in the box if we rotated it.');
                    my $original_x_per_layer = int($box->x / $item->x);
                    my $original_y_per_layer = int($box->y / $item->y);
                    my $original_count_per_layer = $original_x_per_layer * $original_y_per_layer;
                    my $new_count_per_layer = int($box->x / $item->y) * int($box->y / $item->x); 
                    if ( $new_count_per_layer > $original_count_per_layer #  you can fit more items per layer in a swap
                        || $original_x_per_layer == 0 || $original_y_per_layer == 0 # if we keep it the current rotation we definitely won't fit, probably due to previous rotation
                        ) {
                        $log->info('Rotating '.$item->{name}.', because we can fit more per layer if we rotate.');
                        my $temp_x = $item->x;
                        $item->x($item->y);
                        $item->y($temp_x);
                    }
                }
            }
            else {
                $log->error('Item has a zero (0) dimension. That should not happen.');
            }

            # pack the item into the box
            unless ($box->pack_item($item)) {
                if ($countdown) { # we still have other boxes to try
                    $log->info("moving to next box type");
                    next BOXTYPE;
                }
                else { # no more boxes to try, time for spanning
                    if (scalar(@{$self->boxes}) > $item_count) {
                        $log->warn("More boxes than items.");
                        #ouch 'more boxes than items', 'The number of boxes has exceded the number of items, which should never happen.';
                    }
                    $log->info("no more box types, spanning");
                    $self->push_boxes($box);
                    $box = $self->make_box($box_type);
                    redo ITEM;
                }
            }
        }
        
        # we made it through our entire item list, yay!
        $log->info("finished!");
        $self->push_boxes($box);
        last BOXTYPE;
    }
}

=head2 packing_list()

Returns a data structure with all the item names and quantities packed into boxes. This can be used to generate manifests.

 [
    {                                   # box one
        id              => "xxx",
        name            => "big box",
        weight          => 30.1,
        packing_list    => {
            "soda"          => 3,
            "apple"         => 1,
            "water bottle"  => 2,
        }
    }
 ]

=cut

sub packing_list {
    my $self = shift;
    my @boxes;
    foreach my $box (@{$self->boxes}) {
        my ($weight, $list) = $box->packing_list;
        push @boxes, {
            id              => $box->id,
            name            => $box->name,
            weight          => $weight,
            packing_list    => $list,
        };
    }
    return \@boxes;
}

=head2 packing_instructions()

Returns a data structure with all the item names individually packed into rows, layers, and boxes. This can be used to build documentation on how to pack a set of boxes, and to generate a complete build history.

 [
    {                                                   # box one
        id              => "xxx",
        name            => "big box",
        layers           => [    
            {                                           # layer one
                rows => [
                    {                                   # row one
                        items => [
                            {                           # item one
                                name    => "apple",
                                ...
                            },
                            ...
                        ],
                    },
                    ...
                ],
                ...
            },
        ],
    },
 ]

=cut

sub packing_instructions {
    my $self = shift;
    my @boxes = map { $_->packing_instructions} @{ $self->boxes };
    return \@boxes;
}

=head1 TODO

There are some additional optimizations that could be done to speed things up a bit. We might also be able to get a better fill percentage (less void space), although that's not really the intent of Box::Calc.

=head1 PREREQS

L<Moose>
L<Ouch>
L<Log::Any>
L<Data::GUID>

=head1 SUPPORT

=over

=item Repository

L<http://github.com/rizen/Box-Calc>

=item Bug Reports

L<http://github.com/rizen/Box-Calc/issues>

=back


=head1 SEE ALSO

Although these modules don't solve the same problem as this module, they may help you build something that does if Box::Calc doesn't quite help you do what you want.

=over

=item L<Algorithm::Knapsack>

=item L<Algorithm::Bucketizer>

=item L<Algorithm::Knap01DP>

=back

=head1 AUTHOR

=over

=item JT Smith <jt_at_plainblack_dot_com>

=item Colin Kuskie <colink_at_plainblack_dot_com>

=back

=head1 LEGAL

Box::Calc is Copyright 2012 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
