#########################
use Archive::ByteBoozer qw(:crunch);
use IO::Scalar;
use Test::More tests => 2;
#########################
sub dump_hex_data {
    my (@data) = @_;
    my $hex_data_dump = join ',', map { sprintf q{$%02x}, ord $_ } @data;
    return $hex_data_dump;
}
#########################
{
    my @data = (0x00, 0x10, 0x01, 0x01, 0x01, 0x01, 0x01);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my $end_address = 0x2800;
    my %params = (source => $in, target => $out, relocate_output_up_to => $end_address);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf9, 0x27, 0x30, 0x00, 0x10, 0x01, 0x80, 0xff, 0xff);
    is(
        dump_hex_data(@crunched_data),
        dump_hex_data(@expected_data),
        'relocating compressed data up to the given end address',
    );
}
#########################
{
    my @data = (0x00, 0x10, 0x01, 0x01, 0x01, 0x01, 0x01);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my $new_start_address = 0xabcd;
    my $end_address = 0x2800;
    my %params = (source => $in, target => $out, relocate_output => $new_start_address, relocate_output_up_to => $end_address);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf9, 0x27, 0x30, 0x00, 0x10, 0x01, 0x80, 0xff, 0xff);
    is(
        dump_hex_data(@crunched_data),
        dump_hex_data(@expected_data),
        'relocate_output_up_to takes precedence over relocate_output',
    );
}
#########################
