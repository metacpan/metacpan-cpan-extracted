use strict;
use warnings;
use Test::More;

BEGIN { use_ok( 'CSV::Processor::Utils', qw(insert_after_index make_prefix) ); }

my @a = qw/b b c d b/;
my $res = insert_after_index( 1, "x", \@a );
ok $res, 'insert_after_index return 1 if ok';
is_deeply \@a, [ 'b', 'b', 'x', 'c', 'd', 'b' ],
  'insert_after_index works fine';

@a = qw/b b c d b/;
$res = insert_after_index( 5, "x", \@a );
ok !$res, 'return 0 if provided index is more than list size';

is make_prefix( '/test/ya.csv', 'p_' ), '/test/p_ya.csv',
  'make_prefix works fine';

done_testing;
