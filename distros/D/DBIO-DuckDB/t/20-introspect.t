#!/usr/bin/env perl
# t/20-introspect.t — DBIO::DuckDB::Introspect against a freshly deployed
# in-memory DuckDB.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Test;
use DBIO::DuckDB::Introspect;

my $schema = DBIO::DuckDB::Test->init_schema(no_populate => 1);
my $model  = DBIO::DuckDB::Introspect->new(dbh => $schema->storage->dbh)->model;

is ref $model, 'HASH', 'model is hashref';
ok exists $model->{tables}{artist}, 'artist table introspected';
ok exists $model->{tables}{cd},     'cd table introspected';
is $model->{tables}{artist}{kind}, 'table', 'artist is a table';

my @artist_cols = sort map { $_->{column_name} } @{ $model->{columns}{artist} };
ok scalar(grep { $_ eq 'artistid' } @artist_cols), 'artist has artistid column';
ok scalar(grep { $_ eq 'name' }     @artist_cols), 'artist has name column';

my ($pk_col) = grep { $_->{column_name} eq 'artistid' } @{ $model->{columns}{artist} };
ok $pk_col->{is_pk}, 'artistid is primary key';

ok exists $model->{foreign_keys}, 'foreign_keys key present';
ok exists $model->{indexes},      'indexes key present';

done_testing;
