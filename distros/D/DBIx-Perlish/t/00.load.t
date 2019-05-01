use strict;
use warnings;
use Test::More;

BEGIN {
use_ok( 'DBIx::Perlish' );
}

package DBI::db;
sub foo {}

package main;
use base q(DBI::db);

sub selectcol_arrayref { return [5] }

my $dbh = bless { Driver => { Name => 'test', } };

sub subby { return now() };

eval "use DBIx::Perlish qw(:all);";
ok( !$@, 'load and import' . ($@ // '- all ok'));

my $r;
$r = eval "db_fetch { return now() };";
ok( !$@, 'db_fetch {} ' . ($@ // '- all ok'));
ok( $r == 5, 'db_fetch {} runs ok');
undef $r;

$r = eval "db_fetch sub { return now() };";
ok( !$@, 'db_fetch sub {} ' . ($@ // '- all ok'));
ok( $r == 5, 'db_fetch sub {} runs ok');
undef $r;

$r = eval "db_fetch \\&subby;";
ok( !$@, 'db_fetch \\&subby ' . ($@ // '- all ok'));
ok( $r == 5, 'db_fetch \\&subby runs ok');
undef $r;

done_testing;
