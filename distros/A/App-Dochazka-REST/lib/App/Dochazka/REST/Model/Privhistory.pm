# ************************************************************************* 
# Copyright (c) 2014-2015, SUSE LLC
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

package App::Dochazka::REST::Model::Privhistory;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::REST::Model::Shared qw( cud get_history load );
use Data::Dumper;
use Params::Validate qw( :all );
use Try::Tiny;

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Privhistory';




=head1 NAME

App::Dochazka::REST::Model::Privhistory - privilege history functions




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Privhistory;

    ...



=head1 DESCRIPTION

A description of the privhistory data model follows.


=head2 Privilege levels in the database

=head3 Type

The privilege levels themselves are defined in the C<privilege> enumerated
type:

    CREATE TYPE privilege AS ENUM ('passerby', 'inactive', 'active',
    'admin')


=head3 Table

Employees are associated with privilege levels using a C<privhistory>
table:

    CREATE TABLE IF NOT EXISTS privhistory (
        phid       serial PRIMARY KEY,
        eid        integer REFERENCES employees (eid) NOT NULL,
        priv       privilege NOT NULL;
        effective  timestamp NOT NULL,
        remark     text,
        stamp      json
    );



=head3 Stored procedures

There are also two stored procedures for determining privilege levels:

=over

=item * C<priv_at_timestamp> 
Takes an EID and a timestamp; returns privilege level of that employee as
of the timestamp. If the privilege level cannot be determined for the given
timestamp, defaults to the lowest privilege level ('passerby').

=item * C<current_priv>
Wrapper for C<priv_at_timestamp>. Takes an EID and returns the current
privilege level for that employee.

=back


=head2 Privhistory in the Perl API

When an employee object is loaded (assuming the employee exists), the
employee's current privilege level and schedule are included in the employee
object. No additional object need be created for this. Privhistory objects
are created only when an employee's privilege level changes or when an
employee's privilege history is to be viewed.

In the data model, individual privhistory records are represented by
"privhistory objects". All methods and functions for manipulating these objects
are contained in L<App::Dochazka::REST::Model::Privhistory>. The most important
methods are:

=over

=item * constructor (L<spawn>)

=item * basic accessors (L<phid>, L<eid>, L<priv>, L<effective>, L<remark>)

=item * L<reset> (recycles an existing object by setting it to desired state)

=item * L<load> (loads a single privhistory record)

=item * L<load_by_phid> (wrapper for load_by_id)

=item * L<load_by_id> (load a single privhistory record by its PHID)

=item * L<insert> (inserts object into database)

=item * L<delete> (deletes object from database)

=back

For basic C<privhistory> workflow, see C<t/model/privhistory.t>.




=head1 EXPORTS

This module provides the following exports:

=over 

=item L<phid_exists> (boolean)

=item L<get_privhistory>

=back

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( phid_exists get_privhistory );




=head1 METHODS


=head2 load_by_eid

Supposed to be a class method, but in reality we just don't care what the first
argument is.

=cut

sub load_by_eid {
    shift; # discard the first argument
    my ( $conn, $eid, $ts ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },                # EID
        { type => SCALAR|UNDEF, optional => 1 }, # timestamp
    );
  
    if ( $ts ) {
        return load(
            conn => $conn,
            class => __PACKAGE__,
            sql => $site->SQL_PRIVHISTORY_SELECT_ARBITRARY,
            keys => [ $eid, $ts ],
        );
    }

    return load(
        conn => $conn,
        class => __PACKAGE__,
        sql => $site->SQL_PRIVHISTORY_SELECT_CURRENT,
        keys => [ $eid ],
    );
}


=head2 load_by_id

Class method.

=cut

sub load_by_id {
    my $self = shift;
    my ( $conn, $phid ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR }, 
    );

    return load(
        conn => $conn,
        class => __PACKAGE__,
        sql => $site->SQL_PRIVHISTORY_SELECT_BY_PHID,
        keys => [ $phid ],
    );
}


=head2 load_by_phid

Wrapper for load_by_id

=cut

sub load_by_phid {
    my $self = shift;
    my ( $conn, $phid ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR }, 
    );
    return $self->load_by_id( $conn, $phid );
}


=head2 insert

Instance method. Attempts to INSERT a record into the 'privhistory' table.
Field values are taken from the object. Returns a status object.

=cut

sub insert {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_PRIVHISTORY_INSERT,
        attrs => [ 'eid', 'priv', 'effective', 'remark' ],
    );

    return $status;
}


=head2 update

Instance method. Updates the record. Returns status object.

=cut

sub update {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_PRIVHISTORY_UPDATE,
        attrs => [ 'priv', 'effective', 'remark', 'phid' ],
    );

    return $status;
}


=head2 delete

Instance method. Deletes the record. Returns status object.

=cut

sub delete {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_PRIVHISTORY_DELETE,
        attrs => [ 'phid' ],
    );
    $self->reset( 'phid' => $self->{phid} ) if $status->ok;

    return $status;
}



=head1 FUNCTIONS


=head2 phid_exists

Boolean function

=cut

BEGIN {
    no strict 'refs';
    *{'phid_exists'} = App::Dochazka::REST::Model::Shared::make_test_exists( 'phid' );
}


=head2 get_privhistory

Takes a PARAMHASH which can have one or more of the properties 'eid', 'nick',
and 'tsrange'.

At least one of { 'eid', 'nick' } must be specified. If both are specified,
the employee is determined according to 'eid'.

The function returns the history of privilege level changes for that employee
over the given tsrange, or the entire history if no tsrange is supplied. 

The return value will always be an L<App::CELL::Status|status> object.

Upon success, the payload will contain a 'history' key, the value of which will
be a reference to an array of C<privhistory> objects. If nothing is found, the
array will be empty. If there is a DBI error, the payload will be undefined.

=cut

sub get_privhistory {
    my $context = shift;
    return get_history( 'priv', $context->{'dbix_conn'}, @_ );
}




=head1 EXAMPLES

In this section, some examples are presented to help understand how this
module is used.

=head2 Mr. Moujersky joins the firm

Mr. Moujersky was hired and his first day on the job was 2012-06-04. The
C<privhistory> entry for that might be:

    phid       1037 (automatically assigned by PostgreSQL)
    eid        135 (Mr. Moujersky's Dochazka EID)
    priv       'active'
    effective  '2012-06-04 00:00'


=head2 Mr. Moujersky becomes an administrator

Effective 2013-01-01, Mr. Moujersky was given the additional responsibility
of being a Dochazka administrator for his site.

    phid        1512 (automatically assigned by PostgreSQL)
    eid        135 (Mr. Moujersky's Dochazka EID)
    priv       'admin'
    effective  '2013-01-01 00:00'


=head2 Mr. Moujersky goes on parental leave

In February 2014, Mrs. Moujersky gave birth to a baby boy and effective
2014-07-01 Mr. Moujersky went on parental leave to take care of the
Moujersky's older child over the summer while his wife takes care of the
baby.

    phid        1692 (automatically assigned by PostgreSQL)
    eid        135 (Mr. Moujersky's Dochazka EID)
    priv       'inactive'
    effective  '2014-07-01 00:00'

Note that Dochazka will begin enforcing the new privilege level as of 
C<effective>, and not before. However, if Dochazka's session management
is set up to use LDAP authentication, Mr. Moujersky's access to Dochazka may be
revoked at any time at the LDAP level, effectively shutting him out.




=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;

