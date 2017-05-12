use strict;
use warnings;

use Test::More tests => 8;

BEGIN { use_ok 'Data::Petitcom::BMP' }

subtest 'is_valid_spsize' => sub {
    ok !Data::Petitcom::BMP::is_valid_spsize( 0, 0 );
    ok !Data::Petitcom::BMP::is_valid_spsize( 1, 1 );
    ok Data::Petitcom::BMP::is_valid_spsize( 8,  8 );
    ok Data::Petitcom::BMP::is_valid_spsize( 64, 64 );
    ok !Data::Petitcom::BMP::is_valid_spsize( 16,  64 );
    ok !Data::Petitcom::BMP::is_valid_spsize( 128, 32 );
};

subtest '_xy' => sub {
    my ( $width,    $height )    = ( 16, 16 );
    my ( $sp_width, $sp_height ) = ( 8,  8 );

    my @xy_head = qw{
        0:0 1:0 2:0 3:0 4:0 5:0 6:0 7:0
        0:1 1:1 2:1 3:1 4:1 5:1 6:1 7:1
    };
    my @xy_tail = qw{
        8:14 9:14 10:14 11:14 12:14 13:14 14:14 15:14
        8:15 9:15 10:15 11:15 12:15 13:15 14:15 15:15
    };
    my @xy_pixels;
    Data::Petitcom::BMP::_xy {
        my ( $x, $y, $info ) = @_;
        push @xy_pixels, sprintf( '%d:%d', $x, $y );
    }
    width     => $width,
    height    => $height,
    sp_width  => $sp_width,
    sp_height => $sp_height,
    vflip     => 0;
    is_deeply [ @xy_pixels[ 0 .. 15 ] ],    \@xy_head;
    is_deeply [ @xy_pixels[ 240 .. 255 ] ], \@xy_tail;

    my @vflip_xy_head = qw{
        0:15 1:15 2:15 3:15 4:15 5:15 6:15 7:15
        0:14 1:14 2:14 3:14 4:14 5:14 6:14 7:14
    };
    my @vflip_xy_tail = qw{
        8:1 9:1 10:1 11:1 12:1 13:1 14:1 15:1
        8:0 9:0 10:0 11:0 12:0 13:0 14:0 15:0
    };
    my @vflip_xy_pixels;
    Data::Petitcom::BMP::_xy {
        my ( $x, $y, $info ) = @_;
        push @vflip_xy_pixels, sprintf( '%d:%d', $x, $y );
    }
    width     => $width,
    height    => $height,
    sp_width  => $sp_width,
    sp_height => $sp_height,
    vflip     => 1;
    is_deeply [ @vflip_xy_pixels[ 0 .. 15 ] ],    \@vflip_xy_head;
    is_deeply [ @vflip_xy_pixels[ 240 .. 255 ] ], \@vflip_xy_tail;
};

my $raw_bmp;
subtest 'Dump/Load' => sub {
    my ( $width, $height ) = ( 16, 16 );
    $raw_bmp = Data::Petitcom::BMP::Dump(
        width  => $width,
        height => $height,
        pixels => [ 0 .. 255 ],    # 0, 0 => bottom-left
    );
    ok $raw_bmp;
    is length($raw_bmp), 14 + 40 + 256 * 4 + $width * $height;

    my $bmp = Data::Petitcom::BMP::Load($raw_bmp);
    is $bmp->{width},  $width;
    is $bmp->{height}, $height;
    ok $bmp->{colormap};
    is scalar( @{ $bmp->{pixels} } ), $width * $height;
};

my $raw_data;
subtest 'BMP2DATA' => sub {
    $raw_data = Data::Petitcom::BMP::BMP2DATA(
        $raw_bmp,
        sp_width  => 8,
        sp_height => 8,
    );
    my @data_array = unpack 'C*', $raw_data; # 0, 0 => top-left
    my @expect_data_head = (
        240, 241, 242, 243, 244, 245, 246, 247,
        224, 225, 226, 227, 228, 229, 230, 231,
    );
    my @expect_data_tail = (
        24, 25, 26, 27, 28, 29, 30, 31,
         8,  9,  10, 11, 12, 13, 14, 15,
    );
    is_deeply [ @data_array[0..15] ], \@expect_data_head, '8x8 top-left';
    is_deeply [ @data_array[240..255] ], \@expect_data_tail, '8x8 bottom-right';
};

subtest 'DATA2BMP' => sub {
    my $converted_raw_bmp = Data::Petitcom::BMP::DATA2BMP(
        $raw_data,
        width     => 16,
        height    => 16,
        sp_width  => 8,
        sp_height => 8,
    );
    my $converted_bmp = Data::Petitcom::BMP::Load($converted_raw_bmp);
    my $bmp           = Data::Petitcom::BMP::Load($raw_bmp);
    is_deeply $converted_bmp, $bmp;
};

subtest 'RGB888toRGB555' => sub {
    my $rgb888 = {
        0xFFFFFF => 0x7FFF,
        0xFF0000 => 0x001F,
        0x00FF00 => 0x03E0,
        0x0000FF => 0x7C00,
        0x000000 => 0x0000,
    };
    for my $color (keys %$rgb888) {
        is Data::Petitcom::BMP::RGB888toRGB555($color)->[0], $rgb888->{$color};
    }
};

subtest 'RGB555toRGB888' => sub {
    my $rgb555 = {
        0x7FFF => 0xFFFFFF,
        0x001F => 0xFF0000,
        0x03E0 => 0x00FF00,
        0x7C00 => 0x0000FF,
        0x0000 => 0x000000,
    };
    for my $color (keys %$rgb555) {
        is Data::Petitcom::BMP::RGB555toRGB888($color)->[0], $rgb555->{$color};
    }
};
