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

my $retr_sql = $sql_file->retr('foobar_query');
my $thaw_sql = AlignDB::SQL->thaw($retr_sql);
is( $thaw_sql->as_sql, $sql->as_sql, 'Retrieved query from library.' );

my $thaw_sql2 = $sql_file->retrieve('foobar_query');
is( $thaw_sql2->as_sql, $sql->as_sql, 'Retrieved query from library.' );
