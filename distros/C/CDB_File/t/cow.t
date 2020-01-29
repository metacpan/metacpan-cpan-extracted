#!perl

use strict;
use warnings;

use Test::More;

use CDB_File;

use File::Temp;
use Devel::Peek;
use B::COW qw{:all};

plan( skip_all => "COW support required") unless can_cow();

plan tests => 10;

my $tmpdir = File::Temp->newdir();

my $good_file_db   = "$tmpdir/good.cdb";
my $good_file_temp = "$tmpdir/good.tmp";

my %a = qw(one Hello two Goodbye);
eval { CDB_File::create( %a, $good_file_db, $good_file_temp ) or die "Failed to create cdb: $!" };
is( "$@", '', "Create cdb" );

my %h;
# Test that good file works.
tie( %h, "CDB_File", $good_file_db ) and pass("Test that good file works");

my $t = tied %h;
isa_ok( $t, "CDB_File" );

my $one = $t->FETCH('one');
is( $one, 'Hello', "Test that good file FETCHes right results" );

ok is_cow( $one ), "FETCH value is COW'd" or Dump $one;
is cowrefcnt( $one ), 1, "  cowrefcnt = 1";

{
    foreach my $k ( sort keys %h ) {
        my $got = $h{$k};
        ok is_cow( $got ), "fetch value '$k' is COW" or Dump $got;
        is cowrefcnt( $got ), 1, "  cowrefcnt = 1";
    }
}
