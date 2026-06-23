use strict;
use warnings;

use Test::More;
use DBIO::Test;

my $schema = DBIO::Test->init_schema;

# All expected sources are registered
my @sources = sort $schema->sources;
ok scalar @sources > 20, 'schema has many sources loaded (got ' . scalar(@sources) . ')';

for my $name (qw(Artist CD Track Tag Genre Producer LinerNotes Bookmark)) {
  ok( (grep { $_ eq $name } @sources), "source '$name' is registered" );
}

# ResultSource metadata works
my $artist_src = $schema->source('Artist');
ok $artist_src, 'can get Artist source';

my @cols = $artist_src->columns;
ok scalar @cols >= 3, 'Artist has columns';
ok $artist_src->has_column('artistid'), 'Artist has artistid column';
ok $artist_src->has_column('name'), 'Artist has name column';

# Primary key
my @pk = $artist_src->primary_columns;
is_deeply \@pk, ['artistid'], 'Artist primary key is artistid';

# Relationships
my $cd_info = $artist_src->relationship_info('cds');
ok $cd_info, 'Artist has cds relationship';

my $cd_src = $schema->source('CD');
my $artist_rel = $cd_src->relationship_info('artist');
ok $artist_rel, 'CD has artist relationship';

# Column info
my $col_info = $artist_src->column_info('name');
is $col_info->{data_type}, 'varchar', 'Artist.name data_type is varchar';
is $col_info->{size}, 100, 'Artist.name size is 100';

done_testing;
