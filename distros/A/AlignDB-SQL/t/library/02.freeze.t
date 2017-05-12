#!/usr/bin/perl
use strict;
use warnings;

use Test::More qw( no_plan );    #tests => 59;

BEGIN {
    use_ok('AlignDB::SQL::Library');
}
use AlignDB::SQL;

my $temp_lib = "temp.lib";
my $sql_file = AlignDB::SQL::Library->new( lib => $temp_lib );

my $sql = AlignDB::SQL->new();
$sql->select( [ 'id', 'name' ] );
$sql->add_select('bucket_id');
$sql->add_select('note_id');
$sql->from( ['foo'] );
$sql->add_where( 'name', 'fred' );
$sql->add_where( 'bucket_id', { op => '!=', value => 47 } );
$sql->add_where( 'note_id', \'IS NULL' );
$sql->limit(1);

$sql_file->set( 'foobar_query', $sql );
is( $sql_file->retrieve('foobar_query')->as_sql,
    $sql->as_sql, 'Create a new query in the library.' );

$sql_file->drop('foobar_query');
is( $sql_file->retr('foobar_query'), undef, 'Dropped query from library.' );

$sql_file->set( 'foobar_query', $sql );
is( $sql_file->retr('foobar_query'),
    $sql->freeze, 'Create a new query in the library, again.' );

$sql_file->write;
ok( -e $temp_lib );
