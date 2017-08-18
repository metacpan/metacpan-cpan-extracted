[![Build Status](https://travis-ci.org/satoshi/Artifactory-Client.svg?branch=master)](https://travis-ci.org/satoshi/Artifactory-Client)

# NAME

Artifactory::Client - Perl client for Artifactory REST API

# VERSION

Version 1.5.1

# SYNOPSIS

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

# Dev Env Setup / Running Tests

    carton install

    # to run unit tests
    prove -r t

# GENERIC METHODS

## get( @args )

Invokes GET request on LWP::UserAgent-like object; params are passed through.

## post( @args )

nvokes POST request on LWP::UserAgent-like object; params are passed through.

## put( @args )

Invokes PUT request on LWP::UserAgent-like object; params are passed through.

## delete( @args )

Invokes DELETE request on LWP::UserAgent-like object; params are passed
through.

## request( @args )

Invokes request() on LWP::UserAgent-like object; params are passed through.

# BUILDS

## all\_builds

Retrieves information on all builds from artifactory.

## build\_runs( $build\_name )

Retrieves information of a particular build from artifactory.

## build\_upload( $path\_to\_json )

Upload Build

## build\_info( $build\_name, $build\_number )

Retrieves information of a particular build number.

## builds\_diff( $build\_name, $new\_build\_number, $old\_build\_number )

Retrieves diff of 2 builds

## build\_promotion( $build\_name, $build\_number, $payload )

Promotes a build by POSTing payload

## promote\_docker\_image( targetRepo => "target\_repo", dockerRepository => "dockerRepository", tag => "tag", copy => 'false' )

Promotes a Docker image from one repository to another

## delete\_builds( name => $build\_name, buildnumbers => \[ buildnumbers \], artifacts => 0,1, deleteall => 0,1 )

Removes builds stored in Artifactory. Useful for cleaning up old build info data

## build\_rename( $build\_name, $new\_build\_name )

Renames a build

## distribute\_build( 'build\_name', $build\_number, %hash\_of\_json\_payload )

Deploys builds from Artifactory to Bintray, and creates an entry in the corresponding Artifactory distribution
repository specified.

## control\_build\_retention( 'build\_name', deleteBuildArtifacts => 'true', count => 100, ... )

Specifies retention parameters for build info.

# ARTIFACTS & STORAGE

## folder\_info( $path )

Returns folder info

## file\_info( $path )

Returns file info

## get\_storage\_summary\_info

Returns storage summary information regarding binaries, file store and repositories

## item\_last\_modified( $path )

Returns item\_last\_modified for a given path

## file\_statistics( $path )

Returns file\_statistics for a given path

## item\_properties( path => $path, properties => \[ key\_names \] )

Takes path and properties then get item properties.

## set\_item\_properties( path => $path, properties => { key => \[ values \] }, recursive => 0,1 )

Takes path and properties then set item properties.  Supply recursive => 0 if you want to suppress propagation of
properties downstream.  Note that properties are a hashref with key-arrayref pairs, such as:

    $prop = { key1 => ['a'], key2 => ['a', 'b'] }

## delete\_item\_properties( path => $path, properties => \[ key\_names \], recursive => 0,1 )

Takes path and properties then delete item properties.  Supply recursive => 0 if you want to suppress propagation of
properties downstream.

## set\_item\_sha256\_checksum( repoKey => 'foo', path => 'bar' )

Calculates an artifact's SHA256 checksum and attaches it as a property (with key "sha256"). If the artifact is a folder,
then recursively calculates the SHA256 of each item in the folder and attaches the property to each item.

## retrieve\_artifact( $path, $filename )

Takes path and retrieves artifact on the path.  If $filename is given, artifact content goes into the $filename rather
than the HTTP::Response object.

## retrieve\_latest\_artifact( path => $path, version => $version, release => $release, integration => $integration,
 flag => 'snapshot', 'release', 'integration' )

Takes path, version, flag of 'snapshot', 'release' or 'integration' and retrieves artifact

## retrieve\_build\_artifacts\_archive( $payload )

Takes payload (hashref) then retrieve build artifacts archive.

## retrieve\_folder\_or\_repository\_archive( path => '/foobar', archiveType => 'zip' )

Retrieves an archive file (supports zip/tar/tar.gz/tgz) containing all the artifacts that reside under the specified
path (folder or repository root). Requires Enable Folder Download to be set.

## trace\_artifact\_retrieval( $path )

Takes path and traces artifact retrieval

## archive\_entry\_download( $path, $archive\_path )

Takes path and archive\_path, retrieves an archived resource from the specified archive destination.

## create\_directory( path => $path, properties => { key => \[ values \] } )

Takes path, properties then create a directory.  Directory needs to end with a /, such as "/some\_dir/".

## deploy\_artifact( path => $path, properties => { key => \[ values \] }, file => $file )

Takes path on Artifactory, properties and filename then deploys the file.  Note that properties are a hashref with
key-arrayref pairs, such as:

    $prop = { key1 => ['a'], key2 => ['a', 'b'] }

## deploy\_artifact\_by\_checksum( path => $path, properties => { key => \[ values \] }, file => $file, sha1 => $sha1 )

Takes path, properties, filename and sha1 then deploys the file.  Note that properties are a hashref with key-arrayref
pairs, such as:

    $prop = { key1 => ['a'], key2 => ['a', 'b'] }

## deploy\_artifacts\_from\_archive( path => $path, file => $file )

Path is the path on Artifactory, file is path to local archive.  Will deploy $file to $path.

## push\_a\_set\_of\_artifacts\_to\_bintray( descriptor => 'foo', gpgPassphrase => 'top\_secret', gpgSign => 'true' )

Push a set of artifacts to Bintray as a version.  Uses a descriptor file (that must have 'bintray-info' in it's filename
and a .json extension) that was deployed to artifactory, the call accepts the full path to the descriptor as a
parameter.

## push\_docker\_tag\_to\_bintray( dockerImage => 'jfrog/ubuntu:latest', async => 'true', ... )

Push Docker tag to Bintray.  Calculation can be synchronous (the default) or asynchronous.  You will need to enter your
Bintray credentials, for more details, please refer to Entering your Bintray credentials.

## distribute\_artifact( publish => 'true', async => 'false' )

Deploys artifacts from Artifactory to Bintray, and creates an entry in the corresponding Artifactory distribution
repository specified

## file\_compliance\_info( $path )

Retrieves file compliance info of a given path.

## delete\_item( $path )

Delete $path on artifactory.

## copy\_item( from => $from, to => $to, dry => 1, suppressLayouts => 0/1, failFast => 0/1 )

Copies an artifact from $from to $to.  Note that for this particular API call, the $from and $to must include repository
names as copy source and destination may be different repositories.  You can also supply dry, suppressLayouts and
failFast values as specified in the documentation.

## move\_item( from => $from, to => $to, dry => 1, suppressLayouts => 0/1, failFast => 0/1 )

Moves an artifact from $from to $to.  Note that for this particular API call, the $from and $to must include repository
names as copy source and destination may be different repositories.  You can also supply dry, suppressLayouts and
failFast values as specified in the documentation.

## get\_repository\_replication\_configuration

Get repository replication configuration

## set\_repository\_replication\_configuration( $payload )

Set repository replication configuration

## update\_repository\_replication\_configuration( $payload )

Update repository replication configuration

## delete\_repository\_replication\_configuration

Delete repository replication configuration

## scheduled\_replication\_status

Gets scheduled replication status of a repository

## pull\_push\_replication( payload => $payload, path => $path )

Schedules immediate content replication between two Artifactory instances

## create\_or\_replace\_local\_multi\_push\_replication( $payload )

Creates or replaces a local multi-push replication configuration. Supported by local and local-cached repositories

## update\_local\_multi\_push\_replication( $payload )

Updates a local multi-push replication configuration. Supported by local and local-cached repositories

## delete\_local\_multi\_push\_replication( $url )

Deletes a local multi-push replication configuration. Supported by local and local-cached repositories

## enable\_or\_disable\_multiple\_replications( 'enable|disable', include => \[ \], exclude => \[ \] )

Enables/disables multiple replication tasks by repository or Artifactory server based in include and exclude patterns.

## get\_global\_system\_replication\_configuration

Returns the global system replication configuration status, i.e. if push and pull replications are blocked or unblocked.

## block\_system\_replication( push => 'false', pull => 'true' )

Blocks replications globally. Push and pull are true by default. If false, replication for the corresponding type is not
blocked.

## unblock\_system\_replication( push => 'false', pull => 'true' )

Unblocks replications globally. Push and pull are true by default. If false, replication for the corresponding type is
not unblocked.

## artifact\_sync\_download( $path, content => 'progress', mark => 1000 )

Downloads an artifact with or without returning the actual content to the client. When tracking the progress marks are
printed (by default every 1024 bytes). This is extremely useful if you want to trigger downloads on a remote Artifactory
server, for example to force eager cache population of large artifacts, but want to avoid the bandwidth consumption
involved in transferring the artifacts to the triggering client. If no content parameter is specified the file content
is downloaded to the client.

## file\_list( $dir, %opts )

Get a flat (the default) or deep listing of the files and folders (not included by default) within a folder

## get\_background\_tasks

Retrieves list of background tasks currently scheduled or running in Artifactory. In HA, the nodeId is added to each
task. Task can be in one of few states: scheduled, running, stopped, canceled. Running task also shows the task start
time.

## empty\_trash\_can

Empties the trash can permanently deleting all its current contents.

## delete\_item\_from\_trash\_can($path)

Permanently deletes an item from the trash can.

## restore\_item\_from\_trash\_can( $from, $to )

Restore an item from the trash can.

## optimize\_system\_storage

Raises a flag to invoke balancing between redundant storage units of a sharded filestore following the next garbage
collection.

# SEARCHES

## artifactory\_query\_language( $aql\_statement )

Flexible and high performance search using Artifactory Query Language (AQL).

## artifact\_search( name => $name, repos => \[ @repos \], result\_detail => \[qw(info properties)\], )

Artifact search by part of file name

## archive\_entry\_search( name => $name, repos => \[ @repos \] )

Search archive entries for classes or any other jar resources

## gavc\_search( g => 'foo', c => 'bar', result\_detail => \[qw(info properties)\], )

Search by Maven coordinates: groupId, artifactId, version & classifier

## property\_search( p => \[ 'v1', 'v2' \], repos => \[ 'repo1', 'repo2' \], result\_detail => \[qw(info properties)\], )

Search by properties

## checksum\_search( md5 => '12345', repos => \[ 'repo1', 'repo2' \], result\_detail => \[qw(info properties)\], )

Artifact search by checksum (md5 or sha1)

## bad\_checksum\_search( type => 'md5', repos => \[ 'repo1', 'repo2' \]  )

Find all artifacts that have a bad or missing client checksum values (md5 or
sha1)

## artifacts\_not\_downloaded\_since( notUsedSince => 12345, createdBefore => 12345, repos => \[ 'repo1', 'repo2' \] )

Retrieve all artifacts not downloaded since the specified Java epoch in msec.

## artifacts\_with\_date\_in\_date\_range( from => 12345, repos => \[ 'repo1', 'repo2' \], dateFields => \[ 'created' \] )

Get all artifacts with specified dates within the given range. Search can be limited to specific repositories (local or
caches).

## artifacts\_created\_in\_date\_range( from => 12345, to => 12345, repos => \[ 'repo1', 'repo2' \] )

Get all artifacts created in date range

## pattern\_search( $pattern )

Get all artifacts matching the given Ant path pattern

## builds\_for\_dependency( sha1 => 'abcde' )

Find all the builds an artifact is a dependency of (where the artifact is included in the build-info dependencies)

## license\_search( unapproved => 1, unknown => 1, notfound => 0, neutral => 0, repos => \[ 'foo', 'bar' \] )

Search for artifacts with specified statuses

## artifact\_version\_search( g => 'foo', a => 'bar', v => '1.0', repos => \[ 'foo', 'bar' \] )

Search for all available artifact versions by GroupId and ArtifactId in local, remote or virtual repositories

## artifact\_latest\_version\_search\_based\_on\_layout( g => 'foo', a => 'bar', v => '1.0', repos => \[ 'foo', 'bar' \] )

Search for the latest artifact version by groupId and artifactId, based on the layout defined in the repository

## artifact\_latest\_version\_search\_based\_on\_properties( repo => '\_any', path => '/a/b', listFiles => 1 )

Search for artifacts with the latest value in the "version" property

## build\_artifacts\_search( buildNumber => 15, buildName => 'foobar' )

Find all the artifacts related to a specific build

## list\_docker\_repositories( n => 5, last => 'last\_tag\_value' )

Lists all Docker repositories hosted in under an Artifactory Docker repository.

## list\_docker\_tags( $image\_name, n => 5, last => 'last\_tag\_value' )

Lists all tags of the specified Artifactory Docker repository.

# SECURITY

## get\_users

Get the users list

## get\_user\_details( $user )

Get the details of an Artifactory user

## get\_user\_encrypted\_password

Get the encrypted password of the authenticated requestor

## create\_or\_replace\_user( $user, %args )

Creates a new user in Artifactory or replaces an existing user

## update\_user( $user, %args )

Updates an exiting user in Artifactory with the provided user details

## delete\_user( $user )

Removes an Artifactory user

## expire\_password\_for\_a\_single\_user( $user )

Expires a user's password

## expire\_password\_for\_multiple\_users( $user1, $user2 )

Expires password for a list of users

## expire\_password\_for\_all\_users

Expires password for all users

## unexpire\_password\_for\_a\_single\_user( $user )

Unexpires a user's password

## change\_password( user => 'david', oldPassword => 'foo', newPassword => 'bar' )

Changes a user's password

## get\_password\_expiration\_policy

Retrieves the password expiration policy

## set\_password\_expiration\_policy

Sets the password expiration policy

## configure\_user\_lock\_policy( enabled => 'true|false', loginAttempts => $num )

Configures the user lock policy that locks users out of their account if the number of repeated incorrect login attempts
exceeds the configured maximum allowed.

## retrieve\_user\_lock\_policy

Retrieves the currently configured user lock policy.

## get\_locked\_out\_users

If locking out users is enabled, lists all users that were locked out due to recurrent incorrect login attempts.

## unlock\_locked\_out\_user

Unlocks a single user that was locked out due to recurrent incorrect login attempts.

## unlock\_locked\_out\_users

Unlocks a list of users that were locked out due to recurrent incorrect login attempts.

## unlock\_all\_locked\_out\_users

Unlocks all users that were locked out due to recurrent incorrect login attempts.

## create\_api\_key( apiKey => '3OloposOtVFyCMrT+cXmCAScmVMPrSYXkWIjiyDCXsY=' )

Create an API key for the current user

## get\_api\_key

Get the current user's own API key

## revoke\_api\_key

Revokes the current user's API key

## revoke\_user\_api\_key

Revokes the API key of another user

## revoke\_all\_api\_keys

Revokes all API keys currently defined in the system

## get\_groups

Get the groups list

## get\_group\_details( $group )

Get the details of an Artifactory Group

## create\_or\_replace\_group( $group, %args )

Creates a new group in Artifactory or replaces an existing group

## update\_group( $group, %args )

Updates an exiting group in Artifactory with the provided group details

## delete\_group( $group )

Removes an Artifactory group

## get\_permission\_targets

Get the permission targets list

## get\_permission\_target\_details( $name )

Get the details of an Artifactory Permission Target

## create\_or\_replace\_permission\_target( $name, %args )

Creates a new permission target in Artifactory or replaces an existing permission target

## delete\_permission\_target( $name )

Deletes an Artifactory permission target

## effective\_item\_permissions( $path )

Returns a list of effective permissions for the specified item (file or folder)

## security\_configuration

Retrieve the security configuration (security.xml)

## activate\_master\_key\_encryption

Creates a new master key and activates master key encryption

## deactivate\_master\_key\_encryption

Removes the current master key and deactivates master key encryption

## set\_gpg\_public\_key( key => $string )

Sets the public key that Artifactory provides to Debian clients to verify packages

## get\_gpg\_public\_key

Gets the public key that Artifactory provides to Debian clients to verify packages

## set\_gpg\_private\_key( key => $string )

Sets the private key that Artifactory will use to sign Debian packages

## set\_gpg\_pass\_phrase( $passphrase )

Sets the pass phrase required signing Debian packages using the private key

## create\_token( username => 'johnq', scope => 'member-of-groups:readers' )

Creates an access token

## refresh\_token( grant\_type => 'refresh\_token', refresh\_token => 'fgsg53t3g' )

Refresh an access token to extend its validity. If only the access token and the refresh token are provided (and no
other parameters), this pair is used for authentication. If username or any other parameter is provided, then the
request must be authenticated by a token that grants admin permissions.

## revoke\_token( token => 'fgsg53t3g' )

Revoke an access token

## get\_service\_id

Provides the service ID of an Artifactory instance or cluster

## get\_certificates

Returns a list of installed SSL certificates.

## add\_certificate( $alias, $file\_path )

Adds an SSL certificate.

## delete\_certificate( $alias )

Deletes an SSL certificate.

# REPOSITORIES

## get\_repositories( $type )

Returns a list of minimal repository details for all repositories of the specified type

## repository\_configuration( $name, %args )

Retrieves the current configuration of a repository

## create\_or\_replace\_repository\_configuration( $name, \\%payload, %args )

Creates a new repository in Artifactory with the provided configuration or replaces the configuration of an existing
repository

## update\_repository\_configuration( $name, \\%payload )

Updates an exiting repository configuration in Artifactory with the provided configuration elements

## delete\_repository( $name )

Removes a repository configuration together with the whole repository content

## calculate\_yum\_repository\_metadata( async => 0/1 )

Calculates/recalculates the YUM metdata for this repository, based on the RPM package currently hosted in the repository

## calculate\_nuget\_repository\_metadata

Recalculates all the NuGet packages for this repository (local/cache/virtual), and re-annotate the NuGet properties for
each NuGet package according to it's internal nuspec file

## calculate\_npm\_repository\_metadata

Recalculates the npm search index for this repository (local/virtual). Please see the Npm integration documentation for
more details.

## calculate\_maven\_index( repos => \[ 'repo1', 'repo2' \], force => 0/1 )

Calculates/caches a Maven index for the specified repositories

## calculate\_maven\_metadata( $path )

Calculates Maven metadata on the specified path (local repositories only)

## calculate\_debian\_repository\_metadata( async => 0/1 )

Calculates/recalculates the Packages and Release metadata for this repository,based on the Debian packages in it.
Calculation can be synchronous (the default) or asynchronous.

## calculate\_opkg\_repository\_metadata( async => 0/1, writeProps => 1 )

Calculates/recalculates the Packages and Release metadata for this repository,based on the ipk packages in it (in each
feed location).

## calculate\_bower\_index

Recalculates the index for a Bower repository.

# SYSTEM & CONFIGURATION

## system\_info

Get general system information

## verify\_connection( endpoint => 'http://server/foobar', username => 'admin', password => 'password' )

Verifies a two-way connection between Artifactory and another product

## system\_health\_ping

Get a simple status response about the state of Artifactory

## general\_configuration

Get the general configuration (artifactory.config.xml)

## save\_general\_configuration( $file )

Save the general configuration (artifactory.config.xml)

## update\_custom\_url\_base( $url )

Changes the Custom URL base

## license\_information

Retrieve information about the currently installed license

## install\_license( $licensekey )

Install new license key or change the current one

## ha\_license\_information

Retrieve information about the currently installed licenses in an HA cluster

## install\_ha\_cluster\_licenses( \[ { licenseKey => 'foobar' }, { licenseKey => 'barbaz' } \] )

Install a new license key(s) on an HA cluster

## delete\_ha\_cluster\_license( 'licenseHash1', 'licenseHash2' )

Deletes a license key from an HA cluster

## version\_and\_addons\_information

Retrieve information about the current Artifactory version, revision, and currently installed Add-ons

## get\_reverse\_proxy\_configuration

Retrieves the reverse proxy configuration

## update\_reverse\_proxy\_configuration(%data)

Updates the reverse proxy configuration

## get\_reverse\_proxy\_snippet

Gets the reverse proxy configuration snippet in text format

## create\_bootstrap\_bundle

This rest is relevant for High Availability set up. It will create a bootstrap bundle on the primary node of an
Artifactory HA installation that will include all the relevant keys so a new node can access the database and fetch all
the relevant configuration files. The same bundle must be installed on all nodes during an installation of new nodes or
if upgrading from a version older than 5.0. For more details, please refer to Installing Artifactory HA.

# PLUGINS

## execute\_plugin\_code( $execution\_name, $params, $async )

Executes a named execution closure found in the executions section of a user plugin

## retrieve\_all\_available\_plugin\_info

Retrieves all available user plugin information (subject to the permissions of the provided credentials)

## retrieve\_plugin\_info\_of\_a\_certain\_type( $type )

Retrieves all available user plugin information (subject to the permissions of the provided credentials) of the
specified type

## retrieve\_build\_staging\_strategy( strategyName => 'strategy1', buildName => 'build1', %args )

Retrieves a build staging strategy defined by a user plugin

## execute\_build\_promotion( promotionName => 'promotion1', buildName => 'build1', buildNumber => 3, %args )

Executes a named promotion closure found in the promotions section of a user plugin

## reload\_plugins

Reloads user plugins if there are modifications since the last user plugins reload. Works regardless of the automatic
user plugins refresh interval

# IMPORT & EXPORT

## import\_repository\_content( path => 'foobar', repo => 'repo', metadata => 1, verbose => 0 )

Import one or more repositories

## import\_system\_settings\_example

Returned default Import Settings JSON

## full\_system\_import( importPath => '/import/path', includeMetadata => 'false' etc )

Import full system from a server local Artifactory export directory

## export\_system\_settings\_example

Returned default Export Settings JSON

## export\_system( exportPath => '/export/path', includeMetadata => 'true' etc )

Export full system to a server local directory

## create\_bundle( %hash of data structure )

Create a new support bundle

## list\_bundles

Lists previously created bundle currently stored in the system

## get\_bundle( $name )

Downloads a previously created bundle currently stored in the system

## delete\_bundle( $name )

Deletes a previously created bundle from the system.

# AUTHOR

Satoshi Yagi, `<satoshi.yagi at yahoo.com>`

# BUGS

Please report any bugs or feature requests to `bug-artifactory-client at
rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Artifactory-Client](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Artifactory-Client).  I will
be notified, and then you'll automatically be notified of progress on your bug
as I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Artifactory::Client

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Artifactory-Client](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Artifactory-Client)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/Artifactory-Client](http://annocpan.org/dist/Artifactory-Client)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Artifactory-Client](http://cpanratings.perl.org/d/Artifactory-Client)

- Search CPAN

    [http://search.cpan.org/dist/Artifactory-Client/](http://search.cpan.org/dist/Artifactory-Client/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2014-2015, Yahoo! Inc.

This program is free software; you can redistribute it and/or modify it under
the terms of the the Artistic License (2.0). You may obtain a copy of the full
license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

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
