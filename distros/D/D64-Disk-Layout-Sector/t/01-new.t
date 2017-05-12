########################################
use strict;
use warnings;
use Test::Deep;
use Test::Exception;
use Test::More tests => 24;
########################################
our $class;
BEGIN {
    $class = 'D64::Disk::Layout::Sector';
    use_ok($class);
}
########################################
{
    can_ok($class, qw(new data file_data track sector is_valid_ts_link ts_link ts_pointer is_last_in_chain alloc_size empty clean print));
}
########################################
our $sector_data_size = eval "\$${class}::SECTOR_DATA_SIZE";
########################################
{
    my $object = $class->new();
    my $data = chr (0x00) x $sector_data_size;
    my $test1 = $object->data() eq $data;
    my $test2 = $object->track() == 0x00;
    my $test3 = $object->sector() == 0x00;
    my $test4 = $object->empty();
    ok($test1 && $test2 && $test3 && $test4, 'empty object initialized with 256 x $00 bytes (get scalar data)');
}
########################################
{
    my $object = $class->new();
    my @data = $object->data();
    my @expected_data = map { chr 0x00 } (0x01 .. $sector_data_size);
    cmp_deeply(\@data, \@expected_data, 'empty object initialized with 256 x $00 bytes (get array data)');
}
########################################
sub get_data {
    my @data = map { chr 0x00 } (0x01 .. $sector_data_size);
    my @file = map { chr } map { hex } qw(00 04 00 10 00);
    splice @data, 0, scalar (@file), @file;
    return @data;
}
########################################
sub get_args {
    my @data = get_data();
    my $track = 0x11;
    my $sector = 0x00;
    return (data => \@data, track => $track, sector => $sector);
}
########################################
{
    my %args = get_args();
    $args{data} = [];
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'initialize new object with a missing data',
    );
}
########################################
{
    my %args = get_args();
    $args{data} = {};
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid arguments given\E/,
        'initialize new object with an invalid data type',
    );
}
########################################
{
    my %args = get_args();
    $args{data} = undef;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to initialize sector data: undefined value of data (256 bytes expected)\E/,
        'initialize new object with an undefined data type',
    );
}
########################################
{
    my %args = get_args();
    delete $args{data};
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to initialize sector data: undefined value of data (256 bytes expected)\E/,
        'initialize new object without a data parameter',
    );
}
########################################
{
    my %args = get_args();
    $args{data} = '';
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid length of data\E/,
        'initialize new object with an empty data',
    );
}
########################################
{
    my %args = get_args();
    pop @{ $args{data} };
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'initialize new object with insufficient amount of data',
    );
}
########################################
{
    my %args = get_args();
    push @{ $args{data} }, chr 0x00;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid amount of data\E/,
        'initialize new object with excessive amount of data',
    );
}
########################################
{
    my %args = get_args();
    $args{data}->[0x03] = chr 0x0100;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid byte value at offset 3 ("\x{100}")\E/,
        'initialize new object with illegal wide character amongst 256 bytes of data',
    );
}
########################################
{
    my %args = get_args();
    $args{data}->[0x06] = [];
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid data type at offset 6 (ARRAY)\E/,
        'initialize new object with a non-scalar variable amongst 256 bytes of data',
    );
}
########################################
{
    my %args = get_args();
    $args{data}->[0x09] = undef;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid byte value at offset 9 (undef)\E/,
        'initialize new object with an undefined value amongst 256 bytes of data',
    );
}
########################################
{
    my %args = get_args();
    $args{data}->[0x0c] = '';
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to set sector data: Invalid byte value at offset 12 ('')\E/,
        'initialize new object with an empty value amongst 256 bytes of data',
    );
}
########################################
{
    my %args = get_args();
    $args{track} = undef;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to initialize track property: undefined value of track (numeric value expected)\E/,
        'initialize new object with an undefined track location',
    );
}
########################################
{
    my %args = get_args();
    $args{track} = 0x00;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QIllegal value (0) of track location of sector data (track 0 does not exist)\E/,
        'initialize new object with an illegal track location',
    );
}
########################################
{
    my %args = get_args();
    $args{track} = [];
    throws_ok(
        sub { $class->new(%args); },
        qr/\QInvalid type ([]) of track location of sector data (single byte expected)\E/,
        'initialize new object with an invalid track variable',
    );
}
########################################
{
    my %args = get_args();
    $args{track} = 0x0100;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QInvalid value (256) of track location of sector data (single byte expected)\E/,
        'initialize new object with a non-byte track location',
    );
}
########################################
{
    my %args = get_args();
    $args{track} = '0x13';
    throws_ok(
        sub { $class->new(%args); },
        qr/\QInvalid value ('0x13') of track location of sector data (single byte expected)\E/,
        'initialize new object with a non-numeric track location',
    );
}
########################################
{
    my %args = get_args();
    $args{sector} = undef;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QUnable to initialize sector property: undefined value of sector (numeric value expected)\E/,
        'initialize new object with an undefined sector location',
    );
}
########################################
{
    my %args = get_args();
    $args{sector} = [];
    throws_ok(
        sub { $class->new(%args); },
        qr/\QInvalid type ([]) of sector location of sector data (single byte expected)\E/,
        'initialize new object with an invalid sector variable',
    );
}
########################################
{
    my %args = get_args();
    $args{sector} = 0x0100;
    throws_ok(
        sub { $class->new(%args); },
        qr/\QInvalid value (256) of sector location of sector data (single byte expected)\E/,
        'initialize new object with a non-byte sector location',
    );
}
########################################
{
    my %args = get_args();
    $args{sector} = '0x01';
    throws_ok(
        sub { $class->new(%args); },
        qr/\QInvalid value ('0x01') of sector location of sector data (single byte expected)\E/,
        'initialize new object with a non-numeric sector location',
    );
}
########################################
