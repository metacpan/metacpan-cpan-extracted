#!/perl

use strict;
use warnings;

use Test::Most;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";


use_ok 'DBIx::Result::Convert::JSONSchema::Type::MySQL';
use_ok 'DBIx::Result::Convert::JSONSchema';
use_ok 'Test::SchemaMock';

my $TYPE_MAP    = DBIx::Result::Convert::JSONSchema::Type::MySQL->get_type_map();

my $schema_mock = Test::SchemaMock->new();
my $schema      = $schema_mock->schema;
my $mock_data   = $schema_mock->mock_data;

isa_ok
    my $converter = DBIx::Result::Convert::JSONSchema->new(
        schema        => $schema,
        schema_source => 'MySQL'
    ),
    'DBIx::Result::Convert::JSONSchema';

throws_ok {
    $converter->get_json_schema();
} qr/missing schema source/;

throws_ok {
    $converter->get_json_schema('Dog');
} qr/Can't find source for Dog/;

my $json_schema = $converter->get_json_schema('MySQLTypeTest');
is ref $json_schema, 'HASH', 'got json schema HashRef';

subtest 'JSON schema keys' => sub {

    my $nr_of_keys = scalar keys %{ $mock_data };
    is keys %{ $json_schema->{properties} }, $nr_of_keys, "got number of $nr_of_keys expected keys";
    is ref $json_schema->{properties}->{ $_ }, 'HASH', "key $_ contains property definition"
        for keys %{ $mock_data };

};

subtest 'MySQL DBIx data type to JSON data type' => sub {

    my $column_info = $converter->_get_column_info('MySQLTypeTest');

    foreach my $schema_definition_key ( keys %{ $column_info } ) {
        my $dbix_field_data_type  = $column_info->{ $schema_definition_key }->{data_type};
        my $json_schema_data_type = $json_schema->{properties}->{ $schema_definition_key }->{type};

        # might contain 'null' if the field is nullable
        my %types = ref $json_schema_data_type eq 'ARRAY' ? map { $_ => 1 } @{ $json_schema_data_type } : ( $json_schema_data_type => 1 );

        ok $types{ $TYPE_MAP->{ $dbix_field_data_type } },
            sprintf "key '$schema_definition_key' with DBIx type '$dbix_field_data_type' converted to JSON schema type";
    }

};

subtest 'JSON schema fields contain pattern' => sub {

    my $column_info     = $converter->_get_column_info('MySQLTypeTest');
    my %has_pattern_map = map { $_ => 1 } keys %{ $converter->pattern_map };

    foreach my $schema_definition_key ( keys %{ $column_info } ) {
        if ( $has_pattern_map{ $column_info->{ $schema_definition_key }->{data_type} } ) {
            ok $json_schema->{properties}->{ $schema_definition_key }->{pattern},
                "field $schema_definition_key has regexp pattern";
        }
    }

};

subtest 'string types have default minLength and maxLength' => sub {

    foreach my $json_schema_key ( keys %{ $json_schema->{properties} } ) {
        my $json_schema_type = $json_schema->{properties}->{ $json_schema_key }->{type};

        if ( $json_schema_type && $json_schema_type eq 'string' ) {
            ok defined $json_schema->{properties}->{ $json_schema_key }->{minLength},
                "JSON schema property $json_schema_key has minLength for string type";
            ok defined $json_schema->{properties}->{ $json_schema_key }->{maxLength},
                "JSON schema property $json_schema_key has maxLength for string type";

        }
    }

};

subtest 'integer types have default minimum and maximum' => sub {

    foreach my $json_schema_key ( keys %{ $json_schema->{properties} } ) {
        my $json_schema_type = $json_schema->{properties}->{ $json_schema_key }->{type};
        next unless $json_schema_type;

        my %type_map = ref $json_schema_type eq 'ARRAY' ? map {
            $_ => 1
        } @{ $json_schema_type } : ( $json_schema_type => 1 );

        if ( $type_map{integer} ) {
            ok defined $json_schema->{properties}->{ $json_schema_key }->{minimum},
                "JSON schema property $json_schema_key has minimum for integer type";
            ok defined $json_schema->{properties}->{ $json_schema_key }->{maximum},
                "JSON schema property $json_schema_key has maximum for integer type";

        }
    }

};

done_testing;
