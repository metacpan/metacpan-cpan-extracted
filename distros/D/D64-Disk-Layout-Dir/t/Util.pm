package D64::Disk::Layout::Dir::Test::Util;

use bytes;
use strict;
use utf8;
use warnings;

use base qw(Exporter);
our %EXPORT_TAGS = ();
$EXPORT_TAGS{'func'} = [ qw(&get_empty_data &get_empty_sector &get_empty_sectors &get_empty_item &get_empty_items &get_dir_data &get_more_dir_data &get_dir_sectors &get_more_dir_sectors &get_all_dir_items &get_more_all_dir_items &get_dir_items &get_more_dir_items &get_item_bytes &add_items_to_data) ];
$EXPORT_TAGS{'all'} = [ @{$EXPORT_TAGS{'func'}} ];
our @EXPORT_OK = ( @{$EXPORT_TAGS{'all'}} );
our @EXPORT = qw();

our $sector_data_size = eval "\$D64::Disk::Layout::Sector::SECTOR_DATA_SIZE";

our $items_per_sector = eval "\$D64::Disk::Layout::Dir::ITEMS_PER_SECTOR";
our $total_sector_count = eval "\$D64::Disk::Layout::Dir::TOTAL_SECTOR_COUNT";

our $directory_first_track = eval "\$D64::Disk::Layout::Dir::DIRECTORY_FIRST_TRACK";
our $directory_first_sector = eval "\$D64::Disk::Layout::Dir::DIRECTORY_FIRST_SECTOR";

our $directory_item_size = eval "\$D64::Disk::Dir::Item::ITEM_SIZE";

sub get_empty_data {
    my @data = map { chr (0x00), chr (0xff), map { chr 0x00 } (0x03 .. $sector_data_size) } (0x01 .. $total_sector_count);
    return wantarray ? @data : join '', @data;
}

sub get_empty_sector {
    my ($track, $sector) = @_;
    my @data = (chr (0x00), chr (0xff), map { chr 0x00 } (0x03 .. $sector_data_size));
    $sector = D64::Disk::Layout::Dir->set_iok($sector);
    return D64::Disk::Layout::Sector->new(data => \@data, track => $track, sector => $sector);
}

sub get_empty_sectors {
    my $track = $directory_first_track;
    my $sector = $directory_first_sector;
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    my @sectors = map {
        my $empty_sector = get_empty_sector($track, $sector);
        $sector += 0x03;
        $sector -= 0x11 if $sector > 0x12;
        $empty_sector;
    } (0x01 .. $total_sector_count);

    # Fix sector link value for an empty disk directory:
    my $first_sector_data = $sectors[0x00]->data();
    substr $first_sector_data, 0x01, 0x01, chr 0xff;
    $sectors[0x00]->data($first_sector_data);

    return wantarray ? @sectors : \@sectors;
}

sub get_empty_item {
    return D64::Disk::Dir::Item->new();
}

sub get_empty_items {
    my @items = map { get_empty_item() } (0x01 .. $items_per_sector * $total_sector_count);
    return wantarray ? @items : \@items;
}

sub get_item_bytes {
    my ($num_items) = @_;

    if ($num_items < 0 || $num_items > $items_per_sector * $total_sector_count) {
        die sprintf 'Invalid number of directory items requested: %d', $num_items;
    }

    my @tracks = map { chr } map { hex } qw(11 13 10 14 0f 15 0e 16);
    my @sectors = map { chr } map { hex }  qw(00 01 03 06 07 09 0c 0d);
    my @filesizes = map { chr } map { hex }  qw(01 02 03 01 02 03 01 02);

    my @items;

    for my $i (0x01 .. $num_items) {
        my $hi = (($i - 1) & 0b11111000) >> 3;
        my $lo = (($i - 1) & 0b00000111);

        my @item = map { chr } map { hex } qw(82 11 00 46 49 4c 45 30 31 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);

        $item[0x01] = $tracks[$hi];
        $item[0x02] = $sectors[$lo];
        $item[0x07] = chr hex (30 + $hi);
        $item[0x08] = chr hex (31 + $lo);
        $item[0x1c] = $filesizes[$lo];

        push @items, \@item;
    }

    return @items;
}

sub add_items_to_data {
    my ($items, $data, $offset) = @_;
    $offset ||= 0;
    for (my $i = 0; $i < @{$items}; $i++) {
        my @item = @{$items->[$i]};
        my $index = $i * (0x02 + $directory_item_size) + 0x02;
        $index += $offset * (0x02 + $directory_item_size);
        splice @{$data}, $index, scalar (@item), @item;
    }
    return;
}

sub get_dir_data {
    my @data = map { chr (0x00), chr (0xff), map { chr 0x00 } (0x03 .. $sector_data_size) } (0x01 .. $total_sector_count);
    my @items = get_item_bytes(3);
    add_items_to_data(\@items, \@data);
    $data[0x01] = chr 0xff;
    return wantarray ? @data : join '', @data;
}

sub get_more_dir_data {
    my @data = map { chr (0x00), chr (0xff), map { chr 0x00 } (0x03 .. $sector_data_size) } (0x01 .. $total_sector_count);
    my @items = get_item_bytes(12);
    add_items_to_data(\@items, \@data);
    $data[0x00] = chr 0x12;
    $data[0x01] = chr 0x02;
    $data[$sector_data_size + 0x01] = chr 0xff;
    return wantarray ? @data : join '', @data;
}

sub get_dir_sectors {
    my $track = $directory_first_track;
    my $sector = $directory_first_sector;
    my @sectors = map {
        my $empty_sector = get_empty_sector($track, $sector);
        $sector += 0x03;
        $sector -= 0x11 if $sector > 0x12;
        $empty_sector;
    } (0x01 .. $total_sector_count);
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    my @items = get_item_bytes(3);
    add_items_to_data(\@items, \@data);
    $data[0x01] = chr 0xff;
    $sectors[0]->data(@data);
    return wantarray ? @sectors : \@sectors;
}

sub get_more_dir_sectors {
    my $track = $directory_first_track;
    my $sector = 0;
    my @custom_write_order = (1, 2, 4, 7, 10, 13, 16, 5, 8, 11, 14, 17, 3, 6, 9, 12, 15, 18);
    my @sectors = map { get_empty_sector($track, $custom_write_order[$sector++]) } (0x01 .. $total_sector_count);
    my @items = get_item_bytes(12);
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    add_items_to_data([@items[0..7]], \@data);
    $data[0x00] = chr 0x12;
    $data[0x01] = chr 0x02;
    $sectors[0]->data(@data);
    @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    add_items_to_data([@items[8..11]], \@data);
    $data[0x01] = chr 0xff;
    $sectors[1]->data(@data);
    return wantarray ? @sectors : \@sectors;
}

sub get_all_dir_items {
    my @items = map { get_empty_item() } (0x01 .. $items_per_sector * $total_sector_count);
    my @item_bytes = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(3);
    splice @items, 0, scalar (@item_bytes), @item_bytes;
    return wantarray ? @items : \@items;
}

sub get_more_all_dir_items {
    my @items = map { get_empty_item() } (0x01 .. $items_per_sector * $total_sector_count);
    my @item_bytes = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(12);
    splice @items, 0, scalar (@item_bytes), @item_bytes;
    return wantarray ? @items : \@items;
}

sub get_dir_items {
    my @items = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(3);
    return wantarray ? @items : \@items;
}

sub get_more_dir_items {
    my @items = map { D64::Disk::Dir::Item->new($_) } get_item_bytes(12);
    return wantarray ? @items : \@items;
}
