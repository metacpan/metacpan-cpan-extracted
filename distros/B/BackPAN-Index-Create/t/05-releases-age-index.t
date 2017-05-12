#! perl

use strict;
use warnings;
use Test::More 0.88 tests => 5;

use BackPAN::Index::Create              qw/ create_backpan_index /;

use lib 't/lib';
use BackPAN::Index::Create::TestUtils   qw/ setup_testpan text_files_match /;

my $generated_file_name = 't/generated-releases-author-index.txt';
my $expected_file_name  = 't/expected-releases-author-index.txt';

ok(setup_testpan(), "Set mtime on all files in the TestPAN");

eval {
    create_backpan_index({
        basedir         => "t/testpan",
        output          => $generated_file_name,
        releases_only   => 1,
        order           => 'author'
    });
};

ok(!$@, "create_backpan_index() should without croaking");
ok(text_files_match($generated_file_name, $expected_file_name),
   "generated releases index should match the expected content");
ok(unlink($generated_file_name),
   "Should be able to remove the generated index file");
ok(!-f $generated_file_name,
   "The generated file should no longer exist");

