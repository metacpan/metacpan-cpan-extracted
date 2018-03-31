package Data::JSONSchema::Ajv::Types;
$Data::JSONSchema::Ajv::Types::VERSION = '0.03';
use strict;
use warnings;

=head1 NAME

Data::JSONSchema::Ajv::Types

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Helpers for JSON <-> Perl translations

=head1 SUMMARY

No user-serviceable parts in here

=cut

use Data::Visitor::Callback;
use Data::GUID;

my $guid = Data::GUID->new->as_string;

our $TRUE  = "Data::JSONSchema::Ajv::types::TRUE::$guid";
our $FALSE = "Data::JSONSchema::Ajv::types::FALSE::$guid";
our $NULL  = "Data::JSONSchema::Ajv::types::NULL::$guid";

my $convert = sub {
    my ( $v, $obj ) = @_;
    if ($obj) {
        return $TRUE;
    }
    else {
        return $FALSE;
    }
};

our $visitor = Data::Visitor::Callback->new(
    'Types::Serialiser::BooleanBase' => $convert,
    'JSON::Boolean'                  => $convert,
    'JSON::PP::Boolean'              => $convert,

    # undef -> JavaScript::Duktape::XS->null
    value => sub { $_ // $NULL }
);

our $src = <<"JavaScript";

var data_json_schema_ajv_type_exchange_types = {
    "$TRUE" : true,
    "$FALSE": false,
    "$NULL" : null
};

function data_json_schema_ajv_type_exchange(obj) {
    // Deal with the case where we just get a string on the input
    if (typeof obj == "string" ) {
        if (data_json_schema_ajv_type_exchange_types.hasOwnProperty(obj)) {
            obj = data_json_schema_ajv_type_exchange_types[obj];
        }
        return obj;
    }

    // Deal with everything else
    for (var prop in obj) {
        if (typeof obj[prop] == "string") {
            var val = obj[prop];
            if (data_json_schema_ajv_type_exchange_types.hasOwnProperty(val)) {
                obj[prop] = data_json_schema_ajv_type_exchange_types[val];
            }
        }
    }

    return obj;
}

JavaScript

1;
