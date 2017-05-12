#########################
use Archive::ByteBoozer qw(:crunch);
use Capture::Tiny qw(capture_stdout);
use File::Temp qw(tempfile unlink0);
use IO::File;
use IO::Scalar;
use Test::Deep;
use Test::Exception;
use Test::More tests => 9;
#########################
{
    my @data = (0x00, 0x10, 0x01, 0x02, 0x03, 0x04, 0x05);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my %params = (source => $in, target => $out);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf0, 0xff, 0x58, 0x00, 0x10, 0xbf, 0x01, 0x02, 0x03, 0x04, 0x05, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'crunching data with the default settings');
}
#########################
{
    my @data = (0x00, 0x10, 0x01, 0x02, 0x03, 0x04, 0x05);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my %params = (source => $in, target => $out, verbose => 1);
    my $stdout = capture_stdout {
        crunch(%params);
    };
    chomp $stdout;
    my $expected_message = '[Archive::ByteBoozer] Compressed 7 bytes into 12 bytes.';
    is($stdout, $expected_message, 'enabling verbose output while crunching data');
}
#########################
{
    my @data = (0x00, 0x10, 0x01, 0x02, 0x03, 0x04, 0x05);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my $new_start_address = 0xabcd;
    my %params = (source => $in, target => $out, relocate_output => $new_start_address);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xcd, 0xab, 0x58, 0x00, 0x10, 0xbf, 0x01, 0x02, 0x03, 0x04, 0x05, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'relocating compressed data to the given start address');
}
#########################
{
    my @data = (0x01, 0x02, 0x03, 0x04, 0x05);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my $initial_address = 0x2468;
    my %params = (source => $in, target => $out, precede_initial_address => $initial_address);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf0, 0xff, 0x58, 0x68, 0x24, 0xbf, 0x01, 0x02, 0x03, 0x04, 0x05, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'crunching data preceding it with the given initial address');
}
#########################
{
    my @data = (0x00, 0x10, 0x01, 0x02, 0x03, 0x04, 0x05);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my $initial_address = 0xc4b5;
    my %params = (source => $in, target => $out, replace_initial_address => $initial_address);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf0, 0xff, 0x58, 0xb5, 0xc4, 0xbf, 0x01, 0x02, 0x03, 0x04, 0x05, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'crunching data replacing it with the new initial address');
}
#########################
{
    my @data = ();
    push @data, map { int rand 0x100 } (0x00 .. 0xff) for (0x00 .. 0xff);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my $initial_address = 0x0400;
    my %params = (source => $in, target => $out, precede_initial_address => $initial_address);
    throws_ok(
        sub { crunch(%params) },
        qr/packed file too large/,
        'packed file too large error check',
    );
}
#########################
{
    my @data = (0x00, 0x10, 0x01);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my %params = (source => $in, target => $out);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf4, 0xff, 0x80, 0x00, 0x10, 0x3f, 0x01, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'crunching minimal possible input data');
}
#########################
{
    my ($fh, $filename) = tempfile();
    binmode  $fh, ':bytes';
    my @data = (0x00, 0x20, 0x4c, 0x00, 0x20);
    my $data = join '', map { chr $_ } @data;
    $fh->syswrite($data, length $data);
    my $in = new IO::File $filename, "r";
    my $out = new IO::Scalar;
    my %params = (source => $in, target => $out);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf2, 0xff, 0x60, 0x00, 0x20, 0xbf, 0x4c, 0x00, 0x20, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'reading data from file');
    unlink0($fh, $filename) or die "Error unlinking file $filename safely";
}
#########################
{
    my ($fh, $filename) = tempfile();
    my @data = (0x00, 0x30, 0x4c, 0x00, 0x30);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::File $filename, "w";
    my %params = (source => $in, target => $out);
    crunch(%params);
    my $size = (stat $filename)[7];
    my $crunched_data = <$fh>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf2, 0xff, 0x60, 0x00, 0x30, 0xbf, 0x4c, 0x00, 0x30, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'writing compressed data to file');
    unlink0($fh, $filename) or die "Error unlinking file $filename safely";
}
#########################
