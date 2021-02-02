use warnings;
use strict;
use Test::More tests => 10;
 
use Data::QuickMemoPlus::Reader qw( lqm_to_str );

BEGIN {
    unshift @INC, 't/lib';
}

use_ok 'ExampleMemo';
can_ok 'Data::QuickMemoPlus::Reader', 'lqm_to_str';
can_ok 'ExampleMemo', 'memo_with_header';
can_ok 'ExampleMemo', 'memo_with_header_no_timestamp';
can_ok 'ExampleMemo', 'memo_no_header';
can_ok 'ExampleMemo', 'jlqm';


my $lqm_file = 't/data/QuickMemo+_191208_220400(5).lqm';
is  ( lqm_to_str($lqm_file), ExampleMemo::memo_with_header(), 'memo with full header' );

$lqm_file = 't/data/good_file.lqm';
is  ( lqm_to_str($lqm_file), ExampleMemo::memo_with_header_no_timestamp(), 'memo with header - missing timestamp' );

$Data::QuickMemoPlus::Reader::suppress_header = 1;
is  ( lqm_to_str($lqm_file), ExampleMemo::memo_no_header(), 'memo with no header' );

is  ( Data::QuickMemoPlus::Reader::extract_json_from_lqm($lqm_file), ExampleMemo::jlqm(), 'jlqm json contents' );
