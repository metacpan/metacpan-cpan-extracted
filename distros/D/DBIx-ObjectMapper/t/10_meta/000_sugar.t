use strict;
use warnings;
use Test::More;

use DBIx::ObjectMapper::Metadata::Sugar qw(:all);

{
    ok my $id = Col( 'id', Int(), PrimaryKey );
    is ref($id), 'HASH';
    is $id->{name}, 'id';
    ok $id->{primary_key};
    is $id->{is_nullable}, 0;
    is ref($id->{type}), 'DBIx::ObjectMapper::Metadata::Table::Column::Type::Int';
};

{
    ok my $col = Col(
        'col' => (
            String(10), NotNull, ServerDefault('hoge'), Readonly, Unique,
            OnUpdate { 'on_update' },
            Default { 'default' },
            ToStorage { 'to_storage' },
            FromStorage { 'from_storage' },
            ServerCheck( 'length(hoge) > 10'),
            ForeignKey( 'foo' => 'cd' ),
            Validation { 1 }
        )
    );
    is ref($col), 'HASH';
    is $col->{name}, 'col';
    is ref($col->{type}), 'DBIx::ObjectMapper::Metadata::Table::Column::Type::String';
    is $col->{type}->size, 10;
    is $col->{on_update}->(), 'on_update';
    is $col->{default}->(), 'default';
    is $col->{to_storage}->(), 'to_storage';
    is $col->{from_storage}->(), 'from_storage';
    is $col->{server_check}, 'length(hoge) > 10';
    is_deeply $col->{foreign_key}, [ 'foo', 'cd' ];
    is $col->{validation}->(), 1;
    is $col->{unique}, 1;
};

done_testing;
