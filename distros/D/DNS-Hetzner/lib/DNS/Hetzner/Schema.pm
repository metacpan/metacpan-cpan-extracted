package DNS::Hetzner::Schema;

# ABSTRACT: OpenAPI schema for the DNS API

use v5.24;

use Mojo::Base -strict, -signatures;

use JSON::Validator;
use JSON::Validator::Formats;
use List::Util qw(uniq);
use Mojo::JSON qw(decode_json);
use Mojo::Loader qw(data_section);
use Mojo::Util qw(camelize);

our $VERSION = '0.02';

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

version 0.02

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
         "ExistingRecord" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/BaseRecord"
               }
            ],
            "type" : "object",
            "properties" : {
               "id" : {
                  "readOnly" : true,
                  "type" : "string",
                  "description" : "ID of record"
               },
               "created" : {
                  "description" : "Time record was created",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               },
               "modified" : {
                  "readOnly" : true,
                  "type" : "string",
                  "description" : "Time record was last updated",
                  "format" : "date-time"
               }
            }
         },
         "Pagination" : {
            "description" : "",
            "type" : "object",
            "properties" : {
               "last_page" : {
                  "description" : "This value represents the last page",
                  "type" : "number",
                  "minimum" : 1
               },
               "total_entries" : {
                  "type" : "number",
                  "description" : "This value represents the total number of entries"
               },
               "page" : {
                  "minimum" : 1,
                  "type" : "number",
                  "description" : "This value represents the current page"
               },
               "per_page" : {
                  "minimum" : 1,
                  "type" : "number",
                  "description" : "This value represents the number of entries that are returned per page"
               }
            }
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
         "BaseRecord" : {
            "properties" : {
               "value" : {
                  "description" : "Value of record (e.g. 127.0.0.1, 1.1.1.1)",
                  "type" : "string"
               },
               "ttl" : {
                  "type" : "integer",
                  "format" : "uint64",
                  "description" : "TTL of record"
               },
               "name" : {
                  "description" : "Name of record",
                  "type" : "string"
               },
               "zone_id" : {
                  "description" : "ID of zone this record is associated with",
                  "type" : "string"
               },
               "type" : {
                  "$ref" : "#/components/schemas/RecordTypeCreatable"
               }
            }
         },
         "BaseZone" : {
            "properties" : {
               "name" : {
                  "description" : "Name of zone",
                  "type" : "string"
               },
               "legacy_dns_host" : {
                  "type" : "string",
                  "readOnly" : true
               },
               "ns" : {
                  "type" : "array",
                  "readOnly" : true,
                  "items" : {
                     "type" : "string"
                  }
               },
               "paused" : {
                  "readOnly" : true,
                  "type" : "boolean"
               },
               "permission" : {
                  "type" : "string",
                  "readOnly" : true,
                  "description" : "Zone's permissions"
               },
               "project" : {
                  "type" : "string",
                  "readOnly" : true
               },
               "ttl" : {
                  "format" : "uint64",
                  "description" : "TTL of zone",
                  "type" : "integer"
               },
               "owner" : {
                  "readOnly" : true,
                  "type" : "string",
                  "description" : "Owner of zone"
               },
               "id" : {
                  "description" : "ID of zone",
                  "readOnly" : true,
                  "type" : "string"
               },
               "txt_verification" : {
                  "readOnly" : true,
                  "properties" : {
                     "token" : {
                        "description" : "Value of the TXT record",
                        "readOnly" : true,
                        "type" : "string"
                     },
                     "name" : {
                        "description" : "Name of the TXT record",
                        "readOnly" : true,
                        "type" : "string"
                     }
                  },
                  "type" : "object",
                  "description" : "Shape of the TXT record that has to be set to verify a zone. If name and token are empty, no TXT record needs to be set"
               },
               "registrar" : {
                  "readOnly" : true,
                  "type" : "string"
               },
               "created" : {
                  "readOnly" : true,
                  "type" : "string",
                  "description" : "Time zone was created",
                  "format" : "date-time"
               },
               "legacy_ns" : {
                  "items" : {
                     "type" : "string"
                  },
                  "readOnly" : true,
                  "type" : "array"
               },
               "status" : {
                  "type" : "string",
                  "readOnly" : true,
                  "description" : "Status of zone",
                  "enum" : [
                     "verified",
                     "failed",
                     "pending"
                  ]
               },
               "verified" : {
                  "description" : "Verification of zone",
                  "format" : "date-time",
                  "readOnly" : true,
                  "type" : "string"
               },
               "records_count" : {
                  "description" : "Amount of records associated to this zone",
                  "format" : "uint64",
                  "type" : "integer",
                  "readOnly" : true
               },
               "is_secondary_dns" : {
                  "readOnly" : true,
                  "type" : "boolean",
                  "description" : "Indicates if a zone is a secondary DNS zone"
               },
               "modified" : {
                  "readOnly" : true,
                  "type" : "string",
                  "format" : "date-time",
                  "description" : "Time zone was last updated"
               }
            },
            "type" : "object"
         },
         "ZoneResponse" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/BaseZone"
               }
            ],
            "type" : "object"
         },
         "Record" : {
            "required" : [
               "name",
               "type",
               "value",
               "zone_id"
            ],
            "type" : "object",
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/ExistingRecord"
               }
            ]
         },
         "RecordTypeCreatable" : {
            "type" : "string",
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
            "description" : "Type of the record"
         },
         "Meta" : {
            "properties" : {
               "pagination" : {
                  "$ref" : "#/components/schemas/Pagination"
               }
            },
            "type" : "object",
            "description" : ""
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
         "Zone" : {
            "allOf" : [
               {
                  "$ref" : "#/components/schemas/BaseZone"
               }
            ],
            "type" : "object",
            "required" : [
               "name"
            ]
         }
      },
      "securitySchemes" : {
         "Auth-API-Token" : {
            "in" : "header",
            "type" : "apiKey",
            "description" : "You can create an API token in the DNS console.",
            "name" : "Auth-API-Token"
         }
      }
   },
   "openapi" : "3.0.1",
   "servers" : [
      {
         "url" : "https://dns.hetzner.com/api/v1"
      }
   ],
   "info" : {
      "contact" : {
         "name" : "Hetzner Online GmbH",
         "email" : "support@hetzner.com"
      },
      "title" : "Hetzner DNS Public API",
      "version" : "1.0",
      "x-logo" : {
         "altText" : "Hetzner",
         "url" : "https://www.hetzner.com/themes/hetzner/images/logo/hetzner-logo.svg"
      },
      "description" : "This is the public documentation Hetzner's DNS API."
   },
   "paths" : {
      "/records/bulk" : {
         "post" : {
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
            "tags" : [
               "Records"
            ],
            "parameters" : [],
            "summary" : "Bulk Create Records",
            "operationId" : "BulkCreateRecords",
            "responses" : {
               "200" : {
                  "description" : "Successful response",
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "properties" : {
                              "valid_records" : {
                                 "type" : "array",
                                 "items" : {
                                    "$ref" : "#/components/schemas/BaseRecord"
                                 }
                              },
                              "invalid_records" : {
                                 "type" : "array",
                                 "items" : {
                                    "$ref" : "#/components/schemas/BaseRecord"
                                 }
                              },
                              "records" : {
                                 "type" : "array",
                                 "items" : {
                                    "$ref" : "#/components/schemas/RecordResponse"
                                 }
                              }
                           },
                           "type" : "object"
                        }
                     }
                  }
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "x-codegen-request-body-name" : "body",
            "x-code-samples" : [
               {
                  "source" : "## Bulk Create Records\n# Create several records at once.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/records/bulk\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"records\": [\n    {\n      \"value\": \"81.169.145.141\",\n      \"type\": \"A\",\n      \"name\": \"autoconfig\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:5800::1141\",\n      \"type\": \"AAAA\",\n      \"name\": \"autoconfig\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.145.105\",\n      \"type\": \"A\",\n      \"name\": \"www\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:1105::\",\n      \"type\": \"AAAA\",\n      \"name\": \"www\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.145.105\",\n      \"type\": \"A\",\n      \"name\": \"cloud\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:1105::\",\n      \"type\": \"AAAA\",\n      \"name\": \"cloud\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.145.105\",\n      \"type\": \"A\",\n      \"name\": \"@\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:1105::\",\n      \"type\": \"AAAA\",\n      \"name\": \"@\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.145.97\",\n      \"type\": \"A\",\n      \"name\": \"smtpin\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:202:50f0::1097\",\n      \"type\": \"AAAA\",\n      \"name\": \"smtpin\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20b:43:6653::506\",\n      \"type\": \"AAAA\",\n      \"name\": \"shades06\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"85.214.0.236\",\n      \"type\": \"A\",\n      \"name\": \"shades06\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"10 smtpin\",\n      \"type\": \"MX\",\n      \"name\": \"@\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"81.169.146.21\",\n      \"type\": \"A\",\n      \"name\": \"docks11\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    },\n    {\n      \"value\": \"2a01:238:20a:930:6653::d11\",\n      \"type\": \"AAAA\",\n      \"name\": \"docks11\",\n      \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n    }\n  ]\n}'\n",
                  "lang" : "cURL"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendBulkCreateRecords() {\n\t// Bulk Create Records (POST https://dns.hetzner.com/api/v1/records/bulk)\n\n\tjson := []byte(`{\"records\": [{\"value\": \"81.169.145.141\",\"type\": \"A\",\"name\": \"autoconfig\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:5800::1141\",\"type\": \"AAAA\",\"name\": \"autoconfig\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.145.105\",\"type\": \"A\",\"name\": \"www\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:1105::\",\"type\": \"AAAA\",\"name\": \"www\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.145.105\",\"type\": \"A\",\"name\": \"cloud\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:1105::\",\"type\": \"AAAA\",\"name\": \"cloud\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.145.105\",\"type\": \"A\",\"name\": \"@\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:1105::\",\"type\": \"AAAA\",\"name\": \"@\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.145.97\",\"type\": \"A\",\"name\": \"smtpin\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:202:50f0::1097\",\"type\": \"AAAA\",\"name\": \"smtpin\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20b:43:6653::506\",\"type\": \"AAAA\",\"name\": \"shades06\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"85.214.0.236\",\"type\": \"A\",\"name\": \"shades06\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"10 smtpin\",\"type\": \"MX\",\"name\": \"@\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"81.169.146.21\",\"type\": \"A\",\"name\": \"docks11\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"},{\"value\": \"2a01:238:20a:930:6653::d11\",\"type\": \"AAAA\",\"name\": \"docks11\",\"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"}]}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/records/bulk\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/bulk');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'records' => [\n    [\n      'value' => '81.169.145.141',\n      'type' => 'A',\n      'name' => 'autoconfig',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:5800::1141',\n      'type' => 'AAAA',\n      'name' => 'autoconfig',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.145.105',\n      'type' => 'A',\n      'name' => 'www',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:1105::',\n      'type' => 'AAAA',\n      'name' => 'www',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.145.105',\n      'type' => 'A',\n      'name' => 'cloud',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:1105::',\n      'type' => 'AAAA',\n      'name' => 'cloud',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.145.105',\n      'type' => 'A',\n      'name' => '@',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:1105::',\n      'type' => 'AAAA',\n      'name' => '@',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.145.97',\n      'type' => 'A',\n      'name' => 'smtpin',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:202:50f0::1097',\n      'type' => 'AAAA',\n      'name' => 'smtpin',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20b:43:6653::506',\n      'type' => 'AAAA',\n      'name' => 'shades06',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '85.214.0.236',\n      'type' => 'A',\n      'name' => 'shades06',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '10 smtpin',\n      'type' => 'MX',\n      'name' => '@',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '81.169.146.21',\n      'type' => 'A',\n      'name' => 'docks11',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ],\n    [\n      'value' => '2a01:238:20a:930:6653::d11',\n      'type' => 'AAAA',\n      'name' => 'docks11',\n      'zone_id' => 'LXmSv4RsTcmYtugtyVWExG'\n    ]\n  ]\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Bulk Create Records\n    # POST https://dns.hetzner.com/api/v1/records/bulk\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/records/bulk\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"records\": [\n                    {\n                        \"value\": \"81.169.145.141\",\n                        \"type\": \"A\",\n                        \"name\": \"autoconfig\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:5800::1141\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"autoconfig\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.145.105\",\n                        \"type\": \"A\",\n                        \"name\": \"www\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:1105::\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"www\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.145.105\",\n                        \"type\": \"A\",\n                        \"name\": \"cloud\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:1105::\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"cloud\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.145.105\",\n                        \"type\": \"A\",\n                        \"name\": \"@\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:1105::\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"@\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.145.97\",\n                        \"type\": \"A\",\n                        \"name\": \"smtpin\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:202:50f0::1097\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"smtpin\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20b:43:6653::506\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"shades06\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"85.214.0.236\",\n                        \"type\": \"A\",\n                        \"name\": \"shades06\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"10 smtpin\",\n                        \"type\": \"MX\",\n                        \"name\": \"@\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"81.169.146.21\",\n                        \"type\": \"A\",\n                        \"name\": \"docks11\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    },\n                    {\n                        \"value\": \"2a01:238:20a:930:6653::d11\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"docks11\",\n                        \"zone_id\": \"LXmSv4RsTcmYtugtyVWExG\"\n                    }\n                ]\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "description" : "Create several records at once."
         },
         "put" : {
            "x-code-samples" : [
               {
                  "source" : "## Bulk Update Records\n# Update several records at once.\ncurl -X \"PUT\" \"https://dns.hetzner.com/api/v1/records/bulk\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"records\": [\n    {\n      \"id\": \"mnsQmZmXXmWh5MpFeT67ZZ\",\n      \"value\": \"2a01:4f8:d0a:11f5::2\",\n      \"type\": \"AAAA\",\n      \"name\": \"www\",\n      \"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"\n    },\n    {\n      \"id\": \"uuK5PKsmfvi7853g5wXfRa\",\n      \"value\": \"2a01:4f8:d0a:11f5::2\",\n      \"ttl\": 60,\n      \"type\": \"AAAA\",\n      \"name\": \"mail\",\n      \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n    },\n    {\n      \"id\": \"L5RawAt6pJrdhFacynLrVg\",\n      \"value\": \"2a01:4f8:d0a:11f5::2\",\n      \"ttl\": 60,\n      \"type\": \"AAAA\",\n      \"name\": \"cloud\",\n      \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n    },\n    {\n      \"id\": \"HD3FZLUoxZQ2GpDCxPGEjY\",\n      \"value\": \"2a01:4f8:d0a:11f5::2\",\n      \"ttl\": 60,\n      \"type\": \"AAAA\",\n      \"name\": \"@\",\n      \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n    }\n  ]\n}'\n",
                  "lang" : "cURL"
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
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Bulk Update Records\n    # PUT https://dns.hetzner.com/api/v1/records/bulk\n\n    try:\n        response = requests.put(\n            url=\"https://dns.hetzner.com/api/v1/records/bulk\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"records\": [\n                    {\n                        \"id\": \"mnsQmZmXXmWh5MpFeT67ZZ\",\n                        \"value\": \"2a01:4f8:d0a:11f5::2\",\n                        \"type\": \"AAAA\",\n                        \"name\": \"www\",\n                        \"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"\n                    },\n                    {\n                        \"id\": \"uuK5PKsmfvi7853g5wXfRa\",\n                        \"value\": \"2a01:4f8:d0a:11f5::2\",\n                        \"ttl\": 60,\n                        \"type\": \"AAAA\",\n                        \"name\": \"mail\",\n                        \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n                    },\n                    {\n                        \"id\": \"L5RawAt6pJrdhFacynLrVg\",\n                        \"value\": \"2a01:4f8:d0a:11f5::2\",\n                        \"ttl\": 60,\n                        \"type\": \"AAAA\",\n                        \"name\": \"cloud\",\n                        \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n                    },\n                    {\n                        \"id\": \"HD3FZLUoxZQ2GpDCxPGEjY\",\n                        \"value\": \"2a01:4f8:d0a:11f5::2\",\n                        \"ttl\": 60,\n                        \"type\": \"AAAA\",\n                        \"name\": \"@\",\n                        \"zone_id\": \"6hYQBACMFjqWg6VKPfnvgD\"\n                    }\n                ]\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n",
                  "lang" : "Python"
               }
            ],
            "description" : "Update several records at once.",
            "summary" : "Bulk Update Records",
            "operationId" : "BulkUpdateRecords",
            "x-codegen-request-body-name" : "body",
            "responses" : {
               "422" : {
                  "description" : "Unprocessable entity"
               },
               "409" : {
                  "description" : "Conflict"
               },
               "404" : {
                  "description" : "Not found"
               },
               "200" : {
                  "description" : "Successful response",
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "type" : "object",
                           "properties" : {
                              "failed_records" : {
                                 "items" : {
                                    "$ref" : "#/components/schemas/BaseRecord"
                                 },
                                 "type" : "array"
                              },
                              "records" : {
                                 "type" : "array",
                                 "items" : {
                                    "$ref" : "#/components/schemas/RecordResponse"
                                 }
                              }
                           }
                        }
                     }
                  }
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            },
            "parameters" : [],
            "requestBody" : {
               "required" : false,
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
               }
            },
            "tags" : [
               "Records"
            ]
         },
         "parameters" : [
            {
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "in" : "header",
               "style" : "simple",
               "name" : "Auth-API-Token",
               "explode" : false
            }
         ]
      },
      "/records/{RecordID}" : {
         "delete" : {
            "summary" : "Delete Record",
            "operationId" : "DeleteRecord",
            "tags" : [
               "Records"
            ],
            "responses" : {
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "404" : {
                  "description" : "Not found"
               },
               "200" : {
                  "description" : "Successful response"
               }
            },
            "parameters" : [
               {
                  "description" : "ID of record to delete",
                  "explode" : false,
                  "name" : "RecordID",
                  "style" : "simple",
                  "in" : "path",
                  "schema" : {
                     "type" : "string"
                  },
                  "required" : true
               }
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Delete Record\n# Deletes a record.\ncurl -X \"DELETE\" \"https://dns.hetzner.com/api/v1/records/1\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'\n"
               },
               {
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendDeleteRecord() {\n\t// Delete Record (DELETE https://dns.hetzner.com/api/v1/records/1)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"DELETE\", \"https://dns.hetzner.com/api/v1/records/1\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n",
                  "lang" : "Go"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/1');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Delete Record\n    # DELETE https://dns.hetzner.com/api/v1/records/1\n\n    try:\n        response = requests.delete(\n            url=\"https://dns.hetzner.com/api/v1/records/1\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n",
                  "lang" : "Python"
               }
            ],
            "description" : "Deletes a record."
         },
         "get" : {
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Get Record\n# Returns information about a single record.\ncurl \"https://dns.hetzner.com/api/v1/records/1\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'\n"
               },
               {
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendGetRecord() {\n\t// Get Record (GET https://dns.hetzner.com/api/v1/records/1)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/records/1\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n",
                  "lang" : "Go"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/1');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Get Record\n    # GET https://dns.hetzner.com/api/v1/records/1\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/records/1\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n",
                  "lang" : "Python"
               }
            ],
            "parameters" : [
               {
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "in" : "path",
                  "style" : "simple",
                  "name" : "RecordID",
                  "explode" : false,
                  "description" : "ID of record to get"
               }
            ],
            "description" : "Returns information about a single record.",
            "operationId" : "GetRecord",
            "tags" : [
               "Records"
            ],
            "summary" : "Get Record",
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
               "404" : {
                  "description" : "Not found"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "401" : {
                  "description" : "Unauthorized"
               }
            }
         },
         "put" : {
            "parameters" : [
               {
                  "required" : true,
                  "in" : "path",
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple",
                  "explode" : false,
                  "description" : "ID of record to be updated",
                  "name" : "RecordID"
               }
            ],
            "tags" : [
               "Records"
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
            "description" : "Updates a record.",
            "x-code-samples" : [
               {
                  "source" : "## Update Record\n# Updates a record.\ncurl -X \"PUT\" \"https://dns.hetzner.com/api/v1/records/1\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"value\": \"1.1.1.2\",\n  \"ttl\": 0,\n  \"type\": \"A\",\n  \"name\": \"www\",\n  \"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"\n}'\n",
                  "lang" : "cURL"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendUpdateRecord() {\n\t// Update Record (PUT https://dns.hetzner.com/api/v1/records/1)\n\n\tjson := []byte(`{\"value\": \"1.1.1.2\",\"ttl\": 0,\"type\": \"A\",\"name\": \"www\",\"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"PUT\", \"https://dns.hetzner.com/api/v1/records/1\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records/1');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'value' => '1.1.1.2',\n  'ttl' => 0,\n  'type' => 'A',\n  'name' => 'www',\n  'zone_id' => 'oH7shFebR6nLPgTnmvNjM8'\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Update Record\n    # PUT https://dns.hetzner.com/api/v1/records/1\n\n    try:\n        response = requests.put(\n            url=\"https://dns.hetzner.com/api/v1/records/1\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"value\": \"1.1.1.2\",\n                \"ttl\": 0,\n                \"type\": \"A\",\n                \"name\": \"www\",\n                \"zone_id\": \"oH7shFebR6nLPgTnmvNjM8\"\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "x-codegen-request-body-name" : "body",
            "responses" : {
               "422" : {
                  "description" : "Unprocessable entity"
               },
               "409" : {
                  "description" : "Conflict"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "200" : {
                  "description" : "Successful response",
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "type" : "object",
                           "properties" : {
                              "record" : {
                                 "$ref" : "#/components/schemas/RecordResponse"
                              }
                           }
                        }
                     }
                  }
               },
               "404" : {
                  "description" : "Not found"
               }
            },
            "summary" : "Update Record",
            "operationId" : "UpdateRecord"
         },
         "parameters" : [
            {
               "style" : "simple",
               "name" : "Auth-API-Token",
               "explode" : false,
               "required" : true,
               "schema" : {
                  "type" : "string"
               },
               "in" : "header"
            }
         ]
      },
      "/zones/{ZoneID}" : {
         "parameters" : [
            {
               "schema" : {
                  "type" : "string"
               },
               "in" : "header",
               "required" : true,
               "name" : "Auth-API-Token",
               "explode" : false,
               "style" : "simple"
            }
         ],
         "get" : {
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Get Zone\n# Returns an object containing all information about a zone. Zone to get is identified by 'ZoneID'.\ncurl \"https://dns.hetzner.com/api/v1/zones/1\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -H 'Content-Type: application/json; charset=utf-8'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendGetZone() {\n\t// Get Zone (GET https://dns.hetzner.com/api/v1/zones/1)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/zones/\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\treq.Header.Add(\"Content-Type\", \"application/json; charset=utf-8\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/1');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n  'Content-Type: application/json; charset=utf-8',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Get Zone\n    # GET https://dns.hetzner.com/api/v1/zones/1\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/zones/\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n                \"Content-Type\": \"application/json; charset=utf-8\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "parameters" : [
               {
                  "description" : "ID of zone to get",
                  "explode" : false,
                  "name" : "ZoneID",
                  "style" : "simple",
                  "in" : "path",
                  "schema" : {
                     "type" : "string"
                  },
                  "required" : true
               }
            ],
            "description" : "Returns an object containing all information about a zone. Zone to get is identified by 'ZoneID'.",
            "tags" : [
               "Zones"
            ],
            "operationId" : "GetZone",
            "summary" : "Get Zone",
            "responses" : {
               "200" : {
                  "description" : "Successful response",
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "type" : "object",
                           "properties" : {
                              "zone" : {
                                 "$ref" : "#/components/schemas/ZoneResponse"
                              }
                           }
                        }
                     }
                  }
               },
               "404" : {
                  "description" : "Not found"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "401" : {
                  "description" : "Unauthorized"
               }
            }
         },
         "delete" : {
            "parameters" : [
               {
                  "schema" : {
                     "type" : "string"
                  },
                  "in" : "path",
                  "required" : true,
                  "name" : "ZoneID",
                  "explode" : false,
                  "description" : "ID of zone to be deleted",
                  "style" : "simple"
               }
            ],
            "x-code-samples" : [
               {
                  "source" : "## Delete Zone\n# Deletes a zone.\ncurl -X \"DELETE\" \"https://dns.hetzner.com/api/v1/zones/\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'\n",
                  "lang" : "cURL"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendDeleteZone() {\n\t// Delete Zone (DELETE https://dns.hetzner.com/api/v1/zones/)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"DELETE\", \"https://dns.hetzner.com/api/v1/zones/\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'DELETE');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Delete Zone\n    # DELETE https://dns.hetzner.com/api/v1/zones/\n\n    try:\n        response = requests.delete(\n            url=\"https://dns.hetzner.com/api/v1/zones/\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n",
                  "lang" : "Python"
               }
            ],
            "description" : "Deletes a zone.",
            "summary" : "Delete Zone",
            "operationId" : "DeleteZone",
            "tags" : [
               "Zones"
            ],
            "responses" : {
               "404" : {
                  "description" : "Not found"
               },
               "200" : {
                  "description" : "Successful response"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "403" : {
                  "description" : "Forbidden"
               }
            }
         },
         "put" : {
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Update Zone\n# Updates a zone.\ncurl -X \"PUT\" \"https://dns.hetzner.com/api/v1/zones/\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"name\": \"example.com\",\n  \"ttl\": 86400\n}'\n"
               },
               {
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendUpdateZone() {\n\t// Update Zone (PUT https://dns.hetzner.com/api/v1/zones/)\n\n\tjson := []byte(`{\"name\": \"example.com\",\"ttl\": 86400}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"PUT\", \"https://dns.hetzner.com/api/v1/zones/\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n",
                  "lang" : "Go"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'PUT');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'name' => 'example.com',\n  'ttl' => 86400\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Update Zone\n    # PUT https://dns.hetzner.com/api/v1/zones/\n\n    try:\n        response = requests.put(\n            url=\"https://dns.hetzner.com/api/v1/zones/\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"name\": \"example.com\",\n                \"ttl\": 86400\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n",
                  "lang" : "Python"
               }
            ],
            "description" : "Updates a zone.",
            "operationId" : "UpdateZone",
            "summary" : "Update Zone",
            "x-codegen-request-body-name" : "body",
            "responses" : {
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "404" : {
                  "description" : "Not found"
               },
               "200" : {
                  "description" : "Successful response",
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
                  }
               },
               "409" : {
                  "description" : "Conflict"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "parameters" : [
               {
                  "required" : true,
                  "schema" : {
                     "type" : "string"
                  },
                  "in" : "path",
                  "style" : "simple",
                  "name" : "ZoneID",
                  "explode" : false,
                  "description" : "ID of zone to update"
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
            "tags" : [
               "Zones"
            ]
         }
      },
      "/zones/{ZoneID}/export" : {
         "get" : {
            "responses" : {
               "422" : {
                  "description" : "Unprocessable entity"
               },
               "404" : {
                  "description" : "Not found"
               },
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
               }
            },
            "tags" : [
               "Zones"
            ],
            "operationId" : "ExportZoneFile",
            "summary" : "Export Zone file",
            "description" : "Export a zone file.",
            "x-code-samples" : [
               {
                  "source" : "## Export Zone file\n# Export a zone file.\ncurl \"https://dns.hetzner.com/api/v1/zones/1/export\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -H 'Content-Type: application/x-www-form-urlencoded; charset=utf-8'\n",
                  "lang" : "cURL"
               },
               {
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"net/url\"\n\t\"bytes\"\n)\n\nfunc sendExportZoneFile() {\n\t// Export Zone file (GET https://dns.hetzner.com/api/v1/zones/1/export)\n\n\tparams := url.Values{}\n\tbody := bytes.NewBufferString(params.Encode())\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/zones/1/export\", body)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\treq.Header.Add(\"Content-Type\", \"application/x-www-form-urlencoded; charset=utf-8\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n",
                  "lang" : "Go"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/1/export');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n  'Content-Type: application/x-www-form-urlencoded; charset=utf-8',\n]);\n\n// form body\n$body = [\n];\n$body = http_build_query($body);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Export Zone file\n    # GET https://dns.hetzner.com/api/v1/zones/1/export\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/zones/1/export\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n                \"Content-Type\": \"application/x-www-form-urlencoded; charset=utf-8\",\n            },\n            data={\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "parameters" : [
               {
                  "required" : true,
                  "in" : "path",
                  "schema" : {
                     "type" : "string"
                  },
                  "style" : "simple",
                  "description" : "ID of zone to be exported",
                  "explode" : false,
                  "name" : "ZoneID"
               }
            ]
         },
         "parameters" : [
            {
               "in" : "header",
               "schema" : {
                  "type" : "string"
               },
               "required" : true,
               "explode" : false,
               "name" : "Auth-API-Token",
               "style" : "simple"
            }
         ]
      },
      "/zones" : {
         "post" : {
            "parameters" : [],
            "requestBody" : {
               "required" : false,
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "$ref" : "#/components/schemas/Zone"
                     }
                  }
               }
            },
            "tags" : [
               "Zones"
            ],
            "description" : "Creates a new zone.",
            "x-code-samples" : [
               {
                  "source" : "## Create Zone\n# Creates a new zone.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/zones\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"name\": \"example.com\",\n  \"ttl\": 86400\n}'\n",
                  "lang" : "cURL"
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
            "responses" : {
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "201" : {
                  "description" : "Created",
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "type" : "object",
                           "properties" : {
                              "zone" : {
                                 "$ref" : "#/components/schemas/ZoneResponse"
                              }
                           }
                        }
                     }
                  }
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "x-codegen-request-body-name" : "body",
            "operationId" : "CreateZone",
            "summary" : "Create Zone"
         },
         "get" : {
            "x-code-samples" : [
               {
                  "source" : "## Get Zones\n# Returns all zones associated with the user.\ncurl \"https://dns.hetzner.com/api/v1/zones\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'\n",
                  "lang" : "cURL"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendGetZones() {\n\t// Get Zones (GET https://dns.hetzner.com/api/v1/zones)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/zones\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Get Zones\n    # GET https://dns.hetzner.com/api/v1/zones\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/zones\",\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "parameters" : [
               {
                  "required" : false,
                  "schema" : {
                     "type" : "string"
                  },
                  "in" : "query",
                  "style" : "form",
                  "name" : "name",
                  "explode" : true,
                  "description" : "Full name of a zone. Will return an array with one or no results"
               },
               {
                  "schema" : {
                     "type" : "string"
                  },
                  "in" : "query",
                  "required" : false,
                  "name" : "search_name",
                  "explode" : true,
                  "description" : "Partial name of a zone. Will return a maximum of 100 zones that contain the searched string",
                  "style" : "form"
               },
               {
                  "required" : false,
                  "in" : "query",
                  "schema" : {
                     "maximum" : 100,
                     "type" : "number",
                     "default" : 100
                  },
                  "style" : "form",
                  "explode" : true,
                  "description" : "Number of zones to be shown per page. Returns 100 by default",
                  "name" : "per_page"
               },
               {
                  "schema" : {
                     "minimum" : 1,
                     "type" : "number",
                     "default" : 1
                  },
                  "in" : "query",
                  "required" : false,
                  "name" : "page",
                  "explode" : true,
                  "description" : "A page parameter specifies the page to fetch.<br />The number of the first page is 1",
                  "style" : "form"
               }
            ],
            "description" : "Returns paginated zones associated with the user. Limited to 100 zones per request.",
            "tags" : [
               "Zones"
            ],
            "operationId" : "GetZones",
            "summary" : "Get All Zones",
            "responses" : {
               "400" : {
                  "description" : "Pagination selectors are mutually exclusive"
               },
               "200" : {
                  "description" : "Successful response",
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
                  }
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               }
            }
         },
         "parameters" : [
            {
               "schema" : {
                  "type" : "string"
               },
               "in" : "header",
               "required" : true,
               "name" : "Auth-API-Token",
               "explode" : false,
               "style" : "simple"
            }
         ]
      },
      "/zones/file/validate" : {
         "parameters" : [
            {
               "style" : "simple",
               "explode" : false,
               "name" : "Auth-API-Token",
               "required" : true,
               "in" : "header",
               "schema" : {
                  "type" : "string"
               }
            }
         ],
         "post" : {
            "tags" : [
               "Zones"
            ],
            "requestBody" : {
               "description" : "Zone file to validate",
               "content" : {
                  "text/plain" : {
                     "schema" : {
                        "type" : "string"
                     }
                  }
               },
               "required" : true
            },
            "parameters" : [],
            "summary" : "Validate Zone file plain",
            "operationId" : "ValidateZoneFilePlain",
            "x-codegen-request-body-name" : "ZoneFile",
            "responses" : {
               "200" : {
                  "description" : "Successful response",
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "type" : "object",
                           "properties" : {
                              "parsed_records" : {
                                 "type" : "number"
                              },
                              "valid_records" : {
                                 "type" : "array",
                                 "items" : {
                                    "$ref" : "#/components/schemas/RecordResponse"
                                 }
                              }
                           }
                        }
                     }
                  }
               },
               "404" : {
                  "description" : "Not found"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "401" : {
                  "description" : "Unauthorized"
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Validate Zone file plain\n# Validate a zone file in text/plain format.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/zones/1/validate\" \\\n     -H 'Content-Type: text/plain' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"strings\"\n)\n\nfunc sendImportZoneFilePlain() {\n\t// Import Zone file plain (POST https://dns.hetzner.com/api/v1/zones/1/validate)\n\n\tbody := strings.NewReader(`$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600`)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/zones/1/validate\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"text/plain\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/file/validate');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: text/plain',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// body string\n$body = '$ORIGIN example.com.\n$TTL 7200\n@ IN SOA shades06.rzone.de. postmaster.robot.first-ns.de. (\n    2019111200 ;serial\n    14400 ;refresh\n    1800 ;retry\n    604800 ;expire\n    86400) ;minimum\n    \n@ IN NS ns3.second-ns.de\n@ IN NS ns.second-ns.com\n@ IN NS ns1.your-server.de\n\n@                        IN A       188.40.28.2\n\nbustertest               IN A       195.201.7.252\n\nmail                     IN A       188.40.28.2\n\nwww                      IN A       188.40.28.2\n\n@                        IN AAAA    2a01:4f8:d0a:11f5::2\n\nmail                     IN AAAA    2a01:4f8:d0a:11f5::2\n\nwww                      IN AAAA    2a01:4f8:d0a:11f5::2';\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Validate Zone file plain\n    # POST https://dns.hetzner.com/api/v1/zones/file/validate\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/zones/file/validate\",\n            headers={\n                \"Content-Type\": \"text/plain\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=\"$ORIGIN example.com.\n$TTL 7200\n@ IN SOA shades06.rzone.de. postmaster.robot.first-ns.de. (\n    2019111200 ;serial\n    14400 ;refresh\n    1800 ;retry\n    604800 ;expire\n    86400) ;minimum\n    \n@ IN NS ns3.second-ns.de\n@ IN NS ns.second-ns.com\n@ IN NS ns1.your-server.de\n\n@                        IN A       188.40.28.2\n\nbustertest               IN A       195.201.7.252\n\nmail                     IN A       188.40.28.2\n\nwww                      IN A       188.40.28.2\n\n@                        IN AAAA    2a01:4f8:d0a:11f5::2\n\nmail                     IN AAAA    2a01:4f8:d0a:11f5::2\n\nwww                      IN AAAA    2a01:4f8:d0a:11f5::2\"\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n",
                  "lang" : "Python"
               }
            ],
            "description" : "Validate a zone file in text/plain format."
         }
      },
      "/records" : {
         "post" : {
            "description" : "Creates a new record.",
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Create Record\n# Creates a new record.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/records\" \\\n     -H 'Content-Type: application/json' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'{\n  \"value\": \"1.1.1.1\",\n  \"ttl\": 86400,\n  \"type\": \"A\",\n  \"name\": \"www\",\n  \"zone_id\": \"1\"\n}'\n"
               },
               {
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"bytes\"\n)\n\nfunc sendCreateRecord() {\n\t// Create Record (POST https://dns.hetzner.com/api/v1/records)\n\n\tjson := []byte(`{\"value\": \"1.1.1.1\",\"ttl\": 86400,\"type\": \"A\",\"name\": \"www\",\"zone_id\": \"1\"}`)\n\tbody := bytes.NewBuffer(json)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/records\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"application/json\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n",
                  "lang" : "Go"
               },
               {
                  "lang" : "PHP (cURL)",
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: application/json',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// json body\n$json_array = [\n  'value' => '1.1.1.1',\n  'ttl' => 86400,\n  'type' => 'A',\n  'name' => 'www',\n  'zone_id' => '1'\n]; \n$body = json_encode($json_array);\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n"
               },
               {
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\nimport json\n\n\ndef send_request():\n    # Create Record\n    # POST https://dns.hetzner.com/api/v1/records\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/records\",\n            headers={\n                \"Content-Type\": \"application/json\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=json.dumps({\n                \"value\": \"1.1.1.1\",\n                \"ttl\": 86400,\n                \"type\": \"A\",\n                \"name\": \"www\",\n                \"zone_id\": \"1\"\n            })\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n",
                  "lang" : "Python"
               }
            ],
            "responses" : {
               "401" : {
                  "description" : "Unauthorized"
               },
               "403" : {
                  "description" : "Forbidden"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "200" : {
                  "description" : "Successful response",
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "type" : "object",
                           "properties" : {
                              "record" : {
                                 "$ref" : "#/components/schemas/RecordResponse"
                              }
                           }
                        }
                     }
                  }
               },
               "422" : {
                  "description" : "Unprocessable entity"
               }
            },
            "x-codegen-request-body-name" : "body",
            "summary" : "Create Record",
            "operationId" : "CreateRecord",
            "parameters" : [],
            "tags" : [
               "Records"
            ],
            "requestBody" : {
               "required" : false,
               "content" : {
                  "application/json" : {
                     "schema" : {
                        "$ref" : "#/components/schemas/Record"
                     }
                  }
               }
            }
         },
         "get" : {
            "responses" : {
               "401" : {
                  "description" : "Unauthorized"
               },
               "406" : {
                  "description" : "Not acceptable"
               },
               "200" : {
                  "description" : "Successful response",
                  "content" : {
                     "application/json" : {
                        "schema" : {
                           "type" : "object",
                           "properties" : {
                              "records" : {
                                 "type" : "array",
                                 "items" : {
                                    "$ref" : "#/components/schemas/RecordResponse"
                                 }
                              },
                              "meta" : {
                                 "$ref" : "#/components/schemas/Meta"
                              }
                           }
                        }
                     }
                  }
               },
               "400" : {
                  "description" : "Pagination selectors are mutually exclusive"
               }
            },
            "summary" : "Get All Records",
            "tags" : [
               "Records"
            ],
            "operationId" : "GetRecords",
            "description" : "Returns all records associated with user.",
            "parameters" : [
               {
                  "description" : "ID of zone",
                  "explode" : true,
                  "name" : "zone_id",
                  "style" : "form",
                  "in" : "query",
                  "schema" : {
                     "type" : "string"
                  },
                  "required" : false
               },
               {
                  "style" : "form",
                  "name" : "per_page",
                  "description" : "Number of records to be shown per page. Returns all by default",
                  "explode" : true,
                  "required" : false,
                  "schema" : {
                     "type" : "number"
                  },
                  "in" : "query"
               },
               {
                  "required" : false,
                  "schema" : {
                     "default" : 1,
                     "type" : "number",
                     "minimum" : 1
                  },
                  "in" : "query",
                  "style" : "form",
                  "name" : "page",
                  "description" : "A page parameter specifies the page to fetch.<br />The number of the first page is 1",
                  "explode" : true
               }
            ],
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Get Records\n# Returns all records associated with user.\ncurl \"https://dns.hetzner.com/api/v1/records?zone_id=1\" \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj'"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n)\n\nfunc sendGetRecords() {\n\t// Get Records (GET https://dns.hetzner.com/api/v1/records?zone_id=1)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"GET\", \"https://dns.hetzner.com/api/v1/records?zone_id=1\", nil)\n\n\t// Headers\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\tparseFormErr := req.ParseForm()\n\tif parseFormErr != nil {\n\t  fmt.Println(parseFormErr)    \n\t}\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/records?zone_id=1');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Get Records\n    # GET https://dns.hetzner.com/api/v1/records\n\n    try:\n        response = requests.get(\n            url=\"https://dns.hetzner.com/api/v1/records\",\n            params={\n                \"zone_id\": \"1\",\n            },\n            headers={\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n",
                  "lang" : "Python"
               }
            ]
         },
         "parameters" : [
            {
               "name" : "Auth-API-Token",
               "explode" : false,
               "style" : "simple",
               "schema" : {
                  "type" : "string"
               },
               "in" : "header",
               "required" : true
            }
         ]
      },
      "/zones/{ZoneID}/import" : {
         "parameters" : [
            {
               "style" : "simple",
               "explode" : false,
               "name" : "Auth-API-Token",
               "required" : true,
               "in" : "header",
               "schema" : {
                  "type" : "string"
               }
            }
         ],
         "post" : {
            "requestBody" : {
               "required" : false,
               "content" : {
                  "text/plain" : {
                     "schema" : {
                        "type" : "string"
                     }
                  }
               },
               "description" : "Zone file to import"
            },
            "tags" : [
               "Zones"
            ],
            "parameters" : [
               {
                  "style" : "simple",
                  "explode" : false,
                  "description" : "ID of zone to be imported",
                  "name" : "ZoneID",
                  "required" : true,
                  "in" : "path",
                  "schema" : {
                     "type" : "string"
                  }
               }
            ],
            "operationId" : "ImportZoneFilePlain",
            "summary" : "Import Zone file plain",
            "x-codegen-request-body-name" : "body",
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
            "x-code-samples" : [
               {
                  "lang" : "cURL",
                  "source" : "## Import Zone file plain\n# Import a zone file in text/plain format.\ncurl -X \"POST\" \"https://dns.hetzner.com/api/v1/zones/1/import\" \\\n     -H 'Content-Type: text/plain' \\\n     -H 'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj' \\\n     -d $'$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600'\n"
               },
               {
                  "lang" : "Go",
                  "source" : "package main\n\nimport (\n\t\"fmt\"\n\t\"io/ioutil\"\n\t\"net/http\"\n\t\"strings\"\n)\n\nfunc sendImportZoneFilePlain() {\n\t// Import Zone file plain (POST https://dns.hetzner.com/api/v1/zones/1/import)\n\n\tbody := strings.NewReader(`$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600`)\n\n\t// Create client\n\tclient := &http.Client{}\n\n\t// Create request\n\treq, err := http.NewRequest(\"POST\", \"https://dns.hetzner.com/api/v1/zones/1/import\", body)\n\n\t// Headers\n\treq.Header.Add(\"Content-Type\", \"text/plain\")\n\treq.Header.Add(\"Auth-API-Token\", \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\")\n\n\t// Fetch Request\n\tresp, err := client.Do(req)\n\t\n\tif err != nil {\n\t\tfmt.Println(\"Failure : \", err)\n\t}\n\n\t// Read Response Body\n\trespBody, _ := ioutil.ReadAll(resp.Body)\n\n\t// Display Results\n\tfmt.Println(\"response Status : \", resp.Status)\n\tfmt.Println(\"response Headers : \", resp.Header)\n\tfmt.Println(\"response Body : \", string(respBody))\n}\n\n\n"
               },
               {
                  "source" : "<?php\n\n// get cURL resource\n$ch = curl_init();\n\n// set url\ncurl_setopt($ch, CURLOPT_URL, 'https://dns.hetzner.com/api/v1/zones/1/import');\n\n// set method\ncurl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'POST');\n\n// return the transfer as a string\ncurl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);\n\n// set headers\ncurl_setopt($ch, CURLOPT_HTTPHEADER, [\n  'Content-Type: text/plain',\n  'Auth-API-Token: LlGoDUQ39S6akqoav5meAsv5OIpeywhj',\n]);\n\n// body string\n$body = '$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600';\n\n// set body\ncurl_setopt($ch, CURLOPT_POST, 1);\ncurl_setopt($ch, CURLOPT_POSTFIELDS, $body);\n\n// send the request and save response to $response\n$response = curl_exec($ch);\n\n// stop if fails\nif (!$response) {\n  die('Error: \"' . curl_error($ch) . '\" - Code: ' . curl_errno($ch));\n}\n\necho 'HTTP Status Code: ' . curl_getinfo($ch, CURLINFO_HTTP_CODE) . PHP_EOL;\necho 'Response Body: ' . $response . PHP_EOL;\n\n// close curl resource to free up system resources \ncurl_close($ch);\n\n\n",
                  "lang" : "PHP (cURL)"
               },
               {
                  "lang" : "Python",
                  "source" : "# Install the Python Requests library:\n# `pip install requests`\n\nimport requests\n\n\ndef send_request():\n    # Import Zone file plain\n    # POST https://dns.hetzner.com/api/v1/zones/1/import\n\n    try:\n        response = requests.post(\n            url=\"https://dns.hetzner.com/api/v1/zones/1/import\",\n            headers={\n                \"Content-Type\": \"text/plain\",\n                \"Auth-API-Token\": \"LlGoDUQ39S6akqoav5meAsv5OIpeywhj\",\n            },\n            data=\"$ORIGIN example.com.\n$TTL 86400\ntest IN A 88.99.0.114\n@ IN SOA ns1.first-ns.de. dns.hetzner.com. 2019112800 86400 7200 3600000 3600\"\n        )\n        print('Response HTTP Status Code: {status_code}'.format(\n            status_code=response.status_code))\n        print('Response HTTP Response Body: {content}'.format(\n            content=response.content))\n    except requests.exceptions.RequestException:\n        print('HTTP Request failed')\n\n\n"
               }
            ],
            "description" : "Import a zone file in text/plain format."
         }
      }
   }
}

