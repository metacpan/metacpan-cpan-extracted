# ABSTRACT: Internal module with the API specification
package Arango::Tango::API;
$Arango::Tango::API::VERSION = '0.010';
use Arango::Tango::Database;
use Arango::Tango::Collection;

use strict;
use warnings;
use HTTP::Tiny;
use JSON;
use Clone 'clone';
use MIME::Base64 3.11 'encode_base64url';
use URI::Encode qw(uri_encode);
use JSON::Schema::Fit 0.07;

my %API = (
    current_database   => { method => 'get',    uri => '_api/database/current'                  },
    delete_database    => { method => 'delete', uri => '_api/database/{name}'                   },
    create_document    => { method => 'post',   uri => '{{database}}_api/document/{collection}' },
    delete_collection  => { method => 'delete', uri => '{{database}}_api/collection/{name}'     },
    collection_load    => { method => 'put',    uri => '{{database}}_api/collection/{name}/load', params => { count => { type => 'integer' } } },
    collection_unload  => { method => 'put',    uri => '{{database}}_api/collection/{name}/unload' },
    collection_truncate  => { method => 'put',  uri => '{{database}}_api/collection/{name}/truncate' },
    collection_properties => { method => 'get', uri => '{{database}}_api/collection/{name}/properties' },
    collection_set_properties => { method => 'put', uri => '{{database}}_api/collection/{name}/properties',
                                   params => {  waitForSync => { type => 'boolean' }, journalSize => { type => 'integer' }}},
    collection_load_indexes => { method => 'put', uri => '{{database}}_api/collection/{name}/loadIndexesIntoMemory'},
    collection_recalculate_count => { method => 'put', uri => '{{database}}_api/collection/{name}/recalculateCount' },
    collection_revision => { method => 'get',   uri => '{{database}}_api/collection/{name}/revision' },
    collection_rename  => { method => 'put',    uri => '{{database}}_api/collection/{collection}/rename' , params => { name => { type => 'string' } } },
    collection_info    => { method => 'get',    uri => '{{database}}_api/collection/{name}'     },
    collection_rotate  => { method => 'put',    uri => '{{database}}_api/collection/{name}/rotate'   },
    collection_checksum => { method => 'get',   uri => '{{database}}_api/collection/{name}/checksum', params => { withRevisions => { type => 'boolean' }, withData => {type=>'boolean' }}},
    collection_count   => { method => 'get',    uri => '{{database}}_api/collection/{name}/count',    params => { withRevisions => { type => 'boolean' }, withData => {type=>'boolean' }}},
    collection_figures => { method => 'get',    uri => '{{database}}_api/collection/{name}/figures',  params => { withRevisions => { type => 'boolean' }, withData => {type=>'boolean' }}},
    list_collections   => { method => 'get',    uri => '{{database}}_api/collection', params => { excludeSystem => { type => 'boolean' } } },
    cursor_next        => { method => 'put',    uri => '{{database}}_api/cursor/{id}'           },
    cursor_delete      => { method => 'delete', uri => '{{database}}_api/cursor/{id}'           },
    get_user_databases => { method => 'get' ,   uri => '_api/user/{username}/database',  params => { full => {type => 'boolean' } } },
    cluster_endpoints  => { method => 'get',    uri => '_api/cluster/endpoints'               },
    engine             => { method => 'get',    uri => '_api/engine'                          },
    status             => { method => 'get',    uri => '_admin/status'                        },
    time               => { method => 'get',    uri => '_admin/time'                          },
    target_version     => { method => 'get',    uri => '_admin/database/target-version'       },
    statistics         => { method => 'get',    uri => '_admin/statistics'                    },
    log_level          => { method => 'get',    uri => '_admin/log/level'                     },
    server_id          => { method => 'get',    uri => '_admin/server/id'                     },
    server_role        => { method => 'get',    uri => '_admin/server/role'                   },
    server_mode        => { method => 'get',    uri => '_admin/server/mode'                   },
    server_availability => { method => 'get',  uri => '_admin/server/availability'            },
    statistics_description  => { method => 'get', uri => '_admin/statistics-description'      },
    list_users         => { method => 'get',    uri => '_api/user'                            },
    get_user           => { method => 'get',    uri => '_api/user/{username}'                 },
    accessible_databases => { method =>'get',  uri => '_api/database/user'                   },
    get_access_level   => { method => 'get',    uri => '_api/user/{username}/database/{database}' },
    clear_access_level => { method => 'delete', uri => '_api/user/{username}/database/{database}' },
    set_access_level   => { method => 'put',    uri => '_api/user/{username}/database/{database}', params => { grant => { type => 'string', enum => [qw'rw ro none'], default => 'none' }}},
    get_access_level_c => { method => 'get',   uri => '_api/user/{username}/database/{database}/{collection}' },
    clear_access_level_c => { method => 'delete', uri => '_api/user/{username}/database/{database}/{collection}' },
    set_access_level_c => { method => 'put',   uri => '_api/user/{username}/database/{database}/{collection}', params => { grant => { type => 'string', enum => [qw'rw ro none'], default => 'none' }}},
    'create_database'  => {
        method  => 'post',
        uri     => '_api/database',
        params  => {
            name => { type => 'string' },
            users => {
                items => {
                    type => 'object',
                    additionalProperties => 0,
                    properties => {
                        username => { type => 'string' },
                        passwd   => { type => 'string'},
                        active   => { type => 'boolean' },
                        extra    => { type => 'object', additionalProperties => 1 }
                    }
                },
                type => 'array'
            }
        },
        builder => sub {
            my ($self, %params) = @_;
            return Arango::Tango::Database->_new(arango => $self, 'name' => $params{name});
        },
    },
   'create_collection' => {
        method  => 'post',
        uri     => '{{database}}_api/collection',
        params  => {
            keyOptions => { type => 'object', additionalProperties => 0, params => {
                allowUserKeys => { type => 'boolean' },
                type          => { type => 'string', default => 'traditional', enum => [qw'traditional autoincrement uuid padded'] },
                increment     => { type => 'integer' },
                offset        => { type => 'integer' },
            }},
            journalSize       => { type => 'integer' },
            replicationFactor => { type => 'integer' },
            waitForSync       => { type => 'boolean' },
            doCompact         => { type => 'boolean' },
            shardingStrategy  => {
                type    => 'string',
                default => 'community-compat',
                enum    => ['community-compat', 'enterprise-compat', 'enterprise-smart-edge-compat', 'hash', 'enterprise-hash-smart-edge']},
            isVolatile        => { type => 'boolean' },
            shardKeys         => { type => 'array', items => {type => 'string'} },
            numberOfShards    => { type => 'integer' },
            isSystem          => { type => 'booean' },
            type              => { type => 'string', default => '2', enum => ['2', '3'] },
            indexBuckets      => { type => 'integer' },
            distributeShardsLike => { type => 'string' },
            name              => { type => 'string' }
        },
        builder => sub {
            my ($self, %params) = @_;
            return Arango::Tango::Collection->_new(arango => $self, database => $params{database}, 'name' => $params{name});
        },
    },
    'all_keys' => {
        method => 'put',
        uri    => '{{database}}_api/simple/all-keys',
        params => { type => { type => 'string' }, collection => { type => 'string' } },
    },
    'version' => {
        method => 'get',
        uri    => '_api/version',
        params => {  details => { type => 'boolean' } } ,
    },
    'create_cursor' => {
        method => 'post',
        uri    => '{{database}}_api/cursor',
        params => {
            query       => { type => 'string'  },
            count       => { type => 'boolean' },
            batchSize   => { type => 'integer' },
            cache       => { type => 'boolean' },
            memoryLimit => { type => 'integer' },
            ttl         => { type => 'integer' },
            bindVars => { type => 'object', additionalProperties => 1 },
            options  => { type => 'object', additionalProperties => 0, properties => {
                    failOnWarning               => { type => 'boolean' },
                    profile                     => { type => 'integer', maximum => 2, minimum => 0 }, # 0, 1, 2
                    maxTransactionSize          => { type => 'integer' },
                    stream                      => { type => 'boolean' },
                    skipInaccessibleCollections => { type => 'boolean' },
                    maxWarningCount             => { type => 'integer' },
                    intermediateCommitCount     => { type => 'integer' },
                    satelliteSyncWait           => { type => 'integer' },
                    fullCount                   => { type => 'boolean' },
                    intermediateCommitSize      => { type => 'integer' },
                    'optimizer.rules'           => { type => 'string'  },
                    maxPlans                    => { type => 'integer' },
                 }
            },
        },
      },
      delete_user => { method => 'delete', uri => '_api/user/{username}' },
      create_user => {
          method => 'post',
          uri => '_api/user',
          params => {
              password => { type => 'string'  },
              active   => { type => 'boolean' },
              user     => { type => 'string'  },
              extra    => { type => 'object', additionalProperties => 1 },
          }
      },
      update_user => {
          method => 'patch',
          uri => '_api/user/{user}',
          params => {
              password => { type => 'string'  },
              active   => { type => 'boolean' },
              extra    => { type => 'object', additionalProperties => 1 },
          }
      },
      replace_user => {
          method => 'put',
          uri => '_api/user/{user}',
          params => {
              password => { type => 'string'  },
              active   => { type => 'boolean' },
              extra    => { type => 'object', additionalProperties => 1 },
          }
      },
      log => {
          method => 'get',
          uri => '_admin/log',
          params => {
              upto   => { type => 'string', default => 'info', enum => [qw'fatal error warning info debug 0 1 2 3 4'] },
              level  => { type => 'string', default => 'info', enum => [qw'fatal error warning info debug'] },
              size   => { type => 'integer', minimum => 0 },
              offset => { type => 'integer', minimum => 0 },
              search => { type => 'string' },
              sort   => { type => 'string', default => 'asc', enum => [qw'asc desc'] }, # asc, desc
          }
      }
);



sub _check_options {
    my ($params, $properties) = @_;
    my $schema = { type => 'object', additionalProperties => 0, properties => $properties };
    my $prepared_data = JSON::Schema::Fit->new(replace_invalid_values => 1)->get_adjusted($params, $schema);
    return $prepared_data;
}

sub _api {
    my ($self, $action, $params) = @_;

    my $uri = $API{$action}{uri};

    my $params_copy = clone $params;

    $uri =~ s!\{\{database\}\}! defined $params->{database} ? "_db/$params->{database}/" : "" !e;
    $uri =~ s/\{([^}]+)\}/$params->{$1}/g;

    my $url = "http://" . $self->{host} . ":" . $self->{port} . "/" . $uri;

    my $body = ref($params) eq "HASH" && exists $params->{body} ? $params->{body} : undef;
    my $opts = ref($params) eq "HASH" ? $params : {};

    $opts = exists($API{$action}{params}) ? _check_options($opts, $API{$action}{params}) : {};

    if ($API{$action}{method} eq 'get' && scalar(keys %$opts)) { 
        $url .= "?" . join("&", map { "$_=" . uri_encode($opts->{$_} )} keys %$opts);
    } else {
        if ($body && ref($body) eq "HASH") {
            $opts = { content => encode_json $body }
        }
        elsif (defined($body)) { # JSON
            $opts = { content => $body }
        }
        else {
            $opts = { content => encode_json $opts }
        }
    }

    #use Data::Dumper;
#print STDERR " -- $action | $API{$action}{method} | $url\n";
    #print STDERR "\n\nOPTS:\n\n", Dumper($opts);

    my $response = $self->{http}->request($API{$action}{method}, $url, $opts);

    if ($response->{success}) {
        my $ans = decode_json($response->{content});
        if ($ans->{error}) {
            return $ans;
        } elsif (exists($API{$action}{builder})) {
            return $API{$action}{builder}->( $self, %$params_copy );
        } else {
            return $ans;
        }
    }
    else {
        die "Arango::Tango | ($response->{status}) $response->{reason}";
    }
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Arango::Tango::API - Internal module with the API specification

=head1 VERSION

version 0.010

=head1 AUTHOR

Alberto Simões <ambs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Alberto Simões.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
