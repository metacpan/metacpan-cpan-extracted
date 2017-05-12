#!perl

use strict;
use warnings;
no warnings 'uninitialized'; # I would use common::sense but I don't want to increase the requirement list :-)

use Test::More;
use lib 't/lib';

use DBICx::Backend::Move::Test::Schema::TestTools;
my $error = DBICx::Backend::Move::Test::Schema::TestTools::setup_db('t/fixtures/testdb.yml', 'dbi:SQLite:dbname=t/from.sqlite');
die $error if $error;
unlink 't/to.sqlite';

use_ok('DBICx::Backend::Move::SQLite');

my $connect_from = [ 'dbi:SQLite:dbname=t/from.sqlite', '', '' ];
my $connect_to   = [ 'dbi:SQLite:dbname=t/to.sqlite'  , '', '' ];
my $schema       = 'DBICx::Backend::Move::Test::Schema';

my $from = $schema->connect(@$connect_from);
is($from->resultset('Host')->find(1)->desc, 'Marie', 'Filtered content in Perl (Source)');
is($from->resultset('Host')->find(1)->get_column('desc'), 'compressed:Marie', 'Unfiltered content in DB (Source)');


my $migrator = DBICx::Backend::Move::SQLite->new();
my $retval = $migrator->migrate($connect_from, $connect_to, { schema => $schema });
is($retval, 0, 'Migrated database');

my $to = $schema->connect(@$connect_to);
is($to->resultset('Host')->find(1)->desc, 'Marie', 'Filtered content in Perl (Destination)');
is($to->resultset('Host')->find(1)->get_column('desc'), 'compressed:Marie', 'Unfiltered content in DB (Destination)');

done_testing();
