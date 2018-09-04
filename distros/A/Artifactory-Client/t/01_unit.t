#!/usr/local/bin/perl

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use FindBin qw($Bin);
use lib "$Bin/../lib", "$Bin/../local/lib/perl5";
use JSON::MaybeXS;
use WWW::Mechanize;
use URI::http;
use HTTP::Request;
use Artifactory::Client;
use Path::Tiny;

# it became silly to do this in every subtest
no strict 'refs';
no warnings 'redefine';

my $artifactory = 'http://example.com';
my $port        = 7777;
my $repository  = 'repository';

my %mock_responses = (
    http_404 => bless( { '_rc' => 404, '_headers' => bless( {}, 'HTTP::Headers' ) }, 'HTTP::Response' ),
    http_200 => bless( { '_rc' => 200,   '_content' => '{ "foo" : "bar" }' }, 'HTTP::Response' ),
    http_201 => bless( { '_rc' => 201 }, 'HTTP::Response' ),
    http_202 => bless( { '_rc' => 202 }, 'HTTP::Response' ),
    http_204 => bless( { '_rc' => 204 }, 'HTTP::Response' ),
);

subtest 'check if ua is LWP::UserAgent', sub {
    my $client = setup();
    isa_ok( $client->ua, 'LWP::UserAgent' );

    my $ua = WWW::Mechanize->new();
    $client->ua($ua);
    isa_ok( $client->ua, 'WWW::Mechanize' );
};

subtest 'deploy_artifact with properties and content', sub {
    my $client     = setup();
    my $properties = {
        one => ['two'],
        baz => [ 'three', 'four' ],
    };
    my $path    = '/unique_path';
    my $content = "content of artifact";

    local *{'LWP::UserAgent::request'} = sub {
        return $mock_responses{http_201};
    };

    my $resp = $client->deploy_artifact( path => $path, properties => $properties, file => "$Bin/data/test.json" );
    is( $resp->is_success, 1, 'request came back successfully' );

    local *{'LWP::UserAgent::get'} = sub {
        my ( $self, $url ) = @_;

        if ( $url eq "$artifactory:$port/artifactory/api/storage/$repository/unique_path?properties" ) {
            return bless(
                {
                    '_content' => '{
                    "properties" : {
                        "baz" : [ "three", "four" ],
                        "one" : [ "two" ]
                    }
                }',
                    '_rc'      => 200,
                    '_headers' => bless( {}, 'HTTP::Headers' ),
                },
                'HTTP::Response'
            );
        }
        else {
            return bless(
                {
                    '_content' => 'content of artifact',
                    '_rc'      => 200,
                    '_headers' => bless( {}, 'HTTP::Headers' ),
                },
                'HTTP::Response'
            );
        }
    };

    my $resp2 = $client->item_properties( path => $path );
    my $scalar = decode_json( $resp2->decoded_content );
    is_deeply( $scalar->{properties}, $properties, 'properties are correct' );
    my $artifact_url = "$artifactory:$port/$repository$path";
    my $resp3        = $client->get($artifact_url);
    is( $resp3->decoded_content, $content, 'content matches' );
};

subtest 'set_item_properties on non-existing artifact', sub {
    my $client     = setup();
    my $properties = {
        one => [1],
        two => [2],
    };

    local *{'LWP::UserAgent::put'} = sub {
        return $mock_responses{http_404};
    };
    my $resp = $client->set_item_properties( path => '/unique_path', properties => $properties );
    is( $resp->code, 404, 'got 404 for attempting to set props on non-existent artifact' );
};

subtest 'deploy artifact by checksum', sub {
    my $client = setup();
    my $path   = '/unique_path';
    my $sha1   = 'da39a3ee5e6b4b0d3255bfef95601890afd80709';    # sha-1 of 0 byte file

    local *{'LWP::UserAgent::request'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_headers' => bless(
                            {
                                'x-checksum-sha1'   => $sha1,
                                'x-checksum-deploy' => 'true',
                            },
                            'HTTP::Headers'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };

    my $resp = $client->deploy_artifact_by_checksum( path => $path, sha1 => $sha1 );
    is( $resp->request()->header('x-checksum-deploy'), 'true', 'x-checksum-deploy set' );
    is( $resp->request()->header('x-checksum-sha1'),   $sha1,  'x-checksum-sha1 set' );

    local *{'LWP::UserAgent::request'} = sub {
        return $mock_responses{http_404};
    };

    my $resp2 = $client->deploy_artifact_by_checksum( path => $path );    # no sha-1 on purpose
    is( $resp2->code, 404, 'got 404 since no sha1 was supplied' );
};

subtest 'item properties', sub {
    my $client     = setup();
    my $properties = {
        this => [ 'here', 'there' ],
        that => ['one'],
    };

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_content' => '{
                "properties" : {
                    "that" : [ "one" ]
                }
            }',
                '_headers' => bless( {}, 'HTTP::Headers' ),
            },
            'HTTP::Response'
        );
    };

    my $resp = $client->item_properties( path => '/unique_path', properties => ['that'] );
    my $scalar = decode_json( $resp->decoded_content );
    is_deeply( $scalar->{properties}, { that => ['one'] }, 'property content is correct' );
};

subtest 'retrieve artifact', sub {
    my $client  = setup();
    my $content = "content of artifact";

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_content' => 'content of artifact',
                '_headers' => bless( {}, 'HTTP::Headers' ),
            },
            'HTTP::Response'
        );
    };

    my $resp = $client->retrieve_artifact('/unique_path');
    is( $resp->decoded_content, $content, 'artifact retrieved successfully' );
};

subtest 'all_builds', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->all_builds();
    is( $resp->is_success, 1, 'fetched all builds' );
};

subtest 'delete_item', sub {
    my $client = setup();

    local *{'LWP::UserAgent::delete'} = sub {
        return $mock_responses{http_204};
    };
    my $resp = $client->delete_item('/unique_path');
    is( $resp->code, 204, 'deleted item' );
};

subtest 'build_runs', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->build_runs('api-test');
    is( $resp->code, 200, 'got build runs' );
};

subtest 'build_upload', sub {
    my $client = setup();

    local *{'LWP::UserAgent::put'} = sub {
        return $mock_responses{http_200};
    };

    my $json_file = "$Bin/data/test.json";
    my $resp      = $client->build_upload($json_file);
    is( $resp->code, 200, 'got build upload' );
};

subtest 'build_info', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->build_info( 'api-test', 14 );
    is( $resp->code, 200, 'got build info' );
};

subtest 'builds_diff', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->builds_diff( 'api-test', 14, 10 );
    is( $resp->code, 200, 'got builds diff' );
};

subtest 'build_promotion', sub {
    my $client = setup();
    my $payload = { status => "staged", };

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->build_promotion( 'api-test', 10, $payload );
    is( $resp->code, 200, 'build_promotion succeeded' );
};

subtest 'promote_docker_image', sub {
    my $client = setup();
    my %data   = (
        targetRepo       => "target_repo",
        dockerRepository => "dockerRepository",
        tag              => "tag",
        copy             => 'false',
    );
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->promote_docker_image(%data);
    is( $resp->code, 200, 'promote_docker_image succeeded' );
};

subtest 'delete_builds', sub {
    my $client = setup();

    local *{'LWP::UserAgent::delete'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o =
'http://example.com:7777/artifactory/api/build/api-test?buildNumbers=1&artifacts=0&deleteAll=0'
                                );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };

    my $resp = $client->delete_builds( name => 'api-test', buildnumbers => [1], artifacts => 0, deleteall => 0 );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr/buildNumbers=1/, 'buildNumbers showed up' );
    like( $url_in_response, qr/artifacts=0/,    'artifacts showed up' );
    like( $url_in_response, qr/deleteAll=0/,    'deleteAll showed up' );
};

subtest 'build_rename', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->build_rename( 'api-test', 'something' );
    is( $resp->code, 200, 'build_rename succeeded' );
};

subtest 'distribute_build', sub {
    my $client = setup();
    my %info   = (
        gpgPassphrase => 'foobar',
        'targetRepo'  => 'foobar',
    );

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };

    my $resp = $client->distribute_build( 'build_name', 5, %info );
    is( $resp->code, 200, 'distribute_build succeeded' );
};

subtest 'control_build_retention', sub {
    my $client = setup();

    my %info = (
        deleteBuildArtifacts         => 'true',
        count                        => 2,
        minimumBuildDate             => 1407345768020,
        buildNumbersNotToBeDiscarded => [8],
    );

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };

    my $resp = $client->control_build_retention( 'build_name', %info );
    is( $resp->code, 200, 'control_build_retention succeeded' );
};

subtest 'push_docker_tag_to_bintray', sub {
    my $client = setup();
    my %info   = (
        dockerImage    => 'jfrog/ubuntu:latest',
        bintraySubject => 'shayy',
        bintrayRepo    => 'containers',
        async          => 'false'
    );

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };

    my $resp = $client->push_docker_tag_to_bintray(%info);
    is( $resp->code, 200, 'push_docker_tag_to_bintray_succeeded' );
};

subtest 'folder_info', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->folder_info("/some_dir");
    is( $resp->code, 200, 'folder_info succeeded' );
};

subtest 'file_info', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->file_info("/somefile");
    is( $resp->code, 200, 'file_info succeeded' );
};

subtest 'get_storage_summary_info', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_storage_summary_info();
    is( $resp->code, 200, 'get_storage_summary_info succeeded' );
};

subtest 'item_last_modified', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->item_last_modified('/unique_path');
    is( $resp->code, 200, 'item_last_modified succeeded' );
};

subtest 'file_statistics', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->file_statistics('/unique_path');
    is( $resp->code, 200, 'file_statistics succeeded' );
};

subtest 'delete_item_properties', sub {
    my $client = setup();

    local *{'LWP::UserAgent::delete'} = sub {
        return $mock_responses{http_204};
    };
    my $resp = $client->delete_item_properties( path => '/unique_path', properties => ['first'] );
    is( $resp->code, 204, 'delete_item_properties succeeded' );
};

subtest 'set_item_sha256_checksum', sub {
    my $client = setup();
    my %args   = (
        repoKey => 'libs-release-local',
        path    => '/'
    );

    local *{'LWP::UserAgent::post'} = sub { return $mock_responses{http_200}; };
    my $resp = $client->set_item_sha256_checksum(%args);
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'retrieve_latest_artifact', sub {
    my $client = setup();
    my $path   = '/unique_path';

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o =
'http://example.com:7777/artifactory/repository/unique_path/0.9.9-SNAPSHOT/unique_path-0.9.9-SNAPSHOT.jar'
                                );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->retrieve_latest_artifact( path => $path, version => '0.9.9', flag => 'snapshot' );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr/\Qunique_path-0.9.9-SNAPSHOT.jar\E/, 'snapshot URL looks sane' );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o =
'http://example.com:7777/artifactory/repository/unique_path/release/unique_path-release.jar'
                                );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    $resp = $client->retrieve_latest_artifact( path => $path, release => 'release', flag => 'release' );
    my $url_in_response2 = $resp->request->uri;
    like( $url_in_response2, qr/\Qunique_path-release.jar\E/, 'release URL looks sane' );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o =
'http://example.com:7777/artifactory/repository/unique_path/1.0-integration/unique_path-1.0-integration.jar'
                                );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    $resp = $client->retrieve_latest_artifact(
        path        => $path,
        version     => '1.0',
        integration => 'integration',
        flag        => 'integration'
    );
    my $url_in_response3 = $resp->request->uri;
    like( $url_in_response3, qr/\Qunique_path-1.0-integration.jar\E/, 'integration URL looks sane' );
};

subtest 'retrieve_build_artifacts_archive', sub {
    my $client  = setup();
    my $payload = {
        buildName   => 'api-test',
        buildNumber => 10,
        archiveType => 'zip',
    };

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->retrieve_build_artifacts_archive($payload);
    is( $resp->code, 200, 'retrieve_build_artifacts_archive succeeded' );
};

subtest 'retrieve_folder_or_repository_archive', sub {
    my $client = setup();
    my %info   = (
        path        => '/foobar',
        archiveType => 'zip',
    );

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->retrieve_folder_or_repository_archive(%info);
    is( $resp->code, 200, 'retrieve_folder_or_repository_archive succeeded' );
};

subtest 'trace_artifact_retrieval', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->trace_artifact_retrieval('/unique_path');
    is( $resp->code, 200, 'trace_artifact_retrieval succeeded' );
};

subtest 'archive_entry_download', sub {
    my $client       = setup();
    my $path         = '/unique_path';
    my $archive_path = '/archive_path';

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/repo$path!$archive_path" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->archive_entry_download( $path, $archive_path );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr/$path!$archive_path/, 'archive_entry_download succeeded' );
};

subtest 'create_directory', sub {
    my $client = setup();
    my $dir    = '/unique_dir/';

    local *{'LWP::UserAgent::request'} = sub {
        return $mock_responses{http_201};
    };
    my $resp = $client->create_directory( path => $dir );
    is( $resp->code, 201, 'create_directory succeeded' );
};

subtest 'deploy_artifacts_from_archive', sub {
    my $client = setup();

    local *{'LWP::UserAgent::request'} = sub {
        return $mock_responses{http_200};
    };

    local *{'Path::Tiny::slurp'} = sub {

        # no-op, unit test reads no file
    };
    my $resp = $client->deploy_artifacts_from_archive( file => "$Bin/data/test.xml", path => '/some_path/test.zip' );
    is( $resp->code, 200, 'deploy_artifacts_from_archive worked' );
};

subtest 'push_a_set_of_artifacts_to_bintray', sub {
    my $client = setup();
    my %info   = (
        descriptor    => 'some_path',
        gpgPassphrase => 'top_secret',
        gpgSign       => 'true'
    );

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };

    my $resp = $client->push_a_set_of_artifacts_to_bintray(%info);
    is( $resp->code, 200, 'push_a_set_of_artifacts_to_bintray' );
};

subtest 'distribute_artifact', sub {
    my $client = setup();
    my %info   = (
        publish       => 'true',
        gpgPassphrase => 'abc',
    );

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };

    my $resp = $client->distribute_artifact(%info);
    is( $resp->code, 200, 'distribute_artifact' );
};

subtest 'file_compliance_info', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/compliance/repo/some_path" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->file_compliance_info('/some_path');
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/compliance|, 'requsted URL looks sane' );
};

subtest 'copy_item', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->copy_item( from => "/repo/some_path", to => "/repo2/some_path2" );
    is( $resp->code, 200, 'copy_item worked' );
};

subtest 'move_item', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->move_item( from => "/repo/some_path", to => "/repo2/some_path2" );
    is( $resp->code, 200, 'move_item worked' );
};

subtest 'request method call', sub {
    my $client = setup();
    my $req = HTTP::Request->new( GET => 'http://www.example.com/' );

    local *{'LWP::UserAgent::request'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->request($req);
    is( $resp->code, 200, 'request method call worked' );
};

subtest 'scheduled_replication_status', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->scheduled_replication_status();
    is( $resp->code, 200, 'scheduled_replication_status succeeded' );
};

subtest 'get_repository_replication_configuration', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/replications/foobar" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_repository_replication_configuration();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/replications|, 'requsted URL looks sane' );
};

subtest 'set_repository_replication_configuration', sub {
    my $client = setup();
    my $payload = { username => "admin", };

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/replications/foobar" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->set_repository_replication_configuration($payload);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/replications|, 'requsted URL looks sane' );
};

subtest 'update_repository_replication_configuration', sub {
    my $client = setup();
    my $payload = { username => "admin", };

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/replications/foobar" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->update_repository_replication_configuration($payload);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/replications|, 'requsted URL looks sane' );
};

subtest 'pull_push_replication', sub {
    my $client  = setup();
    my $payload = { username => 'replicator', };
    my $path    = '/foo/bar';

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/replication/execute/foobar" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->pull_push_replication( payload => $payload, path => $path );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/replication/execute/foobar|, 'requsted URL looks sane' );
};

subtest 'create_or_replace_local_multi_push_replication', sub {
    my $client  = setup();
    my $payload = {
        cronExp                => "0 0/9 14 * * ?",
        enableEventReplication => 'true'
    };

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/replications/multiple" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->create_or_replace_local_multi_push_replication($payload);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/replications/multiple|, 'requsted URL looks sane' );
};

subtest 'update_local_multi_push_replication', sub {
    my $client  = setup();
    my $payload = {
        cronExp                => "0 0/9 14 * * ?",
        enableEventReplication => 'true'
    };

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/replications/multiple" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->update_local_multi_push_replication($payload);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/replications/multiple|, 'requsted URL looks sane' );
};

subtest 'delete_local_multi_push_replication', sub {
    my $client = setup();
    my $url    = 'http://10.0.0.1/artifactory/libs-release-local';

    local *{'LWP::UserAgent::delete'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o =
"http://example.com:7777/artifactory/api/replications/repository?url=http://10.0.0.1/artifactory/libs-release-local"
                                );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->delete_local_multi_push_replication($url);
    my $url_in_response = $resp->request->uri;
    like(
        $url_in_response,
        qr|/api/replications/repository\?url=http://10.0.0.1/artifactory/libs-release-local|,
        'requsted URL looks sane'
    );
};

subtest 'enable_or_disable_multiple_replications', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my %info = (
        include => ["**"],
        exclude => [ "http://artimaster:port/artifactory/**", "https://somearti:port/artifactory/local-repo" ]
    );
    my $resp = $client->enable_or_disable_multiple_replications( 'enable', %info );
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'get_global_system_replication_configuration', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_global_system_replication_configuration();
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'get_remote_repositories_registered_for_replication', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_remote_repositories_registered_for_replication('repository');
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'block_system_replication', sub {
    my $client = setup();

    my %info = (
        push => 'false',
        pull => 'false'
    );

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->block_system_replication(%info);
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'unblock_system_replication', sub {
    my $client = setup();

    my %info = (
        push => 'false',
        pull => 'false'
    );

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->unblock_system_replication(%info);
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'artifact_sync_download', sub {
    my $client = setup();
    my %args   = (
        content => 'progress',
        mark    => 1000,
    );
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->artifact_sync_download( '/foobar', %args );
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'file_list', sub {
    my $client = setup();
    my %opts   = (
        deep            => 1,
        depth           => 1,
        listFolders     => 1,
        mdTimestamps    => 1,
        includeRootPath => 1,
    );

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->file_list( '/some_dir/', %opts );
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'get_background_tasks', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_background_tasks();
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'empty_trash_can', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->empty_trash_can();
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'delete_item_from_trash_can', sub {
    my $client = setup();

    local *{'LWP::UserAgent::delete'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->delete_item_from_trash_can('foobar');
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'restore_item_from_trash_can', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->restore_item_from_trash_can( 'npm_local', 'npm_local2' );
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'optimize_system_storage', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->optimize_system_storage();
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'artifactory_query_language', sub {
    my $client = setup();
    my $aql    = q|items.find({"repo":{"$eq":"testrepo"}}|;

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->artifactory_query_language($aql);
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'artifact_search', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->artifact_search( name => 'some_file', repos => ['foobar'] );
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'archive_entry_search', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/archive" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->archive_entry_search( name => 'archive', repos => ['repo'] );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/archive|, 'requsted URL looks sane' );
};

subtest 'gavc_search', sub {
    my $client = setup();
    my %args   = (
        g     => 'foo',
        a     => 'bar',
        v     => '1.0',
        c     => 'abc',
        repos => [ 'repo', 'abc' ],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->gavc_search(%args);
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'property_search', sub {
    my $client = setup();
    my %args   = (
        key   => [ 'val1', 'val2' ],
        repos => [ 'repo', 'abc' ],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->property_search(%args);
    is( $resp->code, 200, 'got 200 back' );
};

subtest 'checksum_search', sub {
    my $client = setup();
    my %args   = (
        md5   => '12345',
        repos => [ 'repo', 'abc' ],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/checksum" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->checksum_search(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/checksum|, 'requsted URL looks sane' );
};

subtest 'bad_checksum_search', sub {
    my $client = setup();
    my %args   = (
        type  => 'md5',
        repos => [ 'repo', 'abc' ],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/badChecksum" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->bad_checksum_search(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/badChecksum|, 'requsted URL looks sane' );
};

subtest 'artifacts_not_downloaded_since', sub {
    my $client = setup();
    my %args   = (
        notUsedSince  => 12345,
        createdBefore => 12345,
        repos         => [ 'repo', 'abc' ],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/usage" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->artifacts_not_downloaded_since(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/usage|, 'requsted URL looks sane' );
};

subtest 'artifacts_with_date_in_date_range', sub {
    my $client = setup();
    my %args   = (
        from       => 12345,
        repos      => [ 'repo1', 'repo2' ],
        dateFields => [ 'created', 'lastModified', 'lastDownloaded' ],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/dates" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };

    my $resp            = $client->artifacts_with_date_in_date_range(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/dates|, 'requested URL looks sane' );
};

subtest 'artifacts_created_in_date_range', sub {
    my $client = setup();
    my %args   = (
        from  => 12345,
        repos => [ 'repo', 'abc' ],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/creation" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->artifacts_created_in_date_range(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/creation|, 'requsted URL looks sane' );
};

subtest 'pattern_search', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->pattern_search('killer/*/ninja/*/*.jar');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'builds_for_dependency', sub {
    my $client = setup();
    my %args = ( sha1 => 'abcde', );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/dependency" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->builds_for_dependency(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/dependency|, 'requsted URL looks sane' );
};

subtest 'license_search', sub {
    my $client = setup();
    my %args   = (
        unapproved => 1,
        unknown    => 1,
        notfound   => 0,
        neutral    => 0,
        approved   => 0,
        autofind   => 0,
        repos      => ['foo'],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/license" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->license_search(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/license|, 'requsted URL looks sane' );
};

subtest 'artifact_version_search', sub {
    my $client = setup();
    my %args   = (
        g      => 'foo',
        a      => 'bar',
        v      => '1.0',
        remote => 1,
        repos  => ['dist-packages'],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/versions" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->artifact_version_search(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/versions|, 'requsted URL looks sane' );
};

subtest 'artifact_latest_version_search_based_on_layout', sub {
    my $client = setup();
    my %args   = (
        g      => 'foo',
        a      => 'bar',
        v      => '1.0',
        remote => 1,
        repos  => ['foo'],
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/search/latestVersion" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->artifact_latest_version_search_based_on_layout(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/search/latestVersion|, 'requsted URL looks sane' );
};

subtest 'artifact_latest_version_search_based_on_properties', sub {
    my $client = setup();
    my %args   = (
        repo      => '_any',
        path      => '/a/b',
        listFiles => 1,
    );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' =>
                          bless( do { \( my $o = "http://example.com:7777/artifactory/api/versions" ) }, 'URI::http' ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->artifact_latest_version_search_based_on_properties(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/versions|, 'requsted URL looks sane' );
};

subtest 'build_artifacts_search', sub {
    my $client = setup();
    my %args   = (
        buildName   => 'api-test',
        buildNumber => 14,
    );

    local *{'LWP::UserAgent::post'} = sub {
        return return $mock_responses{http_200};
    };
    my $resp = $client->build_artifacts_search(%args);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'list_docker_repositories', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return return $mock_responses{http_200};
    };
    my $resp = $client->list_docker_repositories();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'list_docker_tags', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return return $mock_responses{http_200};
    };
    my $resp = $client->list_docker_tags( 'foobar', n => 5, last => 'some_last_value' );
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'get_users', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/users" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_users();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/users|, 'requsted URL looks sane' );
};

subtest 'get_user_details', sub {
    my $client = setup();
    my $user   = 'foo';

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/users/$user" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_user_details($user);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/users/$user|, 'requsted URL looks sane' );
};

subtest 'get_user_encrypted_password', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/encryptedPassword" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_user_encrypted_password();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/encryptedPassword|, 'requsted URL looks sane' );
};

subtest 'create_or_replace_user', sub {
    my $client = setup();
    my $user   = 'foo';
    my %args   = ( name => 'foo', );

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/users/$user" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->create_or_replace_user( $user, %args );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/users/$user|, 'requsted URL looks sane' );
};

subtest 'update_user', sub {
    my $client = setup();
    my $user   = 'foo';
    my %args   = ( name => 'foo', );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/users/$user" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->update_user( $user, %args );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/users/$user|, 'requsted URL looks sane' );
};

subtest 'delete_user', sub {
    my $client = setup();
    my $user   = 'foo';

    local *{'LWP::UserAgent::delete'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/users/$user" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->delete_user($user);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/users/$user|, 'requsted URL looks sane' );
};

subtest 'expire_password_for_a_single_user', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->expire_password_for_a_single_user('david');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'expire_password_for_multiple_users', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->expire_password_for_multiple_users( 'david', 'johnb' );
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'expire_password_for_all_users', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->expire_password_for_all_users();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'unexpire_password_for_a_single_user', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->unexpire_password_for_a_single_user('david');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'change_password', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my %info = (
        userName    => 'david',
        oldPassword => 'foo',
        newPassword => 'bar',
    );
    my $resp = $client->change_password(%info);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'get_password_expiration_policy', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_password_expiration_policy();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'set_password_expiration_policy', sub {
    my $client = setup();
    local *{'LWP::UserAgent::put'} = sub {
        return $mock_responses{http_200};
    };
    my %info = (
        enabled        => 'true',
        passwordMaxAge => 999,
        notifyByEmail  => 'true'
    );
    my $resp = $client->set_password_expiration_policy(%info);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'configure_user_lock_policy', sub {
    my $client = setup();
    local *{'LWP::UserAgent::put'} = sub {
        return $mock_responses{http_200};
    };
    my %info = (
        enabled       => 'true',
        loginAttempts => 3
    );
    my $resp = $client->configure_user_lock_policy(%info);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'retrieve_user_lock_policy', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->retrieve_user_lock_policy();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'get_locked_out_users', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_locked_out_users();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'unlock_locked_out_user', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->unlock_locked_out_user('admin');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'unlock_locked_out_users', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->unlock_locked_out_users( 'admin', 'davids' );
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'unlock_all_locked_out_users', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->unlock_all_locked_out_users();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'create_api_key', sub {
    my $client = setup();
    my %data = ( apiKey => '3OloposOtVFyCMrT+cXmCAScmVMPrSYXkWIjiyDCXsY=' );
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->create_api_key(%data);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'get_api_key', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_api_key();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'revoke_api_key', sub {
    my $client = setup();

    # makes 2 calls, one to get the current key and the other to delete it
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    local *{'LWP::UserAgent::delete'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->revoke_api_key();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'revoke_user_api_key', sub {
    my $client = setup();

    # makes 2 calls, one to get the current key and the other to delete it
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    local *{'LWP::UserAgent::delete'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->revoke_user_api_key("foobar_user");
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'revoke_all_api_keys', sub {
    my $client = setup();

    # makes 2 calls, one to get the current key and the other to delete it
    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    local *{'LWP::UserAgent::delete'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->revoke_all_api_keys( deleteAll => 1 );
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'get_groups', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/groups" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_groups();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/groups|, 'requsted URL looks sane' );
};

subtest 'get_group_details', sub {
    my $client = setup();
    my $group  = 'dev-leads';

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/groups/$group" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_group_details($group);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/groups/$group|, 'requsted URL looks sane' );
};

subtest 'create_or_replace_group', sub {
    my $client = setup();
    my $group  = 'dev-leads';
    my %args   = ( name => 'dev-leads', );

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/groups/$group" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->create_or_replace_group( $group, %args );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/groups/$group|, 'requsted URL looks sane' );
};

subtest 'update_group', sub {
    my $client = setup();
    my $group  = 'dev-leads';
    my %args   = ( name => 'dev-leads', );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/groups/$group" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->update_group( $group, %args );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/groups/$group|, 'requsted URL looks sane' );
};

subtest 'delete_group', sub {
    my $client = setup();
    my $group  = 'dev-leads';

    local *{'LWP::UserAgent::delete'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/groups/$group" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->delete_group($group);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/groups/$group|, 'requsted URL looks sane' );
};

subtest 'get_permission_targets', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/permissions" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_permission_targets();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/permissions|, 'requsted URL looks sane' );
};

subtest 'get_permission_target_details', sub {
    my $client = setup();
    my $name   = 'populateCaches';

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/permissions/$name" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_permission_target_details($name);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/permissions/$name|, 'requsted URL looks sane' );
};

subtest 'create_or_replace_permission_target', sub {
    my $client = setup();
    my $name   = 'populateCaches';
    my %args   = ( name => 'populateCaches', );

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/security/permissions/$name" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->create_or_replace_permission_target( $name, %args );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/permissions/$name|, 'requsted URL looks sane' );
};

subtest 'delete_permission_target', sub {
    my $client     = setup();
    my $permission = 'populateCaches';

    local *{'LWP::UserAgent::delete'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o = "http://example.com:7777/artifactory/api/security/permissions/$permission" );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->delete_permission_target($permission);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/security/permissions/$permission|, 'requsted URL looks sane' );
};

subtest 'effective_item_permissions', sub {
    my $client = setup();
    my $path   = '/foobar';

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->effective_item_permissions($path);
    is( $resp->code, 200, 'request came back successfully' );
};

subtest 'security_configuration', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/security" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->security_configuration();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/security|, 'requsted URL looks sane' );
};

subtest 'activate_master_key_encryption', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/encrypt" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->activate_master_key_encryption();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/encrypt|, 'requsted URL looks sane' );
};

subtest 'deactivate_master_key_encryption', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/decrypt" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->deactivate_master_key_encryption();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/decrypt|, 'requsted URL looks sane' );
};

subtest 'set_gpg_public_key', sub {
    my $client = setup();

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/gpg/key/public" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->set_gpg_public_key();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/gpg/key/public|, 'requsted URL looks sane' );
};

subtest 'get_gpg_public_key', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/gpg/key/public" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->get_gpg_public_key();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/gpg/key/public|, 'requsted URL looks sane' );
};

subtest 'set_gpg_private_key', sub {
    my $client = setup();

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/gpg/key/private" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->set_gpg_private_key();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/gpg/key/private|, 'requsted URL looks sane' );
};

subtest 'set_gpg_pass_phrase', sub {
    my $client = setup();

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/gpg/key/passphrase" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->set_gpg_pass_phrase('foobar');
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/gpg/key/passphrase|, 'requsted URL looks sane' );
};

subtest 'create_token', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->create_token( username => 'johnq', scope => 'member-of-groups:readers' );
    is( $resp->code, 200, 'create_token' );
};

subtest 'refresh_token', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->refresh_token( grant_type => 'refresh_token', refresh_token => 'fgsg53tg' );
    is( $resp->code, 200, 'refresh_token' );
};

subtest 'revoke_token', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->revoke_token( token => 'fgsg53tg' );
    is( $resp->code, 200, 'revoke_token' );
};

subtest 'get_service_id', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_service_id();
    is( $resp->code, 200, 'get_service_id' );
};

subtest 'get_certificates', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_certificates();
    is( $resp->code, 200, 'get_certificates' );
};

subtest 'add_certificate', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->add_certificate( 'foobar', "$Bin/data/test.xml" );
    is( $resp->code, 200, 'add_certificates' );
};

subtest 'delete_certificate', sub {
    my $client = setup();

    local *{'LWP::UserAgent::delete'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->delete_certificate('foobar');
    is( $resp->code, 200, 'delete_certificates' );
};

subtest 'get_repositories', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_repositories('local');
    is( $resp->code, 200, 'got repositories' );
};

subtest 'repository_configuration', sub {
    my $client = setup();
    my $repo   = 'dist-packages';
    my %args   = ( type => 'local', );

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/repositories/$repo" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->repository_configuration( $repo, %args );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/repositories/$repo|, 'requsted URL looks sane' );
};

subtest 'create_or_replace_repository_configuration', sub {
    my $client  = setup();
    my $repo    = 'foo';
    my $payload = { key => "local-repo1", };
    my %args    = ( pos => 2, );

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/repositories/$repo" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->create_or_replace_repository_configuration( $repo, $payload, %args );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/repositories/$repo|, 'requsted URL looks sane' );
};

subtest 'update_repository_configuration', sub {
    my $client  = setup();
    my $repo    = 'foo';
    my $payload = { key => "local-repo1", };

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/repositories/$repo" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->update_repository_configuration( $repo, $payload );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/repositories/$repo|, 'requsted URL looks sane' );
};

subtest 'delete_repository', sub {
    my $client = setup();
    my $repo   = 'dist-packages';

    local *{'LWP::UserAgent::delete'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/repositories/$repo" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->delete_repository($repo);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/repositories/$repo|, 'requsted URL looks sane' );
};

subtest 'calculate_yum_repository_metadata', sub {
    my $client = setup();
    my %args = ( async => 1, );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/yum/$repository?async=1" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->calculate_yum_repository_metadata(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/yum/$repository\?async=1|, 'requsted URL looks sane' );
};

subtest 'calculate_nuget_repository_metadata', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/nuget/$repository/reindex" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->calculate_nuget_repository_metadata();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/nuget/$repository/reindex|, 'requsted URL looks sane' );
};

subtest 'calculate_npm_repository_metadata', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/npm/$repository/reindex" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->calculate_npm_repository_metadata();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/npm/$repository/reindex|, 'requsted URL looks sane' );
};

subtest 'calculate_maven_index', sub {
    my $client = setup();
    my %args   = (
        repos => [ 'dist-packages', 'foo' ],
        force => 1,
    );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' =>
                          bless( do { \( my $o = "http://example.com:7777/artifactory/api/maven?" ) }, 'URI::http' ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->calculate_maven_index(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/maven?|, 'requsted URL looks sane' );
};

subtest 'calculate_maven_metadata', sub {
    my $client = setup();
    my $path   = '/foo/bar';

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/maven/calculateMetadata" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->calculate_maven_metadata($path);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/maven/calculateMetadata|, 'requsted URL looks sane' );
};

subtest 'calculate_debian_repository_metadata', sub {
    my $client = setup();
    my %args = ( async => 1, );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o = "http://example.com:7777/artifactory/api/deb/reindex/$repository?async=1" );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->calculate_debian_repository_metadata(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/deb/reindex/$repository\?async=1|, 'requsted URL looks sane' );
};

subtest 'calculate_opkg_repository_metadata', sub {
    my $client = setup();
    my %args   = (
        async      => 1,
        writeProps => 0
    );
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->calculate_opkg_repository_metadata(%args);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'calculate_bower_index', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->calculate_bower_index();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'calculate_helm_chart_index', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->calculate_helm_chart_index();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'calculate_cran_repository_metadata', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->calculate_cran_repository_metadata();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'calculate_conda_repository_metadata', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->calculate_conda_repository_metadata();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'system_info', sub {
    my $client = setup();
    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' =>
                          bless( do { \( my $o = "http://example.com:7777/artifactory/api/system" ) }, 'URI::http' ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->system_info();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system|, 'requsted URL looks sane' );
};

subtest 'verify_connection', sub {
    my $client = setup();
    my %args   = (
        endpoint => 'http://localhost/foobar',
        username => 'admin',
        password => 'password'
    );
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->verify_connection(%args);
    is( $resp->code, 200, 'verify_connection succeeded' );
};

subtest 'system_health_ping', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->system_health_ping();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'general_configuration', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/configuration" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->general_configuration();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/configuration|, 'requsted URL looks sane' );
};

subtest 'save_general_configuration', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/configuration" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };

    local *{'Path::Tiny::slurp'} = sub {

        # no-op, unit test reads no file
    };
    my $resp            = $client->save_general_configuration('test.xml');
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/configuration|, 'requsted URL looks sane' );
};

subtest 'update_custom_url_base', sub {
    my $client = setup();

    local *{'LWP::UserAgent::put'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/configuration/baseUrl" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };

    my $resp            = $client->update_custom_url_base('https://mycompany.com:444/artifactory');
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/configuration/baseUrl|, 'requested URL looks sane' );
};

subtest 'license_information', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/license" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->license_information();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/license|, 'requsted URL looks sane' );
};

subtest 'install_license', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/license" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->install_license('your_license_key');
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/license|, 'requsted URL looks sane' );
};

subtest 'ha_license_information', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/licenses" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->ha_license_information();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/licenses|, 'requsted URL looks sane' );
};

subtest 'install_ha_cluster_licenses', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/licenses" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp =
      $client->install_ha_cluster_licenses( [ { licenseKey => "foobar" }, { licenseKey => "barbaz" } ] );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/licenses|, 'requsted URL looks sane' );
};

subtest 'delete_ha_cluster_license', sub {
    my $client = setup();

    local *{'LWP::UserAgent::delete'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/system/licenses" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp = $client->delete_ha_cluster_license( 'hash1', 'hash2' );
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/system/licenses|, 'requsted URL looks sane' );
};

subtest 'version_and_addons_information', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->version_and_addons_information();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'get_reverse_proxy_configuration', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_reverse_proxy_configuration();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'update_reverse_proxy_configuration', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my %data = (
        key           => "nginx",
        webServerType => "NGINX",
        sslPort       => 443,
        httpPort      => 76
    );
    my $resp = $client->update_reverse_proxy_configuration(%data);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'get_reverse_proxy_snippet', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_reverse_proxy_snippet();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'execute_plugin_code', sub {
    my $client         = setup();
    my $execution_name = 'cleanup';
    my $params         = {
        suffix => ['SNAPSHOT'],
        types  => [ 'jar', 'war', 'zip' ],
    };
    my $async = { async => 1 };

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_202};
    };
    my $resp = $client->execute_plugin_code( $execution_name, $params, $async );
    is( $resp->code, 202, 'request succeeded' );
};

subtest 'retrieve_all_available_plugin_info', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->retrieve_all_available_plugin_info();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'retrieve_plugin_info_of_a_certain_type', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->retrieve_plugin_info_of_a_certain_type('staging');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'retrieve_build_staging_strategy', sub {
    my $client = setup();
    my %args   = (
        strategyName => 'strategy1',
        buildName    => 'build1',
        types        => [ 'jar', 'war', 'zip' ]
    );

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->retrieve_build_staging_strategy(%args);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'execute_build_promotion', sub {
    my $client = setup();
    my %args   = (
        promotionName => 'promotion1',
        buildName     => 'build1',
        buildNumber   => 3,
        types         => [ 'jar', 'war', 'zip' ],
    );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o =
"http://example.com:7777/artifactory/api/plugins/build/promote/promotion1/build1/3"
                                );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->execute_build_promotion(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/plugins/build/promote/promotion1/build1/3|, 'requsted URL looks sane' );
};

subtest 'reload_plugins', sub {
    my $client = setup();

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do {
                                \( my $o = "http://example.com:7777/artifactory/api/plugins/reload" );
                            },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->reload_plugins();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/plugins/reload|, 'requested URL looks sane' );
};

subtest 'import_repository_content', sub {
    my $client = setup();
    my %args   = (
        path     => 'foobar',
        repo     => 'repo',
        metadata => 1,
        verbose  => 0
    );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/import/repositories?" ) },
                            'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };

    my $resp            = $client->import_repository_content(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/import/repositories?|, 'requsted URL looks sane' );
};

subtest 'import_system_settings_example', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/import/system" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->import_system_settings_example();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/import/system|, 'requsted URL looks sane' );
};

subtest 'full_system_import', sub {
    my $client = setup();
    my %args   = (
        importPath      => '/import/path',
        includeMetadata => 'false',
        verbose         => 'false',
        failOnError     => 'true',
        failIfEmpty     => 'true',
    );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/import/system" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->full_system_import(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/import/system|, 'requsted URL looks sane' );
};

subtest 'export_system_settings_example', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/export/system" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->export_system_settings_example();
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/export/system|, 'requsted URL looks sane' );
};

subtest 'export_system', sub {
    my $client = setup();
    my %args   = (
        exportPath      => '/export/path',
        includeMetadata => 'true',
        createArchive   => 'false',
        bypassFiltering => 'false',
        verbose         => 'false',
        failOnError     => 'true',
        failIfEmpty     => 'true',
        m2              => 'false',
        incremental     => 'false',
        excludeContent  => 'false'
    );

    local *{'LWP::UserAgent::post'} = sub {
        return bless(
            {
                '_request' => bless(
                    {
                        '_uri' => bless(
                            do { \( my $o = "http://example.com:7777/artifactory/api/export/system" ) }, 'URI::http'
                        ),
                    },
                    'HTTP::Request'
                )
            },
            'HTTP::Response'
        );
    };
    my $resp            = $client->export_system(%args);
    my $url_in_response = $resp->request->uri;
    like( $url_in_response, qr|/api/export/system|, 'requsted URL looks sane' );
};

subtest 'ignore_xray_alert', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->ignore_xray_alert('/foo');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'allow_download_of_blocked_artifacts', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->allow_download_of_blocked_artifacts('true');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'allow_download_when_xray_is_unavailable', sub {
    my $client = setup();
    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->allow_download_when_xray_is_unavailable('true');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'create_bundle', sub {
    my $client = setup();
    my %data   = ();

    local *{'LWP::UserAgent::post'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->create_bundle(%data);
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'list_bundles', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->list_bundles();
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'get_bundle', sub {
    my $client = setup();

    local *{'LWP::UserAgent::get'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->get_bundle('foobar');
    is( $resp->code, 200, 'request succeeded' );
};

subtest 'delete_bundle', sub {
    my $client = setup();

    local *{'LWP::UserAgent::delete'} = sub {
        return $mock_responses{http_200};
    };
    my $resp = $client->delete_bundle('foobar');
    is( $resp->code, 200, 'request succeeded' );
};

done_testing();

sub setup {
    my $args = {
        artifactory => $artifactory,
        port        => $port,
        repository  => $repository,
    };
    return Artifactory::Client->new($args);
}
