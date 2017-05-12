# Test applying predefined deltas.  We do this before generating any so
# that the gdiff_apply() function can be trusted to check the deltas
# produced in later tests.

use strict;
use warnings;
use Test::More tests => 3 + 2;
use IO::Scalar;
use Algorithm::GDiffDelta qw( gdiff_apply );
use File::Spec::Functions;
use File::Temp qw( tmpnam );

my $data_dir = catdir(qw( t data ));

# Use the example input/output/delta from the GDIFF spec as the first
# test.  To start with, reading and writing from IO::Scalar objects
# to make sure everything works with fake filehandles.
my $orig = 'ABCDEFG';
my $orig_bak = $orig;
my $new = 'ABXYCDBCDE';
my $delta = "\xD1\xFF\xD1\xFF\x04" .
            "\xF9\0\0\x02\x02XY\xF9\0\x02\x02\xF9\0\x01\x04\0";
my $delta_bak = $delta;
my $ios_orig_file = IO::Scalar->new(\$orig);
my $ios_delta_file = IO::Scalar->new(\$delta);
my $ios_new_file = IO::Scalar->new;
gdiff_apply($ios_orig_file, $ios_delta_file, $ios_new_file);
is("$ios_orig_file", $orig_bak,
   'make sure original data in IO::Scalar still OK');
is("$ios_delta_file", $delta_bak,
   'make sure delta in IO::Scalar still OK');
is("$ios_new_file", $new, 'apply example delta using IO::Scalar');

# Now test with real files, using sample data in 't/data'.
for (1 .. 2) {
    my $orig_filename = catfile($data_dir, "$_.orig");
    my $delta_filename = catfile($data_dir, "$_.gdiff");
    my $new_filename = catfile($data_dir, "$_.new");

    open my $orig_file, '<', $orig_filename
      or die "error opening $orig_filename: $!";
    open my $delta_file, '<', $delta_filename
      or die "error opening $delta_filename: $!";
    my $tmp_filename = tmpnam();
    open my $output_file, '>', $tmp_filename
      or die "error opening $tmp_filename: $!";

    gdiff_apply($orig_file, $delta_file, $output_file);
    close $output_file;     # to flush it

    my $expected_new = read_file($new_filename);
    my $actual_new = read_file($tmp_filename);
    is($actual_new, $expected_new,
       "apply sample files numbered $_ with real file handles");
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
