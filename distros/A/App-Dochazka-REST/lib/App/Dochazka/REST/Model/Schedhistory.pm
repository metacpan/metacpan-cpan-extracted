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

package App::Dochazka::REST::Model::Schedhistory;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::REST::Model::Shared qw( cud get_history load );
use Data::Dumper;
use Params::Validate qw( :all );

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Schedhistory';




=head1 NAME

App::Dochazka::REST::Model::Schedhistory - schedule history functions




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Schedhistory;

    ...



=head1 DESCRIPTION

A description of the schedhistory data model follows.


=head2 Schedhistory in the database

=head3 Table

Once we know the SID of the schedule we would like to assign to a given
employee, it is time to insert a record into the C<schedhistory> table:

      CREATE TABLE IF NOT EXISTS schedhistory (
        shid       serial PRIMARY KEY,
        eid        integer REFERENCES employees (eid) NOT NULL,
        sid        integer REFERENCES schedules (sid) NOT NULL,
        effective  timestamp NOT NULL,
        remark     text,
        stamp      json
      );

=head3 Stored procedures

This table also includes two stored procedures -- C<sid_at_timestamp> and
C<current_schedule> -- which will return an employee's schedule as of a given
date/time and as of 'now', respectively. For the procedure definitions, see
C<dbinit_Config.pm>

See also L<When history changes take effect>.


=head2 Schedhistory in the Perl API

=over

=item * constructor (L<spawn>)

=item * L<reset> method (recycles an existing object)

=item * basic accessors (L<shid>, L<eid>, L<sid>, L<effective>, L<remark>)

=item * L<load_by_eid> method (load schedhistory record from EID and optional timestamp)

=item * L<load_by_shid> method (wrapper for load_by_id)

=item * L<load_by_id> (load schedhistory record by its SHID)

=item * L<insert> method (straightforward)

=item * L<delete> method (straightforward) -- not tested yet # FIXME

=back

For basic workflow, see C<t/model/schedule.t>.




=head1 EXPORTS

This module provides the following exports:

=over 

=item L<get_schedhistory>

=back

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( get_schedhistory );



=head1 METHODS


=head2 load_by_eid

Class method. Given an EID, and, optionally, a timestamp, attempt to 
look it up in the database. Generate a status object: if a schedhistory 
record is found, it will be in the payload and the code will be
'DISPATCH_RECORDS_FOUND'.

=cut

sub load_by_eid {
    my $self = shift;
    my ( $conn, $eid, $ts ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR },                # EID
        { type => SCALAR|UNDEF, optional => 1 }, # optional timestamp
    );

    if ( $ts ) {
        return load(
            conn => $conn,
            class => __PACKAGE__,
            sql => $site->SQL_SCHEDHISTORY_SELECT_ARBITRARY,
            keys => [ $eid, $ts ],
        );
    }

    return load(
        conn => $conn,
        class => __PACKAGE__,
        sql => $site->SQL_SCHEDHISTORY_SELECT_CURRENT,
        keys => [ $eid ],
    );
}
    


=head2 load_by_id

Given a shid, load a single schedhistory record.

=cut

sub load_by_id {
    my $self = shift;
    my ( $conn, $shid ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR } 
    );

    return load(
        conn => $conn,
        class => __PACKAGE__,
        sql => $site->SQL_SCHEDHISTORY_SELECT_BY_SHID,
        keys => [ $shid ],
    );
}


=head2 load_by_shid

Wrapper for load_by_id

=cut

sub load_by_shid {
    my $self = shift;
    my ( $conn, $shid ) = validate_pos( @_, 
        { isa => 'DBIx::Connector' },
        { type => SCALAR } 
    );

    return $self->load_by_id( $conn, $shid );
}


=head2 insert

Instance method. Attempts to INSERT a record into the 'Schedhistory' table.
Field values are taken from the object. Returns a status object.

=cut

sub insert {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'},
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_SCHEDHISTORY_INSERT,
        attrs => [ 'eid', 'sid', 'effective', 'remark' ],
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
        sql => $site->SQL_SCHEDHISTORY_UPDATE,
        attrs => [ 'sid', 'effective', 'remark', 'shid' ],
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
        sql => $site->SQL_SCHEDHISTORY_DELETE,
        attrs => [ 'shid' ],
    );
    $self->reset( 'shid' => $self->{shid} ) if $status->ok;

    return $status;
}


=head2 get_schedhistory

Takes a PARAMHASH which can have one or more of the properties 'eid', 'nick',
and 'tsrange'.

At least one of { 'eid', 'nick' } must be specified. If both are specified,
the employee is determined according to 'eid'.

The function returns the history of schedule changes for that employee
over the given tsrange, or the entire history if no tsrange is supplied. 

The return value will always be an L<App::CELL::Status|status> object.

Upon success, the payload will be a reference to an array of C<schedhistory>
objects. If nothing is found, the array will be empty. If there is a DBI error,
the payload will be undefined.

=cut

sub get_schedhistory {
    my $context = shift;
    return get_history( 'sched', $context->{'dbix_conn'}, @_ );
}



=head1 EXAMPLES

In this section, some examples are presented to give an idea of how this
module is used.


=head2 Sam Wallace joins the firm

Let's say Sam's initial schedule is 09:00-17:00, Monday to Friday. To
reflect that, the C<schedintvls> table might contain the following intervals
for C<< sid = 9 >>

    '[2014-06-02 09:00, 2014-06-02 17:00)'
    '[2014-06-03 09:00, 2014-06-03 17:00)'
    '[2014-06-04 09:00, 2014-06-04 17:00)'
    '[2014-06-05 09:00, 2014-06-05 17:00)'
    '[2014-06-06 09:00, 2014-06-06 17:00)'

and the C<schedhistory> table would contain a record like this:

    shid      848 (automatically assigned by PostgreSQL)
    eid       39 (Sam's Dochazka EID)
    sid       9
    effective '2014-06-04 00:00'

(This is a straightfoward example.)


=head2 Sam goes on night shift

A few months later, Sam gets assigned to the night shift. A new
C<schedhistory> record is added:

    shid     1215 (automatically assigned by PostgreSQL)
    eid        39 (Sam's Dochazka EID)
    sid        17 (link to Sam's new weekly work schedule)
    effective  '2014-11-17 12:00'

And the schedule intervals for C<< sid = 17 >> could be:

    '[2014-06-02 23:00, 2014-06-03 07:00)'
    '[2014-06-03 23:00, 2014-06-04 07:00)'
    '[2014-06-04 23:00, 2014-06-05 07:00)'
    '[2014-06-05 23:00, 2014-06-06 07:00)'
    '[2014-06-06 23:00, 2014-06-07 07:00)'
    
(Remember: the date part in this case designates the day of the week)




=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;



