use strict;
use warnings;
use Test::More;

# Verify that schemas and result classes can be defined with 'use DBIO' syntax.

{
    package MyTest::SQLiteSchema;
    use DBIO 'Schema';
    __PACKAGE__->load_components('SQLite');
}

{
    package MyTest::SQLiteSchema::Result::Artist;
    use DBIO;

    __PACKAGE__->table('artist');
    __PACKAGE__->add_columns(
        id   => { data_type => 'integer', is_auto_increment => 1 },
        name => { data_type => 'varchar', size => 100 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(cds => 'MyTest::SQLiteSchema::Result::CD', 'artist_id');
}

{
    package MyTest::SQLiteSchema::Result::CD;
    use DBIO;

    __PACKAGE__->table('cd');
    __PACKAGE__->add_columns(
        id        => { data_type => 'integer', is_auto_increment => 1 },
        artist_id => { data_type => 'integer' },
        title     => { data_type => 'varchar', size => 200 },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(artist => 'MyTest::SQLiteSchema::Result::Artist', 'artist_id');
}

MyTest::SQLiteSchema->register_class(Artist => 'MyTest::SQLiteSchema::Result::Artist');
MyTest::SQLiteSchema->register_class(CD     => 'MyTest::SQLiteSchema::Result::CD');

ok 'MyTest::SQLiteSchema::Result::Artist'->isa('DBIO::Core'),
    'use DBIO sets up DBIO::Core inheritance';

ok 'MyTest::SQLiteSchema::Result::CD'->isa('DBIO::Core'),
    'second result class also inherits DBIO::Core';

my $schema = MyTest::SQLiteSchema->connect(
    'dbi:SQLite::memory:', '', '', { quote_names => 0 },
);
isa_ok $schema->storage, 'DBIO::SQLite::Storage',
    'SQLite storage loaded via load_components';

$schema->deploy;

subtest 'create and retrieve artist' => sub {
    my $artist = $schema->resultset('Artist')->create({ name => 'Test Artist' });
    ok  $artist->id,   'auto-increment id assigned';
    is  $artist->name, 'Test Artist', 'name column correct';
};

subtest 'belongs_to / has_many relationship' => sub {
    my $artist = $schema->resultset('Artist')->create({ name => 'With CDs' });
    my $cd     = $schema->resultset('CD')->create({
        artist_id => $artist->id,
        title     => 'First Album',
    });
    is $cd->artist->name,  'With CDs', 'belongs_to traversal works';
    is $artist->cds->count, 1,         'has_many count correct';
};

subtest 'search and update' => sub {
    $schema->resultset('Artist')->create({ name => 'Search Me' });
    my $found = $schema->resultset('Artist')->search({ name => 'Search Me' })->single;
    ok $found, 'search returns result';
    $found->update({ name => 'Updated' });
    is $schema->resultset('Artist')->search({ name => 'Updated' })->count,
        1, 'update persisted';
};

done_testing;
