use warnings;
use strict;
use Test::More tests => 13;
use File::Copy qw(copy);
use File::Path qw(make_path);

use Data::QuickMemoPlus::Reader qw( lqm_to_str lqm_to_txt );

BEGIN {
    unshift @INC, 't/lib';
}

use_ok 'ExampleMemo';
can_ok 'Data::QuickMemoPlus::Reader', 'lqm_to_str';
can_ok 'Data::QuickMemoPlus::Reader', 'lqm_to_txt';
can_ok 'ExampleMemo', 'memo_with_header';
can_ok 'ExampleMemo', 'memo_with_header_no_timestamp';
can_ok 'ExampleMemo', 'memo_no_header';
can_ok 'ExampleMemo', 'jlqm';

my $lqm_file = 't/data/QuickMemo+_191208_220400(5).lqm';
is  ( lqm_to_str($lqm_file), ExampleMemo::memo_with_header(), 'memo with full header' );

$lqm_file = 't/data/good_file.lqm';
is  ( lqm_to_str($lqm_file), ExampleMemo::memo_with_header_no_timestamp(), 'memo with header - missing timestamp' );

{
    local $Data::QuickMemoPlus::Reader::IncludeHeader;
    is  ( lqm_to_str($lqm_file), ExampleMemo::memo_no_header(), 'memo with no header' );
}
is  ( Data::QuickMemoPlus::Reader::extract_json_from_lqm($lqm_file), ExampleMemo::jlqm(), 'jlqm json contents' );

## make test directory.
my $lqm_directory = 't/data';
my $test_directory = 't/data/t 1';
rmdir $test_directory if -d $test_directory;
make_path $test_directory ;
my $lqm_dir_glob = "$lqm_directory/*.lqm";
foreach ( glob qq("$lqm_dir_glob") ) {
    copy $_, $test_directory;
}
## convert all *.lqm in directory
my $file_count = lqm_to_txt($test_directory);
## count how many files. test for that.
my @text_files = glob qq("$test_directory/*.txt");
is  ( scalar @text_files, $file_count, 'convert multiple files.' );

$test_directory = 't/data/t 2';
rmdir $test_directory if -d $test_directory;
make_path $test_directory ;
copy 't/data/QuickMemo+_191208_220400(5).lqm', $test_directory;
## convert single good file
$file_count = lqm_to_txt($test_directory . '/QuickMemo+_191208_220400(5).lqm');
## count how many files. test for that.
@text_files = glob qq("$test_directory/*.txt");
is  ( scalar @text_files, $file_count, 'convert single good file.' );
