use strict;
use warnings;
use Test::More;

# Test DBIO::Candy
{
    package TestCandy::Result::Artist;
    use DBIO::Candy;

    table 'artists';

    column id => {
        data_type => 'integer',
        is_auto_increment => 1,
    };

    primary_key 'id';

    column name => {
        data_type => 'varchar',
        size => 100,
    };

    unique_constraint ['name'];
}

ok(TestCandy::Result::Artist->isa('DBIO::Core'), 'Candy sets base class to DBIO::Core');
is(TestCandy::Result::Artist->table, 'artists', 'Candy table() works');
ok(TestCandy::Result::Artist->has_column('id'), 'Candy column() works');
ok(TestCandy::Result::Artist->has_column('name'), 'Candy column() works for name');
is_deeply(
    [TestCandy::Result::Artist->primary_columns],
    ['id'],
    'Candy primary_key() works'
);

# Verify sugar functions are cleaned up
# table() is inherited from DBIO::Core, so it stays — only pure sugar functions get cleaned
ok(!TestCandy::Result::Artist->can('column'), 'Sugar function column() cleaned from namespace');
ok(!TestCandy::Result::Artist->can('unique_constraint'), 'Sugar function unique_constraint() cleaned from namespace');

# Test DBIO::Cake
{
    package TestCake::Result::CD;
    use DBIO::Cake;

    table 'cds';

    col id       => integer, auto_inc;
    col title    => varchar(255);
    col year     => integer, null;
    col rating   => boolean, default(0);

    primary_key 'id';
}

ok(TestCake::Result::CD->isa('DBIO::Core'), 'Cake sets base class to DBIO::Core');
is(TestCake::Result::CD->table, 'cds', 'Cake table() works');
ok(TestCake::Result::CD->has_column('id'), 'Cake col() works for id');
ok(TestCake::Result::CD->has_column('title'), 'Cake col() works for title');

my $id_info = TestCake::Result::CD->column_info('id');
is($id_info->{data_type}, 'integer', 'Cake integer type');
is($id_info->{is_auto_increment}, 1, 'Cake auto_inc');

my $title_info = TestCake::Result::CD->column_info('title');
is($title_info->{data_type}, 'varchar', 'Cake varchar type');
is($title_info->{size}, 255, 'Cake varchar size');

my $year_info = TestCake::Result::CD->column_info('year');
is($year_info->{is_nullable}, 1, 'Cake null modifier');

my $rating_info = TestCake::Result::CD->column_info('rating');
is($rating_info->{data_type}, 'boolean', 'Cake boolean type');
is($rating_info->{default_value}, 0, 'Cake default()');
is($rating_info->{is_nullable}, 0, 'Cake default is_nullable => 0');

# Verify sugar functions are cleaned up
# table() is inherited from DBIO::Core, so it stays
ok(!TestCake::Result::CD->can('col'), 'Cake sugar col() cleaned');
ok(!TestCake::Result::CD->can('integer'), 'Cake sugar integer() cleaned');

# Test extended Cake types
{
    package TestCake::Result::Embedding;
    use DBIO::Cake;

    table 'embeddings';

    col id        => serial;
    col content   => text;
    col embedding => vector(1536);
    col half_emb  => halfvec(768);
    col ip_addr   => inet;
    col search    => tsvector;
    col tags      => hstore;
    col created   => timestamptz;
    col duration  => interval;
    col price     => money;
    col flags     => bit(8);
    col vflags    => varbit(64);
    col loc       => point;
    col ages      => int4range;
    col doc       => xml;
    col mac       => macaddr;

    primary_key 'id';
}

my $emb_id = TestCake::Result::Embedding->column_info('id');
is($emb_id->{data_type}, 'serial', 'Cake serial type');
is($emb_id->{is_auto_increment}, 1, 'Cake serial implies auto_inc');

my $emb_vec = TestCake::Result::Embedding->column_info('embedding');
is($emb_vec->{data_type}, 'vector', 'Cake vector type');
is($emb_vec->{size}, 1536, 'Cake vector dimensions');

my $emb_half = TestCake::Result::Embedding->column_info('half_emb');
is($emb_half->{data_type}, 'halfvec', 'Cake halfvec type');
is($emb_half->{size}, 768, 'Cake halfvec dimensions');

my $emb_ip = TestCake::Result::Embedding->column_info('ip_addr');
is($emb_ip->{data_type}, 'inet', 'Cake inet type');

my $emb_ts = TestCake::Result::Embedding->column_info('search');
is($emb_ts->{data_type}, 'tsvector', 'Cake tsvector type');

my $emb_hs = TestCake::Result::Embedding->column_info('tags');
is($emb_hs->{data_type}, 'hstore', 'Cake hstore type');

my $emb_tstz = TestCake::Result::Embedding->column_info('created');
is($emb_tstz->{data_type}, 'timestamp with time zone', 'Cake timestamptz type');

my $emb_interval = TestCake::Result::Embedding->column_info('duration');
is($emb_interval->{data_type}, 'interval', 'Cake interval type');

my $emb_money = TestCake::Result::Embedding->column_info('price');
is($emb_money->{data_type}, 'money', 'Cake money type');

my $emb_bit = TestCake::Result::Embedding->column_info('flags');
is($emb_bit->{data_type}, 'bit', 'Cake bit type');
is($emb_bit->{size}, 8, 'Cake bit size');

my $emb_varbit = TestCake::Result::Embedding->column_info('vflags');
is($emb_varbit->{data_type}, 'varbit', 'Cake varbit type');
is($emb_varbit->{size}, 64, 'Cake varbit size');

my $emb_point = TestCake::Result::Embedding->column_info('loc');
is($emb_point->{data_type}, 'point', 'Cake point type');

my $emb_range = TestCake::Result::Embedding->column_info('ages');
is($emb_range->{data_type}, 'int4range', 'Cake int4range type');

my $emb_xml = TestCake::Result::Embedding->column_info('doc');
is($emb_xml->{data_type}, 'xml', 'Cake xml type');

my $emb_mac = TestCake::Result::Embedding->column_info('mac');
is($emb_mac->{data_type}, 'macaddr', 'Cake macaddr type');

done_testing;
