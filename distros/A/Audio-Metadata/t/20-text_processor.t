use strict;
use warnings;

use Test::More tests => 3;
use File::Basename ();
use File::Spec;
use Cwd ();
use File::Copy ();

use Audio::Metadata::TextProcessor;


# Derive path to test FLAC file from the path to this test script.
my $test_dir = File::Basename::dirname(Cwd::abs_path($0));
my $orig_test_file_name = File::Spec->catfile($test_dir, 'test-original.flac');

# Make copies of sample file to avoid damaging it during testing.
my @test_file_names;
my $test_file_count = 3;

for (0 .. $test_file_count - 1) {
    my $test_file_name = File::Spec->catfile($test_dir, sprintf('%02d-test.flac', $_ + 1));
    File::Copy::copy($orig_test_file_name, $test_file_name)
        or die "Could not copy \"$orig_test_file_name\" to \"$test_file_name\": $!";

    push @test_file_names, $test_file_name;
}

UPDATE_FROM_TEXT: {
    my @test_file_texts = map <<EOT, 0 .. $test_file_count - 1;
_FILE_NAME $test_file_names[$_]
ALBUM album 0$_
ARTIST artist 0$_
YEAR 198$_
EOT

    my $text_processor = Audio::Metadata::TextProcessor->new({
        input  => \ join("\n", @test_file_texts),
        output => \ my $output,
    });
    $text_processor->update;

    foreach (0 .. $test_file_count - 1) {
        my $audio_file = Audio::Metadata->new_from_path($test_file_names[$_]);
        is($audio_file->as_text, $test_file_texts[$_], 'Retrived text matches written ' . ($_ + 1));
    }
}

UPDATE_FROM_CUE: {
    my $curr_dir = Cwd::getcwd();
    chdir $test_dir;
    my $text_processor = Audio::Metadata::TextProcessor->new({
        input  => File::Spec->catfile($test_dir, 'test.cue'),
        output => \ my $output,
    });
    $text_processor->update_from_cue;
    chdir $curr_dir;
}

unlink @test_file_names;
