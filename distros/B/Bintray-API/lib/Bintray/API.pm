package Bintray::API;

#######################
# LOAD MODULES
#######################
use strict;
use warnings FATAL => 'all';
use Carp qw(croak carp);

#######################
# VERSION
#######################
our $VERSION = '1.0.2';

#######################
# LOAD CPAN MODULES
#######################
use Object::Tiny qw(session);

#######################
# LOAD DIST MODULES
#######################
use Bintray::API::Search;
use Bintray::API::Session;
use Bintray::API::Subject;

#######################
# PUBLIC METHODS
#######################

## ====================
## CONSTRUCTOR
## ====================
sub new {
    my ( $class, @args ) = @_;

    # Set Session
    my %opts;
    $opts{session} = Bintray::API::Session->new(@args);

    # Return Object (tiny)
  return $class->SUPER::new(%opts);
} ## end sub new

## ====================
## Bintray OBJECTS
## ====================
sub search {
  return Bintray::API::Search->new(
        session => shift->session,
        @_,
    );
} ## end sub search


sub subject {
  return Bintray::API::Subject->new(
        session => shift->session,
        @_,
    );
} ## end sub subject

#######################
1;

__END__

#######################
# POD SECTION
#######################
=pod

=head1 NAME

Bintray::API - Perl interface to the Bintray API

=head1 SYNOPSIS

    # Initialize
    my $btray = Bintray::API->new(
        username => 'user',
        apikey   => 'XXXXXXXXXXXXXXXXX',
    );

    # Repository
    my $repo = $btray->subject()->repo( name => 'myrepo' );
    foreach my $pkg ( $repo->packages() ) {
        print $pkg->{name} . "\n";
    }

    # Packages and Versions
    my $package = $repo->package( name => 'mypackage' );
    my $version = $package->version( name => '1.0' );
    my $version_info = $version->info();

    # Upload and Publish a file
    $version->upload(
        file      => '/path/to/local/file',
        repo_path => 'myfiles/file',
        publish   => 1,
    );

=head1 DESCRIPTION

L<Bintray|http://bintray.com> is a L<social platform for
community-based software
distribution|https://bintray.com/docs/bintrayuserguide.html#_what_is_bintray>.

This module provides a Perl wrapper to the L<Bintray REST
API|https://bintray.com/docs/api.html>.

=head1 API Methods

This distribution is structured similar to L<Bintray
Entities|https://bintray.com/docs/bintrayuserguide.html#_bintray_entities>.

=head2 SUBJECT

A I<subject> is either a user or an organization

    # Initialize a subject
    my $subject = $btray->subject(

        # Provide an optional _name_
        #   - defaults to the current username
        name => 'my_company',
    );

    # Subject methods
    my $info       = $subject->info();          # Get info
    my $followers  = $subject->followers();     # Get followers
    my $hooks      = $subject->get_webhooks();  # Get Registered hooks
    my $repos      = $subject->repos();         # Get user repositories
    my @repo_names = $subject->repo_names();    # Shortcut to list repo names

=head2 REPOSITORY

    # Initialize a Repo
    my $repo = $subject->repo( name => 'myrepo' );

    # Repository methods
    my $info          = $repo->info();           # Repo information
    my $packages      = $repo->packages();       # Get packages
    my @package_names = $repo->package_names();  # List of packages
    my $hooks         = $repo->get_webhooks();   # Hooks listing

    ## Repository Operations

    # Create Package
    $repo->create_package(
        {
            name     => 'MyPackage',
            desc     => 'foo bar',
            labels   => [qw(foo)],
            licenses => [ 'GPL-3.0', 'Artistic-License-2.0', ],
        }
    );

    # Delete Package
    $repo->delete_package( name => 'MyPackage' );

=head2 PACKAGE

    ## Initialize Package
    my $package = $repo->package( name => 'MyPackage' );
    my $info = $package->info();

    ## Package operations

    # Update
    $package->update( details => {...} );

    # Versions
    $package->create_version(
        details => {
            name          => '1.0',
            release_notes => 'foobar',
            release_url   => 'http://foo/bar'
        }
    );
    $package->delete_version( name => '1.0' );

    # Attributes
    $package->get_attributes();
    $package->set_attributes(
        attributes => [
            {
                name   => 'foo',
                values => [qw(bar baz)],
                type   => 'string',
            },
        ],
    );
    $package->update_attributes( attributes => [...] );

    # Hooks
    $package->set_webhook( url => 'http://....' );
    $package->delete_webhook();

=head2 VERSIONS

    ## Initialize Versions
    my $version = $package->version( name => '1.0' );
    my $info = $version->info();  # Info

    ## Version Operations

    # Upload
    $version->upload(
        file      => '/path/to/local/file',
        repo_path => 'myfiles/file',

        # Optional params
        publish => 0,  # Publish on upload
        explode => 0,  # Upload an exploded archive
    );

    # Update details
    $version->update(
        details => {
            desc   => 'version description',
            labels => [qw(foo bar)],
        },
    );

    # Sign
    $version->sign( passphrase => '...' );

    # Publish
    $version->publish();

    # Discard
    $version->discard();

    # Attributes
    my $attributes = $version->get_aatributes();
    $version->set_attributes( attributes => [...] );
    $version->update_attributes( attributes => [...] );

=head2 SEARCH

    ## Init Search object
    my $search = $btray->search();

    # Search Repos
    @results = $search->repos(
        name => 'myrepo',     # // either name or desc is required
        desc => 'maven repo',
    );

    # Search Packages
    @results = $search->packages(
        name    => '...',
        desc    => '...',
        repo    => '...',
        subject => '...',     # // User or Org
    );

    # Search files
    @results = $search->files(
        name => '...',
        sha1 => '...',
        repo => '...',
    );

    # Search Users or Organizations
    @results = $search->users( name => '...' );

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests at
L<https://github.com/mithun/perl-bintray-api/issues>

=head1 AUTHOR

Mithun Ayachit C<mithun@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2014, Mithun Ayachit. All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

=cut
