#########################
use strict;
use warnings;
use Test::Deep;
use Test::Exception;
use Test::More tests => 10;
BEGIN { use_ok('D64::File::PRG') };
#########################
sub get_initial_program_data {
    my $addr = 0x1000;
    my $data = join ('', map {chr} (0x4c, 0x06, 0x10, 0x4c, 0x06, 0x10, 0x60));
    return ($addr, $data);
}
#########################
sub get_updated_program_data {
    my $addr = 0x0801;
    my $data = join ('', map {chr} (0x0a, 0x08, 0x01, 0x00, 0x99, 0x22, 0x93, 0x22, 0x00));
    return ($addr, $data);
}
#########################
sub get_updated_file {
    my $file = join ('', map {chr} (0x01, 0x08, 0x0a, 0x08, 0x01, 0x00, 0x99, 0x22, 0x93, 0x22, 0x00));
    return $file;
}
#########################
sub integer_to_address {
    my ($integer) = @_;
    my $address_hi = chr ($integer >> 8 & 0xff);
    my $address_lo = chr ($integer & 0xff);
    return $address_lo . $address_hi;
}
#########################
sub check_file_data_validity {
    my ($prg, $get_data_subref) = @_;
    my ($test_addr, $test_data) = $get_data_subref->();
    my $test_bytes = integer_to_address($test_addr) . $test_data;
    my $file_bytes = $prg->get_data(FORMAT => 'RAW', LOAD_ADDR_INCL => 1);
    return $test_bytes eq $file_bytes;
}
#########################
sub check_raw_data_validity {
    my ($prg, $get_data_subref) = @_;
    my $test_bytes = $get_data_subref->();
    my $file_bytes = $prg->get_data(FORMAT => 'RAW', LOAD_ADDR_INCL => 0);
    return $test_bytes eq $file_bytes;
}
#########################
sub check_loading_address_validity {
    my ($prg, $get_data_subref) = @_;
    my ($test_addr) = $get_data_subref->();
    my @file_addr_bytes = split //, substr $prg->get_data(FORMAT => 'RAW', LOAD_ADDR_INCL => 1), 0, 2;
    my $file_addr = ord ($file_addr_bytes[0]) + ord ($file_addr_bytes[1]) * 0x0100;
    return $test_addr == $file_addr;
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    # Check that old data is valid:
    my $test1 = check_file_data_validity($prg, \&get_initial_program_data);

    ($addr, $data) = get_updated_program_data();
    $prg->set_data(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    # Check that new data is valid:
    my $test2 = check_file_data_validity($prg, \&get_updated_program_data);

    ok($test1 && $test2, 'setting new raw program data and new loading address');
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    # Check that old data is valid:
    my $test1 = check_raw_data_validity($prg, \&get_initial_program_data);
    my $test2 = check_loading_address_validity($prg, \&get_initial_program_data);

    ($addr, $data) = get_updated_program_data();
    $prg->set_data(RAW_DATA => \$data);
    # Check that new data is valid:
    my $test3 = check_raw_data_validity($prg, \&get_updated_program_data);
    my $test4 = check_loading_address_validity($prg, \&get_initial_program_data);

    ok($test1 && $test2 && $test3 && $test4, 'setting new raw program data, loading address remaining unchanged');
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    # Check that old data is valid:
    my $test1 = check_file_data_validity($prg, \&get_initial_program_data);

    my $file = get_updated_file();
    $prg->set_file_data(FILE_DATA => \$file);
    # Check that new data is valid:
    my $test2 = check_file_data_validity($prg, \&get_updated_program_data);

    ok($test1 && $test2, 'setting new file data (loading address and raw program data included)');
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    throws_ok(
        sub { $prg->set_data(LOADING_ADDRESS => undef, RAW_DATA => \$data); },
        qr/an undefined loading address has been provided to the method that was supposed to change its value/,
        'set_data method throws exception on providing undefined loading address',
    );
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    throws_ok(
        sub { $prg->set_data(LOADING_ADDRESS => 'ABC', RAW_DATA => \$data); },
        qr/a non-numeric scalar value cannot be converted into loading address/,
        'set_data method throws exception on providing invalid loading address',
    );
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    throws_ok(
        sub { $prg->set_data(LOADING_ADDRESS => $addr, RAW_DATA => undef); },
        qr/raw data has to be a SCALAR reference \(but is a SCALAR itself\)/,
        'set_data method throws exception on providing undefined raw program data',
    );
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    throws_ok(
        sub { $prg->set_file_data(FILE_DATA => undef); },
        qr/unexpected end of file while reading loading address from IO::Scalar filehandle/,
        'set_file_data method throws exception on providing undefined file data',
    );
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    my $file = chr 0x01;
    throws_ok(
        sub { $prg->set_file_data(FILE_DATA => \$file); },
        qr/unexpected end of file while reading loading address from IO::Scalar filehandle/,
        'set_file_data method throws exception on providing insufficient file data',
    );
}
#########################
{
    my ($addr, $data) = get_initial_program_data();
    my $prg = D64::File::PRG->new(LOADING_ADDRESS => $addr, RAW_DATA => \$data);
    my $file = join ('', map {chr} (0x01, 0x08));
    $prg->set_file_data(FILE_DATA => \$file);

    my $test1 = check_loading_address_validity($prg, \&get_updated_program_data);
    my $file_bytes = $prg->get_data(FORMAT => 'RAW', LOAD_ADDR_INCL => 0);
    my $test2 = length ($file_bytes) == 0;

    ok($test1 && $test2, 'setting new file data (file data containing only loading address and nothing beside it)');
}
#########################
