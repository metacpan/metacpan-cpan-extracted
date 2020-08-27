use strict;
use warnings;
use Test::More;
use Test::Exception;
use lib qw(t/lib);
use DBSchema;

my $schema     = DBSchema->get_test_schema();
my $podcast_rs = $schema->resultset('Podcast');

{
    my $ret1 = DBIx::Class::ResultSet::RecursiveUpdate::Functions::_master_relation_cond( $podcast_rs, 'owner' );
    my $ret2 = DBIx::Class::ResultSet::RecursiveUpdate::Functions::_master_relation_cond( $podcast_rs, 'owner' );
    is $ret1, $ret2, "no side effects";
}

{
    my $before = join ',', sort keys %{$podcast_rs->result_source->column_info('id')};
    DBIx::Class::ResultSet::RecursiveUpdate::Functions::_get_columns_by_accessor($podcast_rs);
    my $after  = join ',', sort keys %{$podcast_rs->result_source->column_info('id')};
    is $before, $after, "no side effects";
}

done_testing;
