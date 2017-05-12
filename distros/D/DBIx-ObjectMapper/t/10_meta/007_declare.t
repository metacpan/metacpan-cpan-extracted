use strict;
use warnings;
use Test::More;
use DBIx::ObjectMapper::Metadata;

{
    package TestMeta007::A;
    use DBIx::ObjectMapper::Metadata::Declare;

    Table 'foo' =>  [
        Col( 'id' => Int(), PrimaryKey ),
        Col( 'name' => Text(), NotNull ),
    ] =>  { autoload => 1 };

    1;
};

{
    package TestMeta007::B;
    use DBIx::ObjectMapper::Metadata::Declare;

    Table 'bar' =>  [
        Col( 'id' => Int(), PrimaryKey ),
        Col( 'name' => Text(), NotNull ),
    ];

    Table 'baz' => [
        Col( 'id' => BigInt(), PrimaryKey ),
        Col( 't'        => String(10), Unique, NotNull ),
        Col( 'created'  => Datetime(), Default    { \'now()' } ),
        Col( 'modified' => Datetime(), OnUpdate   { \'now()' } ),
    ];

    1;
};

ok( TestMeta007::A->get_declaration() );
ok( TestMeta007::B->get_declaration() );
ok( TestMeta007::A->get_declaration('foo') );
ok( TestMeta007::B->get_declaration('bar') );
ok( TestMeta007::B->get_declaration('baz') );

is_deeply(
    TestMeta007::A->get_declaration(),
    [ TestMeta007::A->get_declaration('foo') ],
);

is( TestMeta007::B->get_declaration, 2 );

my @d = TestMeta007::A->get_declaration('foo');
is $d[0], 'foo';
is ref($d[1][0]), 'HASH';
ok $d[1][0]->{primary_key};
ok !$d[1][0]->{is_nullable};
ok $d[2]->{autoload};


my $metadata = DBIx::ObjectMapper::Metadata->new;
ok my @tables = $metadata->load_from_declaration('TestMeta007::B');
is @tables, 2;
is ref($_), 'DBIx::ObjectMapper::Metadata::Table' for @tables;

done_testing;
