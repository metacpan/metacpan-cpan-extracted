package Artifactory::Client;

use strict;
use warnings FATAL => 'all';

use Moose;

use Data::Dumper;
use URI;
use JSON::MaybeXS;
use LWP::UserAgent;
use Path::Tiny qw();
use MooseX::StrictConstructor;
use URI::Escape qw(uri_escape);
use File::Basename qw(basename);
use HTTP::Request::StreamingUpload;

use namespace::autoclean;

=head1 NAME

Artifactory::Client - Perl client for Artifactory REST API

=head1 VERSION

Version 1.5.2

=cut

our $VERSION = 'v1.5.2';

=head1 SYNOPSIS

This is a Perl client for Artifactory REST API:
https://www.jfrog.com/confluence/display/RTF/Artifactory+REST+API Every public method provided in this module returns a
HTTP::Response object.

    use Artifactory::Client;

    my $h = HTTP::Headers->new();
    $h->authorization_basic( 'admin', 'password' );
    my $ua = LWP::UserAgent->new( default_headers => $h );

    my $args = {
        artifactory  => 'http://artifactory.server.com',
        port         => 8080,
        repository   => 'myrepository',
        context_root => '/', # Context root for artifactory. Defaults to 'artifactory'.
        ua           => $ua  # Dropping in custom UA with default_headers set.  Default is a plain LWP::UserAgent.
    };

    my $client = Artifactory::Client->new( $args );
    my $path = '/foo'; # path on artifactory

    # Properties are a hashref of key-arrayref pairs.  Note that value must be an arrayref even for a single element.
    # This is to conform with Artifactory which treats property values as a list.
    my $properties = {
        one => ['two'],
        baz => ['three'],
    };
    my $file = '/local/file.xml';

    # Name of methods are taken straight from Artifactory REST API documentation.  'Deploy Artifact' would map to
    # deploy_artifact method, like below.  The caller gets HTTP::Response object back.
    my $resp = $client->deploy_artifact( path => $path, properties => $properties, file => $file );

    # Custom requests can also be made via usual get / post / put / delete requests.
    my $resp = $client->get( 'http://artifactory.server.com/path/to/resource' );

    # Repository override for calls that have a repository in the endpoint.  The passed-in repository will not persist.
    my $resp = $client->calculate_yum_repository_metadata( repository => 'different_repo', async => 1 );

=cut

=head1 Dev Env Setup / Running Tests

    carton install

    # to run unit tests
    prove -r t

=cut

has 'artifactory' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    writer   => '_set_artifactory',
);

has 'port' => (
    is      => 'ro',
    isa     => 'Int',
    default => 80,
);

has 'context_root' => (
    is      => 'ro',
    isa     => 'Str',
    default => 'artifactory',
);

has 'ua' => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    builder => '_build_ua',
    lazy    => 1,
);

has 'repository' => (
    is      => 'ro',
    isa     => 'Str',
    default => '',
    writer  => '_set_repository',
);

has '_json' => (
    is      => 'ro',
    builder => '_build_json',
    lazy    => 1,
);

has '_api_url' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    writer   => '_set_api_url',
);

has '_art_url' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    writer   => '_set_art_url',
);

sub BUILD {
    my ($self) = @_;

    # Save URIs
    my $uri = URI->new( $self->artifactory() );
    $uri->port( $self->port );
    my $context_root = $self->context_root();
    $context_root = '' if ( $context_root eq '/' );

    $uri->path_segments( $context_root, );
    my $_art_url = $uri->canonical()->as_string();
    $_art_url =~ s{\/$}{}xi;
    $self->_set_art_url($_art_url);

    $uri->path_segments( $context_root, 'api' );
    $self->_set_api_url( $uri->canonical()->as_string() );

    # Save Repository
    my $repo = $self->repository;
    $repo =~ s{^\/}{}xi;
    $repo =~ s{\/$}{}xi;
    $self->_set_repository($repo);

    return 1;
}

=head1 GENERIC METHODS

=cut

=head2 get( @args )

Invokes GET request on LWP::UserAgent-like object; params are passed through.

=cut

sub get {
    my ( $self, @args ) = @_;
    return $self->_request( 'get', @args );
}

=head2 post( @args )

nvokes POST request on LWP::UserAgent-like object; params are passed through.

=cut

sub post {
    my ( $self, @args ) = @_;
    return $self->_request( 'post', @args );
}

=head2 put( @args )

Invokes PUT request on LWP::UserAgent-like object; params are passed through.

=cut

sub put {
    my ( $self, @args ) = @_;
    return $self->_request( 'put', @args );
}

=head2 delete( @args )

Invokes DELETE request on LWP::UserAgent-like object; params are passed
through.

=cut

sub delete {
    my ( $self, @args ) = @_;
    return $self->_request( 'delete', @args );
}

=head2 request( @args )

Invokes request() on LWP::UserAgent-like object; params are passed through.

=cut

sub request {
    my ( $self, @args ) = @_;
    return $self->_request( 'request', @args );
}

=head1 BUILDS

=cut

=head2 all_builds

Retrieves information on all builds from artifactory.

=cut

sub all_builds {
    my $self = shift;
    return $self->_get_build('');
}

=head2 build_runs( $build_name )

Retrieves information of a particular build from artifactory.

=cut

sub build_runs {
    my ( $self, $build ) = @_;
    return $self->_get_build($build);
}

=head2 build_upload( $path_to_json )

Upload Build

=cut

sub build_upload {
    my ( $self, $json_file ) = @_;

    open( my $fh, '<', $json_file );
    chomp( my @lines = <$fh> );
    my $json_input = join( "", @lines );
    my $data       = $self->_json->decode($json_input);
    my $url        = $self->_api_url() . "/build";
    return $self->put(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode($data)
    );
}

=head2 build_info( $build_name, $build_number )

Retrieves information of a particular build number.

=cut

sub build_info {
    my ( $self, $build, $number ) = @_;
    return $self->_get_build("$build/$number");
}

=head2 builds_diff( $build_name, $new_build_number, $old_build_number )

Retrieves diff of 2 builds

=cut

sub builds_diff {
    my ( $self, $build, $new, $old ) = @_;
    return $self->_get_build("$build/$new?diff=$old");
}

=head2 build_promotion( $build_name, $build_number, $payload )

Promotes a build by POSTing payload

=cut

sub build_promotion {
    my ( $self, $build, $number, $payload ) = @_;

    my $url = $self->_api_url() . "/build/promote/$build/$number";
    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode($payload)
    );
}

=head2 promote_docker_image( targetRepo => "target_repo", dockerRepository => "dockerRepository", tag => "tag", copy => 'false' )

Promotes a Docker image from one repository to another

=cut

sub promote_docker_image {
    my ( $self, %args ) = @_;

    my $repo = $args{repository} || $self->repository();
    my $url = $self->_api_url() . "/docker/$repo/v2/promote";
    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode( \%args )
    );
}

=head2 delete_builds( name => $build_name, buildnumbers => [ buildnumbers ], artifacts => 0,1, deleteall => 0,1 )

Removes builds stored in Artifactory. Useful for cleaning up old build info data

=cut

sub delete_builds {
    my ( $self, %args ) = @_;
    my $build        = $args{name};
    my $buildnumbers = $args{buildnumbers};
    my $artifacts    = $args{artifacts};
    my $deleteall    = $args{deleteall};

    my $url = $self->_api_url() . "/build/$build";
    my @params = $self->_gather_delete_builds_params( $buildnumbers, $artifacts, $deleteall );

    if (@params) {
        $url .= "?";
        $url .= join( "&", @params );
    }
    return $self->delete($url);
}

=head2 build_rename( $build_name, $new_build_name )

Renames a build

=cut

sub build_rename {
    my ( $self, $build, $new_build ) = @_;

    my $url = $self->_api_url() . "/build/rename/$build?to=$new_build";
    return $self->post($url);
}

=head2 distribute_build( 'build_name', $build_number, %hash_of_json_payload )

Deploys builds from Artifactory to Bintray, and creates an entry in the corresponding Artifactory distribution
repository specified.

=cut

sub distribute_build {
    my ( $self, $build_name, $build_number, %args ) = @_;

    my $url = $self->_api_url() . "/build/distribute/$build_name/$build_number";
    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%args )
    );
}

=head2 control_build_retention( 'build_name', deleteBuildArtifacts => 'true', count => 100, ... )

Specifies retention parameters for build info.

=cut

sub control_build_retention {
    my ( $self, $build_name, %args ) = @_;

    my $url = $self->_api_url() . "/build/retention/$build_name";
    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%args )
    );
}

=head1 ARTIFACTS & STORAGE

=cut

=head2 folder_info( $path )

Returns folder info

=cut

sub folder_info {
    my ( $self, $path ) = @_;

    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/storage/$path";

    return $self->get($url);
}

=head2 file_info( $path )

Returns file info

=cut

sub file_info {
    my ( $self, $path ) = @_;
    return $self->folder_info($path);    # should be OK to do this
}

=head2 get_storage_summary_info

Returns storage summary information regarding binaries, file store and repositories

=cut

sub get_storage_summary_info {
    my $self = shift;
    my $url  = $self->_api_url() . '/storageinfo';
    return $self->get($url);
}

=head2 item_last_modified( $path )

Returns item_last_modified for a given path

=cut

sub item_last_modified {
    my ( $self, $path ) = @_;
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/storage/$path?lastModified";
    return $self->get($url);
}

=head2 file_statistics( $path )

Returns file_statistics for a given path

=cut

sub file_statistics {
    my ( $self, $path ) = @_;
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/storage/$path?stats";
    return $self->get($url);
}

=head2 item_properties( path => $path, properties => [ key_names ] )

Takes path and properties then get item properties.

=cut

sub item_properties {
    my ( $self, %args ) = @_;

    my $path       = $args{path};
    my $properties = $args{properties};

    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/storage/$path?properties";

    if ( ref($properties) eq 'ARRAY' ) {
        my $str = join( ',', @{$properties} );
        $url .= "=" . $str;
    }
    return $self->get($url);
}

=head2 set_item_properties( path => $path, properties => { key => [ values ] }, recursive => 0,1 )

Takes path and properties then set item properties.  Supply recursive => 0 if you want to suppress propagation of
properties downstream.  Note that properties are a hashref with key-arrayref pairs, such as:

    $prop = { key1 => ['a'], key2 => ['a', 'b'] }

=cut

sub set_item_properties {
    my ( $self, %args ) = @_;

    my $path       = $args{path};
    my $properties = $args{properties};
    my $recursive  = $args{recursive};

    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/storage/$path?properties=";

    my $request = $url . $self->_attach_properties( properties => $properties );
    $request .= "&recursive=$recursive" if ( defined $recursive );
    return $self->put($request);
}

=head2 delete_item_properties( path => $path, properties => [ key_names ], recursive => 0,1 )

Takes path and properties then delete item properties.  Supply recursive => 0 if you want to suppress propagation of
properties downstream.

=cut

sub delete_item_properties {
    my ( $self, %args ) = @_;

    my $path       = $args{path};
    my $properties = $args{properties};
    my $recursive  = $args{recursive};

    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/storage/$path?properties=" . join( ",", @{$properties} );
    $url .= "&recursive=$recursive" if ( defined $recursive );
    return $self->delete($url);
}

=head2 set_item_sha256_checksum( repoKey => 'foo', path => 'bar' )

Calculates an artifact's SHA256 checksum and attaches it as a property (with key "sha256"). If the artifact is a folder,
then recursively calculates the SHA256 of each item in the folder and attaches the property to each item.

=cut

sub set_item_sha256_checksum {
    my ( $self, %args ) = @_;
    my $url = $self->_api_url() . '/checksum/sha256';
    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode( \%args )
    );
}

=head2 retrieve_artifact( $path, $filename )

Takes path and retrieves artifact on the path.  If $filename is given, artifact content goes into the $filename rather
than the HTTP::Response object.

=cut

sub retrieve_artifact {
    my ( $self, $path, $filename ) = @_;
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_art_url() . "/$path";
    return ($filename)
      ? $self->get( $url, ":content_file" => $filename )
      : $self->get($url);
}

=head2 retrieve_latest_artifact( path => $path, version => $version, release => $release, integration => $integration,
 flag => 'snapshot', 'release', 'integration' )

Takes path, version, flag of 'snapshot', 'release' or 'integration' and retrieves artifact

=cut

sub retrieve_latest_artifact {
    my ( $self, %args ) = @_;

    my $path        = $args{path};
    my $version     = $args{version};
    my $release     = $args{release};
    my $integration = $args{integration};
    my $flag        = $args{flag};
    $path = $self->_merge_repo_and_path($path);

    my $base_url = $self->_art_url() . "/$path";
    my $basename = basename($path);
    my $url;
    $url = "$base_url/$version-SNAPSHOT/$basename-$version-SNAPSHOT.jar" if ( $version && $flag eq 'snapshot' );
    $url = "$base_url/$release/$basename-$release.jar"                   if ( $flag eq 'release' );
    $url = "$base_url/$version-$integration/$basename-$version-$integration.jar"
      if ( $version && $flag eq 'integration' );
    return $self->get($url);
}

=head2 retrieve_build_artifacts_archive( $payload )

Takes payload (hashref) then retrieve build artifacts archive.

=cut

sub retrieve_build_artifacts_archive {
    my ( $self, $payload ) = @_;

    my $url = $self->_api_url() . "/archive/buildArtifacts";
    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode($payload)
    );
}

=head2 retrieve_folder_or_repository_archive( path => '/foobar', archiveType => 'zip' )

Retrieves an archive file (supports zip/tar/tar.gz/tgz) containing all the artifacts that reside under the specified
path (folder or repository root). Requires Enable Folder Download to be set.

=cut

sub retrieve_folder_or_repository_archive {
    my ( $self, %args ) = @_;
    my $path = delete $args{path};
    my $url = $self->_api_url() . '/archive/download' . $path . '?' . $self->_stringify_hash( '', %args );
    return $self->get($url);
}

=head2 trace_artifact_retrieval( $path )

Takes path and traces artifact retrieval

=cut

sub trace_artifact_retrieval {
    my ( $self, $path ) = @_;
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_art_url() . "/$path?trace";
    return $self->get($url);
}

=head2 archive_entry_download( $path, $archive_path )

Takes path and archive_path, retrieves an archived resource from the specified archive destination.

=cut

sub archive_entry_download {
    my ( $self, $path, $archive_path ) = @_;
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_art_url() . "/$path!$archive_path";
    return $self->get($url);
}

=head2 create_directory( path => $path, properties => { key => [ values ] } )

Takes path, properties then create a directory.  Directory needs to end with a /, such as "/some_dir/".

=cut

sub create_directory {
    my ( $self, %args ) = @_;
    return $self->deploy_artifact(%args);
}

=head2 deploy_artifact( path => $path, properties => { key => [ values ] }, file => $file )

Takes path on Artifactory, properties and filename then deploys the file.  Note that properties are a hashref with
key-arrayref pairs, such as:

    $prop = { key1 => ['a'], key2 => ['a', 'b'] }

=cut

sub deploy_artifact {
    my ( $self, %args ) = @_;

    my $path       = $args{path};
    my $properties = $args{properties};
    my $file       = $args{file};
    my $header     = $args{header};

    $path = $self->_merge_repo_and_path($path);
    my @joiners = ( $self->_art_url() . "/$path" );
    my $props = $self->_attach_properties( properties => $properties, matrix => 1 );
    push @joiners, $props if ($props);    # if properties aren't passed in, the function returns empty string

    my $url = join( ";", @joiners );
    my $req = HTTP::Request::StreamingUpload->new(
        PUT     => $url,
        headers => HTTP::Headers->new( %{$header} ),
        ( $file ? ( fh => Path::Tiny::path($file)->openr_raw() ) : () ),
    );
    return $self->request($req);
}

=head2 deploy_artifact_by_checksum( path => $path, properties => { key => [ values ] }, file => $file, sha1 => $sha1 )

Takes path, properties, filename and sha1 then deploys the file.  Note that properties are a hashref with key-arrayref
pairs, such as:

    $prop = { key1 => ['a'], key2 => ['a', 'b'] }

=cut

sub deploy_artifact_by_checksum {
    my ( $self, %args ) = @_;

    my $sha1   = $args{sha1};
    my $header = {
        'X-Checksum-Deploy' => 'true',
        'X-Checksum-Sha1'   => $sha1,
    };
    $args{header} = $header;
    return $self->deploy_artifact(%args);
}

=head2 deploy_artifacts_from_archive( path => $path, file => $file )

Path is the path on Artifactory, file is path to local archive.  Will deploy $file to $path.

=cut

sub deploy_artifacts_from_archive {
    my ( $self, %args ) = @_;

    my $header = { 'X-Explode-Archive' => 'true', };
    $args{header} = $header;
    return $self->deploy_artifact(%args);
}

=head2 push_a_set_of_artifacts_to_bintray( descriptor => 'foo', gpgPassphrase => 'top_secret', gpgSign => 'true' )

Push a set of artifacts to Bintray as a version.  Uses a descriptor file (that must have 'bintray-info' in it's filename
and a .json extension) that was deployed to artifactory, the call accepts the full path to the descriptor as a
parameter.

=cut

sub push_a_set_of_artifacts_to_bintray {
    my ( $self, %args ) = @_;

    my $url = $self->_api_url() . "/bintray/push";
    my $params = $self->_stringify_hash( '&', %args );
    $url .= "?" . $params if ($params);
    return $self->post($url);
}

=head2 push_docker_tag_to_bintray( dockerImage => 'jfrog/ubuntu:latest', async => 'true', ... )

Push Docker tag to Bintray.  Calculation can be synchronous (the default) or asynchronous.  You will need to enter your
Bintray credentials, for more details, please refer to Entering your Bintray credentials.

=cut

sub push_docker_tag_to_bintray {
    my ( $self, %args ) = @_;

    my $url = $self->_api_url() . '/bintray/docker/push/' . $self->repository();
    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode( \%args )
    );
}

=head2 distribute_artifact( publish => 'true', async => 'false' )

Deploys artifacts from Artifactory to Bintray, and creates an entry in the corresponding Artifactory distribution
repository specified

=cut

sub distribute_artifact {
    my ( $self, %args ) = @_;

    my $url = $self->_api_url() . '/distribute';
    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode( \%args )
    );
}

=head2 file_compliance_info( $path )

Retrieves file compliance info of a given path.

=cut

sub file_compliance_info {
    my ( $self, $path ) = @_;
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/compliance/$path";
    return $self->get($url);
}

=head2 delete_item( $path )

Delete $path on artifactory.

=cut

sub delete_item {
    my ( $self, $path ) = @_;
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_art_url() . "/$path";
    return $self->delete($url);
}

=head2 copy_item( from => $from, to => $to, dry => 1, suppressLayouts => 0/1, failFast => 0/1 )

Copies an artifact from $from to $to.  Note that for this particular API call, the $from and $to must include repository
names as copy source and destination may be different repositories.  You can also supply dry, suppressLayouts and
failFast values as specified in the documentation.

=cut

sub copy_item {
    my ( $self, %args ) = @_;
    $args{method} = 'copy';
    return $self->_handle_item(%args);
}

=head2 move_item( from => $from, to => $to, dry => 1, suppressLayouts => 0/1, failFast => 0/1 )

Moves an artifact from $from to $to.  Note that for this particular API call, the $from and $to must include repository
names as copy source and destination may be different repositories.  You can also supply dry, suppressLayouts and
failFast values as specified in the documentation.

=cut

sub move_item {
    my ( $self, %args ) = @_;
    $args{method} = 'move';
    return $self->_handle_item(%args);
}

=head2 get_repository_replication_configuration

Get repository replication configuration

=cut

sub get_repository_replication_configuration {
    my $self = shift;
    return $self->_handle_repository_replication_configuration('get');
}

=head2 set_repository_replication_configuration( $payload )

Set repository replication configuration

=cut

sub set_repository_replication_configuration {
    my ( $self, $payload ) = @_;
    return $self->_handle_repository_replication_configuration( 'put', $payload );
}

=head2 update_repository_replication_configuration( $payload )

Update repository replication configuration

=cut

sub update_repository_replication_configuration {
    my ( $self, $payload ) = @_;
    return $self->_handle_repository_replication_configuration( 'post', $payload );
}

=head2 delete_repository_replication_configuration

Delete repository replication configuration

=cut

sub delete_repository_replication_configuration {
    my $self = shift;
    return $self->_handle_repository_replication_configuration('delete');
}

=head2 scheduled_replication_status

Gets scheduled replication status of a repository

=cut

sub scheduled_replication_status {
    my ( $self, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    my $url = $self->_api_url() . "/replication/$repository";
    return $self->get($url);
}

=head2 pull_push_replication( payload => $payload, path => $path )

Schedules immediate content replication between two Artifactory instances

=cut

sub pull_push_replication {
    my ( $self, %args ) = @_;
    my $payload = $args{payload};
    my $path    = $args{path};
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/replication/execute/$path";
    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode($payload)
    );
}

=head2 create_or_replace_local_multi_push_replication( $payload )

Creates or replaces a local multi-push replication configuration. Supported by local and local-cached repositories

=cut

sub create_or_replace_local_multi_push_replication {
    my ( $self, $payload ) = @_;
    return $self->_handle_multi_push_replication( $payload, 'put' );
}

=head2 update_local_multi_push_replication( $payload )

Updates a local multi-push replication configuration. Supported by local and local-cached repositories

=cut

sub update_local_multi_push_replication {
    my ( $self, $payload ) = @_;
    return $self->_handle_multi_push_replication( $payload, 'post' );
}

=head2 delete_local_multi_push_replication( $url )

Deletes a local multi-push replication configuration. Supported by local and local-cached repositories

=cut

sub delete_local_multi_push_replication {
    my ( $self, $url, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    my $call_url = $self->_api_url() . "/replications/$repository?url=$url";
    return $self->delete($call_url);
}

=head2 enable_or_disable_multiple_replications( 'enable|disable', include => [ ], exclude => [ ] )

Enables/disables multiple replication tasks by repository or Artifactory server based in include and exclude patterns.

=cut

sub enable_or_disable_multiple_replications {
    my ( $self, $flag, %args ) = @_;
    my $url = $self->_api_url() . "/replications/$flag";
    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode( \%args )
    );
}

=head2 get_global_system_replication_configuration

Returns the global system replication configuration status, i.e. if push and pull replications are blocked or unblocked.

=cut

sub get_global_system_replication_configuration {
    my $self = shift;
    my $url  = $self->_api_url() . "/system/replications";
    return $self->get($url);
}

=head2 block_system_replication( push => 'false', pull => 'true' )

Blocks replications globally. Push and pull are true by default. If false, replication for the corresponding type is not
blocked.

=cut

sub block_system_replication {
    my ( $self, %args ) = @_;
    return $self->_handle_block_system_replication( 'block', %args );
}

=head2 unblock_system_replication( push => 'false', pull => 'true' )

Unblocks replications globally. Push and pull are true by default. If false, replication for the corresponding type is
not unblocked.

=cut

sub unblock_system_replication {
    my ( $self, %args ) = @_;
    return $self->_handle_block_system_replication( 'unblock', %args );
}

=head2 artifact_sync_download( $path, content => 'progress', mark => 1000 )

Downloads an artifact with or without returning the actual content to the client. When tracking the progress marks are
printed (by default every 1024 bytes). This is extremely useful if you want to trigger downloads on a remote Artifactory
server, for example to force eager cache population of large artifacts, but want to avoid the bandwidth consumption
involved in transferring the artifacts to the triggering client. If no content parameter is specified the file content
is downloaded to the client.

=cut

sub artifact_sync_download {
    my ( $self, $path, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    my $url = $self->_api_url() . "/download/$repository" . $path;
    $url .= "?" . $self->_stringify_hash( '&', %args ) if (%args);
    return $self->get($url);
}

=head2 file_list( $dir, %opts )

Get a flat (the default) or deep listing of the files and folders (not included by default) within a folder

=cut

sub file_list {
    my ( $self, $dir, %opts ) = @_;
    $dir = $self->_merge_repo_and_path($dir);
    my $url = $self->_api_url() . "/storage/$dir?list";

    for my $opt ( keys %opts ) {
        my $val = $opts{$opt};
        $url .= "&${opt}=$val";
    }
    return $self->get($url);
}

=head2 get_background_tasks

Retrieves list of background tasks currently scheduled or running in Artifactory. In HA, the nodeId is added to each
task. Task can be in one of few states: scheduled, running, stopped, canceled. Running task also shows the task start
time.

=cut

sub get_background_tasks {
    my $self = shift;
    my $url  = $self->_api_url() . "/tasks";
    return $self->get($url);
}

=head2 empty_trash_can

Empties the trash can permanently deleting all its current contents.

=cut

sub empty_trash_can {
    my $self = shift;
    my $url  = $self->_api_url() . "/trash/empty";
    return $self->post($url);
}

=head2 delete_item_from_trash_can($path)

Permanently deletes an item from the trash can.

=cut

sub delete_item_from_trash_can {
    my ( $self, $path ) = @_;
    my $url = $self->_api_url() . "/trash/$path";
    return $self->delete($url);
}

=head2 restore_item_from_trash_can( $from, $to )

Restore an item from the trash can.

=cut

sub restore_item_from_trash_can {
    my ( $self, $from, $to ) = @_;
    my $url = $self->_api_url() . "/trash/restore/$from?to=$to";
    return $self->post($url);
}

=head2 optimize_system_storage

Raises a flag to invoke balancing between redundant storage units of a sharded filestore following the next garbage
collection.

=cut

sub optimize_system_storage {
    my $self = shift;
    my $url  = $self->_api_url() . "/system/storage/optimize";
    return $self->post($url);
}

=head1 SEARCHES

=cut

=head2 artifactory_query_language( $aql_statement )

Flexible and high performance search using Artifactory Query Language (AQL).

=cut

sub artifactory_query_language {
    my ( $self, $aql ) = @_;

    my $url = $self->_api_url() . "/search/aql";
    return $self->post(
        $url,
        "Content-Type" => 'text/plain',
        Content        => $aql
    );
}

=head2 artifact_search( name => $name, repos => [ @repos ], result_detail => [qw(info properties)], )

Artifact search by part of file name

=cut

sub artifact_search {
    my ( $self, %args ) = @_;
    return $self->_handle_search( 'artifact', %args );
}

=head2 archive_entry_search( name => $name, repos => [ @repos ] )

Search archive entries for classes or any other jar resources

=cut

sub archive_entry_search {
    my ( $self, %args ) = @_;
    return $self->_handle_search( 'archive', %args );
}

=head2 gavc_search( g => 'foo', c => 'bar', result_detail => [qw(info properties)], )

Search by Maven coordinates: groupId, artifactId, version & classifier

=cut

sub gavc_search {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'gavc', %args );
}

=head2 property_search( p => [ 'v1', 'v2' ], repos => [ 'repo1', 'repo2' ], result_detail => [qw(info properties)], )

Search by properties

=cut

sub property_search {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'prop', %args );
}

=head2 checksum_search( md5 => '12345', repos => [ 'repo1', 'repo2' ], result_detail => [qw(info properties)], )

Artifact search by checksum (md5 or sha1)

=cut

sub checksum_search {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'checksum', %args );
}

=head2 bad_checksum_search( type => 'md5', repos => [ 'repo1', 'repo2' ]  )

Find all artifacts that have a bad or missing client checksum values (md5 or
sha1)

=cut

sub bad_checksum_search {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'badChecksum', %args );
}

=head2 artifacts_not_downloaded_since( notUsedSince => 12345, createdBefore => 12345, repos => [ 'repo1', 'repo2' ] )

Retrieve all artifacts not downloaded since the specified Java epoch in msec.

=cut

sub artifacts_not_downloaded_since {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'usage', %args );
}

=head2 artifacts_with_date_in_date_range( from => 12345, repos => [ 'repo1', 'repo2' ], dateFields => [ 'created' ] )

Get all artifacts with specified dates within the given range. Search can be limited to specific repositories (local or
caches).

=cut

sub artifacts_with_date_in_date_range {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'dates', %args );
}

=head2 artifacts_created_in_date_range( from => 12345, to => 12345, repos => [ 'repo1', 'repo2' ] )

Get all artifacts created in date range

=cut

sub artifacts_created_in_date_range {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'creation', %args );
}

=head2 pattern_search( $pattern )

Get all artifacts matching the given Ant path pattern

=cut

sub pattern_search {
    my ( $self, $pattern, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    my $url = $self->_api_url() . "/search/pattern?pattern=$repository:$pattern";
    return $self->get($url);
}

=head2 builds_for_dependency( sha1 => 'abcde' )

Find all the builds an artifact is a dependency of (where the artifact is included in the build-info dependencies)

=cut

sub builds_for_dependency {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'dependency', %args );
}

=head2 license_search( unapproved => 1, unknown => 1, notfound => 0, neutral => 0, repos => [ 'foo', 'bar' ] )

Search for artifacts with specified statuses

=cut

sub license_search {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'license', %args );
}

=head2 artifact_version_search( g => 'foo', a => 'bar', v => '1.0', repos => [ 'foo', 'bar' ] )

Search for all available artifact versions by GroupId and ArtifactId in local, remote or virtual repositories

=cut

sub artifact_version_search {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'versions', %args );
}

=head2 artifact_latest_version_search_based_on_layout( g => 'foo', a => 'bar', v => '1.0', repos => [ 'foo', 'bar' ] )

Search for the latest artifact version by groupId and artifactId, based on the layout defined in the repository

=cut

sub artifact_latest_version_search_based_on_layout {
    my ( $self, %args ) = @_;
    return $self->_handle_search_props( 'latestVersion', %args );
}

=head2 artifact_latest_version_search_based_on_properties( repo => '_any', path => '/a/b', listFiles => 1 )

Search for artifacts with the latest value in the "version" property

=cut

sub artifact_latest_version_search_based_on_properties {
    my ( $self, %args ) = @_;
    my $repo = delete $args{repo};
    my $path = delete $args{path};

    $repo =~ s{^\/}{}xi;
    $repo =~ s{\/$}{}xi;

    $path =~ s{^\/}{}xi;
    $path =~ s{\/$}{}xi;

    my $url = $self->_api_url() . "/versions/$repo/$path?";
    $url .= $self->_stringify_hash( '&', %args );
    return $self->get($url);
}

=head2 build_artifacts_search( buildNumber => 15, buildName => 'foobar' )

Find all the artifacts related to a specific build

=cut

sub build_artifacts_search {
    my ( $self, %args ) = @_;

    my $url = $self->_api_url() . "/search/buildArtifacts";
    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%args )
    );
}

=head2 list_docker_repositories( n => 5, last => 'last_tag_value' )

Lists all Docker repositories hosted in under an Artifactory Docker repository.

=cut

sub list_docker_repositories {
    my ( $self, %args ) = @_;
    my $repository = delete $args{repository} || $self->repository();
    my $url = $self->_api_url() . "/docker/$repository/v2/_catalog";
    $url .= '?' . $self->_stringify_hash( '&', %args ) if (%args);

    return $self->get($url);
}

=head2 list_docker_tags( $image_name, n => 5, last => 'last_tag_value' )

Lists all tags of the specified Artifactory Docker repository.

=cut

sub list_docker_tags {
    my ( $self, $image_name, %args ) = @_;
    my $repository = delete $args{repository} || $self->repository();
    my $url = $self->_api_url() . "/docker/$repository/v2/$image_name/tags/list";
    $url .= '?' . $self->_stringify_hash( '&', %args ) if (%args);

    return $self->get($url);
}

=head1 SECURITY

=cut

=head2 get_users

Get the users list

=cut

sub get_users {
    my $self = shift;
    return $self->_handle_security( undef, 'get', 'users' );
}

=head2 get_user_details( $user )

Get the details of an Artifactory user

=cut

sub get_user_details {
    my ( $self, $user ) = @_;
    return $self->_handle_security( $user, 'get', 'users' );
}

=head2 get_user_encrypted_password

Get the encrypted password of the authenticated requestor

=cut

sub get_user_encrypted_password {
    my $self = shift;
    return $self->_handle_security( undef, 'get', 'encryptedPassword' );
}

=head2 create_or_replace_user( $user, %args )

Creates a new user in Artifactory or replaces an existing user

=cut

sub create_or_replace_user {
    my ( $self, $user, %args ) = @_;
    return $self->_handle_security( $user, 'put', 'users', %args );
}

=head2 update_user( $user, %args )

Updates an exiting user in Artifactory with the provided user details

=cut

sub update_user {
    my ( $self, $user, %args ) = @_;
    return $self->_handle_security( $user, 'post', 'users', %args );
}

=head2 delete_user( $user )

Removes an Artifactory user

=cut

sub delete_user {
    my ( $self, $user ) = @_;
    return $self->_handle_security( $user, 'delete', 'users' );
}

=head2 expire_password_for_a_single_user( $user )

Expires a user's password

=cut

sub expire_password_for_a_single_user {
    my ( $self, $user ) = @_;
    my $url = $self->_api_url() . "/security/users/authorization/expirePassword/$user";
    return $self->post($url);
}

=head2 expire_password_for_multiple_users( $user1, $user2 )

Expires password for a list of users

=cut

sub expire_password_for_multiple_users {
    my ( $self, @users ) = @_;
    my $url = $self->_api_url() . "/security/users/authorization/expirePassword";
    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( [@users] )
    );
}

=head2 expire_password_for_all_users

Expires password for all users

=cut

sub expire_password_for_all_users {
    my ( $self, @users ) = @_;
    my $url = $self->_api_url() . "/security/users/authorization/expirePasswordForAllUsers";
    return $self->post($url);
}

=head2 unexpire_password_for_a_single_user( $user )

Unexpires a user's password

=cut

sub unexpire_password_for_a_single_user {
    my ( $self, $user ) = @_;
    my $url = $self->_api_url() . "/security/users/authorization/unexpirePassword/$user";
    return $self->post($url);
}

=head2 change_password( user => 'david', oldPassword => 'foo', newPassword => 'bar' )

Changes a user's password

=cut

sub change_password {
    my ( $self, %info ) = @_;
    my $url         = $self->_api_url() . "/security/users/authorization/changePassword";
    my $newpassword = delete $info{newPassword};
    $info{newPassword1} = $newpassword;
    $info{newPassword2} = $newpassword;    # API requires new passwords twice, once for verification

    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%info )
    );
}

=head2 get_password_expiration_policy

Retrieves the password expiration policy

=cut

sub get_password_expiration_policy {
    my $self = shift;
    my $url  = $self->_api_url() . "/security/configuration/passwordExpirationPolicy";
    return $self->get($url);
}

=head2 set_password_expiration_policy

Sets the password expiration policy

=cut

sub set_password_expiration_policy {
    my ( $self, %info ) = @_;
    my $url = $self->_api_url() . "/security/configuration/passwordExpirationPolicy";
    return $self->put(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%info )
    );
}

=head2 configure_user_lock_policy( enabled => 'true|false', loginAttempts => $num )

Configures the user lock policy that locks users out of their account if the number of repeated incorrect login attempts
exceeds the configured maximum allowed.

=cut

sub configure_user_lock_policy {
    my ( $self, %info ) = @_;
    my $url = $self->_api_url() . "/security/userLockPolicy";
    return $self->put(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%info )
    );
}

=head2 retrieve_user_lock_policy

Retrieves the currently configured user lock policy.

=cut

sub retrieve_user_lock_policy {
    my $self = shift;
    my $url  = $self->_api_url() . "/security/userLockPolicy";
    return $self->get($url);
}

=head2 get_locked_out_users

If locking out users is enabled, lists all users that were locked out due to recurrent incorrect login attempts.

=cut

sub get_locked_out_users {
    my $self = shift;
    my $url  = $self->_api_url() . "/security/lockedUsers";
    return $self->get($url);
}

=head2 unlock_locked_out_user

Unlocks a single user that was locked out due to recurrent incorrect login attempts.

=cut

sub unlock_locked_out_user {
    my ( $self, $name ) = @_;
    my $url = $self->_api_url() . "/security/unlockUsers/$name";
    return $self->post($url);
}

=head2 unlock_locked_out_users

Unlocks a list of users that were locked out due to recurrent incorrect login attempts.

=cut

sub unlock_locked_out_users {
    my ( $self, @users ) = @_;
    my $url = $self->_api_url() . "/security/unlockUsers";
    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \@users )
    );
}

=head2 unlock_all_locked_out_users

Unlocks all users that were locked out due to recurrent incorrect login attempts.

=cut

sub unlock_all_locked_out_users {
    my $self = shift;
    my $url  = $self->_api_url() . "/security/unlockAllUsers";
    return $self->post($url);
}

=head2 create_api_key( apiKey => '3OloposOtVFyCMrT+cXmCAScmVMPrSYXkWIjiyDCXsY=' )

Create an API key for the current user

=cut

sub create_api_key {
    my ( $self, %args ) = @_;
    return $self->_handle_api_key( 'post', %args );
}

=head2 get_api_key

Get the current user's own API key

=cut

sub get_api_key {
    my $self = shift;
    return $self->_handle_api_key('get');
}

=head2 revoke_api_key

Revokes the current user's API key

=cut

sub revoke_api_key {
    my $self = shift;
    return $self->_handle_revoke_api_key('/apiKey/auth');
}

=head2 revoke_user_api_key

Revokes the API key of another user

=cut

sub revoke_user_api_key {
    my ( $self, $user ) = @_;
    return $self->_handle_revoke_api_key("/apiKey/auth/$user");
}

=head2 revoke_all_api_keys

Revokes all API keys currently defined in the system

=cut

sub revoke_all_api_keys {
    my ( $self, %args ) = @_;
    my $deleteall = ( defined $args{deleteAll} ) ? $args{deleteAll} : 1;
    return $self->_handle_revoke_api_key("/apiKey?deleteAll=$deleteall");
}

=head2 get_groups

Get the groups list

=cut

sub get_groups {
    my $self = shift;
    return $self->_handle_security( undef, 'get', 'groups' );
}

=head2 get_group_details( $group )

Get the details of an Artifactory Group

=cut

sub get_group_details {
    my ( $self, $group ) = @_;
    return $self->_handle_security( $group, 'get', 'groups' );
}

=head2 create_or_replace_group( $group, %args )

Creates a new group in Artifactory or replaces an existing group

=cut

sub create_or_replace_group {
    my ( $self, $group, %args ) = @_;
    return $self->_handle_security( $group, 'put', 'groups', %args );
}

=head2 update_group( $group, %args )

Updates an exiting group in Artifactory with the provided group details

=cut

sub update_group {
    my ( $self, $group, %args ) = @_;
    return $self->_handle_security( $group, 'post', 'groups', %args );
}

=head2 delete_group( $group )

Removes an Artifactory group

=cut

sub delete_group {
    my ( $self, $group ) = @_;
    return $self->_handle_security( $group, 'delete', 'groups' );
}

=head2 get_permission_targets

Get the permission targets list

=cut

sub get_permission_targets {
    my $self = shift;
    return $self->_handle_security( undef, 'get', 'permissions' );
}

=head2 get_permission_target_details( $name )

Get the details of an Artifactory Permission Target

=cut

sub get_permission_target_details {
    my ( $self, $name ) = @_;
    return $self->_handle_security( $name, 'get', 'permissions' );
}

=head2 create_or_replace_permission_target( $name, %args )

Creates a new permission target in Artifactory or replaces an existing permission target

=cut

sub create_or_replace_permission_target {
    my ( $self, $name, %args ) = @_;
    return $self->_handle_security( $name, 'put', 'permissions', %args );
}

=head2 delete_permission_target( $name )

Deletes an Artifactory permission target

=cut

sub delete_permission_target {
    my ( $self, $name ) = @_;
    return $self->_handle_security( $name, 'delete', 'permissions' );
}

=head2 effective_item_permissions( $path )

Returns a list of effective permissions for the specified item (file or folder)

=cut

sub effective_item_permissions {
    my ( $self, $arg ) = @_;

    my $path = $self->_merge_repo_and_path($arg);
    my $url  = $self->_api_url() . "/storage/$path?permissions";
    return $self->get($url);
}

=head2 security_configuration

Retrieve the security configuration (security.xml)

=cut

sub security_configuration {
    my ( $self, $path ) = @_;

    my $url = $self->_api_url() . "/system/security";
    return $self->get($url);
}

=head2 activate_master_key_encryption

Creates a new master key and activates master key encryption

=cut

sub activate_master_key_encryption {
    my $self = shift;
    my $url  = $self->_api_url() . "/system/encrypt";
    return $self->post($url);
}

=head2 deactivate_master_key_encryption

Removes the current master key and deactivates master key encryption

=cut

sub deactivate_master_key_encryption {
    my $self = shift;
    my $url  = $self->_api_url() . "/system/decrypt";
    return $self->post($url);
}

=head2 set_gpg_public_key( key => $string )

Sets the public key that Artifactory provides to Debian clients to verify packages

=cut

sub set_gpg_public_key {
    my ( $self, %args ) = @_;
    my $key = $args{key};
    return $self->_handle_gpg_key( 'public', 'put', content => $key );
}

=head2 get_gpg_public_key

Gets the public key that Artifactory provides to Debian clients to verify packages

=cut

sub get_gpg_public_key {
    my $self = shift;
    return $self->_handle_gpg_key( 'public', 'get' );
}

=head2 set_gpg_private_key( key => $string )

Sets the private key that Artifactory will use to sign Debian packages

=cut

sub set_gpg_private_key {
    my ( $self, %args ) = @_;
    my $key = $args{key};
    return $self->_handle_gpg_key( 'private', 'put', content => $key );
}

=head2 set_gpg_pass_phrase( $passphrase )

Sets the pass phrase required signing Debian packages using the private key

=cut

sub set_gpg_pass_phrase {
    my ( $self, $pass ) = @_;
    return $self->_handle_gpg_key( 'passphrase', 'put', 'X-GPG-PASSPHRASE' => $pass );
}

=head2 create_token( username => 'johnq', scope => 'member-of-groups:readers' )

Creates an access token

=cut

sub create_token {
    my ( $self, %data ) = @_;
    my $url = $self->_api_url() . "/security/token";
    return $self->post( $url, content => \%data );
}

=head2 refresh_token( grant_type => 'refresh_token', refresh_token => 'fgsg53t3g' )

Refresh an access token to extend its validity. If only the access token and the refresh token are provided (and no
other parameters), this pair is used for authentication. If username or any other parameter is provided, then the
request must be authenticated by a token that grants admin permissions.

=cut

sub refresh_token {
    my ( $self, %data ) = @_;
    return $self->create_token(%data);
}

=head2 revoke_token( token => 'fgsg53t3g' )

Revoke an access token

=cut

sub revoke_token {
    my ( $self, %data ) = @_;
    my $url = $self->_api_url() . "/security/token/revoke";
    return $self->post( $url, content => \%data );
}

=head2 get_service_id

Provides the service ID of an Artifactory instance or cluster

=cut

sub get_service_id {
    my $self = shift;
    my $url  = $self->_api_url() . "/system/service_id";
    return $self->get($url);
}

=head2 get_certificates

Returns a list of installed SSL certificates.

=cut

sub get_certificates {
    my $self = shift;
    my $url  = $self->_api_url() . "/system/security/certificates";
    return $self->get($url);
}

=head2 add_certificate( $alias, $file_path )

Adds an SSL certificate.

=cut

sub add_certificate {
    my ( $self, $alias, $file ) = @_;
    my $url  = $self->_api_url() . "/system/security/certificates/$alias";
    my $data = Path::Tiny::path($file)->slurp();
    return $self->post( $url, 'Content-Type' => 'application/text', content => $data );
}

=head2 delete_certificate( $alias )

Deletes an SSL certificate.

=cut

sub delete_certificate {
    my ( $self, $alias ) = @_;
    my $url = $self->_api_url() . "/system/security/certificates/$alias";
    return $self->delete($url);
}

=head1 REPOSITORIES

=cut

=head2 get_repositories( $type )

Returns a list of minimal repository details for all repositories of the specified type

=cut

sub get_repositories {
    my ( $self, $type ) = @_;

    my $url = $self->_api_url() . "/repositories";
    $url .= "?type=$type" if ($type);

    return $self->get($url);
}

=head2 repository_configuration( $name, %args )

Retrieves the current configuration of a repository

=cut

sub repository_configuration {
    my ( $self, $repo, %args ) = @_;

    $repo =~ s{^\/}{}xi;
    $repo =~ s{\/$}{}xi;

    my $url =
      (%args)
      ? $self->_api_url() . "/repositories/$repo?"
      : $self->_api_url() . "/repositories/$repo";
    $url .= $self->_stringify_hash( '&', %args ) if (%args);
    return $self->get($url);
}

=head2 create_or_replace_repository_configuration( $name, \%payload, %args )

Creates a new repository in Artifactory with the provided configuration or replaces the configuration of an existing
repository

=cut

sub create_or_replace_repository_configuration {
    my ( $self, $repo, $payload, %args ) = @_;
    return $self->_handle_repositories( $repo, $payload, 'put', %args );
}

=head2 update_repository_configuration( $name, \%payload )

Updates an exiting repository configuration in Artifactory with the provided configuration elements

=cut

sub update_repository_configuration {
    my ( $self, $repo, $payload ) = @_;
    return $self->_handle_repositories( $repo, $payload, 'post' );
}

=head2 delete_repository( $name )

Removes a repository configuration together with the whole repository content

=cut

sub delete_repository {
    my ( $self, $repo ) = @_;
    return $self->_handle_repositories( $repo, undef, 'delete' );
}

=head2 calculate_yum_repository_metadata( async => 0/1 )

Calculates/recalculates the YUM metdata for this repository, based on the RPM package currently hosted in the repository

=cut

sub calculate_yum_repository_metadata {
    my ( $self, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    return $self->_handle_repository_reindex( "/yum/$repository", %args );
}

=head2 calculate_nuget_repository_metadata

Recalculates all the NuGet packages for this repository (local/cache/virtual), and re-annotate the NuGet properties for
each NuGet package according to it's internal nuspec file

=cut

sub calculate_nuget_repository_metadata {
    my ( $self, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    return $self->_handle_repository_reindex("/nuget/$repository/reindex");
}

=head2 calculate_npm_repository_metadata

Recalculates the npm search index for this repository (local/virtual). Please see the Npm integration documentation for
more details.

=cut

sub calculate_npm_repository_metadata {
    my ( $self, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    return $self->_handle_repository_reindex("/npm/$repository/reindex");
}

=head2 calculate_maven_index( repos => [ 'repo1', 'repo2' ], force => 0/1 )

Calculates/caches a Maven index for the specified repositories

=cut

sub calculate_maven_index {
    my ( $self, %args ) = @_;

    my $url = $self->_api_url() . "/maven?";
    $url .= $self->_stringify_hash( '&', %args );
    return $self->post($url);
}

=head2 calculate_maven_metadata( $path )

Calculates Maven metadata on the specified path (local repositories only)

=cut

sub calculate_maven_metadata {
    my ( $self, $path ) = @_;
    $path = $self->_merge_repo_and_path($path);
    my $url = $self->_api_url() . "/maven/calculateMetadata/$path";
    return $self->post($url);
}

=head2 calculate_debian_repository_metadata( async => 0/1 )

Calculates/recalculates the Packages and Release metadata for this repository,based on the Debian packages in it.
Calculation can be synchronous (the default) or asynchronous.

=cut

sub calculate_debian_repository_metadata {
    my ( $self, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    return $self->_handle_repository_reindex( "/deb/reindex/$repository", %args );
}

=head2 calculate_opkg_repository_metadata( async => 0/1, writeProps => 1 )

Calculates/recalculates the Packages and Release metadata for this repository,based on the ipk packages in it (in each
feed location).

=cut

sub calculate_opkg_repository_metadata {
    my ( $self, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    return $self->_handle_repository_reindex( "/opkg/reindex/$repository", %args );
}

=head2 calculate_bower_index

Recalculates the index for a Bower repository.

=cut

sub calculate_bower_index {
    my ( $self, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    return $self->_handle_repository_reindex("/bower/$repository/reindex");
}

=head2 calculate_helm_chart_index

Calculates Helm chart index on the specified path (local repositories only).

=cut

sub calculate_helm_chart_index {
    my ( $self, %args ) = @_;
    my $repository = $args{repository} || $self->repository();
    return $self->_handle_repository_reindex("/helm/$repository/reindex");
}

=head1 SYSTEM & CONFIGURATION

=cut

=head2 system_info

Get general system information

=cut

sub system_info {
    my $self = shift;
    return $self->_handle_system();
}

=head2 verify_connection( endpoint => 'http://server/foobar', username => 'admin', password => 'password' )

Verifies a two-way connection between Artifactory and another product

=cut

sub verify_connection {
    my ( $self, %args ) = @_;
    my $url = $self->_api_url() . "/system/verifyconnection";

    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%args )
    );
}

=head2 system_health_ping

Get a simple status response about the state of Artifactory

=cut

sub system_health_ping {
    my $self = shift;
    return $self->_handle_system('ping');
}

=head2 general_configuration

Get the general configuration (artifactory.config.xml)

=cut

sub general_configuration {
    my $self = shift;
    return $self->_handle_system('configuration');
}

=head2 save_general_configuration( $file )

Save the general configuration (artifactory.config.xml)

=cut

sub save_general_configuration {
    my ( $self, $xml ) = @_;

    my $file = Path::Tiny::path($xml)->slurp( { binmode => ":raw" } );
    my $url = $self->_api_url() . "/system/configuration";
    return $self->post(
        $url,
        'Content-Type' => 'application/xml',
        content        => $file
    );
}

=head2 update_custom_url_base( $url )

Changes the Custom URL base

=cut

sub update_custom_url_base {
    my ( $self, $base ) = @_;
    my $url = $self->_api_url() . '/system/configuration/baseUrl';
    return $self->put(
        $url,
        'Content-Type' => 'text/plain',
        content        => $base
    );
}

=head2 license_information

Retrieve information about the currently installed license

=cut

sub license_information {
    my $self = shift;

    my $url = $self->_api_url() . "/system/license";
    return $self->get($url);
}

=head2 install_license( $licensekey )

Install new license key or change the current one

=cut

sub install_license {
    my ( $self, $key ) = @_;
    my $url = $self->_api_url() . "/system/license";

    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( { licenseKey => $key } )
    );
}

=head2 ha_license_information

Retrieve information about the currently installed licenses in an HA cluster

=cut

sub ha_license_information {
    my $self = shift;

    my $url = $self->_api_url() . "/system/licenses";
    return $self->get($url);
}

=head2 install_ha_cluster_licenses( [ { licenseKey => 'foobar' }, { licenseKey => 'barbaz' } ] )

Install a new license key(s) on an HA cluster

=cut

sub install_ha_cluster_licenses {
    my ( $self, $ref ) = @_;
    my $url = $self->_api_url() . "/system/licenses";

    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode($ref)
    );
}

=head2 delete_ha_cluster_license( 'licenseHash1', 'licenseHash2' )

Deletes a license key from an HA cluster

=cut

sub delete_ha_cluster_license {
    my ( $self, @licenses ) = @_;
    my $url = $self->_api_url() . "/system/licenses?";
    $url .= $self->_handle_non_matrix_props( 'licenseHash', \@licenses );
    return $self->delete( $url, 'Content-Type' => 'application/json' );
}

=head2 version_and_addons_information

Retrieve information about the current Artifactory version, revision, and currently installed Add-ons

=cut

sub version_and_addons_information {
    my $self = shift;

    my $url = $self->_api_url() . "/system/version";
    return $self->get($url);
}

=head2 get_reverse_proxy_configuration

Retrieves the reverse proxy configuration

=cut

sub get_reverse_proxy_configuration {
    my $self = shift;

    my $url = $self->_api_url() . "/system/configuration/webServer";
    return $self->get($url);
}

=head2 update_reverse_proxy_configuration(%data)

Updates the reverse proxy configuration

=cut

sub update_reverse_proxy_configuration {
    my ( $self, %data ) = @_;

    my $url = $self->_api_url() . "/system/configuration/webServer";
    return $self->post(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%data )
    );
}

=head2 get_reverse_proxy_snippet

Gets the reverse proxy configuration snippet in text format

=cut

sub get_reverse_proxy_snippet {
    my $self = shift;

    my $url = $self->_api_url() . "/system/configuration/reverseProxy/nginx";
    return $self->get($url);
}

=head1 PLUGINS

=cut

=head2 execute_plugin_code( $execution_name, $params, $async )

Executes a named execution closure found in the executions section of a user plugin

=cut

sub execute_plugin_code {
    my ( $self, $execution_name, $params, $async ) = @_;

    my $url =
      ($params)
      ? $self->_api_url() . "/plugins/execute/$execution_name?params="
      : $self->_api_url() . "/plugins/execute/$execution_name";

    $url = $url . $self->_attach_properties( properties => $params );
    $url .= "&" . $self->_stringify_hash( '&', %{$async} ) if ($async);
    return $self->post($url);
}

=head2 retrieve_all_available_plugin_info

Retrieves all available user plugin information (subject to the permissions of the provided credentials)

=cut

sub retrieve_all_available_plugin_info {
    my $self = shift;
    return $self->_handle_plugins();
}

=head2 retrieve_plugin_info_of_a_certain_type( $type )

Retrieves all available user plugin information (subject to the permissions of the provided credentials) of the
specified type

=cut

sub retrieve_plugin_info_of_a_certain_type {
    my ( $self, $type ) = @_;
    return $self->_handle_plugins($type);
}

=head2 retrieve_build_staging_strategy( strategyName => 'strategy1', buildName => 'build1', %args )

Retrieves a build staging strategy defined by a user plugin

=cut

sub retrieve_build_staging_strategy {
    my ( $self, %args ) = @_;
    my $strategy_name = delete $args{strategyName};
    my $build_name    = delete $args{buildName};

    my $url = $self->_api_url() . "/plugins/build/staging/$strategy_name?buildName=$build_name&params=";
    $url = $url . $self->_attach_properties( properties => \%args );
    return $self->get($url);
}

=head2 execute_build_promotion( promotionName => 'promotion1', buildName => 'build1', buildNumber => 3, %args )

Executes a named promotion closure found in the promotions section of a user plugin

=cut

sub execute_build_promotion {
    my ( $self, %args ) = @_;
    my $promotion_name = delete $args{promotionName};
    my $build_name     = delete $args{buildName};
    my $build_number   = delete $args{buildNumber};

    my $url = $self->_api_url() . "/plugins/build/promote/$promotion_name/$build_name/$build_number?params=";
    $url = $url . $self->_attach_properties( properties => \%args );
    return $self->post($url);
}

=head2 reload_plugins

Reloads user plugins if there are modifications since the last user plugins reload. Works regardless of the automatic
user plugins refresh interval

=cut

sub reload_plugins {
    my $self = shift;
    my $url  = $self->_api_url() . '/plugins/reload';
    return $self->post($url);
}

=head1 IMPORT & EXPORT

=cut

=head2 import_repository_content( path => 'foobar', repo => 'repo', metadata => 1, verbose => 0 )

Import one or more repositories

=cut

sub import_repository_content {
    my ( $self, %args ) = @_;

    my $url = $self->_api_url() . "/import/repositories?";
    $url .= $self->_stringify_hash( '&', %args );
    return $self->post($url);
}

=head2 import_system_settings_example

Returned default Import Settings JSON

=cut

sub import_system_settings_example {
    my $self = shift;
    return $self->_handle_system_settings('import');
}

=head2 full_system_import( importPath => '/import/path', includeMetadata => 'false' etc )

Import full system from a server local Artifactory export directory

=cut

sub full_system_import {
    my ( $self, %args ) = @_;
    return $self->_handle_system_settings( 'import', %args );
}

=head2 export_system_settings_example

Returned default Export Settings JSON

=cut

sub export_system_settings_example {
    my $self = shift;
    return $self->_handle_system_settings('export');
}

=head2 export_system( exportPath => '/export/path', includeMetadata => 'true' etc )

Export full system to a server local directory

=cut

sub export_system {
    my ( $self, %args ) = @_;
    return $self->_handle_system_settings( 'export', %args );
}

=head2 create_bundle( %hash of data structure )

Create a new support bundle

=cut

sub create_bundle {
    my ( $self, %args ) = @_;
    my $url = $self->_api_url() . '/support/bundles';
    %args = () unless %args;

    return $self->post(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode( \%args )
    );
}

=head2 list_bundles

Lists previously created bundle currently stored in the system

=cut

sub list_bundles {
    my $self = shift;
    my $url  = $self->_api_url() . '/support/bundles';
    return $self->get( $url, "Content-Type" => 'application/json', );
}

=head2 get_bundle( $name )

Downloads a previously created bundle currently stored in the system

=cut

sub get_bundle {
    my ( $self, $bundle ) = @_;
    my $url = $self->_api_url() . '/support/bundles/' . $bundle;
    return $self->get( $url, "Content-Type" => 'application/json', );
}

=head2 delete_bundle( $name )

Deletes a previously created bundle from the system.

=cut

sub delete_bundle {
    my ( $self, $bundle ) = @_;
    my $url = $self->_api_url() . '/support/bundles/' . $bundle;
    return $self->delete( $url, "Content-Type" => 'application/json', );
}

sub _build_ua {
    my $self = shift;
    return LWP::UserAgent->new( agent => 'perl-artifactory-client/' . $VERSION, );
}

sub _build_json {
    my ($self) = @_;
    return JSON::MaybeXS->new( utf8 => 1 );
}

sub _request {
    my ( $self, $method, @args ) = @_;
    return $self->ua->$method(@args);
}

sub _get_build {
    my ( $self, $path ) = @_;

    my $url = $self->_api_url() . "/build/$path";
    return $self->get($url);
}

sub _attach_properties {
    my ( $self, %args ) = @_;
    my $properties = $args{properties};
    my $matrix     = $args{matrix};
    my @strings;

    for my $key ( keys %{$properties} ) {
        push @strings, $self->_handle_prop_multivalue( $key, $properties->{$key}, $matrix );
    }

    return join( ";", @strings ) if $matrix;
    return join( "|", @strings );
}

sub _handle_prop_multivalue {
    my ( $self, $key, $values, $matrix ) = @_;

    # need to handle matrix vs non-matrix situations.
    if ($matrix) {
        return $self->_handle_matrix_props( $key, $values );
    }
    return $self->_handle_non_matrix_props( $key, $values );
}

sub _handle_matrix_props {
    my ( $self, $key, $values ) = @_;

    # string looks like key=val;key=val2;key=val3;
    my @strings;
    for my $value ( @{$values} ) {
        $value = '' if ( !defined $value );

        #$value = uri_escape( $value );
        push @strings, "$key=$value";
    }
    return join( ";", @strings );
}

sub _handle_non_matrix_props {
    my ( $self, $key, $values ) = @_;

    # string looks like key=val1,val2,val3|
    my $str = "$key=";
    my @value_holder;
    for my $value ( @{$values} ) {
        $value = '' if ( !defined $value );
        $value = uri_escape($value);
        push @value_holder, $value;
    }
    $str .= join( ",", @value_holder );
    return $str;
}

sub _handle_item {
    my ( $self, %args ) = @_;

    my ( $from, $to, $dry, $suppress_layouts, $fail_fast, $method ) =
      ( $args{from}, $args{to}, $args{dry}, $args{suppress_layouts}, $args{fail_fast}, $args{method} );

    my $url = $self->_api_url() . "/$method$from?to=$to";
    $url .= "&dry=$dry" if ( defined $dry );
    $url .= "&suppressLayouts=$suppress_layouts"
      if ( defined $suppress_layouts );
    $url .= "&failFast=$fail_fast" if ( defined $fail_fast );
    return $self->post($url);
}

sub _handle_repository_replication_configuration {
    my ( $self, $method, $payload ) = @_;
    my $repository = $self->repository();
    my $url        = $self->_api_url() . "/replications/$repository";

    return $self->$method(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode($payload),
    ) if ($payload);

    return $self->$method($url);
}

sub _handle_search {
    my ( $self, $api, %args ) = @_;
    my $name          = $args{name};
    my $repos         = $args{repos};
    my $result_detail = $args{result_detail};

    my $url = $self->_api_url() . "/search/$api?name=$name";

    if ( ref($repos) eq 'ARRAY' ) {
        $url .= "&repos=" . join( ",", @{$repos} );
    }

    my %headers;
    if ( ref($result_detail) eq 'ARRAY' ) {
        $headers{'X-Result-Detail'} = join( ',', @{$result_detail} );
    }

    return $self->get( $url, %headers );
}

sub _handle_search_props {
    my ( $self, $method, %args ) = @_;
    my $result_detail = delete $args{result_detail};

    my $url = $self->_api_url() . "/search/$method?";

    $url .= $self->_stringify_hash( '&', %args );

    my %headers;
    if ( ref($result_detail) eq 'ARRAY' ) {
        $headers{'X-Result-Detail'} = join( ',', @{$result_detail} );
    }

    return $self->get( $url, %headers );
}

sub _stringify_hash {
    my ( $self, $delimiter, %args ) = @_;

    my @strs;
    for my $key ( keys %args ) {
        my $val = $args{$key};

        if ( ref($val) eq 'ARRAY' ) {
            $val = join( ",", @{$val} );
        }
        push @strs, "$key=$val";
    }
    return join( $delimiter, @strs );
}

sub _handle_security {
    my ( $self, $label, $method, $element, %args ) = @_;

    my $url =
      ($label)
      ? $self->_api_url() . "/security/$element/$label"
      : $self->_api_url() . "/security/$element";

    if (%args) {
        return $self->$method(
            $url,
            'Content-Type' => 'application/json',
            content        => $self->_json->encode( \%args )
        );
    }
    return $self->$method($url);
}

sub _handle_repositories {
    my ( $self, $repo, $payload, $method, %args ) = @_;

    $repo =~ s{^\/}{}xi;
    $repo =~ s{\/$}{}xi;

    my $url =
      (%args)
      ? $self->_api_url() . "/repositories/$repo?"
      : $self->_api_url() . "/repositories/$repo";
    $url .= $self->_stringify_hash( '&', %args ) if (%args);

    if ($payload) {
        return $self->$method(
            $url,
            'Content-Type' => 'application/json',
            content        => $self->_json->encode($payload)
        );
    }
    return $self->$method($url);
}

sub _handle_system {
    my ( $self, $arg ) = @_;

    my $url =
      ($arg)
      ? $self->_api_url() . "/system/$arg"
      : $self->_api_url() . "/system";
    return $self->get($url);
}

sub _handle_plugins {
    my ( $self, $type ) = @_;

    my $url =
      ($type)
      ? $self->_api_url() . "/plugins/$type"
      : $self->_api_url() . "/plugins";
    return $self->get($url);
}

sub _handle_system_settings {
    my ( $self, $action, %args ) = @_;

    my $url = $self->_api_url() . "/$action/system";

    if (%args) {
        return $self->post(
            $url,
            'Content-Type' => 'application/json',
            content        => $self->_json->encode( \%args )
        );
    }
    return $self->get($url);
}

sub _handle_gpg_key {
    my ( $self, $type, $method, %args ) = @_;
    my $url = $self->_api_url() . "/gpg/key/$type";
    return $self->$method( $url, %args );
}

sub _handle_repository_reindex {
    my ( $self, $endpoint, %args ) = @_;
    my $url =
      (%args)
      ? $self->_api_url() . $endpoint . "?"
      : $self->_api_url() . $endpoint;
    $url .= $self->_stringify_hash( '&', %args ) if (%args);
    return $self->post($url);
}

sub _handle_multi_push_replication {
    my ( $self, $payload, $method ) = @_;

    my $url = $self->_api_url() . '/replications/multiple';
    return $self->$method(
        $url,
        "Content-Type" => 'application/json',
        Content        => $self->_json->encode($payload)
    );
}

sub _merge_repo_and_path {
    my ( $self, $_path ) = @_;

    $_path = '' if not defined $_path;
    $_path =~ s{^\/}{}xi;

    return join( '/', grep { $_ } $self->repository(), $_path );
}

sub _gather_delete_builds_params {
    my ( $self, $buildnumbers, $artifacts, $deleteall ) = @_;

    my @params;
    if ( ref($buildnumbers) eq 'ARRAY' ) {
        my $str = "buildNumbers=";
        $str .= join( ",", @{$buildnumbers} );
        push @params, $str;
    }
    push @params, "artifacts=$artifacts" if ( defined $artifacts );
    push @params, "deleteAll=$deleteall" if ( defined $deleteall );
    return @params;
}

sub _handle_api_key {
    my ( $self, $method, %args ) = @_;

    my $url = $self->_api_url() . "/apiKey/auth";
    return $self->$method(
        $url,
        'Content-Type' => 'application/json',
        content        => $self->_json->encode( \%args )
    );
}

sub _handle_revoke_api_key {
    my ( $self, $endpoint ) = @_;

    my $resp    = $self->get_api_key();
    my $content = $self->_json->decode( $resp->content );
    my %header;
    $header{'X-Api-Key'} = $content->{apiKey};
    my $url = $self->_api_url() . $endpoint;
    return $self->delete( $url, %header );
}

sub _handle_block_system_replication {
    my ( $self, $ep, %args ) = @_;
    my %merged = (
        push => 'true',
        pull => 'true',
        %args    # overriding defaults
    );
    my $repo = $self->repository();
    my $url = $self->_api_url() . "/system/replications/$ep?" . $self->_stringify_hash( '&', %merged );
    return $self->post($url);
}

__PACKAGE__->meta->make_immutable;

=head1 AUTHOR

Satoshi Yagi, C<< <satoshi.yagi at yahoo.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-artifactory-client at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Artifactory-Client>.  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Artifactory::Client

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Artifactory-Client>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Artifactory-Client>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Artifactory-Client>

=item * Search CPAN

L<http://search.cpan.org/dist/Artifactory-Client/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2014-2015, Yahoo! Inc.

This program is free software; you can redistribute it and/or modify it under
the terms of the the Artistic License (2.0). You may obtain a copy of the full
license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified Versions is
governed by this Artistic License. By using, modifying or distributing the
Package, you accept this license. Do not use, modify, or distribute the
Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made by
someone other than you, you are nevertheless required to ensure that your
Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service mark,
tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge patent
license to make, have made, use, offer to sell, sell, import and otherwise
transfer the Package with respect to any patent claims licensable by the
Copyright Holder that are necessarily infringed by the Package. If you
institute patent litigation (including a cross-claim or counterclaim) against
any party alleging that the Package constitutes direct or contributory patent
infringement, then this Artistic License to you shall terminate on the date
that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND
CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR
NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW.
UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR
ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY
OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
DAMAGE.

=cut

1;
