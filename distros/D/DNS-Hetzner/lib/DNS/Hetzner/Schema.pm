package DNS::Hetzner::Schema;
$DNS::Hetzner::Schema::VERSION = '0.05';
# ABSTRACT: OpenAPI schema for the DNS API

use v5.24;

use Mojo::Base -strict, -signatures;

use JSON::Validator;
use JSON::Validator::Formats;
use List::Util qw(uniq);
use Mojo::JSON qw(decode_json);
use Mojo::Loader qw(data_section);
use Mojo::Util qw(camelize);

use constant IV_SIZE => eval 'require Config;$Config::Config{ivsize}';

sub validate ( $class, $operation, $params = {} ) {
    my ($spec, $validator) = _get_params($operation);

    my %check_params = map {
        my $camelized = camelize $_;
        $camelized =~ s{Id$}{ID};

        $spec->{param_names}->{$camelized} ?
            ($camelized => $params->{$_}) :
            ($_ => $params->{$_});
    } keys $params->%*;

    my @errors = $validator->validate(
        \%check_params,
    );

    if ( @errors ) {
        return ( undef, @errors );
    }

    my %request_params;

    for my $param_name ( sort keys $spec->{param_names}->%* ) {
        my $key = $spec->{param_names}->{$param_name};

        next if !$check_params{$param_name};

        $request_params{$key}->{$param_name} = $check_params{$param_name};
    }

    return \%request_params;
}

sub _get_params ($operation) {
    state %operation_params;

    my $op_data = $operation_params{$operation};
    return $op_data->@* if $op_data;

    my $api_spec = data_section(__PACKAGE__, 'openapi.json');
    $api_spec    =~ s{/components/schemas}{}g;

    my $data    = decode_json( $api_spec );
    my $schemas = $data->{components}->{schemas};

    my %paths = $data->{paths}->%*;

    my $op;

    for my $path ( keys %paths ) {

        METHOD:
        for my $method_name ( keys $paths{$path}->%* ) {
            next METHOD if 'HASH' ne ref $paths{$path}->{$method_name};

            my $method = $paths{$path}->{$method_name};
            if ( $method->{operationId} && $method->{operationId} eq $operation ) {
                $op = $method;
            }
        }
    }

    return {} if !$op;

    my $params = $op->{parameters};

    my %properties;
    my @required;
    my %param_names;

    PARAM:
    for my $param ( $params->@* ) {
        next PARAM if $param->{name} eq 'Auth-API-Token';

        my $name = $param->{name};

        if ( $param->{required} ) {
            push @required, $name;
        }

        $param_names{$name} = $param->{in};
        $properties{$name}  = $param;
    }

    my ($content_type, $body_required);
    if ( $op->{requestBody} ) {
       my $body       = $op->{requestBody}->{content};
       $body_required = $op->{requestBody}->{required};

       ($content_type) = sort keys $body->%*;

       if ( $content_type eq 'application/json' ) {
           my $schema = $body->{$content_type}->{schema};
           my $prop   = $schema->{properties} || {};
           for my $property ( keys $prop->%* ) {
               $properties{$property}  = delete $prop->{$property};
               $param_names{$property} = 'body';
           }

           if ( $schema->{'$ref'} ) {  # '$ref' is not a typo. The key is named '$ref'!
               $properties{'$ref'} = $schema->{'$ref'};
           }
       }
       elsif ( $content_type eq 'text/plain' ) {
           $properties{text}  = { type => "string" };
           $param_names{text} = 'body';
       }
    }

    my $spec = {
        type          => 'object',
        required      => \@required,
        body_required => $body_required,
        properties    => \%properties,
        param_names   => \%param_names,
        content_type  => $content_type,
        $schemas->%*,
    };

    my $validator = JSON::Validator->new->schema($spec);

    $validator->formats->{uint32} = sub {
        my ($sub) = JSON::Validator::Formats->can('_match_number');

        $sub->( unint32 => $_[0], 'L' );
    };

    $validator->formats->{uint64} = sub {
        my ($sub) = JSON::Validator::Formats->can('_match_number');

        $sub->( unint32 => $_[0], IV_SIZE >= 8 ? 'Q' : '' );
    };

    if ( $spec->{properties}->{'$ref'} ) {
        my @ref = $spec->{properties}->{'$ref'};
        while ( my $ref = shift @ref ) {
            $ref =~ s{^#}{};

            my $data = $validator->get( $ref );
            if ( $data->{properties} ) {
                for my $property ( keys $data->{properties}->%* ) {
                    next if $data->{properties}->{$property}->{readOnly};

                    $spec->{param_names}->{$property} = 'body';
                }
            }

            if ( $data->{allOf} ) {
                push @ref, map{ $_->{'$ref'} } $data->{allOf}->@*;
                if ( $data->{required} ) {
                    push $spec->{required}->@*, $data->{required}->@*;
                }
            }
        }
    }

    $spec->{required}->@* = uniq $spec->{required}->@*;

    $operation_params{$operation} = [ $spec, $validator ];
    return $operation_params{$operation}->@*;
}

1;

=pod

=encoding UTF-8

=head1 NAME

DNS::Hetzner::Schema - OpenAPI schema for the DNS API

=head1 VERSION

version 0.05

=head1 SYNOPSIS

=head1 METHODS

=head2 validate

=head1 AUTHOR

Renee Baecker <reneeb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Renee Baecker.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

__DATA__
@@ openapi.json
{
   "components" : {
      "schemas" : {
         "BasePrimaryServer" : {
            "properties" : {
               "address" : {
                  "description" : "IPv4 or IPv6 address of the primary server",
                  "type" : "string"
               },
               "port" : {
                  "description" : "Port number of the primary server",
                  "maximum" : 65535,
                  "minimum" : 1,
                  "type" : "integer"
               },
               "zone_id" : {
                  "description" : "ID of zone this record is associated with",
                  "type" : "string"
               }
            }
         },
         "BaseRecord" : {
            "properties" : {
               "name" : {
                  "description" : "Name of record",
                  "type" : "string"
               },
               "ttl" : {
                  "description" : "TTL of record",
                  "format" : "uint64",
                  "type" : "integer"
               },
               "type" : {
                  "$ref" : "#/components/schemas/RecordTypeCreatable"
               },
               "value" : {
                  "description" : "Value of record (e.g. 127.0.0.1, 1.1.1.1)",
                  "type" : "string"
               },
               "zone_id" : {
                  "description" : "ID of zone this record is associated with",
                  "type" : "string"
               }
            }
         },
         "BaseRecordBulk" : {
            "properties" : {
               "id" : {
                  "description" : "ID of record",
                  "type" : "string"
               },
               "name" : {
                  "description" : "Name of record",
                  "type" : "string"
               },
               "ttl" : {
                  "description" : "TTL of record",
                  "format" : "uint64",
                  "type" : "integer"
               },
               "type" : {
                  "$ref" : "#/components/schemas/RecordTypeCreatable"
               },
               "value" : {
                  "description" : "Value of record (e.g. 127.0.0.1, 1.1.1.1)",
                  "type" : "string"
               },
               "zone_id" : {
                  "description" : "ID of zone this record is associated with",
                  "type" : "string"
               }
            }
         },
         "BaseZone" : {
            "properties" : {
               "created" : {
                  "description" : "Time zone was created",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               },
               "id" : {
                  "description" : "ID of zone",
                  "readOnly" : true,
                  "type" : "string"
               },
               "is_secondary_dns" : {
                  "description" : "Indicates if a zone is a secondary DNS zone",
                  "readOnly" : true,
                  "type" : "boolean"
               },
               "legacy_dns_host" : {
                  "readOnly" : true,
                  "type" : "string"
               },
               "legacy_ns" : {
                  "items" : {
                     "type" : "string"
                  },
                  "readOnly" : true,
                  "type" : "array"
               },
               "modified" : {
                  "description" : "Time zone was last updated",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               },
               "name" : {
                  "description" : "Name of zone",
                  "type" : "string"
               },
               "ns" : {
                  "items" : {
                     "type" : "string"
                  },
                  "readOnly" : true,
                  "type" : "array"
               },
               "owner" : {
                  "description" : "Owner of zone",
                  "readOnly" : true,
                  "type" : "string"
               },
               "paused" : {
                  "readOnly" : true,
                  "type" : "boolean"
               },
               "permission" : {
                  "description" : "Zone's permissions",
                  "readOnly" : true,
                  "type" : "string"
               },
               "project" : {
                  "readOnly" : true,
                  "type" : "string"
               },
               "records_count" : {
                  "description" : "Amount of records associated to this zone",
                  "format" : "uint64",
                  "readOnly" : true,
                  "type" : "integer"
               },
               "registrar" : {
                  "readOnly" : true,
                  "type" : "string"
               },
               "status" : {
                  "description" : "Status of zone",
                  "enum" : [
                     "verified",
                     "failed",
                     "pending"
                  ],
                  "readOnly" : true,
                  "type" : "string"
               },
               "ttl" : {
                  "description" : "TTL of zone",
                  "format" : "uint64",
                  "type" : "integer"
               },
               "txt_verification" : {
                  "description" : "Shape of the TXT record that has to be set to verify a zone. If name and token are empty, no TXT record needs to be set",
                  "properties" : {
                     "name" : {
                        "description" : "Name of the TXT record",
                        "readOnly" : true,
                        "type" : "string"
                     },
                     "token" : {
                        "description" : "Value of the TXT record",
                        "readOnly" : true,
                        "type" : "string"
                     }
                  },
                  "readOnly" : true,
                  "type" : "object"
               },
               "verified" : {
                  "description" : "Verification of zone",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               }
            },
            "type" : "object"
         },
         "ExistingPrimaryServer" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/BasePrimaryServer"
               }
            ],
            "properties" : {
               "created" : {
                  "description" : "Time primary server was created",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               },
               "id" : {
                  "description" : "ID of primary server",
                  "readOnly" : true,
                  "type" : "string"
               },
               "modified" : {
                  "description" : "Time primary server was last updated",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               }
            },
            "type" : "object"
         },
         "ExistingRecord" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/BaseRecord"
               }
            ],
            "properties" : {
               "created" : {
                  "description" : "Time record was created",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               },
               "id" : {
                  "description" : "ID of record",
                  "readOnly" : true,
                  "type" : "string"
               },
               "modified" : {
                  "description" : "Time record was last updated",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               }
            },
            "type" : "object"
         },
         "ExistingRecordBulk" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/BaseRecordBulk"
               }
            ],
            "properties" : {
               "created" : {
                  "description" : "Time record was created",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               },
               "id" : {
                  "description" : "ID of record",
                  "readOnly" : false,
                  "type" : "string"
               },
               "modified" : {
                  "description" : "Time record was last updated",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               }
            },
            "type" : "object"
         },
         "Meta" : {
            "description" : "",
            "properties" : {
               "pagination" : {
                  "$ref" : "#/components/schemas/Pagination"
               }
            },
            "type" : "object"
         },
         "Pagination" : {
            "description" : "",
            "properties" : {
               "last_page" : {
                  "description" : "This value represents the last page",
                  "minimum" : 1,
                  "type" : "number"
               },
               "page" : {
                  "description" : "This value represents the current page",
                  "minimum" : 1,
                  "type" : "number"
               },
               "per_page" : {
                  "description" : "This value represents the number of entries that are returned per page",
                  "minimum" : 1,
                  "type" : "number"
               },
               "total_entries" : {
                  "description" : "This value represents the total number of entries",
                  "type" : "number"
               }
            },
            "type" : "object"
         },
         "PrimaryServer" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/ExistingPrimaryServer"
               }
            ],
            "required" : [
               "id",
               "address",
               "port",
               "zone_id"
            ],
            "type" : "object"
         },
         "PrimaryServerResponse" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/ExistingPrimaryServer"
               }
            ],
            "properties" : {
               "port" : {
                  "maximum" : 65535,
                  "minimum" : 1,
                  "type" : "integer"
               }
            },
            "type" : "object"
         },
         "Record" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/ExistingRecord"
               }
            ],
            "required" : [
               "name",
               "type",
               "value",
               "zone_id"
            ],
            "type" : "object"
         },
         "RecordBulk" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/ExistingRecordBulk"
               }
            ],
            "required" : [
               "id",
               "name",
               "type",
               "value",
               "zone_id"
            ],
            "type" : "object"
         },
         "RecordResponse" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/ExistingRecord"
               }
            ],
            "properties" : {
               "type" : {
                  "$ref" : "#/components/schemas/RecordType"
               }
            },
            "type" : "object"
         },
         "RecordType" : {
            "description" : "Type of the record",
            "enum" : [
               "A",
               "AAAA",
               "PTR",
               "NS",
               "MX",
               "CNAME",
               "RP",
               "TXT",
               "SOA",
               "HINFO",
               "SRV",
               "DANE",
               "TLSA",
               "DS",
               "CAA"
            ],
            "type" : "string"
         },
         "RecordTypeCreatable" : {
            "description" : "Type of the record",
            "enum" : [
               "A",
               "AAAA",
               "NS",
               "MX",
               "CNAME",
               "RP",
               "TXT",
               "SOA",
               "HINFO",
               "SRV",
               "DANE",
               "TLSA",
               "DS",
               "CAA"
            ],
            "type" : "string"
         },
         "Zone" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/BaseZone"
               }
            ],
            "required" : [
               "name"
            ],
            "type" : "object"
         },
         "ZoneResponse" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/BaseZone"
               }
            ],
            "type" : "object"
         }
      },
      "securitySchemes" : {
         "Auth-API-Token" : {
            "description" : "You can create an API token in the DNS console.",
            "in" : "header",
            "name" : "Auth-API-Token",
            "type" : "apiKey"
         }
      }
   },
   "info" : {
      "contact" : {
         "email" : "support@hetzner.com",
         "name" : "Hetzner Online GmbH"
      },
      "description" : "This is the public documentation Hetzner's DNS API.",
      "title" : "Hetzner DNS Public API",
      "version" : "1.1.1",
      "x-logo" : {
         "altText" : "Hetzner",
         "url" : "https://www.hetzner.com/themes/hetzner/images/logo/hetzner-logo.svg"
      }
   },
   "openapi" : "3.0.1",
   "paths" : {
      "/primary_servers" : {
         "get" : {
            "description" : "Returns all primary servers associated with user. Primary servers can also be filtered by zone_id.",
            "operationId" : "GetPrimaryServers",
            "parameters" : [
               {
                  "description" : "ID of zone",
                  "explode" : true,
                  "in" : "query",
                  "name" : "zone_id",
                  "required" : false,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "form"
               }
            ],
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "primary_servers" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/PrimaryServerResponse"
                                 },
                                 "type" : "array"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Get All Primary Servers",
            "tags" : [
               "Primary Servers"
            ]
         },
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "post" : {
            "description" : "Creates a new primary server.",
            "operationId" : "CreatePrimaryServer",
            "parameters" : [],
            "requestBody" : {
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "$ref" : "#/components/schemas/PrimaryServer"
                     }
                  }
               },
               "required" : false
            },
            "responses" : {
               "201" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "primary_server" : {
                                 "$ref" : "#/components/schemas/PrimaryServerResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Created"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Create Primary Server",
            "tags" : [
               "Primary Servers"
            ],
            "x-codegen-request-body-name" : "body"
         }
      },
      "/primary_servers/{PrimaryServerID}" : {
         "delete" : {
            "description" : "Deletes a primary server.",
            "operationId" : "DeletePrimaryServer",
            "parameters" : [
               {
                  "description" : "ID of primary server to be deleted",
                  "explode" : false,
                  "in" : "path",
                  "name" : "PrimaryServerID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "responses" : {
               "200" : {
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Delete Primary Server",
            "tags" : [
               "Primary Servers"
            ]
         },
         "get" : {
            "description" : "Returns an object containing all information of a primary server. Primary Server to get is identified by 'PrimaryServerID'.",
            "operationId" : "GetPrimaryServer",
            "parameters" : [
               {
                  "description" : "ID of primary server to get",
                  "explode" : false,
                  "in" : "path",
                  "name" : "PrimaryServerID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "primary_server" : {
                                 "$ref" : "#/components/schemas/PrimaryServerResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Get Primary Server",
            "tags" : [
               "Primary Servers"
            ]
         },
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "put" : {
            "description" : "Updates a primary server.",
            "operationId" : "UpdatePrimaryServer",
            "parameters" : [
               {
                  "description" : "ID of primaryServer to update",
                  "explode" : false,
                  "in" : "path",
                  "name" : "PrimaryServerID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "requestBody" : {
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "$ref" : "#/components/schemas/PrimaryServer"
                     }
                  }
               }
            },
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "primary_server" : {
                                 "$ref" : "#/components/schemas/PrimaryServerResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "409" : {
                  "description" : "Conflict"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Update Primary Server",
            "tags" : [
               "Primary Servers"
            ],
            "x-codegen-request-body-name" : "body"
         }
      },
      "/records" : {
         "get" : {
            "description" : "Returns all records associated with user.",
            "operationId" : "GetRecords",
            "parameters" : [
               {
                  "description" : "ID of zone",
                  "explode" : true,
                  "in" : "query",
                  "name" : "zone_id",
                  "required" : false,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "form"
               },
               {
                  "description" : "Number of records to be shown per page. Returns all by default",
                  "explode" : true,
                  "in" : "query",
                  "name" : "per_page",
                  "required" : false,
                  "schema" : {
                     "type" : "number"
                  },
                  "style" : "form"
               },
               {
                  "description" : "A page parameter specifies the page to fetch.<br />The number of the first page is 1",
                  "explode" : true,
                  "in" : "query",
                  "name" : "page",
                  "required" : false,
                  "schema" : {
                     "default" : 1,
                     "minimum" : 1,
                     "type" : "number"
                  },
                  "style" : "form"
               }
            ],
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "records" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/RecordResponse"
                                 },
                                 "type" : "array"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Get All Records",
            "tags" : [
               "Records"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Get Records\n# Returns all records associated with user.\ncurl \"https://dns.hetzner.com/api/v1/records?zone_id={ZoneID}\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendGetRecords() {\n\t// Get Records (GET https://dns.hetzner.com/api/v1/records?zone_id={ZoneID})\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/records?zone_id={ZoneID}\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\tparseFormErr := req.ParseForm()\n\tif parseFormErr != nil {\n\t  fmt.Println(parseFormErr)    \n\t}\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records?zone_id={ZoneID}');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Get Records\n    # GET https://dns.hetzner.com/api/v1/records\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/records\",\n            params={\n                \"zone_id\": \"{ZoneID}\",\n            },\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ]
         },
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "post" : {
            "description" : "Creates a new record.",
            "operationId" : "CreateRecord",
            "parameters" : [],
            "requestBody" : {
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "$ref" : "#/components/schemas/Record"
                     }
                  }
               },
               "required" : false
            },
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "record" : {
                                 "$ref" : "#/components/schemas/RecordResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Create Record",
            "tags" : [
               "Records"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Create Record\n# Creates a new record.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/records\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"value\": \"1.1.1.1\",\n  \"ttl\": 86400,\n  \"type\": \"A\",\n  \"name\": \"www\",\n  \"zone_id\": \"1\"\n}'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendCreateRecord() {\n\t// Create Record (POST https://dns.hetzner.com/api/v1/records)\n\n\tjson := []byte(`{\"value\": \"1.1.1.1\",\"ttl\": 86400,\"type\": \"A\",\"name\": \"www\",\"zone_id\": \"1\"}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/records\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'value' => '1.1.1.1',\n  'ttl' => 86400,\n  'type' => 'A',\n  'name' => 'www',\n  'zone_id' => '1'\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Create Record\n    # POST https://dns.hetzner.com/api/v1/records\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/records\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"value\": \"1.1.1.1\",\n                \"ttl\": 86400,\n                \"type\": \"A\",\n                \"name\": \"www\",\n                \"zone_id\": \"1\"\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "body"
         }
      },
      "/records/bulk" : {
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "post" : {
            "description" : "Create several records at once.",
            "operationId" : "BulkCreateRecords",
            "parameters" : [],
            "requestBody" : {
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "properties" : {
                           "records" : {
                              "items" : {
                                 "$ref" : "#/components/schemas/Record"
                              },
                              "type" : "array"
                           }
                        },
                        "type" : "object"
                     }
                  }
               },
               "required" : false
            },
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "invalid_records" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/BaseRecord"
                                 },
                                 "type" : "array"
                              },
                              "records" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/RecordResponse"
                                 },
                                 "type" : "array"
                              },
                              "valid_records" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/BaseRecord"
                                 },
                                 "type" : "array"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Bulk Create Records",
            "tags" : [
               "Records"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Bulk Create Records\n# Create several records at once.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/records/bulk\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"records\": [\n    {\n      \"value\": \"81.169.145.141\",\n      \"type\": \"A\",\n      \"name\": \"autoconfig\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:5800::1141\",\n      \"type\": \"AAAA\",\n      \"name\": \"autoconfig\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.145.105\",\n      \"type\": \"A\",\n      \"name\": \"www\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:1105::\",\n      \"type\": \"AAAA\",\n      \"name\": \"www\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.145.105\",\n      \"type\": \"A\",\n      \"name\": \"cloud\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:1105::\",\n      \"type\": \"AAAA\",\n      \"name\": \"cloud\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.145.105\",\n      \"type\": \"A\",\n      \"name\": \"@\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:1105::\",\n      \"type\": \"AAAA\",\n      \"name\": \"@\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.145.97\",\n      \"type\": \"A\",\n      \"name\": \"smtpin\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:50f0::1097\",\n      \"type\": \"AAAA\",\n      \"name\": \"smtpin\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20b:43:6653::506\",\n      \"type\": \"AAAA\",\n      \"name\": \"shades06\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"85.214.0.236\",\n      \"type\": \"A\",\n      \"name\": \"shades06\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"10 smtpin\",\n      \"type\": \"MX\",\n      \"name\": \"@\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.146.21\",\n      \"type\": \"A\",\n      \"name\": \"docks11\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:930:6653::d11\",\n      \"type\": \"AAAA\",\n      \"name\": \"docks11\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    }\n  ]\n}'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendBulkCreateRecords() {\n\t// Bulk Create Records (POST https://dns.hetzner.com/api/v1/records/bulk)\n\n\tjson := []byte(`{\"records\": [{\"value\": \"81.169.145.141\",\"type\": \"A\",\"name\": \"autoconfig\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:5800::1141\",\"type\": \"AAAA\",\"name\": \"autoconfig\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.145.105\",\"type\": \"A\",\"name\": \"www\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:1105::\",\"type\": \"AAAA\",\"name\": \"www\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.145.105\",\"type\": \"A\",\"name\": \"cloud\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:1105::\",\"type\": \"AAAA\",\"name\": \"cloud\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.145.105\",\"type\": \"A\",\"name\": \"@\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:1105::\",\"type\": \"AAAA\",\"name\": \"@\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.145.97\",\"type\": \"A\",\"name\": \"smtpin\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:50f0::1097\",\"type\": \"AAAA\",\"name\": \"smtpin\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20b:43:6653::506\",\"type\": \"AAAA\",\"name\": \"shades06\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"85.214.0.236\",\"type\": \"A\",\"name\": \"shades06\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"10 smtpin\",\"type\": \"MX\",\"name\": \"@\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.146.21\",\"type\": \"A\",\"name\": \"docks11\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:930:6653::d11\",\"type\": \"AAAA\",\"name\": \"docks11\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"}]}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/records/bulk\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/bulk');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'records' => [\n    [\n      'value' => '81.169.145.141',\n      'type' => 'A',\n      'name' => 'autoconfig',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:5800::1141',\n      'type' => 'AAAA',\n      'name' => 'autoconfig',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.145.105',\n      'type' => 'A',\n      'name' => 'www',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:1105::',\n      'type' => 'AAAA',\n      'name' => 'www',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.145.105',\n      'type' => 'A',\n      'name' => 'cloud',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:1105::',\n      'type' => 'AAAA',\n      'name' => 'cloud',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.145.105',\n      'type' => 'A',\n      'name' => '@',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:1105::',\n      'type' => 'AAAA',\n      'name' => '@',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.145.97',\n      'type' => 'A',\n      'name' => 'smtpin',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:50f0::1097',\n      'type' => 'AAAA',\n      'name' => 'smtpin',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20b:43:6653::506',\n      'type' => 'AAAA',\n      'name' => 'shades06',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '85.214.0.236',\n      'type' => 'A',\n      'name' => 'shades06',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '10 smtpin',\n      'type' => 'MX',\n      'name' => '@',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.146.21',\n      'type' => 'A',\n      'name' => 'docks11',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:930:6653::d11',\n      'type' => 'AAAA',\n      'name' => 'docks11',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ]\n  ]\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Bulk Create Records\n    # POST https://dns.hetzner.com/api/v1/records/bulk\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/records/bulk\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"records\": [\n                    {\n                        \"value\": \"81.169.145.141\",\n                        \"type\": \"A\",\n                        \"name\": \"autoconfig\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:5800::1141\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"autoconfig\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.145.105\",\n                        \"type\": \"A\",\n                        \"name\": \"www\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:1105::\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"www\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.145.105\",\n                        \"type\": \"A\",\n                        \"name\": \"cloud\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:1105::\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"cloud\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.145.105\",\n                        \"type\": \"A\",\n                        \"name\": \"@\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:1105::\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"@\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.145.97\",\n                        \"type\": \"A\",\n                        \"name\": \"smtpin\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:50f0::1097\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"smtpin\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20b:43:6653::506\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"shades06\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"85.214.0.236\",\n                        \"type\": \"A\",\n                        \"name\": \"shades06\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"10 smtpin\",\n                        \"type\": \"MX\",\n                        \"name\": \"@\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.146.21\",\n                        \"type\": \"A\",\n                        \"name\": \"docks11\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:930:6653::d11\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"docks11\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    }\n                ]\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "body"
         },
         "put" : {
            "description" : "Update several records at once.",
            "operationId" : "BulkUpdateRecords",
            "parameters" : [],
            "requestBody" : {
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "properties" : {
                           "records" : {
                              "items" : {
                                 "$ref" : "#/components/schemas/RecordBulk"
                              },
                              "type" : "array"
                           }
                        },
                        "type" : "object"
                     }
                  }
               },
               "required" : false
            },
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "failed_records" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/BaseRecord"
                                 },
                                 "type" : "array"
                              },
                              "records" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/RecordResponse"
                                 },
                                 "type" : "array"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "409" : {
                  "description" : "Conflict"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Bulk Update Records",
            "tags" : [
               "Records"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Bulk Update Records\n# Update several records at once.\ncurl -X \"PUT\" \"https://dns.hetzner.com/api/v1/records/bulk\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"records\": [\n    {\n      \"id\": \"mnsQmZmXXmWh5MpFeT67ZZ\",\n      \"value\": \"2a01:4f8:d0a:11f5::2\",\n      \"type\": \"AAAA\",\n      \"name\": \"www\",\n      \"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"\n    },\n    {\n      \"id\": \"uuK5PKsmfvi7853g5wXfRa\",\n      \"value\": \"2a01:4f8:d0a:11f5::2\",\n      \"ttl\": 60,\n      \"type\": \"AAAA\",\n      \"name\": \"mail\",\n      \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n    },\n    {\n      \"id\": \"L5RawAt6pJrdhFacynLrVg\",\n      \"value\": \"2a01:4f8:d0a:11f5::2\",\n      \"ttl\": 60,\n      \"type\": \"AAAA\",\n      \"name\": \"cloud\",\n      \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n    },\n    {\n      \"id\": \"HD3FZLUoxZQ2GpDCxPGEjY\",\n      \"value\": \"2a01:4f8:d0a:11f5::2\",\n      \"ttl\": 60,\n      \"type\": \"AAAA\",\n      \"name\": \"@\",\n      \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n    }\n  ]\n}'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendBulkUpdateRecords() {\n\t// Bulk Update Records (PUT https://dns.hetzner.com/api/v1/records/bulk)\n\n\tjson := []byte(`{\"records\": [{\"id\": \"mnsQmZmXXmWh5MpFeT67ZZ\",\"value\": \"2a01:4f8:d0a:11f5::2\",\"type\": \"AAAA\",\"name\": \"www\",\"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"},{\"id\": \"uuK5PKsmfvi7853g5wXfRa\",\"value\": \"2a01:4f8:d0a:11f5::2\",\"ttl\": 60,\"type\": \"AAAA\",\"name\": \"mail\",\"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"},{\"id\": \"L5RawAt6pJrdhFacynLrVg\",\"value\": \"2a01:4f8:d0a:11f5::2\",\"ttl\": 60,\"type\": \"AAAA\",\"name\": \"cloud\",\"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"},{\"id\": \"HD3FZLUoxZQ2GpDCxPGEjY\",\"value\": \"2a01:4f8:d0a:11f5::2\",\"ttl\": 60,\"type\": \"AAAA\",\"name\": \"@\",\"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"}]}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"PUT\", \"https://dns.hetzner.com/api/v1/records/bulk\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/bulk');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'records' => [\n    [\n      'id' => 'mnsQmZmXXmWh5MpFeT67ZZ',\n      'value' => '2a01:4f8:d0a:11f5::2',\n      'type' => 'AAAA',\n      'name' => 'www',\n      'zone_id' => 'oH7shFebR6nLPgTnmvNjM8'\n    ],\n    [\n      'id' => 'uuK5PKsmfvi7853g5wXfRa',\n      'value' => '2a01:4f8:d0a:11f5::2',\n      'ttl' => 60,\n      'type' => 'AAAA',\n      'name' => 'mail',\n      'zone_id' => '6hYQBACMFjqWg6VKPfnvgD'\n    ],\n    [\n      'id' => 'L5RawAt6pJrdhFacynLrVg',\n      'value' => '2a01:4f8:d0a:11f5::2',\n      'ttl' => 60,\n      'type' => 'AAAA',\n      'name' => 'cloud',\n      'zone_id' => '6hYQBACMFjqWg6VKPfnvgD'\n    ],\n    [\n      'id' => 'HD3FZLUoxZQ2GpDCxPGEjY',\n      'value' => '2a01:4f8:d0a:11f5::2',\n      'ttl' => 60,\n      'type' => 'AAAA',\n      'name' => '@',\n      'zone_id' => '6hYQBACMFjqWg6VKPfnvgD'\n    ]\n  ]\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Bulk Update Records\n    # PUT https://dns.hetzner.com/api/v1/records/bulk\n\n    try:\n        response = requests.put(\n            url=\"https://dns.hetzner.com/api/v1/records/bulk\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"records\": [\n                    {\n                        \"id\": \"mnsQmZmXXmWh5MpFeT67ZZ\",\n                        \"value\": \"2a01:4f8:d0a:11f5::2\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"www\",\n                        \"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"\n                    },\n                    {\n                        \"id\": \"uuK5PKsmfvi7853g5wXfRa\",\n                        \"value\": \"2a01:4f8:d0a:11f5::2\",\n                        \"ttl\": 60,\n                        \"type\": \"AAAA\",\n                        \"name\": \"mail\",\n                        \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n                    },\n                    {\n                        \"id\": \"L5RawAt6pJrdhFacynLrVg\",\n                        \"value\": \"2a01:4f8:d0a:11f5::2\",\n                        \"ttl\": 60,\n                        \"type\": \"AAAA\",\n                        \"name\": \"cloud\",\n                        \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n                    },\n                    {\n                        \"id\": \"HD3FZLUoxZQ2GpDCxPGEjY\",\n                        \"value\": \"2a01:4f8:d0a:11f5::2\",\n                        \"ttl\": 60,\n                        \"type\": \"AAAA\",\n                        \"name\": \"@\",\n                        \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n                    }\n                ]\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "body"
         }
      },
      "/records/{RecordID}" : {
         "delete" : {
            "description" : "Deletes a record.",
            "operationId" : "DeleteRecord",
            "parameters" : [
               {
                  "description" : "ID of record to delete",
                  "explode" : false,
                  "in" : "path",
                  "name" : "RecordID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "responses" : {
               "200" : {
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Delete Record",
            "tags" : [
               "Records"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Delete Record\n# Deletes a record.\ncurl -X \"DELETE\" \"https://dns.hetzner.com/api/v1/records/{RecordID}\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendDeleteRecord() {\n\t// Delete Record (DELETE https://dns.hetzner.com/api/v1/records/{RecordID})\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"DELETE\", \"https://dns.hetzner.com/api/v1/records/{RecordID}\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/{RecordID}');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Delete Record\n    # DELETE https://dns.hetzner.com/api/v1/records/{RecordID}\n\n    try:\n        response = requests.delete(\n            url=\"https://dns.hetzner.com/api/v1/records/{RecordID}\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n"
               }
            ]
         },
         "get" : {
            "description" : "Returns information about a single record.",
            "operationId" : "GetRecord",
            "parameters" : [
               {
                  "description" : "ID of record to get",
                  "explode" : false,
                  "in" : "path",
                  "name" : "RecordID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "record" : {
                                 "$ref" : "#/components/schemas/RecordResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Get Record",
            "tags" : [
               "Records"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Get Record\n# Returns information about a single record.\ncurl \"https://dns.hetzner.com/api/v1/records/{RecordID}\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendGetRecord() {\n\t// Get Record (GET https://dns.hetzner.com/api/v1/records/{RecordID})\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/records/{RecordID}\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/{RecordID}');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Get Record\n    # GET https://dns.hetzner.com/api/v1/records/{RecordID}\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/records/{RecordID}\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ]
         },
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "put" : {
            "description" : "Updates a record.",
            "operationId" : "UpdateRecord",
            "parameters" : [
               {
                  "description" : "ID of record to be updated",
                  "explode" : false,
                  "in" : "path",
                  "name" : "RecordID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "requestBody" : {
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "$ref" : "#/components/schemas/Record"
                     }
                  }
               },
               "required" : false
            },
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "record" : {
                                 "$ref" : "#/components/schemas/RecordResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "409" : {
                  "description" : "Conflict"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Update Record",
            "tags" : [
               "Records"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Update Record\n# Updates a record.\ncurl -X \"PUT\" \"https://dns.hetzner.com/api/v1/records/{RecordID}\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"value\": \"1.1.1.2\",\n  \"ttl\": 0,\n  \"type\": \"A\",\n  \"name\": \"www\",\n  \"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"\n}'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendUpdateRecord() {\n\t// Update Record (PUT https://dns.hetzner.com/api/v1/records/{RecordID})\n\n\tjson := []byte(`{\"value\": \"1.1.1.2\",\"ttl\": 0,\"type\": \"A\",\"name\": \"www\",\"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"PUT\", \"https://dns.hetzner.com/api/v1/records/{RecordID}\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/{RecordID}');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'value' => '1.1.1.2',\n  'ttl' => 0,\n  'type' => 'A',\n  'name' => 'www',\n  'zone_id' => 'oH7shFebR6nLPgTnmvNjM8'\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Update Record\n    # PUT https://dns.hetzner.com/api/v1/records/{RecordID}\n\n    try:\n        response = requests.put(\n            url=\"https://dns.hetzner.com/api/v1/records/{RecordID}\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"value\": \"1.1.1.2\",\n                \"ttl\": 0,\n                \"type\": \"A\",\n                \"name\": \"www\",\n                \"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "body"
         }
      },
      "/zones" : {
         "get" : {
            "description" : "Returns paginated zones associated with the user. Limited to 100 zones per request.",
            "operationId" : "GetZones",
            "parameters" : [
               {
                  "description" : "Full name of a zone. Will return an array with one or no results",
                  "explode" : true,
                  "in" : "query",
                  "name" : "name",
                  "required" : false,
                  "schema" : {
                     "example" : "example.com",
                     "type" : "string"
                  },
                  "style" : "form"
               },
               {
                  "description" : "Partial name of a zone. Will return a maximum of 100 zones that contain the searched string",
                  "explode" : true,
                  "in" : "query",
                  "name" : "search_name",
                  "required" : false,
                  "schema" : {
                     "example" : "example",
                     "type" : "string"
                  },
                  "style" : "form"
               },
               {
                  "description" : "Number of zones to be shown per page. Returns 100 by default",
                  "explode" : true,
                  "in" : "query",
                  "name" : "per_page",
                  "required" : false,
                  "schema" : {
                     "default" : 100,
                     "maximum" : 100,
                     "type" : "number"
                  },
                  "style" : "form"
               },
               {
                  "description" : "A page parameter specifies the page to fetch.<br />The number of the first page is 1",
                  "explode" : true,
                  "in" : "query",
                  "name" : "page",
                  "required" : false,
                  "schema" : {
                     "default" : 1,
                     "minimum" : 1,
                     "type" : "number"
                  },
                  "style" : "form"
               }
            ],
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "meta" : {
                                 "$ref" : "#/components/schemas/Meta"
                              },
                              "zones" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/ZoneResponse"
                                 },
                                 "type" : "array"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "400" : {
                  "description" : "Pagination selectors are mutually exclusive"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Get All Zones",
            "tags" : [
               "Zones"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Get Zones\n# Returns all zones associated with the user.\ncurl \"https://dns.hetzner.com/api/v1/zones\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendGetZones() {\n\t// Get Zones (GET https://dns.hetzner.com/api/v1/zones)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/zones\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Get Zones\n    # GET https://dns.hetzner.com/api/v1/zones\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/zones\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ]
         },
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "post" : {
            "description" : "Creates a new zone.",
            "operationId" : "CreateZone",
            "parameters" : [],
            "requestBody" : {
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "$ref" : "#/components/schemas/Zone"
                     }
                  }
               },
               "required" : false
            },
            "responses" : {
               "201" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "zone" : {
                                 "$ref" : "#/components/schemas/ZoneResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Created"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Create Zone",
            "tags" : [
               "Zones"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Create Zone\n# Creates a new zone.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/zones\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"name\": \"example.com\",\n  \"ttl\": 86400\n}'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendCreateZone() {\n\t// Create Zone (POST https://dns.hetzner.com/api/v1/zones)\n\n\tjson := []byte(`{\"name\": \"example.com\",\"ttl\": 86400}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/zones\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'name' => 'example.com',\n  'ttl' => 86400\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Create Zone\n    # POST https://dns.hetzner.com/api/v1/zones\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/zones\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"name\": \"example.com\",\n                \"ttl\": 86400\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "body"
         }
      },
      "/zones/file/validate" : {
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "post" : {
            "description" : "Validate a zone file in text/plain format.",
            "operationId" : "ValidateZoneFilePlain",
            "parameters" : [],
            "requestBody" : {
               "content" : {
                  "text/plain" : {
                     "schema" : {
                        "type" : "string"
                     }
                  }
               },
               "description" : "Zone file to validate",
               "required" : true
            },
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "parsed_records" : {
                                 "type" : "number"
                              },
                              "valid_records" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/RecordResponse"
                                 },
                                 "type" : "array"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Validate Zone file plain",
            "tags" : [
               "Zones"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Validate Zone file plain\n# Validate a zone file in text/plain format.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/zones/file/validate\" \\\n     -H 'Content-Type: text/plain' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"strings\"\n)\n\nfunc sendImportZoneFilePlain() {\n\t// Import Zone file plain (POST https://dns.hetzner.com/api/v1/zones/file/validate)\n\n\tbody := strings.NewReader(`$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600`)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/zones/file/validate\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"text/plain\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/file/validate');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: text/plain',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// body string\n$body = '$ORIGIN example.com.\n$TTL 7200\n@ IN SOA shades06.rzone.de. postmaster.robot.first-ns.de. (\n    2019111200 ;serial\n    14400 ;refresh\n    1800 ;retry\n    604800 ;expire\n    86400) ;minimum\n    \n@ IN NS ns3.second-ns.de\n@ IN NS ns.second-ns.com\n@ IN NS ns1.your-server.de\n\n@                        IN A       188.40.28.2\n\nbustertest               IN A       195.201.7.252\n\nmail                     IN A       188.40.28.2\n\nwww                      IN A       188.40.28.2\n\n@                        IN AAAA    2a01:4f8:d0a:11f5::2\n\nmail                     IN AAAA    2a01:4f8:d0a:11f5::2\n\nwww                      IN AAAA    2a01:4f8:d0a:11f5::2';\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Validate Zone file plain\n    # POST https://dns.hetzner.com/api/v1/zones/file/validate\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/zones/file/validate\",\n            headers={\n                \"Content-Type\": \"text/plain\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=\"$ORIGIN example.com.\n$TTL 7200\n@ IN SOA shades06.rzone.de. postmaster.robot.first-ns.de. (\n    2019111200 ;serial\n    14400 ;refresh\n    1800 ;retry\n    604800 ;expire\n    86400) ;minimum\n    \n@ IN NS ns3.second-ns.de\n@ IN NS ns.second-ns.com\n@ IN NS ns1.your-server.de\n\n@                        IN A       188.40.28.2\n\nbustertest               IN A       195.201.7.252\n\nmail                     IN A       188.40.28.2\n\nwww                      IN A       188.40.28.2\n\n@                        IN AAAA    2a01:4f8:d0a:11f5::2\n\nmail                     IN AAAA    2a01:4f8:d0a:11f5::2\n\nwww                      IN AAAA    2a01:4f8:d0a:11f5::2\"\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "ZoneFile"
         }
      },
      "/zones/{ZoneID}" : {
         "delete" : {
            "description" : "Deletes a zone.",
            "operationId" : "DeleteZone",
            "parameters" : [
               {
                  "description" : "ID of zone to be deleted",
                  "explode" : false,
                  "in" : "path",
                  "name" : "ZoneID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "responses" : {
               "200" : {
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Delete Zone",
            "tags" : [
               "Zones"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Delete Zone\n# Deletes a zone.\ncurl -X \"DELETE\" \"https://dns.hetzner.com/api/v1/zones/{ZoneID}\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendDeleteZone() {\n\t// Delete Zone (DELETE https://dns.hetzner.com/api/v1/zones/{ZoneID})\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"DELETE\", \"https://dns.hetzner.com/api/v1/zones/{ZoneID}\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/{ZoneID}');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Delete Zone\n    # DELETE https://dns.hetzner.com/api/v1/zones/{ZoneID}\n\n    try:\n        response = requests.delete(\n            url=\"https://dns.hetzner.com/api/v1/zones/{ZoneID}\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ]
         },
         "get" : {
            "description" : "Returns an object containing all information about a zone. Zone to get is identified by 'ZoneID'.",
            "operationId" : "GetZone",
            "parameters" : [
               {
                  "description" : "ID of zone to get",
                  "explode" : false,
                  "in" : "path",
                  "name" : "ZoneID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "zone" : {
                                 "$ref" : "#/components/schemas/ZoneResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "summary" : "Get Zone",
            "tags" : [
               "Zones"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Get Zone\n# Returns an object containing all information about a zone. Zone to get is identified by 'ZoneID'.\ncurl \"https://dns.hetzner.com/api/v1/zones/{ZoneID}\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -H 'Content-Type: application/json; charset=utf-8'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendGetZone() {\n\t// Get Zone (GET https://dns.hetzner.com/api/v1/zones/{ZoneID})\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/zones/{ZoneID}\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\treq.Header.Add(\"Content-Type\", \"application/json; charset=utf-8\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/{ZoneID}');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n  'Content-Type: application/json; charset=utf-8',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Get Zone\n    # GET https://dns.hetzner.com/api/v1/zones/{ZoneID}\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/zones/{ZoneID}\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n                \"Content-Type\": \"application/json; charset=utf-8\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ]
         },
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "put" : {
            "description" : "Updates a zone.",
            "operationId" : "UpdateZone",
            "parameters" : [
               {
                  "description" : "ID of zone to update",
                  "explode" : false,
                  "in" : "path",
                  "name" : "ZoneID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "requestBody" : {
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "$ref" : "#/components/schemas/Zone"
                     }
                  }
               }
            },
            "responses" : {
               "200" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "zone" : {
                                 "$ref" : "#/components/schemas/ZoneResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "409" : {
                  "description" : "Conflict"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Update Zone",
            "tags" : [
               "Zones"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Update Zone\n# Updates a zone.\ncurl -X \"PUT\" \"https://dns.hetzner.com/api/v1/zones/{ZoneID}\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"name\": \"example.com\",\n  \"ttl\": 86400\n}'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendUpdateZone() {\n\t// Update Zone (PUT https://dns.hetzner.com/api/v1/zones/{ZoneID})\n\n\tjson := []byte(`{\"name\": \"example.com\",\"ttl\": 86400}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"PUT\", \"https://dns.hetzner.com/api/v1/zones/{ZoneID}\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/{ZoneID}');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'name' => 'example.com',\n  'ttl' => 86400\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Update Zone\n    # PUT https://dns.hetzner.com/api/v1/zones/{ZoneID}\n\n    try:\n        response = requests.put(\n            url=\"https://dns.hetzner.com/api/v1/zones/{ZoneID}\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"name\": \"example.com\",\n                \"ttl\": 86400\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "body"
         }
      },
      "/zones/{ZoneID}/export" : {
         "get" : {
            "description" : "Export a zone file.",
            "operationId" : "ExportZoneFile",
            "parameters" : [
               {
                  "description" : "ID of zone to be exported",
                  "explode" : false,
                  "in" : "path",
                  "name" : "ZoneID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "responses" : {
               "200" : {
                  "content" : {
                     "text/plain" : {
                        "schema" : {
                           "description" : "Zone file that was exported",
                           "type" : "string"
                        }
                     }
                  },
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Export Zone file",
            "tags" : [
               "Zones"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Export Zone file\n# Export a zone file.\ncurl \"https://dns.hetzner.com/api/v1/zones/{ZoneID}/export\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"net/url\"\n\t\"bytes\"\n)\n\nfunc sendExportZoneFile() {\n\t// Export Zone file (GET https://dns.hetzner.com/api/v1/zones/{ZoneID}/export)\n\n\tparams := url.Values{}\n\tbody := bytes.NewBufferString(params.Encode())\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/zones/{ZoneID}/export\", body)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\treq.Header.Add(\"Content-Type\", \"application/x-www-form-urlencoded; charset=utf-8\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/{ZoneID}/export');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n  'Content-Type: application/x-www-form-urlencoded; charset=utf-8',\n]);\n\n// form body\n$body = [\n];\n$body = http_build_query($body);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Export Zone file\n    # GET https://dns.hetzner.com/api/v1/zones/{ZoneID}/export\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/zones/{ZoneID}/export\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n                \"Content-Type\": \"application/x-www-form-urlencoded; charset=utf-8\",\n            },\n            data={\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ]
         },
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ]
      },
      "/zones/{ZoneID}/import" : {
         "parameters" : [
            {
               "explode" : false,
               "in" : "header",
               "name" : "Auth-API-Token",
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "style" : "simple"
            }
         ],
         "post" : {
            "description" : "Import a zone file in text/plain format.",
            "operationId" : "ImportZoneFilePlain",
            "parameters" : [
               {
                  "description" : "ID of zone to be imported",
                  "explode" : false,
                  "in" : "path",
                  "name" : "ZoneID",
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple"
               }
            ],
            "requestBody" : {
               "content" : {
                  "text/plain" : {
                     "schema" : {
                        "type" : "string"
                     }
                  }
               },
               "description" : "Zone file to import",
               "required" : false
            },
            "responses" : {
               "201" : {
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "zone" : {
                                 "$ref" : "#/components/schemas/ZoneResponse"
                              }
                           },
                           "type" : "object"
                        }
                     }
                  },
                  "description" : "Create"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "summary" : "Import Zone file plain",
            "tags" : [
               "Zones"
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Import Zone file plain\n# Import a zone file in text/plain format.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/zones/{ZoneID}/import\" \\\n     -H 'Content-Type: text/plain' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"strings\"\n)\n\nfunc sendImportZoneFilePlain() {\n\t// Import Zone file plain (POST https://dns.hetzner.com/api/v1/zones/{ZoneID}/import)\n\n\tbody := strings.NewReader(`$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600`)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/zones/{ZoneID}/import\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"text/plain\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/{ZoneID}/import');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: text/plain',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// body string\n$body = '$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600';\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Import Zone file plain\n    # POST https://dns.hetzner.com/api/v1/zones/{ZoneID}/import\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/zones/{ZoneID}/import\",\n            headers={\n                \"Content-Type\": \"text/plain\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=\"$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600\"\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "body"
         }
      }
   },
   "servers" : [
      {
         "url" : "https://dns.hetzner.com/api/v1"
      }
   ],
   "tags" : [
      {
         "description" : "A secondary zone can be created, by adding a primary server before adding any records.",
         "name" : "Zones"
      },
      {
         "description" : "",
         "name" : "Records"
      },
      {
         "description" : "Primary servers can only be added to a zone, if no records were added to it, yet. By adding a primary server to a newly created zone, it automatically becomes a secondary zone.",
         "name" : "Primary Servers"
      }
   ]
}

