use strict;
use warnings;
use DBI;
use DBIx::Model;
use File::Spec;
use Test2::Require::Module 'DBD::SQLite';
use Test2::Bundle::Extended;

my $dbh =
  DBI->connect( 'dbi:SQLite:dbname='
      . File::Spec->catfile( 't', 'Chinook_Sqlite.sqlite' ) );

my $db = $dbh->model;

isa_ok $db, 'DBIx::Model::DB';

foreach my $table ( $db->tables ) {
    next unless $table->name eq 'PlaylistTrack';
    isa_ok $table, 'DBIx::Model::Table';

    foreach my $col ( $table->columns ) {
        isa_ok $col, 'DBIx::Model::Column';
    }
}

done_testing();
