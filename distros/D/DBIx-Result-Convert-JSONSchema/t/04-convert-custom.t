#!/perl

use strict;
use warnings;

use Test::Most;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";


use_ok 'DBIx::Result::Convert::JSONSchema';
use_ok 'Test::SchemaMock';

my $schema_mock = Test::SchemaMock->new();
my $schema      = $schema_mock->schema;

isa_ok
    my $converter = DBIx::Result::Convert::JSONSchema->new(
        schema        => $schema,
        schema_source => 'MySQL',
    ),
    'DBIx::Result::Convert::JSONSchema';

my $type_map = { json => 'cat' };
$converter->type_map({
    %{ $converter->type_map },
    %{ $type_map },
});

my $length_map = { char => [ 666, 999 ] };
$converter->length_map({
    %{ $converter->length_map },
    %{ $length_map },
});

my $length_type_map = { integer => [ qw/ X Y / ] };
$converter->length_type_map({
    %{ $converter->length_type_map },
    %{ $length_type_map },
});

my $pattern_map = { date => 'overwritten pattern', json => 'XYZ' };
$converter->pattern_map({
    %{ $converter->pattern_map },
    %{ $pattern_map },
});

my $json_schema = $converter->get_json_schema('MySQLTypeTest');

foreach my $schema_key ( keys %{ $json_schema->{properties} } ) {
    my $property_type = $json_schema->{properties}->{ $schema_key}->{type};
    if ( $property_type && $property_type eq 'integer' ) {
        ok exists $json_schema->{properties}->{ $schema_key}->{X} && exists $json_schema->{properties}->{ $schema_key}->{Y},
            "key $schema_key got overwritten min/max property length type for integer";
    }
}

cmp_bag $json_schema->{properties}->{json}->{type}, [ qw/ cat null / ], 'got overwritten json default type';
is $json_schema->{properties}->{char}->{minLength}, 666, 'got overwritten char min length';
is $json_schema->{properties}->{date}->{pattern}, 'overwritten pattern', 'got overwritten date pattern';
is $json_schema->{properties}->{json}->{pattern}, 'XYZ', 'got new pattern for json type';

done_testing;
