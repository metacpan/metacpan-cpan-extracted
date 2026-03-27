use strict;
use warnings;
use Test::More tests => 4;
use File::Temp qw(tempfile tempdir);
use Apophis;

my $ca = Apophis->new(namespace => 'test-streaming');

# identify_file matches identify for same content
my $content = 'streaming test content here';
my ($fh, $filename) = tempfile(UNLINK => 1);
binmode $fh;
print $fh $content;
close $fh;

my $id_mem = $ca->identify(\$content);
my $id_file = $ca->identify_file($filename);
is($id_mem, $id_file, 'identify_file matches identify for same content');

# Large content (> one 64KB buffer)
my $large = 'x' x 100_000;
my ($fh2, $filename2) = tempfile(UNLINK => 1);
binmode $fh2;
print $fh2 $large;
close $fh2;

my $id_large_mem = $ca->identify(\$large);
my $id_large_file = $ca->identify_file($filename2);
is($id_large_mem, $id_large_file, 'streaming matches in-memory for large content');

# Binary content
my $binary = join('', map { chr($_) } 0..255) x 100;
my ($fh3, $filename3) = tempfile(UNLINK => 1);
binmode $fh3;
print $fh3 $binary;
close $fh3;

my $id_bin_mem = $ca->identify(\$binary);
my $id_bin_file = $ca->identify_file($filename3);
is($id_bin_mem, $id_bin_file, 'streaming matches in-memory for binary content');

# Empty file
my ($fh4, $filename4) = tempfile(UNLINK => 1);
close $fh4;

my $empty = '';
my $id_empty_mem = $ca->identify(\$empty);
my $id_empty_file = $ca->identify_file($filename4);
is($id_empty_mem, $id_empty_file, 'streaming matches in-memory for empty content');
