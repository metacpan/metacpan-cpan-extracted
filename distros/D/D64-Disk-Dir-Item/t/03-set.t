########################################
use strict;
use warnings;
use Test::Exception;
use Test::More tests => 54;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Dir::Item';
    use_ok($class, qw(:all));
}
########################################
sub get_item {
    my @bytes = qw(82 11 00 54 45 53 54 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 a0 00 00 00 00 00 00 00 00 00 01 00);
    my @data = map { chr } map { hex } @bytes;
    my $item = $class->new(@data);
    return $item;
}
########################################
{
    my $item = $class->new();
    $item->type($T_SEQ);
    my $type = $item->type();
    is($type, $T_SEQ, 'set new type for an empty directory item');
}
########################################
{
    my $item = get_item();
    $item->type($T_USR);
    my $type = $item->type();
    is($type, $T_USR, 'set new type for a valid directory item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->type(0b1111); },
        qr/Illegal file type constant/,
        'set invalid type value for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->type(ord ($T_PRG) | 0b11110000); },
        qr/\QInvalid file type constant (only bits 0-3 can be set)\E/,
        'set partially invalid type value for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->type('$T_PRG'); },
        qr/\QInvalid file type constant (type constant expected)\E/,
        'set invalid type length for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->type([$T_PRG]); },
        qr/\QInvalid file type constant (scalar value expected)\E/,
        'set invalid type type for a valid directory item',
    );
}
########################################
{
    my $item = $class->new();
    $item->closed(1);
    ok($item->closed(), 'set closed flag for an empty directory item');
}
########################################
{
    my $item = $class->new();
    $item->closed(0);
    ok(!$item->closed(), 'clear closed flag for an empty directory item');
}
########################################
{
    my $item = get_item();
    $item->closed(1);
    ok($item->closed(), 'set closed flag for a valid directory item');
}
########################################
{
    my $item = get_item();
    $item->closed(0);
    ok(!$item->closed(), 'clear closed flag for a valid directory item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->closed([1]); },
        qr/Invalid "closed" flag/,
        'set invalid closed flag for a valid directory item',
    );
}
########################################
{
    my $item = $class->new();
    $item->locked(1);
    ok($item->locked(), 'set locked flag for an empty directory item');
}
########################################
{
    my $item = $class->new();
    $item->locked(0);
    ok(!$item->locked(), 'clear locked flag for an empty directory item');
}
########################################
{
    my $item = get_item();
    $item->locked(1);
    ok($item->locked(), 'set locked flag for a valid directory item');
}
########################################
{
    my $item = get_item();
    $item->locked(0);
    ok(!$item->locked(), 'clear locked flag for a valid directory item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->locked([1]); },
        qr/Invalid "locked" flag/,
        'set invalid locked flag for a valid directory item',
    );
}
########################################
{
    my $item = $class->new();
    my $track = 0x11;
    $item->track($track);
    is($item->track(), $track, 'set new track location of first sector of file for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $track = 0x13;
    $item->track($track);
    is($item->track(), $track, 'set new track location of first sector of file for a valid directory item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->track(0x0100); },
        qr/\QInvalid value (256) of track location of first sector of file (single byte expected)\E/,
        'set non-byte track location of first sector of file for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->track('0x13'); },
        qr/\QInvalid value ('0x13') of track location of first sector of file (single byte expected)\E/,
        'set non-numeric track location of first sector of file for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->track([0x13]); },
        qr/\QInvalid type ([19]) of track location of first sector of file (single byte expected)\E/,
        'set non-scalar track location of first sector of file for a valid directory item',
    );
}
########################################
{
    my $item = $class->new();
    my $sector = 0x03;
    $item->sector($sector);
    is($item->sector(), $sector, 'set new sector location of first sector of file for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $sector = 0x07;
    $item->sector($sector);
    is($item->sector(), $sector, 'set new sector location of first sector of file for a valid directory item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->sector(0x0100); },
        qr/\QInvalid value (256) of sector location of first sector of file (single byte expected)\E/,
        'set non-byte sector location of first sector of file for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->sector('0x03'); },
        qr/\QInvalid value ('0x03') of sector location of first sector of file (single byte expected)\E/,
        'set non-numeric sector location of first sector of file for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->sector([0x07]); },
        qr/\QInvalid type ([7]) of sector location of first sector of file (single byte expected)\E/,
        'set non-scalar sector location of first sector of file for a valid directory item',
    );
}
########################################
{
    my $item = $class->new();
    $item->type($T_REL);
    my $side_track = 0x11;
    $item->side_track($side_track);
    is($item->side_track(), $side_track, 'set new track location of first side-sector block for an empty relative file item');
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    my $side_track = 0x13;
    $item->side_track($side_track);
    is($item->side_track(), $side_track, 'set new track location of first side-sector block for a valid relative file item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->side_track(0x10); },
        qr/\QIllegal file type ('prg') encountered when attempting to set track location of first side-sector block ('rel' files only)\E/,
        'set new track location of first side-sector block for a valid program file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->side_track(0x0100); },
        qr/\QInvalid value (256) of track location of first side-sector block of file (single byte expected)\E/,
        'set non-byte track location of first side-sector block for a valid relative file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->side_track('0x13'); },
        qr/\QInvalid value ('0x13') of track location of first side-sector block of file (single byte expected)\E/,
        'set non-numeric track location of first side-sector block for a valid relative file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->side_track([0x13]); },
        qr/\QInvalid type ([19]) of track location of first side-sector block of file (single byte expected)\E/,
        'set non-scalar track location of first side-sector block for a valid relative file item',
    );
}
########################################
{
    my $item = $class->new();
    $item->type($T_REL);
    my $side_sector = 0x03;
    $item->side_sector($side_sector);
    is($item->side_sector(), $side_sector, 'set new sector location of first side-sector block for an empty relative file item');
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    my $side_sector = 0x07;
    $item->side_sector($side_sector);
    is($item->side_sector(), $side_sector, 'set new sector location of first side-sector block for a valid relative file item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->side_sector(0x10); },
        qr/\QIllegal file type ('prg') encountered when attempting to set sector location of first side-sector block ('rel' files only)\E/,
        'set new sector location of first side-sector block for a valid program file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->side_sector(0x0100); },
        qr/\QInvalid value (256) of sector location of first side-sector block of file (single byte expected)\E/,
        'set non-byte sector location of first side-sector block for a valid relative file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->side_sector('0x13'); },
        qr/\QInvalid value ('0x13') of sector location of first side-sector block of file (single byte expected)\E/,
        'set non-numeric sector location of first side-sector block for a valid relative file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->side_sector([0x13]); },
        qr/\QInvalid type ([19]) of sector location of first side-sector block of file (single byte expected)\E/,
        'set non-scalar sector location of first side-sector block for a valid relative file item',
    );
}
########################################
{
    my $item = $class->new();
    $item->type($T_REL);
    my $record_length = 0x01;
    $item->record_length($record_length);
    is($item->record_length(), $record_length, 'set new record length for an empty relative file item');
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    my $record_length = 0x02;
    $item->record_length($record_length);
    is($item->record_length(), $record_length, 'set new record length for a valid relative file item');
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    my $record_length = 0xfe;
    $item->record_length($record_length);
    is($item->record_length(), $record_length, 'set maximum possible record length for a valid relative file item');
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->record_length(0xff); },
        qr/\QInvalid value (255) of relative file record length (maximum allowed value 254)\E/,
        'set too large record length for a valid relative file item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->record_length(0x03); },
        qr/\QIllegal file type ('prg') encountered when attempting to set record length ('rel' files only)\E/,
        'set new record length for a valid program file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->record_length(0x0100); },
        qr/\QInvalid value (256) of relative file record length (single byte expected)\E/,
        'set non-byte record length for a valid relative file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->record_length('0x13'); },
        qr/\QInvalid value ('0x13') of relative file record length (single byte expected)\E/,
        'set non-numeric record length for a valid relative file item',
    );
}
########################################
{
    my $item = get_item();
    $item->type($T_REL);
    throws_ok(
        sub { $item->record_length([0x13]); },
        qr/\QInvalid type ([19]) of relative file record length (single byte expected)\E/,
        'set non-scalar record length for a valid relative file item',
    );
}
########################################
{
    my $item = $class->new();
    my $size = 0x10;
    $item->size($size);
    is($item->size(), $size, 'set new file size in sectors for an empty directory item');
}
########################################
{
    my $item = get_item();
    my $size = 0xc8;
    $item->size($size);
    is($item->size(), $size, 'set new file size in sectors for a valid directory item');
}
########################################
{
    my $item = get_item();
    my $size = 0x0140;
    $item->size($size);
    is($item->size(), $size, 'set two-bytes large file size in sectors for a valid directory item');
}
########################################
{
    my $item = get_item();
    my $size = 0xffff;
    $item->size($size);
    is($item->size(), $size, 'set maximum possible file size in sectors for a valid directory item');
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->size(0x10000); },
        qr/\QInvalid value (65536) of file size (maximum allowed value 65535)\E/,
        'set too large file size in sectors for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->size('0x3c'); },
        qr/\QInvalid type ('0x3c') of file size (integer value expected)\E/,
        'set non-numeric file size for a valid directory item',
    );
}
########################################
{
    my $item = get_item();
    throws_ok(
        sub { $item->size([0x78]); },
        qr/\QInvalid type ([120]) of file size (integer value expected)\E/,
        'set non-scalar file size for a valid directory item',
    );
}
########################################
