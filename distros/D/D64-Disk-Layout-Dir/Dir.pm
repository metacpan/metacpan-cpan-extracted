package D64::Disk::Layout::Dir;

=head1 NAME

D64::Disk::Layout::Dir - Handling entire Commodore (D64/D71/D81) disk image directories in pure Perl

=head1 SYNOPSIS

  use D64::Disk::Layout::Dir;

  # Create an empty disk directory instance:
  my $dir = D64::Disk::Layout::Dir->new();

  # Create a new disk directory instance providing 18 * 256 bytes of scalar data:
  my $dir = D64::Disk::Layout::Dir->new(data => $data);

  # Fetch directory object data as a scalar of 18 * 256 bytes:
  my $data = $dir->data();

  # Replace directory providing 18 * 256 bytes of scalar data:
  $dir->data($data);

  # Fetch directory data as an array of up to 18 * 8 items:
  my @items = $dir->items();

  # Replace directory providing an array of up to 18 * 8 items:
  $dir->items(@items);

  # Get count of non-empty items stored in a disk directory:
  my $num_items = $dir->num_items();

  # Fetch directory data as an array of 18 * sectors:
  my @sectors = $dir->sectors();

  # Replace directory providing an array of 18 * sectors:
  $dir->sectors(@sectors);

  # Fetch an item from a directory listing at any given position:
  my $item = $dir->get(item => $index);

  # Fetch a list of items from a directory listing matching given PETSCII pattern:
  my @items = $dir->get(pattern => $petscii_pattern);

  # Append an item to the end of directory listing, increasing number of files by one element:
  $dir->push(item => $item);

  # Pop and return the last directory item, shortening a directory listing by one element:
  my $item = $dir->pop();

  # Shift the first directory item, shortening a directory listing by one and moving everything down:
  my $item = $dir->shift();

  # Prepend an item to the front of directory listing, and return the new number of elements:
  my $num_items = $dir->unshift(item => $item);

  # Mark directory item designated by an offset as deleted:
  my $num_deleted = $dir->delete(index => $index);

  # Wipe out directory item designated by an offset completely:
  my $num_removed = $dir->remove(index => $index);

  # Add a new directory item to a directory listing:
  my $is_success = $dir->add(item => $item);

  # Put an item to a directory listing at any given position:
  my $is_success = $dir->put(item => $item, index => $index);

  # Print out formatted disk directory listing:
  $dir->print();

=head1 DESCRIPTION

C<D64::Disk::Layout::Dir> provides a helper class for C<D64::Disk::Layout> module, enabling users to access and manipulate entire directories of D64/D71/D81 disk images in an object oriented way without the hassle of worrying about the meaning of individual bits and bytes describing each sector data on a disk directory track. The whole family of C<D64::Disk::Layout> modules has been implemented in pure Perl as an alternative to Per Olofsson's "diskimage.c" library originally written in an ANSI C.

=head1 METHODS

=cut

use bytes;
use strict;
use utf8;
use warnings;

our $VERSION = '0.06';

use D64::Disk::Dir::Item qw(:types);
use D64::Disk::Layout::Sector;
use Data::Dumper;
use List::MoreUtils qw(uniq);
use Readonly;
use Text::Convert::PETSCII qw(:convert :validate);

require XSLoader;
XSLoader::load(__PACKAGE__, $VERSION);

Readonly our $ITEMS_PER_SECTOR   => 8;
Readonly our $TOTAL_SECTOR_COUNT => 18;

Readonly our $ITEM_SIZE        => $D64::Disk::Dir::Item::ITEM_SIZE;
Readonly our $SECTOR_DATA_SIZE => $D64::Disk::Layout::Sector::SECTOR_DATA_SIZE;

# First directory track and sector:
Readonly our $DIRECTORY_FIRST_TRACK  => 0x12;
Readonly our $DIRECTORY_FIRST_SECTOR => 0x01;

Readonly our @TRACK_WRITE_ORDER => (
    0x12, 0x12, 0x12, 0x12, 0x12, 0x12,
    0x12, 0x12, 0x12, 0x12, 0x12, 0x12,
    0x12, 0x12, 0x12, 0x12, 0x12, 0x12,
);
Readonly our @SECTOR_WRITE_ORDER => (
    0x01, 0x04, 0x07, 0x0a, 0x0d, 0x10,
    0x02, 0x05, 0x08, 0x0b, 0x0e, 0x11,
    0x03, 0x06, 0x09, 0x0c, 0x0f, 0x12,
);

Readonly our $MAX_ENTRIES => $TOTAL_SECTOR_COUNT * $ITEMS_PER_SECTOR;

=head2 new

Create an empty disk directory instance:

  my $dir = D64::Disk::Layout::Dir->new();

Create a new disk directory instance providing 18 * 256 bytes of scalar data:

  my $dir = D64::Disk::Layout::Dir->new(data => $data);

Create a new disk directory instance given array with 18 * 256 bytes of data:

  my $dir = D64::Disk::Layout::Dir->new(data => \@data);

Alternatively setup source data structure required to initialize new object using 18 * sector objects:

  my @sectors = (
    # It needs to be a list of D64::Disk::Layout::Sector objects:
    D64::Disk::Layout::Sector->new(data => $sector1, track => 18, sector => 1),
    D64::Disk::Layout::Sector->new(data => $sector2, track => 18, sector => 4),
    D64::Disk::Layout::Sector->new(data => $sector3, track => 18, sector => 7),
    # It needs to contain as many sectors as large directory may be:
    ...
  );

Create a new disk directory instance providing source sector data:

  my $dir = D64::Disk::Layout::Dir->new(sectors => \@sectors);

Directory object may also be initialized using the list of directory item objects:

  my @items = (
    # It needs to be a list of D64::Disk::Dir::Item objects:
    D64::Disk::Dir::Item->new($item1),
    D64::Disk::Dir::Item->new($item2),
    D64::Disk::Dir::Item->new($item3),
    # Up to the maximum number of directory entries (18 * 8 = 144):
    ...
  );

Create a new disk directory instance providing list of dir items:

  my $dir = D64::Disk::Layout::Dir->new(items => \@items);

Individual directory items are stored, accessed and manipulated as C<D64::Disk::Dir::Item> objects.

=cut

sub new {
    my ($this) = CORE::shift;
    my $class = ref ($this) || $this;
    my $object = $class->_init();
    my $self = bless $object, $class;
    $self->_setup(@_);
    return $self;
}

sub _init {
    my ($class) = @_;

    my @items = map { D64::Disk::Dir::Item->new() } (1 .. $ITEMS_PER_SECTOR * $TOTAL_SECTOR_COUNT);

    my $object = {
        items        => \@items,
        sector_order => [@SECTOR_WRITE_ORDER],
        track_order  => [@TRACK_WRITE_ORDER],
    };

    return $object;
}

sub _setup {
    my ($self, %args) = @_;

    $self->data($args{data}) if exists $args{data};
    $self->items($args{items}) if exists $args{items};
    $self->sectors($args{sectors}) if exists $args{sectors};

    return undef;
}

sub _validate_data {
    my ($self, $data) = @_;

    my $expected_data_size = $TOTAL_SECTOR_COUNT * $SECTOR_DATA_SIZE;

    unless (defined $data) {
        die sprintf q{Unable to initialize disk directory: Undefined value of data (expected %d bytes)}, $expected_data_size;
    }

    # Convert scalar data into an array:
    unless (ref $data) {
        no bytes;
        $data = [ split //, $data ];
    }
    elsif (ref $data ne 'ARRAY') {
        die sprintf q{Unable to initialize disk directory: Invalid arguments given (expected %d bytes)}, $expected_data_size;
    }

    unless (scalar (@{$data}) == $expected_data_size) {
        die sprintf q{Unable to initialize disk directory: Invalid amount of data (got %d bytes, but required %d)}, scalar (@{$data}), $expected_data_size;
    }

    for (my $i = 0; $i < @{$data}; $i++) {
        my $byte_value = $data->[$i];
        if (ref $byte_value) {
            die sprintf q{Unable to initialize disk directory: Invalid data type at offset %d (%s)}, $i, ref $byte_value;
        }
        unless ($self->_is_valid_byte_value($byte_value)) {
            die sprintf q{Unable to initialize disk directory: Invalid byte value at offset %d (%s)}, $i, $self->_dump($byte_value);
        }
    }

    return @{$data};
}

sub _validate_sectors {
    my ($self, $sectors) = @_;

    my $expected_sectors_size = $TOTAL_SECTOR_COUNT;

    unless (scalar (@{$sectors}) == $expected_sectors_size) {
        die sprintf q{Unable to initialize disk directory: Invalid number of sectors (got %d sectors, but required %d)}, scalar (@{$sectors}), $expected_sectors_size;
    }

    # Remove duplicate sectors (objects sharing the same track/sector position):
    my $count_removed = $self->_remove_duplicate_sectors($sectors);

    unless (defined $sectors) {
        die sprintf q{Unable to initialize disk directory: Undefined value of sectors (expected %d sectors)}, $expected_sectors_size;
    }

    unless (ref $sectors eq 'ARRAY') {
        die sprintf q{Unable to initialize disk directory: Invalid arguments given (expected %d sectors)}, $expected_sectors_size;
    }

    unless (scalar (@{$sectors}) == $expected_sectors_size) {
        die sprintf q{Unable to initialize disk directory: Invalid number of sectors (got %d sectors, but required %d)}, scalar (@{$sectors}), $expected_sectors_size;
    }

    for (my $i = 0; $i < @{$sectors}; $i++) {
        my $sector_value = $sectors->[$i];
        unless ($sector_value->isa('D64::Disk::Layout::Sector')) {
            die sprintf q{Unable to initialize disk directory: Invalid sector type at offset %d (%s)}, $i, ref $sector_value;
        }
    }

    return $sectors;
}

sub _remove_duplicate_sectors {
    my ($self, $sectors) = @_;

    my $count_removed = 0;

    for (my $i = 0; $i < @{$sectors}; $i++) {
        my $sector_object = $sectors->[$i];
        my $track = $sector_object->track();
        my $sector = $sector_object->sector();
        for (my $j = $i + 1; $j < @{$sectors}; $j++) {
            my $test_sector = $sectors->[$j];
            if ($test_sector->track() == $track && $test_sector->sector() == $sector) {
                splice @{$sectors}, $j, 1;
                $j--;
                $count_removed++;
            }
        }
    }

    return $count_removed;
}

sub _find_sector {
    my ($self, $sectors, $track, $sector) = @_;

    return unless defined $track && defined $sector;

    for my $sector_object (@{$sectors}) {
        if ($sector_object->track() == $track && $sector_object->sector() == $sector) {
            return $sector_object;
        }
    }

    return undef;
}

sub _validate_items {
    my ($self, $items) = @_;

    my $expected_items_size = $ITEMS_PER_SECTOR * $TOTAL_SECTOR_COUNT;

    unless (defined $items) {
        die sprintf q{Unable to initialize disk directory: Undefined value of items (expected up to %d items)}, $expected_items_size;
    }

    unless (ref $items eq 'ARRAY') {
        die sprintf q{Unable to initialize disk directory: Invalid arguments given (expected up to %d items)}, $expected_items_size;
    }

    unless (scalar (@{$items}) <= $expected_items_size) {
        die sprintf q{Unable to initialize disk directory: Invalid number of items (got %d items, but required up to %d)}, scalar (@{$items}), $expected_items_size;
    }

    for (my $i = 0; $i < @{$items}; $i++) {
        my $item_value = $items->[$i];
        unless ($item_value->isa('D64::Disk::Dir::Item')) {
            die sprintf q{Unable to initialize disk directory: Invalid item type at offset %d (%s)}, $i, ref $item_value;
        }
        unless ($item_value->validate()) {
            die sprintf q{Unable to initialize disk directory: Invalid item value at offset %d (%s)}, $i, $self->_dump($item_value);
        }
    }

    return undef;
}

=head2 data

Fetch directory object data as a scalar of 18 * 256 bytes:

  my $data = $dir->data();

Fetch directory object data as an array of 18 * 256 bytes:

  my @data = $dir->data();

Replace directory providing 18 * 256 bytes of scalar data:

  $dir->data($data);

Replace directory given array with 18 * 256 bytes of data:

  $dir->data(@data);
  $dir->data(\@data);

=cut

sub data {
    my ($self, @args) = @_;

    if (@args) {
        my ($arg) = @args;
        my $data = (scalar @args == 1) ? $arg : \@args;
        my @data = $self->_validate_data($data);

        my $iter = $self->_get_order_from_data(\@data);
        my ($track_order, $sector_order) = $self->_get_order($iter);

        ## TODO: Optimize code below by constructing directory "items" directly here!!!

        # Convert data into sectors and initialize object:
        my @sectors;
        while (my @sector_data = splice @data, 0, $SECTOR_DATA_SIZE) {
            my $track = CORE::shift @{$track_order};
            my $sector = CORE::shift @{$sector_order};
            my $sector_object = D64::Disk::Layout::Sector->new(data => \@sector_data, track => $track, sector => $sector);
            CORE::push @sectors, $sector_object;
        }
        $self->sectors(@sectors);
    }

    my $items = $self->{items};
    my $num_items = $self->num_items();

    # Get directory object data as an array of bytes:
    my @data;
    for (my $i = 0; $i < @{$items}; $i++) {
        my @item_data = $items->[$i]->data();
        if ($i % $ITEMS_PER_SECTOR == 0 && ($i + $ITEMS_PER_SECTOR) < $num_items) {
            # Add information about the next directory track/sector data:
            CORE::push @data, chr $self->{track_order}->[$i / $ITEMS_PER_SECTOR + 1];
            CORE::push @data, chr $self->{sector_order}->[$i / $ITEMS_PER_SECTOR + 1];
        }
        elsif ($i % $ITEMS_PER_SECTOR == 0 && ($i + $ITEMS_PER_SECTOR) >= $num_items && $i < $num_items) {
            CORE::push @data, chr (0x00), chr (0xff);
        }
        elsif ($i == 0 && $num_items == 0) {
            CORE::push @data, chr (0x00), chr (0xff);
        }
        elsif ($i % $ITEMS_PER_SECTOR == 0) {
            CORE::push @data, chr (0x00), chr (0xff);
        }
        else {
            CORE::push @data, chr (0x00), chr (0x00);
        }
        CORE::push @data, @item_data;
    }

    return wantarray ? @data : join '', @data;
}

sub _get_order_from_data {
    my ($self, $data) = @_;

    my $i = 0;

    return sub {
        my $index = $SECTOR_DATA_SIZE * $i++;

        my $track = ord $data->[$index + 0];
        my $sector = ord $data->[$index + 1];

        return ($track, $sector);
    };
}

sub _get_order {
    my ($self, $next) = @_;

    my @track_order = @TRACK_WRITE_ORDER;
    my @sector_order = @SECTOR_WRITE_ORDER;

    $sector_order[0] = _magic_to_int($DIRECTORY_FIRST_SECTOR);

    for (my $i = 0; $i < @sector_order; $i++) {
        my ($track, $sector) = $next->();

        last if $track == 0x00;

        splice @track_order, $i + 1, 0, $track;
        splice @sector_order, $i + 1, 0, $sector;
    }

    # Remove duplicated track/sector order pairs:
    for (my $i = 0; $i < @sector_order; $i++) {
        my $track = $track_order[$i];
        my $sector = $sector_order[$i];
        for (my $j = $i + 1; $j < @sector_order; $j++) {
            if ($track_order[$j] == $track && $sector_order[$j] == $sector) {
                splice @track_order, $j, 1;
                splice @sector_order, $j, 1;
                $j--;
            }
        }
    }

    return (\@track_order, \@sector_order);
}

=head2 items

Fetch directory object data as an array of up to 18 * 8 items:

  my @items = $dir->items();

This method returns only non-empty directory items.

Replace entire directory providing an array of up to 18 * 8 items:

  $dir->items(@items);
  $dir->items(\@items);

An entire directory object data will be replaced when calling this method. This will happen even when number of items provided as an input parameter is less than the number of non-empty items stored in an object before method was invoked.

=cut

sub items {
    my ($self, @args) = @_;

    if (@args) {
        my ($arg) = @args;
        my $items = (scalar @args == 1) ? (ref $arg ? $arg : [ $arg ]) : \@args;
        $self->_validate_items($items);

        my $object = $self->_init();
        $self->{items}        = $object->{items};
        $self->{sector_order} = $object->{sector_order};
        $self->{track_order}  = $object->{track_order};

        my $i = 0;

        for my $item (@{$items}) {
            $self->{items}->[$i] = $item->clone();
            $i++;
        }
    }

    my $items = $self->{items};
    my $num_items = $self->num_items();

    my @items;

    for (my $i = 0; $i < $num_items; $i++) {
        CORE::push @items, $items->[$i]->clone();
    }

    return @items;
}

=head2 num_items

Get count of non-empty items stored in a disk directory:

  my $num_items = $dir->num_items();

=cut

sub num_items {
    my ($self, @args) = @_;

    my $items = $self->{items};

    for (my $i = 0; $i < @{$items}; $i++) {
        my $item = $items->[$i];

        return $i if $item->empty();
    }

    return scalar @{$items};
}

sub _last_item_index {
    my ($self) = @_;

    my $num_items = $self->num_items();

    return $num_items - 1; # -1 .. ($ITEMS_PER_SECTOR * $TOTAL_SECTOR_COUNT - 1)
}

=head2 sectors

Fetch directory object data as an array of 18 * sector objects:

  my @sectors = $dir->sectors();

Replace entire directory providing an array of 18 * sector objects:

  $dir->sectors(@sectors);
  $dir->sectors(\@sectors);

=cut

sub sectors {
    my ($self, @args) = @_;

    if (@args) {
        my ($arg) = @args;
        my $sectors = (scalar @args == 1) ? (ref $arg ? $arg : [ $arg ]) : \@args;
        $sectors = $self->_validate_sectors($sectors);

        my $object = $self->_init();
        $self->{items} = $object->{items};

        my $iter = $self->_get_order_from_sectors($sectors);
        my ($track_order, $sector_order) = $self->_get_order($iter);

        $self->{sector_order} = $sector_order;
        $self->{track_order} = $track_order;

        my $sector = $sector_order->[0];
        my $track = $track_order->[0];

        my $index = 0;
        while (my $sector_object = $self->_find_sector($sectors, $track, $sector)) {
            my @items = $self->_sector_to_items($sector_object);

            splice @{$self->{items}}, $index * $ITEMS_PER_SECTOR, $ITEMS_PER_SECTOR, @items;

            $index++;

            $sector = $sector_order->[$index];
            $track = $track_order->[$index];

            last unless defined $track && defined $sector;
        }
    }

    my $items = $self->{items};
    my $num_items = $self->num_items();

    # Get directory object data as an array of sectors:
    my @sectors;
    for (my $i = 0; $i < $TOTAL_SECTOR_COUNT; $i++) {
        my $track = $self->{track_order}->[$i];
        my $sector = $self->{sector_order}->[$i];

        my @data;
        for (my $j = 0; $j < $ITEMS_PER_SECTOR; $j++) {
            my @item_data = $items->[$i * $ITEMS_PER_SECTOR + $j]->data();
            if ($j == 0 && ($i + 1) * $ITEMS_PER_SECTOR < $num_items) {
                # Add information about the next directory track/sector data:
                CORE::push @data, chr $self->{track_order}->[$i + 1];
                CORE::push @data, chr $self->{sector_order}->[$i + 1];
            }
            elsif ($j == 0 && ($i + 1) * $ITEMS_PER_SECTOR >= $num_items && $i * $ITEMS_PER_SECTOR < $num_items) {
                CORE::push @data, chr (0x00), chr (0xff);
            }
            elsif ($i == 0 && $j == 0 && $num_items == 0) {
                CORE::push @data, chr (0x00), chr (0xff);
            }
            elsif ($j == 0) {
                CORE::push @data, chr (0x00), chr (0xff);
            }
                else {
                CORE::push @data, chr (0x00), chr (0x00);
            }
            CORE::push @data, @item_data;
        }

        my $sector_object = D64::Disk::Layout::Sector->new(data => \@data, track => $track, sector => $sector);
        CORE::push @sectors, $sector_object;
    }

    return @sectors;
}

=head2 num_sectors

Get total number of allocated sectors that can be used to store disk directory data:

  my $num_sectors = $dir->num_sectors(count => 'all');

In the case of a C<D64> disk image format, the value of C<18> is always returned, as this is a standard number of sectors designated to store disk directory data.

Get number of currently used sectors that are used to store actual disk directory data:

  my $num_sectors = $dir->num_sectors(count => 'used');

In this case method call returns an integer value between C<0> and C<18> (total count of sectors used to store actual data), i.a. for an empty disk directory C<0> is returned, and for a disk directory filled with more than 136 files the value of C<18> will be retrieved.

C<count> parameter defaults to C<all>.

=cut

sub num_sectors {
    my ($self, %args) = @_;

    my $mode = $args{'count'} || 'all';

    if ($mode eq 'all') {
        return $TOTAL_SECTOR_COUNT;
    }
    elsif ($mode eq 'used') {
        my $last_item_index = $self->_last_item_index();

        while (++$last_item_index % 8) {};

        return int ($last_item_index / 8);
    }
    else {
        die sprintf q{Invalid value of "count" parameter: %s}, $mode;
    }
}

sub _get_order_from_sectors {
    my ($self, $sectors) = @_;

    my $track = $DIRECTORY_FIRST_TRACK;
    my $sector = $DIRECTORY_FIRST_SECTOR;

    return sub {
        my $sector_object = $self->_find_sector($sectors, $track, $sector);
        return unless $sector_object;

        my $sector_data = $sector_object->data();

        $track = ord substr $sector_data, 0, 1;
        $sector = ord substr $sector_data, 1, 1;

        return ($track, $sector);
    };
}

sub _sector_to_items {
    my ($self, $sector_object) = @_;

    my @data = $sector_object->data();

    my @items;

    for (my $i = 0; $i < $ITEMS_PER_SECTOR; $i++) {
        my $index = 2 + $i * ($ITEM_SIZE + 2);
        my @item_data = @data[$index .. $index + $ITEM_SIZE - 1];
        CORE::push @items, D64::Disk::Dir::Item->new(@item_data);
    }

    return @items;
}

=head2 get

Fetch an item from a directory listing at any given position:

  my $item = $dir->get(index => $index);

C<$index> indicates an offset from the beginning of a directory listing, with count starting from C<0>. When C<$index> indicates an element beyond the number of non-empty items stored in a disk directory, an undefined value will be returned.

Fetch a list of items from a directory listing matching given PETSCII pattern:

  use Text::Convert::PETSCII qw(:convert);

  my $pattern = ascii_to_petscii 'workstage*';

  my @items = $dir->get(pattern => $pattern);

C<pattern> is expected to be any valid PETSCII text string. Such call to this method always returns B<all> items with filename matching given PETSCII pattern.

=cut

sub get {
    my ($self, %args) = @_;

    if (exists $args{index} && exists $args{pattern}) {
        die q{Unable to fetch an item from a directory listing: ambiguous file index/matching pattern specified (you cannot specify both parameters at the same time)};
    }

    unless (exists $args{index} || exists $args{pattern}) {
        die q{Unable to fetch an item from a directory listing: Missing index/pattern parameter (which element did you want to get?)};
    }

    my $index = $args{index};
    my $pattern = $args{pattern};

    if (exists $args{index}) {

        $self->_validate_index($index, 'get');

        my $num_items = $self->num_items();
        my $items = $self->{items};

        if ($index < $num_items) {
            return $items->[$index];
        }
        else {
            return undef;
        }
    }
    else {

        $self->_validate_pattern($pattern, 'get');

        my @items = $self->items();

        for my $item (@items) {
            my $is_matched = $item->match_name($pattern);

            $item = undef unless $is_matched;
        }

        return grep { defined } @items;
    }
}

sub _validate_index {
    my ($self, $index, $operation) = @_;

    my $items = $self->{items};
    my $maximum_allowed_position = scalar (@{$items}) - 1;

    if (D64::Disk::Dir::Item->is_int($index) && $index >= 0x00 && $index <= $maximum_allowed_position) {
        return undef;
    }

    my $dumped_index = $self->_is_valid_number_value($index) ? $index : $self->_dump($index);

    my %description = (
        'add'    => 'Unable to add an item to a directory listing',
        'delete' => 'Unable to mark disk directory item as deleted',
        'get'    => 'Unable to fetch an item from a directory listing',
        'put'    => 'Unable to put an item to a directory listing',
        'remove' => 'Unable to entirely remove directory item',
    );

    die sprintf q{%s: Invalid index parameter (got "%s", but expected an integer between 0 and %d)}, $description{$operation}, $dumped_index, $maximum_allowed_position;
}

sub _validate_pattern {
    my ($self, $pattern, $operation) = @_;

    if (defined ($pattern) && !ref ($pattern) && is_valid_petscii_string($pattern) && length ($pattern) > 0 && length ($pattern) <= 16) {
        return undef;
    }

    my $pattern_to_dump = ref ($pattern) ? $pattern :
        is_printable_petscii_string($pattern) ? petscii_to_ascii($pattern) :
            $pattern;

    my $dumped_pattern = !defined ($pattern) ? 'undef' :
        $self->_is_valid_number_value($pattern) ? $pattern :
            $self->_dump($pattern_to_dump);

    $dumped_pattern =~ s/^"(.*)"$/$1/;
    $dumped_pattern =~ s/^'(.*)'$/$1/;

    my %description = (
        'delete' => 'Unable to mark disk directory item as deleted',
        'get'    => 'Unable to fetch an item from a directory listing',
        'remove' => 'Unable to entirely remove directory item',
    );

    die sprintf q{%s: Invalid pattern parameter (got "%s", but expected a valid PETSCII text string)}, $description{$operation}, $dumped_pattern;
}

sub _validate_item_object {
    my ($self, $item, $operation) = @_;

    my %description = (
        'add'       => 'Unable to add an item to a directory listing',
        'prepended' => 'Failed to validate prepended directory item',
        'pushed'    => 'Failed to validate pushed directory item',
        'put'       => 'Unable to put an item to a directory listing',
    );

    unless (defined $item) {
        die sprintf q{%s: Undefined item parameter (expected valid item object)}, $description{$operation};
    }

    unless (ref $item && $item->isa('D64::Disk::Dir::Item')) {
        die sprintf q{%s: Invalid item parameter (got "%s", but expected a valid item object)}, $description{$operation}, ref $item;
    }

    return undef;
}

=head2 push

Append an item to the end of directory listing, increasing number of files by one element:

  $dir->push(item => $item);

C<$item> is expected to be a valid C<D64::Disk::Dir::Item> object. This method will not work when number of non-empty items stored in a disk directory has already reached its maximum.

=cut

sub push {
    my ($self, %args) = @_;

    my $num_items = $self->num_items();
    if ($num_items >= $MAX_ENTRIES) {
        warn sprintf q{Unable to push another item to a directory listing, maximum number of %d entries has been reached}, $MAX_ENTRIES;
    }

    my $item = $args{item};
    $self->_validate_item_object($item, 'pushed');

    my $last_item_index = $self->_last_item_index();

    $self->{items}->[$last_item_index + 1] = $item->clone();

    $num_items = $self->num_items();

    return $num_items;
}

=head2 pop

Pop and return the last non-empty directory item, shortening a directory listing by one element:

  my $item = $dir->pop();

When there is at least one non-empty item stored in a disk directory, a C<D64::Disk::Dir::Item> object will be returned. Otherwise return value is undefined.

=cut

sub pop {
    my ($self, %args) = @_;

    my $last_item_index = $self->_last_item_index();

    return if $last_item_index < 0;

    my $item = $self->{items}->[$last_item_index];
    $self->{items}->[$last_item_index] = D64::Disk::Dir::Item->new();

    return $item->clone();
}

=head2 shift

Shift the first directory item, shortening a directory listing by one and moving everything down:

  my $item = $dir->shift();

When there is at least one non-empty item stored in a disk directory, a C<D64::Disk::Dir::Item> object will be returned. Otherwise return value is undefined.

=cut

sub shift {
    my ($self, %args) = @_;

    my $last_item_index = $self->_last_item_index();

    return if $last_item_index < 0;

    my $items = $self->{items};

    my $item = CORE::shift @{$items};
    CORE::push @{$items}, D64::Disk::Dir::Item->new();

    return $item->clone();
}

=head2 unshift

Prepend an item to the front of directory listing, and return the new number of elements:

  my $num_items = $dir->unshift(item => $item);

C<$item> is expected to be a valid C<D64::Disk::Dir::Item> object. This method will not work when number of non-empty items stored in a disk directory has already reached its maximum.

=cut

sub unshift {
    my ($self, %args) = @_;

    my $num_items = $self->num_items();
    if ($num_items >= $MAX_ENTRIES) {
        warn sprintf q{Unable to prepend an item to the front of directory listing, maximum number of %d entries has been reached}, $MAX_ENTRIES;
    }

    my $item = $args{item};
    $self->_validate_item_object($item, 'prepended');

    my $items = $self->{items};
    CORE::pop @{$items};
    CORE::unshift @{$items}, $item->clone();

    $num_items = $self->num_items();

    return $num_items;
}

=head2 delete

Mark directory item designated by an offset as deleted:

  my $num_deleted = $dir->delete(index => $index);

Mark directory item being the first one to match given PETSCII pattern as deleted:

  use Text::Convert::PETSCII qw(:convert);

  my $pattern = ascii_to_petscii 'workstage*';

  my $num_deleted = $dir->delete(pattern => $pattern, global => 0);

Mark all directory items matching given PETSCII pattern as deleted:

  use Text::Convert::PETSCII qw(:convert);

  my $pattern = ascii_to_petscii 'workstage*';

  my $num_deleted = $dir->delete(pattern => $pattern, global => 1);

C<pattern> is expected to be any valid PETSCII text string. C<global> parameter defaults to C<0>, hence deleting only a single file matching given criteria by default. When set to any C<true> value, it will trigger deletion of B<all> items with filename matching given PETSCII pattern.

A call to this method always returns the number of successfully deleted items. When deleting an item designated by an offset of an already deleted directory item, such operation does not contribute to the count of successfully deleted items during such a particular method call. In other words, delete an item once, and you get it counted as a successfully deleted one, delete the same item again, and it will not be counted as a deleted one anymore. Of course an item remains delete in a directory listing, it just does not contribute to a value that is returned from this method's call.

Note that this method does not remove an entry from directory layout, it only marks it as deleted. In order to wipe out an entry entirely, see description of L</remove> method.

=cut

sub delete {
    my ($self, %args) = @_;

    if (exists $args{index} && exists $args{pattern}) {
        die q{Unable to mark directory item as deleted: ambiguous deletion index/pattern specified (you cannot specify both parameters at the same time)};
    }

    unless (exists $args{index} || exists $args{pattern}) {
        die q{Unable to mark directory item as deleted: Missing index/pattern parameter (which element did you want to delete?)};
    }

    my $index = $args{index};
    my $global = $args{global};
    my $pattern = $args{pattern};

    my $num_items = $self->num_items();
    my $items = $self->{items};

    if (exists $args{index}) {

        $self->_validate_index($index, 'delete');

        if ($index < $num_items) {
            my $item = $items->[$index];
            my $count = $self->_delete_item($item);
            return $count;
        }
        else {
            return 0;
        }
    }
    else {

        $self->_validate_pattern($pattern, 'delete');

        my $num_deleted = 0;

        for (my $i = 0; $i < $num_items; $i++) {

            my $item = $items->[$i];

            if ($item->match_name($pattern)) {

                my $count = $self->_delete_item($item);

                $num_deleted += $count;

                # File got deleted and only one was requested to get deleted:
                last if $count and !$global;
            }
        }

        return $num_deleted;
    }
}

sub _delete_item {
    my ($self, $item) = @_;

    my $was_closed = $item->closed();
    my $was_deleted = $item->type($T_DEL);

    my $is_closed = $item->closed(0);
    my $is_deleted = $item->type($T_DEL);

    if ($was_closed == $is_closed && $was_deleted == $is_deleted) {
        return 0;
    }

    return 1;
}

=head2 remove

Wipe out directory item designated by an offset entirely:

  my $num_removed = $dir->remove(index => $index);

Wipe out directory item being the first one to match given PETSCII pattern entirely:

  use Text::Convert::PETSCII qw(:convert);

  my $pattern = ascii_to_petscii 'workstage*';

  my $num_removed = $dir->remove(pattern => $pattern, global => 0);

Wipe out all directory items matching given PETSCII pattern entirely:

  use Text::Convert::PETSCII qw(:convert);

  my $pattern = ascii_to_petscii 'workstage*';

  my $num_removed = $dir->remove(pattern => $pattern, global => 1);

C<pattern> is expected to be any valid PETSCII text string. C<global> parameter defaults to C<0>, hence removing only a single file matching given criteria by default. When set to any C<true> value, it will trigger removal of B<all> items with filename matching given PETSCII pattern.

A call to this method always returns the number of successfully removed items.

Note that this method removes an item from directory layout completely. It works a little bit like C<splice>, Perl's core method, removing a single element designated by an offset from an array of disk directory items, however it does not replace it with any new elements, it just shifts the remaining items, shortening a directory listing by one and moving everything from a given offset down. In order to safely mark given file as deleted without removing it from a directory listing, see description of L</delete> method.

=cut

sub remove {
    my ($self, %args) = @_;

    if (exists $args{index} && exists $args{pattern}) {
        die q{Unable to entirely remove directory item: ambiguous removal index/pattern specified (you cannot specify both parameters at the same time)};
    }

    unless (exists $args{index} || exists $args{pattern}) {
        die q{Unable to entirely remove directory item: Missing index/pattern parameter (which element did you want to remove?)};
    }

    my $index = $args{index};
    my $global = $args{global};
    my $pattern = $args{pattern};

    my $num_items = $self->num_items();
    my $items = $self->{items};

    if (exists $args{index}) {

        $self->_validate_index($index, 'remove');

        if ($index < $num_items) {
            $self->_remove_item($index);
            return 1;
        }
        else {
            return 0;
        }
    }
    else {

        $self->_validate_pattern($pattern, 'remove');

        my $num_deleted = 0;

        for (my $i = 0; $i < $num_items; $i++) {

            my $item = $items->[$i];

            if ($item->match_name($pattern)) {

                $self->_remove_item($i);

                $num_deleted += 1;

                # File got deleted and only one was requested to get deleted:
                last unless $global;

                $i--;
                $num_items--;
            }
        }

        return $num_deleted;
    }
}

sub _remove_item {
    my ($self, $index) = @_;

    my $items = $self->{items};

    splice @{$items}, $index, 1;

    CORE::push @{$items}, D64::Disk::Dir::Item->new();

    return undef;
}

=head2 add

Add a new directory item to a directory listing:

  my $is_success = $dir->add(item => $item);

Add a new directory item designated by an offset:

  my $is_success = $dir->add(item => $item, index => $index);

C<$item> is expected to be a valid C<D64::Disk::Dir::Item> object.

A call to this method returns true on a successful addition of a new entry, and false otherwise. Addition of a new item may not be possible, for instance when a maximum number of allowed disk directory elements has already been reached.

C<$index> indicates an offset from the beginning of a directory listing where a new item should be added, with count starting from C<0>. Note that this method will not only insert a new item into a disk directory, it will also shift the remaining items, extending a directory listing by one and moving everything from a given offset up. When C<$index> indicates an element beyond the number of non-empty items currently stored in a disk directory, subroutine will fail and an undefined value will be returned, because such operation would not make much sense (such added entry would not be obtainable from a directory listing anyway). It will also not work when number of non-empty items stored in a disk directory has already reached its maximum. Please note that this operation will not replace a "*", or "splat" file it encounters at a given offset, rather it will always it altogether with the remaining items, unlike C<add> method called without an C<index> parameter specified at all, which is described in the next paragraph.

When C<$index> parameter is unspecified, the method behaves as follows. It finds the first empty slot in a directory listing (that is a first directory item with a "closed" flag unset), and writes given item at that exact position. It will however not work when there is no writable slot in a directory listing available at all. Please note that this operation may or may not write given item at the end of a directory listing, since it will replace any "*", or "splat" file it encounters earlier on its way. In most cases this is a desired behaviour, that is why it is always performed as a default action.

=cut

sub add {
    my ($self, %args) = @_;

    unless (exists $args{item}) {
        die q{Unable to add an item to a directory listing: Missing item parameter (what element did you want to add?)};
    }

    my $index = $args{index};
    my $item = $args{item};

    $self->_validate_item_object($item, 'add');

    my $num_items = $self->num_items();
    my $items = $self->{items};

    unless (defined $index) {
        my $first_empty_slot = $self->_find_first_empty_slot();

        if (defined $first_empty_slot) {
            splice @{$items}, $first_empty_slot, 0x01, $item->clone();
            return 1;
        }
    }
    else {
        $self->_validate_index($index, 'add');

        if ($num_items >= $MAX_ENTRIES) {
            warn sprintf q{Unable to add another item to a directory listing, maximum number of %d entries has been reached}, $MAX_ENTRIES;
        }

        if ($index <= $num_items) {
            splice @{$items}, $index, 0x00, $item->clone();
            CORE::pop @{$items};
            return 1;
        }
    }

    return 0;
}

sub _find_first_empty_slot {
    my ($self) = @_;

    my $items = $self->{items};

    my $index = 0;

    while ($index < $MAX_ENTRIES) {
        my $item = $items->[$index];
        if ($item->writable()) {
            return $index;
        }
        $index++;
    }

    return undef;
}

=head2 put

Put an item to a directory listing at any given position:

  my $is_success = $dir->put(item => $item, index => $index);

C<$item> is expected to be a valid C<D64::Disk::Dir::Item> object. A call to this method returns true on a successful put of a new entry, and false otherwise.

C<$index> is a required parameter that indicates an offset from the beginning of a directory listing where a new item should be put, with count starting from C<0>. Note that this method does not just insert a new item into a disk directory, it rather replaces an existing item previously stored at a given offset. When C<$index> indicates an element beyond the number of non-empty items currently stored in a disk directory, subroutine will fail and an undefined value will be returned, because such operation would not make much sense (such added entry would not be obtainable from a directory listing anyway).

=cut

sub put {
    my ($self, %args) = @_;

    unless (exists $args{index}) {
        die q{Unable to put an item to a directory listing: Missing index parameter (where did you want to put it?)};
    }
    unless (exists $args{item}) {
        die q{Unable to put an item to a directory listing: Missing item parameter (what did you want to put there?)};
    }

    my $index = $args{index};
    my $item = $args{item};

    $self->_validate_index($index, 'put');
    $self->_validate_item_object($item, 'put');

    my $num_items = $self->num_items();
    my $items = $self->{items};

    if ($index <= $num_items) {
        $items->[$index] = $item->clone();
        return 1;
    }

    return 0;
}

=head2 print

Print out formatted disk directory listing:

  $dir->print(fh => $fh, as_petscii => $as_petscii);

C<$fh> defaults to the standard output. C<as_petscii> defaults to false (meaning that ASCII characters will be printed out by default).

A printout does not include header and number of blocks free lines, because information about disk title, disk ID and number of free sectors is stored in a Block Availability Map (see L<D64::Disk::BAM> for more details on how to access these bits of information).

=cut

sub print {
    my ($self, %args) = @_;

    my $fh = $args{fh} || *STDOUT;
    my $as_petscii = $args{as_petscii} || 0;

    $fh->binmode(':bytes');
    my $stdout = select $fh;

    my $items = $self->{items};
    my $num_items = $self->num_items();

    for (my $i = 0; $i < $num_items; $i++) {
        my $item = $items->[$i];
        $item->print(fh => $fh, as_petscii => $as_petscii);
    }

    select $stdout;

    return undef;
}

sub is_numeric {
    my ($self, $var) = @_;

    my $is_numeric = _is_numeric($var);

    return $is_numeric;
}

sub set_iok {
    my ($self, $var) = @_;

    my $var_iok = _set_iok($var);

    return $var_iok;
}

sub _is_valid_byte_value {
    my ($self, $byte_value) = @_;

    if (length ($byte_value) == 1 && ord ($byte_value) >= 0x00 && ord ($byte_value) <= 0xff) {
        return 1;
    }

    return 0;
}

sub _is_valid_number_value {
    my ($self, $number_value) = @_;

    if (D64::Disk::Dir::Item->is_int($number_value) && $number_value >= 0x00 && $number_value <= 0xff) {
        return 1;
    }

    return 0;
}

sub _dump {
    my ($self, $value) = @_;

    if ($self->_is_valid_number_value($value)) {
        return sprintf q{$%02x}, $value;
    }

    if ($self->is_numeric($value)) {
        return sprintf q{%s}, $value;
    }

    my $dump = Data::Dumper->new([$value])->Indent(0)->Terse(1)->Deepcopy(1)->Sortkeys(1)->Dump();

    return $dump;
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace neither by default nor explicitly.

=head1 SEE ALSO

L<D64::Disk::BAM>, L<D64::Disk::Dir::Item>, L<D64::Disk::Image>, L<D64::Disk::Layout>, L<D64::Disk::Layout::Sector>, L<D64::Disk::Status>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.06 (2021-01-18)

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2021 by Pawel Krol E<lt>pawelkrol@cpan.orgE<gt>.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;

__END__
