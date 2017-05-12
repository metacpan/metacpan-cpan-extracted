#########################
use Archive::ByteBoozer qw(:crunch);
use Capture::Tiny qw(capture_stderr);
use IO::Scalar;
use Test::Deep;
use Test::Exception;
use Test::More tests => 27;
#########################
{
    my %params = ();
    throws_ok(
        sub { crunch(%params) },
        qr/source.*target|target.*source/,
        'mandatory source and target parameters missing',
    );
}
#########################
{
    my $io = new IO::Handle;
    my %params = (source => $io);
    throws_ok(
        sub { crunch(%params) },
        qr/target/,
        'mandatory target parameter missing',
    );
}
#########################
{
    my $io = new IO::Handle;
    my %params = (target => $io);
    throws_ok(
        sub { crunch(%params) },
        qr/source/,
        'mandatory source parameter missing',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my %params = (source => $in, target => $out, dummy => 'parameter');
    throws_ok(
        sub { crunch(%params) },
        qr/dummy/,
        'parameter not listed in the validation options',
    );
}
#########################
{
    my $io = new IO::Handle;
    my %params = (source => $io, target => $io);
    throws_ok(
        sub { crunch(%params) },
        qr/is_not_the_same_as_source|is_not_the_same_as_target/,
        'source and target parameters point to the same object',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $start_address = '0xz0c00';
    my %params = (source => $in, target => $out, attach_decruncher => $start_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'invalid start address of the attached decruncher',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $start_address = -1;
    my %params = (source => $in, target => $out, attach_decruncher => $start_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'negative start address of the attached decruncher',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $start_address = 0x10000;
    my %params = (source => $in, target => $out, attach_decruncher => $start_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'exceeding start address of the attached decruncher',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $initial_address = '0xz0c00';
    my %params = (source => $in, target => $out, precede_initial_address => $initial_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'invalid initial address to precede data',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $initial_address = -1;
    my %params = (source => $in, target => $out, precede_initial_address => $initial_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'negative initial address to precede data',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $initial_address = 0x10000;
    my %params = (source => $in, target => $out, precede_initial_address => $initial_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'exceeding initial address to precede data',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $start_address = '0xz0c00';
    my %params = (source => $in, target => $out, relocate_output => $start_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'invalid start address to relocate the compressed data',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $start_address = -1;
    my %params = (source => $in, target => $out, relocate_output => $start_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'negative start address to relocate the compressed data',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $start_address = 0x10000;
    my %params = (source => $in, target => $out, relocate_output => $start_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'exceeding start address to relocate the compressed data',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $initial_address = '0xz0c00';
    my %params = (source => $in, target => $out, replace_initial_address => $initial_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'invalid initial address to replace original start address',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $initial_address = -1;
    my %params = (source => $in, target => $out, replace_initial_address => $initial_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'negative initial address to replace original start address',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my $initial_address = 0x10000;
    my %params = (source => $in, target => $out, replace_initial_address => $initial_address);
    throws_ok(
        sub { crunch(%params) },
        qr/is_valid_memory_address/,
        'exceeding initial address to replace original start address',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Handle;
    my %params = (source => $in, target => $out, verbose => 'x');
    throws_ok(
        sub { crunch(%params) },
        qr/did not pass regex check/,
        'verbose parameter is not a number',
    );
}
#########################
{
    my $in = new IO::Handle;
    my $out = new IO::Scalar;
    my %params = (source => $in, target => $out);
    throws_ok(
        sub { crunch(%params) },
        qr/source.*closed/,
        'input stream bad filehandle',
    );
}
#########################
{
    my $in = new IO::Scalar;
    $in->close;
    my $out = new IO::Scalar;
    my %params = (source => $in, target => $out);
    throws_ok(
        sub { crunch(%params) },
        qr/source file IO::Handle is closed/,
        'input stream is closed',
    );
}
#########################
{
    my @data = (0x00, 0x10, 0x01, 0x02, 0x03, 0x04, 0x05);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Handle;
    my %params = (source => $in, target => $out);
    throws_ok(
        sub { crunch(%params) },
        qr/target.*closed/,
        'output stream bad filehandle',
    );
}
#########################
{
    my @data = (0x00, 0x10, 0x01, 0x02, 0x03, 0x04, 0x05);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    $out->close;
    my %params = (source => $in, target => $out);
    throws_ok(
        sub { crunch(%params) },
        qr/target file IO::Handle is closed/,
        'output stream is closed',
    );
}
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
    my @data = (0x00, 0x10);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my %params = (source => $in, target => $out);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf6, 0xff, 0xff, 0x00, 0x10, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'crunching no input data, only start address');
}
#########################
{
    my $data = '';
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my $initial_address = 0x4000;
    my %params = (source => $in, target => $out, precede_initial_address => $initial_address);
    crunch(%params);
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf6, 0xff, 0xff, 0x00, 0x40, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'crunching no input data with preceding adddress');
}
#########################
{
    my $data = undef;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my $initial_address = 0x8000;
    my %params = (source => $in, target => $out, precede_initial_address => $initial_address);
    # Capture "Use of uninitialized value in subroutine entry" warning:
    capture_stderr {
        crunch(%params);
    };
    my $crunched_data = <$out>;
    my @crunched_data = split '', $crunched_data;
    my @expected_data = map { chr $_ } (0xf6, 0xff, 0xff, 0x00, 0x80, 0xff);
    cmp_deeply(\@crunched_data, \@expected_data, 'crunching undefined input data with preceding adddress');
}
#########################
{
    my @data = (0x10);
    my $data = join '', map { chr $_ } @data;
    my $in = new IO::Scalar \$data;
    my $out = new IO::Scalar;
    my %params = (source => $in, target => $out);
        throws_ok(
        sub { crunch(%params) },
        qr/no data to crunch/,
        'crunching no input data, even incomplete start address',
    );
}
#########################
