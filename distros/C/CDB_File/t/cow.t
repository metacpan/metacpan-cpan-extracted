#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";
use Helpers;    # Local helper routines used by the test suite.

use Test::More;

use CDB_File;

use Devel::Peek;
use B::COW qw{:all};

plan( skip_all => "COW support required" ) unless can_cow();
plan tests => 14;

my ( $db, $db_tmp ) = get_db_file_pair(1);

my %a = qw(one Hello two Goodbye);
eval { CDB_File::create( %a, $db->filename, $db_tmp->filename ) or die "Failed to create cdb: $!" };
is( "$@", '', "Create cdb" );

my %h;

# Test that good file works.
tie( %h, "CDB_File", $db->filename ) and pass("Test that good file works");

my $t = tied %h;
isa_ok( $t, "CDB_File" );

my $one = $t->FETCH('one');
is( $one, 'Hello', "Test that good file FETCHes right results" );

ok is_cow($one), "FETCH value is COW'd" or Dump $one;
is cowrefcnt($one), 1, "  cowrefcnt = 1";

{
    foreach my $k ( sort keys %h ) {
        my $got = $h{$k};
        ok is_cow($got), "fetch value '$k' is COW" or Dump $got;
        is cowrefcnt($got), 1, "  cowrefcnt = 1";
    }
}

my $first = $t->FIRSTKEY;
ok is_cow($first), "FIRSTKEY value ($first) is COW'd" or Dump $first;
is cowrefcnt($first), 1, "  cowrefcnt = 1";

my $next = $t->NEXTKEY($first);
ok is_cow($next), "NEXTKEY value ($next) is COW'd" or Dump $next;
is cowrefcnt($next), 1, "  cowrefcnt = 1";

exit;
