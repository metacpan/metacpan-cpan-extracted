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

package App::Dochazka::REST::Model::Activity;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::REST::Model::Shared qw( cud load load_multiple priv_by_eid );
use DBI;
use Params::Validate qw{:all};
use Try::Tiny;

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Activity';




=head1 NAME

App::Dochazka::REST::Model::Activity - activity data model




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Activity;

    ...


=head1 DATA MODEL

=head2 Activities in the database 


   CREATE TABLE activities (
       aid        serial PRIMARY KEY,
       code       varchar(32) UNIQUE NOT NULL,
       long_desc  text,
       remark     text
   )

Activity codes will always be in ALL CAPS thanks to a trigger (entitled 
C<code_to_upper>) that runs the PostgreSQL C<upper> function on the code
before every INSERT and UPDATE on this table.



=head2 Activities in the Perl API

=over

=item * constructor (L<spawn>)

=item * basic accessors (L<aid>, L<code>, L<long_desc>, L<remark>)

=item * L<reset> (recycles an existing object by setting it to desired state)

=item * L<TO_JSON> (returns 'unblessed' version of an Activity object)

=item * L<compare> (compare two objects)

=item * L<clone> (clone an object)

=item * L<insert> (inserts object into database)

=item * L<update> (updates database to match the object)

=item * L<delete> (deletes record from database if nothing references it)

=item * L<load_by_aid> (loads a single activity into an object)

=item * L<load_by_code> (loads a single activity into an object)

=item * L<get_all_activities> (load all activities)

=back

L<App::Dochazka::REST::Model::Activity> also exports some convenience
functions:

=over

=item * L<aid_exists> (boolean function)

=item * L<code_exists> (boolean function)

=item * L<aid_by_code> (given a code, returns AID)

=item * L<code_by_aid> (given an AID, return a code)

=item * L<get_all_activities>

=back

For basic C<activity> object workflow, see the unit tests in
C<t/model/activity.t>.



=head1 EXPORTS

This module provides the following exports:

=over 

=item C<aid_by_code> - function

=back

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( 
    aid_by_code 
    aid_exists 
    code_by_aid
    code_exists 
    get_all_activities 
);




=head1 METHODS


=head2 insert

Instance method. Takes the object, as it is, and attempts to insert it into
the database. On success, overwrites object attributes with field values
actually inserted. Returns a status object.

=cut

sub insert {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_ACTIVITY_INSERT,
        attrs => [ 'code', 'long_desc', 'remark' ],
    );

    return $status;
}


=head2 update

Instance method. Assuming that the object has been prepared, i.e. the AID
corresponds to the activity to be updated and the attributes have been
changed as desired, this function runs the actual UPDATE, hopefully
bringing the database into line with the object. Overwrites all the
object's attributes with the values actually written to the database.
Returns status object.

=cut

sub update {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    return $CELL->status_err( 'DOCHAZKA_MALFORMED_400' ) unless $self->{'aid'};

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_ACTIVITY_UPDATE,
        attrs => [ 'code', 'long_desc', 'remark', 'disabled', 'aid' ],
    );

    return $status;
}


=head2 delete

Instance method. Assuming the AID really corresponds to the activity to be
deleted, this method will execute the DELETE statement in the database. It
won't succeed if the activity has any intervals associated with it. Returns
a status object.

=cut

sub delete {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_ACTIVITY_DELETE,
        attrs => [ 'aid' ],
    );
    $self->reset( aid => $self->{aid} ) if $status->ok;

    return $status;
}


=head2 load_by_aid

Loads activity from database, by the AID provided in the argument list,
into a newly-spawned object. The code must be an exact match.  Returns a
status object: if the object is loaded, the code will be
'DISPATCH_RECORDS_FOUND' and the object will be in the payload; if 
the AID is not found in the database, the code will be
'DISPATCH_NO_RECORDS_FOUND'. A non-OK status indicates a DBI error.

=cut

sub load_by_aid {
    my $self = shift;
    my ( $conn, $aid ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_ACTIVITY_SELECT_BY_AID,
        keys => [ $aid ],
    );
}


=head2 load_by_code

Analogous method to L<"load_by_aid">.

=cut

sub load_by_code {
    my $self = shift;
    my ( $conn, $code ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_ACTIVITY_SELECT_BY_CODE,
        keys => [ $code ],
    );
}




=head1 FUNCTIONS

The following functions are not object methods.


=head2 aid_exists

Boolean function


=head2 code_exists

Boolean function

=cut

BEGIN {
    no strict 'refs';
    *{'aid_exists'} = App::Dochazka::REST::Model::Shared::make_test_exists( 'aid' );
    *{'code_exists'} = App::Dochazka::REST::Model::Shared::make_test_exists( 'code' );
}


=head2 aid_by_code

Given a code, attempt to retrieve the corresponding AID.
Returns AID or undef on failure.

=cut

sub aid_by_code {
    my ( $conn, $code ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    my $status = __PACKAGE__->load_by_code( $conn, $code );
    return $status->payload->{'aid'} if $status->code eq 'DISPATCH_RECORDS_FOUND';
    return;
}


=head2 code_by_aid

Given an AID, attempt to retrieve the corresponding code.
Returns code or undef on failure.

=cut

sub code_by_aid {
    my ( $conn, $aid ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    my $status = __PACKAGE__->load_by_aid( $conn, $aid );
    return $status->payload->{'code'} if $status->code eq 'DISPATCH_RECORDS_FOUND';
    return;
}


=head2 get_all_activities

Optionally takes a PARAMHASH that can contain a 'disabled' key which can be
either true or false (defaults to false).

Returns a reference to a hash of hashes, where each hash is one activity object.
If 'disabled' is true, all activities including disabled ones will be included, 
otherwise only the non-disabled activities will be retrieved.

=cut

sub get_all_activities {
    my $conn = shift;
    my %PH = validate( @_, { 
        disabled => { type => SCALAR, default => 0 }
    } );
    
    my $sql = $PH{disabled}
        ? $site->SQL_ACTIVITY_SELECT_ALL_INCLUDING_DISABLED
        : $site->SQL_ACTIVITY_SELECT_ALL_EXCEPT_DISABLED;

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

