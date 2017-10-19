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

package App::Dochazka::REST::Model::Schedule;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::REST::Model::Shared qw( cud decode_schedule_json load load_multiple select_single );
use Data::Dumper;
use JSON;
use Params::Validate qw( :all );
use Try::Tiny;

# we get 'spawn', 'reset', and accessors from parent
use parent 'App::Dochazka::Common::Model::Schedule';




=head1 NAME

App::Dochazka::REST::Model::Schedule - schedule functions




=head1 SYNOPSIS

    use App::Dochazka::REST::Model::Schedule;

    ...



=head1 DESCRIPTION

A description of the schedule data model follows.



=head2 Schedules in the database


=head3 Table

Schedules are stored the C<schedules> table. For any given schedule, there is
always only one record in the table -- i.e., individual schedules can be used
for multiple employees. (For example, an organization might have hundreds of
employees on a single, unified schedule.) 

      CREATE TABLE IF NOT EXISTS schedules (
        sid        serial PRIMARY KEY,
        schedule   text UNIQUE NOT NULL,
        disabled   boolean,
        remark     text
      );

The value of the 'schedule' field is a JSON array which looks something like this:

    [
        { low_dow:"MON", low_time:"08:00", high_dow:"MON", high_time:"12:00" },  
        { low_dow:"MON", low_time:"12:30", high_dow:"MON", high_time:"16:30" },  
        { low_dow:"TUE", low_time:"08:00", high_dow:"TUE", high_time:"12:00" },  
        { low_dow:"TUE", low_time:"12:30", high_dow:"TUE", high_time:"16:30" },
        ...
    ]   

Or, to give an example of a more convoluted schedule:

    [   
        { low_dow:"WED", low_time:"22:15", high_dow:"THU", high_time:"03:25" }, 
        { low_dow:"THU", low_time:"05:25", high_dow:"THU", high_time:"09:55" },
        { low_dow:"SAT", low_time:"19:05", high_dow:"SUN", high_time:"24:00" } 
    ] 

The intervals in the JSON string must be sorted and the whitespace, etc.
must be consistent in order for the UNIQUE constraint in the 'schedule'
table to work properly. However, these precautions will no longer be
necessary after PostgreSQL 9.4 comes out and the field type is changed to
'jsonb'.

The 'disabled' field is intended go be used to control which schedules get
offered in, e.g., front-end dialogs when administrators choose which schedule
to assign to a new employee, and the like. For example, there may be schedules
in the database that were used in the past, but it is no longer desirable to 
offer these schedules in the front-end dialog, so the administrator can "remove"
them from the dialog by setting this field to 'true'.


=head3 Process for creating new schedules

It is important to understand how the JSON string introduced in the previous
section is assembled -- or, more generally, how a schedule is created. Essentially,
the schedule is first created in a C<schedintvls> table, with a record for each
time interval in the schedule. This table has triggers and a C<gist> index that 
enforce schedule data integrity so that only a valid schedule can be inserted.
Once the schedule has been successfully built up in C<schedintvls>, it is 
"translated" (using a stored procedure) into a single JSON string, which is
stored in the C<schedules> table. This process is described in more detail below:  

First, if the schedule already exists in the C<schedules> table, nothing
more need be done -- we can skip to L<Schedhistory>

If the schedule we need is not yet in the database, we will have to create it.
This is a three-step process: (1) build up the schedule in the C<schedintvls>
table (sometimes referred to as the "scratch schedule" table because it is used
to store an intermediate product with only a short lifespan); (2) translate the
schedule to form the schedule's JSON representation; (3) insert the JSON string
into the C<schedules> table.

The C<schedintvls>, or "scratch schedule", table:

      CREATE SEQUENCE scratch_sid_seq;

      CREATE TABLE IF NOT EXISTS schedintvls (
        int_id  serial PRIMARY KEY,
        ssid    integer NOT NULL,
        intvl   tsrange NOT NULL,
        EXCLUDE USING gist (ssid WITH =, intvl WITH &&)
      )/,

As stated above, before the C<schedule> table is touched, a "scratch schedule"
must first be created in the C<schedintvls> table. Although this operation
changes the database, it should be seen as a "dry run". The C<gist> index and
a trigger assure that:

=over

=item * no overlapping entries are entered

=item * all the entries fall within a single 168-hour period

=item * all the times are evenly divisible by five minutes

=back

#
# FIXME: expand the trigger to check for "closed-open" C<< [ ..., ... ) >> tsrange
#

If the schedule is successfully inserted into C<schedintvls>, the next step is
to "translate", or convert, the individual intervals (expressed as tsrange
values) into the four-key hashes described in L<Schedules in the database>,
assemble the JSON string, and insert a new row in C<schedules>. 

To facilitate this conversion, a stored procedure C<translate_schedintvl> was
developed.

Successful insertion into C<schedules> will generate a Schedule ID (SID) for
the schedule, enabling it to be used to make Schedhistory objects.

At this point, the scratch schedule is deleted from the C<schedintvls> table. 


=head2 Schedules in the Perl API


=head3 L<Schedintvls> class

=over 

=item * constructor (L<spawn>)

=item * L<reset> method (recycles an existing object)

=item * basic accessor (L<ssid>)

=item * L<intvls> accessor (arrayref containing all tsrange intervals in schedule) 

=item * L<schedule> accessor (arrayref containing "translated" intervals)

=item * L<load> method (load the object from the database and translate the tsrange intervals)

=item * L<insert> method (insert all the tsrange elements in one go)

=item * L<delete> method (delete all the tsrange elements when we're done with them)

=item * L<json> method (generate JSON string from the translated intervals)

=back

For basic workflow, see C<t/model/schedule.t>.


=head3 C<Schedule> class

=over

=item * constructor (L<spawn>)

=item * L<reset> method (recycles an existing object)

=item * basic accessors (L<sid>, L<schedule>, L<remark>)

=item * L<insert> method (inserts the schedule if it isn't in the database already)

=item * L<delete> method

=item * L<load> method (not implemented yet) 

#=item * L<get_schedule_json> function (get JSON string associated with a given SID)
#
=back

For basic workflow, see C<t/model/schedule.t>.




=head1 EXPORTS

This module provides the following exports:

=over 

#=item * C<get_schedule_json>
#
=item * C<get_all_schedules>

=item * C<sid_exists> (boolean)

=back

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( 
    get_all_schedules
    sid_exists
);



=head1 METHODS


=head2 insert

Instance method. Attempts to INSERT a record into the 'schedules' table.
Field values are taken from the object. Returns a status object.

If the "schedule" field of the schedule to be inserted matches an existing
schedule, no new record is inserted. Instead, the existing schedule record
is returned. In such a case, the "scode", "remark", and "disabled" fields
are ignored - except when they are NULL in the existing record.

=cut

sub insert {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    # if the exact same schedule is already in the database, we
    # don't insert it again
    my $status = select_single( 
        conn => $context->{'dbix_conn'}, 
        sql => $site->SQL_SCHEDULES_SELECT_BY_SCHEDULE, 
        keys => [ $self->{schedule} ],
    );
    $log->info( "select_single returned: " . Dumper $status );
    if ( $status->level eq 'OK' ) {
        my $found_sched = App::Dochazka::REST::Model::Schedule->spawn( 
            sid => $status->payload->[0],
            scode => $status->payload->[1],
            schedule => $status->payload->[2],
            remark => $status->payload->[3],
            disabled => $status->payload->[4],
        );
        $self->{'sid'} = $found_sched->sid;
        {
            #
            # the exact schedule exists, but if any of { scode, remark, disabled }
            # are NULL and we have a value, update the record to reflect the value
            # (in other words, do not prefer NULLs over real values)
            #
            my $do_update = 0;
            if ( ! defined( $found_sched->scode ) and defined( $self->scode ) ) {
                $found_sched->scode( $self->scode );
                $do_update = 1;
            }
            if ( ! defined( $found_sched->remark ) and defined( $self->remark ) ) {
                $found_sched->remark( $self->remark );
                $do_update = 1;
            }
            if ( ! defined( $found_sched->disabled ) and defined( $self->disabled ) ) {
                $found_sched->disabled( $self->disabled );
                $do_update = 1;
            }
            if ( $do_update ) {
                $status = $found_sched->update( $context );
                if ( $status->level eq 'OK' and $status->code eq 'DOCHAZKA_CUD_OK' ) {
                    $status->code( 'DOCHAZKA_SCHEDULE_UPDATE_OK' );
                }
                return $status;
            }
            return $CELL->status_ok( 'DOCHAZKA_SCHEDULE_EXISTS', args => [ $self->{sid} ],
                payload => $found_sched );
        }
    } elsif( $status->level ne 'NOTICE' ) {
        $log->info( "select_single status was neither OK nor NOTICE; returning it as-is" );
        return $status;
    }

    # no exact match found, insert a new record
    $log->debug( __PACKAGE__ . "::insert calling cud to insert new schedule" );
    $status = cud(
        conn => $context->{'dbix_conn'}, 
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_SCHEDULE_INSERT,
        attrs => [ 'scode', 'schedule', 'remark' ],
    );

    if ( $status->ok ) {
        $status->code( 'DOCHAZKA_SCHEDULE_INSERT_OK' );
        $log->info( "Inserted new schedule with SID " . $self->{sid} );
    }
    return $status;
}


=head2 update

Although we do not allow the 'sid' or 'schedule' fields to be updated, schedule
records have 'scode', 'remark' and 'disabled' fields that can be updated via this
method. 

=cut

sub update {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    return $CELL->status_err( 'DOCHAZKA_MALFORMED_400' ) unless $self->{'sid'};

    my $status = cud(
        conn => $context->{'dbix_conn'}, 
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_SCHEDULE_UPDATE,
        attrs => [ 'scode', 'remark', 'disabled', 'sid' ],
    );

    return $status;
}


=head2 delete

Instance method. Attempts to DELETE a schedule record. This may succeed
if no other records in the database refer to this schedule.

=cut

sub delete {
    my $self = shift;
    my ( $context ) = validate_pos( @_, { type => HASHREF } );

    my $status = cud(
        conn => $context->{'dbix_conn'}, 
        eid => $context->{'current'}->{'eid'},
        object => $self,
        sql => $site->SQL_SCHEDULE_DELETE,
        attrs => [ 'sid' ],
    );
    $self->reset( sid => $self->{sid} ) if $status->ok;

    $log->debug( "Entering " . __PACKAGE__ . "::delete with status " . Dumper( $status ) );
    return $status;
}


=head2 load_by_scode

Analogous function to L<App::Dochazka::REST::Model::Activity/"load_by_aid">.

=cut

sub load_by_scode {
    my $self = shift;
    my ( $conn, $scode ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_SCHEDULE_SELECT_BY_SCODE,
        keys => [ $scode ],
    );
}



=head2 load_by_sid

Analogous function to L<App::Dochazka::REST::Model::Activity/"load_by_aid">.

=cut

sub load_by_sid {
    my $self = shift;
    my ( $conn, $sid ) = validate_pos( @_,
        { isa => 'DBIx::Connector' },
        { type => SCALAR },
    );

    return load( 
        conn => $conn,
        class => __PACKAGE__, 
        sql => $site->SQL_SCHEDULE_SELECT_BY_SID,
        keys => [ $sid ],
    );
}



=head1 FUNCTIONS


=head2 sid_exists

Boolean function

=cut

BEGIN {
    no strict 'refs';
    *{'sid_exists'} = App::Dochazka::REST::Model::Shared::make_test_exists( 'sid' );
}


=head2 get_all_schedules

Returns a list of all schedule objects, ordered by sid. Takes one
argument - a paramhash that can contain only one key, 'disabled', 
which can be either true or false (defaults to true). 

=cut

sub get_all_schedules {
    my %PH = validate( @_, { 
        conn => { isa => 'DBIx::Connector' },
        disabled => { type => SCALAR, default => 0 }
    } );
    
    my $sql = $PH{disabled}
        ? $site->SQL_SCHEDULES_SELECT_ALL_INCLUDING_DISABLED
        : $site->SQL_SCHEDULES_SELECT_ALL_EXCEPT_DISABLED;

    # run the query and gather the results

    return load_multiple(
        conn => $PH{'conn'},
        class => __PACKAGE__,
        sql => $sql,
        keys => [],
    );
}


#=head2 get_schedule_json
#
#Given a SID, queries the database for the JSON string associated with the SID.
#Returns undef if not found.
#
#=cut
#
#sub get_schedule_json {
#    my ( $sid ) = @_;
#    die "Problem with arguments in get_schedule_json" if not defined $sid;
#
#    my $json;
#    try {
#        $conn->do( fixup => sub {
#            ( $json ) = $_->selectrow_array( $site->SQL_SCHEDULES_SELECT_SCHEDULE,
#                                         undef,
#                                         $sid );
#        } );
#    }
#    
#    if ( $json ) {
#        $log->debug( __PACKAGE__ . "::get_schedule_json got schedule from database: $json" );
#        return decode_schedule_json( $json );
#    }
#    return;
#}



=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;

