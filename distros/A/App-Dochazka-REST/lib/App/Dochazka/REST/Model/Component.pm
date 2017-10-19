# ************************************************************************* 
# Copyright (c) 2014-2017, SUSE LLC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package App::Dochazka::REST::Model::Component;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::REST::Mason qw( $comp_root $interp );
use App::Dochazka::REST::Model::Shared qw( cud load load_multiple priv_by_eid );
use DBI;
use File::Path;
use File::Spec;
use JSON;
use Params::Validate qw{:all};
use Try::Tiny;

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Component';




=head1 NAME

App::Dochazka::REST::Model::Component - component class




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Component;

    ...


=head1 DATA MODEL

=head2 Components in the database 


   CREATE TABLE components (
       cid         serial PRIMARY KEY,
       path        varchar(2048) UNIQUE NOT NULL,
       source      text NOT NULL,
       acl         varchar(16) NOT NULL,
       validations textj
   )



=head2 Components in the Perl API

=over

=item * constructor (L<spawn>)

=item * basic accessors (L<cid>, L<path>, L<source>, L<acl>, L<validations>)

=item * L<reset> (recycles an existing object by setting it to desired state)

=item * L<TO_JSON> (returns 'unblessed' version of an Activity object)

=item * L<compare> (compare two objects)

=item * L<clone> (clone an object)

=item * L<insert> (inserts object into database)

=item * L<update> (updates database to match the object)

=item * L<delete> (deletes record from database if nothing references it)

=item * L<load_by_cid> (loads a single activity into an object)

=item * L<load_by_path> (loads a single activity into an object)

=back

L<App::Dochazka::REST::Model::Component> also exports some convenience
functions:

=over

=item * L<cid_exists> (boolean function)

=item * L<path_exists> (boolean function)

=item * L<cid_by_path> (given a path, returns CID)

=item * L<get_all_components> (self-explanatory)

=back

For basic C<component> object workflow, see the unit tests in
C<t/model/component.t>.

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( cid_exists path_exists cid_by_path get_all_components );




=head1 METHODS


=head2 insert

Instance method. Takes the object, as it is, and attempts to insert it into
the database. On success, overwrites object attributes with field values
actually inserted. Returns a status object.

=cut

sub insert {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    return $CELL->status_err( 'DOCHAZKA_MALFORMED_400' ) unless
        ( 
          $self->{'path'} and $self->{'source'} and $self->{'acl'} and
          scalar( 
              grep { $self->{'acl'} eq $_ } ( 'admin', 'active', 'inactive', 'passerby' ) 
          ) 
        );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_COMPONENT_INSERT,
        attrs => [ 'path', 'source', 'acl', 'validations' ],
    );

    $self->create_file if $status->ok;

    return $status;
}


=head2 update

Instance method. Assuming that the object has been prepared, i.e. the CID
corresponds to the component to be updated and the attributes have been
changed as desired, this function runs the actual UPDATE, hopefully
bringing the database into line with the object. Overwrites all the
object's attributes with the values actually written to the database.
Returns status object.

=cut

sub update {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    return $CELL->status_err( 'DOCHAZKA_MALFORMED_400' ) unless
        ( 
          $self->{'cid'} and 
          ( 
              $self->{'path'} or $self->{'source'} or $self->{'acl'}
          )
        );

    return $CELL->status_err( 'DOCHAZKA_MALFORMED_400' ) if
        (
          $self->{'acl'} and not scalar( 
              grep { $self->{'acl'} eq $_ } ( 'admin', 'active', 'inactive', 'passerby' ) 
          ) 
        );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_COMPONENT_UPDATE,
        attrs => [ 'path', 'source', 'acl', 'validations', 'cid' ],
    );

    $self->create_file if $status->ok;

    return $status;
}


=head2 delete

Instance method. Assuming the CID really corresponds to the component to be
deleted, this method will execute the DELETE statement in the database. No 
attempt is made to protect from possible deleterious consequences of
deleting components. Returns a status object.

=cut

sub delete {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_COMPONENT_DELETE,
        attrs => [ 'cid' ],
    );
    if ( $status->ok ) {
        $self->delete_file;
        $self->reset( cid => $self->{cid} );
    }

    return $status;
}


=head2 load_by_cid

Loads component from database, by the CID provided in the argument list,
into a newly-spawned object. The CID must be an exact match.  Returns a
status object: if the object is loaded, the status code will be
'DISPATCH_RECORDS_FOUND' and the object will be in the payload; if 
the CID is not found in the database, the status code will be
'DISPATCH_NO_RECORDS_FOUND'. A non-OK status indicates a DBI error.

=cut

sub load_by_cid {
    my $self = shift;
    my ( $conn, $cid ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_COMPONENT_SELECT_BY_CID,
        keys => [ $cid ],
    );
}


=head2 load_by_path

Analogous method to L<"load_by_cid">.

=cut

sub load_by_path {
    my $self = shift;
    my ( $conn, $path ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    $path =~ s{^/}{};

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_COMPONENT_SELECT_BY_PATH,
        keys => [ $path ],
    );
}


=head2 create_file

Create Mason component file under $comp_root

=cut

sub create_file {
    my $self = shift;
    my ( undef, $dirspec, $filespec ) = File::Spec->splitpath( $self->path );
    my $full_path = File::Spec->catfile( $comp_root, $dirspec );
    mkpath( $full_path, 0, 0750 );
    $full_path = File::Spec->catfile( $full_path, $filespec );
    open(my $fh, '>', $full_path) or die "Could not open file '$full_path' $!";
    print $fh $self->source;
    close $fh;
    return;
}


=head2 delete_file

Delete Mason component file under $comp_root

=cut

sub delete_file {
    my $self = shift;
    my $full_path = File::Spec->catfile( $comp_root, $self->path );
    my $count = unlink $full_path;
    if ( $count == 1 ) {
        $log->info( "Component.pm->delete_file: deleted 1 file $full_path" );
    } else {
        $log->error( "Component.pm->delete_file: deleted $count files" );
    }
    return;
}


=head2 generate

Generate output

=cut

sub generate {
    my $self = shift;
    my %ARGS = @_;
    my $path = $self->path;

    # the path in the Component object may or may not start with a '/'
    # Mason requires that it start with an '/', even though it's relative
    $path = '/' . $path unless $path =~ m{^/};

    # the path should exist and be readable
    my $full_path = File::Spec->catfile( $comp_root, $self->path );
    return "$full_path does not exist" unless -e $full_path;
    return "$full_path is not readable" unless -r $full_path;

    # only top-level components can be used to produce output
    # top-level components must end in '.mc' or '.mp', but Mason 
    # expects the component name to be specified without the extension
    return $self->path . " is not a top-level component" unless $path =~ m/\.m[cp]$/;
    $path =~ s/\.m[cp]$//;

    return $interp->run($path, %ARGS)->output;
}


=head1 FUNCTIONS

The following functions are not object methods.


=head2 cid_exists

Boolean function


=head2 path_exists

Boolean function

=cut

BEGIN {
    no strict 'refs';
    *{'cid_exists'} = App::Dochazka::REST::Model::Shared::make_test_exists( 'cid' );
    *{'path_exists'} = App::Dochazka::REST::Model::Shared::make_test_exists( 'path' );
}


=head2 cid_by_path

Given a path, attempt to retrieve the corresponding CID.
Returns CID or undef on failure.

=cut

sub cid_by_path {
    my ( $conn, $path ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    my $status = __PACKAGE__->load_by_path( $conn, $path );
    return $status->payload->{'cid'} if $status->code eq 'DISPATCH_RECORDS_FOUND';
    return;
}



=head2 get_all_components

Returns a reference to a hash of hashes, where each hash is one component object.

=cut

sub get_all_components {
    my $conn = shift;
    
    my $sql = $site->SQL_COMPONENT_SELECT_ALL;

    return load_multiple(
        conn => $conn,
        class => __PACKAGE__,
        sql => $sql,
        keys => [],
    );
}




=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;

