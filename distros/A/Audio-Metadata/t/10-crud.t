use strict;
use warnings;

use Test::More tests => 5;
use Test::Deep;
use File::Copy ();

use Audio::Metadata;


# Derive path to test FLAC file from the path to this test script.
my $orig_test_file_name = $0;
$orig_test_file_name =~ s/[^\/]+$/test-original.flac/;

# Make a copy of sample file to avoid damaging it during testing.
my $test_file_name = 'test.' . ($orig_test_file_name =~ /\.([^.]+)$/)[0];
File::Copy::copy($orig_test_file_name, $test_file_name)
    or die "Could not copy \"$orig_test_file_name\" to \"$test_file_name\": $!";

# Instanciate Audio::Metadata using copy of sample file.
ok(my $audio_file = Audio::Metadata->new_from_path($test_file_name), 'Read audio file');

# Test that medadata is read correctly.
my %test_metadata = (
    ARTIST => 'test artist',
    ALBUM  => 'test album',
    YEAR   => '1980',
);
is_deeply($audio_file->vars_as_hash, \%test_metadata, 'Get metadata');

# Test that medadata is written correctly w/o added padding.
my %updated_metadata = (
    ARTIST => 'updated artist',
    ALBUM  => 'updated album',
    YEAR   => '1996',
);
$audio_file->set_var($_ => $updated_metadata{$_}) foreach keys %updated_metadata;
$audio_file->save;
$audio_file = Audio::Metadata->new_from_path($test_file_name);
is_deeply($audio_file->vars_as_hash, \%updated_metadata, 'Update metadata');

# Same w/added padding.
my $long_comment = 'a' x 50000;
$audio_file->set_var(LONG_COMMENT => $long_comment);
$audio_file->save;
$audio_file = Audio::Metadata->new_from_path($test_file_name);
is_deeply($audio_file->vars_as_hash, { %updated_metadata, LONG_COMMENT => $long_comment }, 'Update metadata w/added padding');

# Test text representation.
my $correct_text = <<EOT;
_FILE_NAME @{[ $audio_file->file_path ]}
ALBUM $updated_metadata{ALBUM}
ARTIST $updated_metadata{ARTIST}
LONG_COMMENT $long_comment
YEAR 1996
EOT
is($audio_file->as_text, $correct_text, 'Get text representation');

# Remove sample file copy.
unlink $test_file_name;
