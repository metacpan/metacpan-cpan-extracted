use strict;
use warnings;
use lib 't/lib';
use LoadTest;
use Test::More tests => 10;
use Devel::Dwarn;

my $mti = LoadTest->source('Foo');

isa_ok( $mti, "DBIx::Class::ResultSource::MultipleTableInheritance" );

can_ok( $mti,
    qw/new add_additional_parents add_additional_parent _source_by_name schema attach_additional_sources set_primary_key set_sequence raw_source_name raw_table_name add_columns add_relationship/
);

ok( !$mti->can($_), "My helper method $_ was removed" )
    for
    qw/argify qualify_with body_cols pk_cols names_of function_body arg_hash rule_body/;

