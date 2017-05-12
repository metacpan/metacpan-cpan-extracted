# Test generating deltas of predefined files.  Make sure that the output can
# be applied to the original file to get the changed one (i.e., that it is
# a correct delta) and also that the delta is as small as I'd expect.

use strict;
use warnings;
use Test::More tests => 6 + 2 * 3;
use IO::Scalar;
use Algorithm::GDiffDelta qw( gdiff_delta gdiff_apply );
use File::Spec::Functions;
use File::Temp qw( tmpnam );

my $data_dir = catdir(qw( t data ));

# Use the example input/output/delta from the GDIFF spec as the first
# test.  To start with, reading and writing from IO::Scalar objects
# to make sure everything works with fake filehandles.
my $orig = 'ABCDEFG';
my $orig_bak = $orig;
my $new = 'ABXYCDBCDE';
my $new_bak = $new;
my $delta = "\xD1\xFF\xD1\xFF\x04" .
            "\xF9\0\0\x02\x02XY\xF9\0\x02\x02\xF9\0\x01\x04\0";
my $ios_orig_file = IO::Scalar->new(\$orig);
my $ios_new_file = IO::Scalar->new(\$new);
my $ios_delta_file = IO::Scalar->new;
gdiff_delta($ios_orig_file, $ios_new_file, $ios_delta_file);
is("$ios_orig_file", $orig_bak,
   'make sure original data in IO::Scalar still OK');
is("$ios_new_file", $new_bak,
   'make sure new data in IO::Scalar still OK');
is(length "$ios_delta_file", 17,
   'check delta produced with IO::Scalar is right length');
like("$ios_delta_file", qr/^\xD1\xFF\xD1\xFF\x04/, 'GDIFF header is right');
like("$ios_delta_file", qr/\x00\z/, 'GDIFF delta ends in EOF opcode');
$ios_orig_file = IO::Scalar->new(\$orig);
$ios_delta_file = IO::Scalar->new(\"$ios_delta_file");
$ios_new_file = IO::Scalar->new;
gdiff_apply($ios_orig_file, $ios_delta_file, $ios_new_file);
is("$ios_new_file", $new_bak, 'delta applies correctly');

# Maximum and minimum lengths we expect the deltas to be for the tests below.
my %DELTA_MAX_LEN = (
    predefined_1 => [ 17, 17 ],
    predefined_2 => [ 433, 435 ],
);

# Now test with real files, using sample data in 't/data'.
for (1 .. 2) {
    my $orig_filename = catfile($data_dir, "$_.orig");
    my $delta_filename = catfile($data_dir, "$_.gdiff");
    my $new_filename = catfile($data_dir, "$_.new");

    open my $orig_file, '<', $orig_filename
      or die "error opening $orig_filename: $!";
    open my $new_file, '<', $new_filename
      or die "error opening $new_filename: $!";
    my $tmp_filename = tmpnam();
    open my $output_file, '>', $tmp_filename
      or die "error opening $tmp_filename: $!";

    gdiff_delta($orig_file, $new_file, $output_file);
    close $output_file;     # to flush it
    open $output_file, '<', $tmp_filename
      or die "error opening $tmp_filename: $!";

    seek $orig_file, 0, 0 or die "error seeking in $orig_filename: $!";
    my $tmp_filename2 = tmpnam();
    open my $output_file2, '>', $tmp_filename2
      or die "error opening $tmp_filename2: $!";
    gdiff_apply($orig_file, $output_file, $output_file2);
    close $output_file2;    # to flush it
    is(read_file($tmp_filename2), read_file($new_filename),
       "delta for sample files numbered $_ produces right output");

    # Make sure the delta is a reasonable size.
    my @stat = stat $output_file or die "error stating $tmp_filename: $!";
    my $size = $stat[7];
    my $expected_size = $DELTA_MAX_LEN{"predefined_$_"};
    ok($size >= $expected_size->[0],
       "delta for $_ should be at least $expected_size->[0] bytes");
    ok($size <= $expected_size->[1],
       "delta for $_ should be at no more than $expected_size->[1] bytes");
}


sub read_file
{
    my ($filename) = @_;

    open my $file, '<', $filename
      or die "error opening $filename: $!";
    my $data = do { local $/; <$file> };
    die "error reading from $filename: $!" unless defined $data;

    return $data;
}

# vim:ft=perl ts=4 sw=4 expandtab:
