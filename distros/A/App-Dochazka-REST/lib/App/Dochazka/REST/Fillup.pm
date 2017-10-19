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

package App::Dochazka::REST::Fillup;

use 5.012;
use strict;
use warnings;
use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::Common::Model;
use App::Dochazka::REST::ConnBank qw( $dbix_conn );
use App::Dochazka::REST::Model::Employee; 
use App::Dochazka::REST::Model::Interval qw(
    fetch_intervals_by_eid_and_tsrange_inclusive
);
use App::Dochazka::REST::Model::Shared qw(
    canonicalize_tsrange
    split_tsrange
);
use App::Dochazka::REST::Model::Tempintvl qw(
    fetch_tempintvls_by_tiid_and_tsrange 
);
use App::Dochazka::REST::Holiday qw(
    calculate_hours
    canon_date_diff
    canon_to_ymd
    get_tomorrow
    holidays_in_daterange
    ymd_to_canon
);
use Data::Dumper;
use Date::Calc qw(
    Add_Delta_Days
    Date_to_Days
    Day_of_Week
    check_date
);
use JSON qw( decode_json );
use Params::Validate qw( :all );
use Try::Tiny;

BEGIN {
    no strict 'refs';
    our %attr= (
        act_obj => { 
            type => HASHREF,
            isa => 'App::Dochazka::REST::Model::Activity', 
            optional => 1
        },
        clobber => { type => BOOLEAN, optional => 1 },
        constructor_status => { 
            type => HASHREF,
            isa => 'App::CELL::Status',
            optional => 1
        },
        context => { type => HASHREF, optional => 1 },
        date_list => { type => ARRAYREF, optional => 1 },
        dry_run => { type => BOOLEAN, optional => 1 },
        emp_obj => {
            type => HASHREF,
            isa => 'App::Dochazka::REST::Model::Employee',
            optional => 1
        },
        intervals => { type => ARRAYREF, optional => 1 },
        long_desc => { type => SCALAR, optional => 1 },
        remark => { type => SCALAR, optional => 1 },
        tiid => { type => SCALAR, optional => 1 },
        tsrange => { type => HASHREF, optional => 1 },
        tsranges => { type => ARRAYREF, optional => 1 },
    );
    map {
        my $fn = __PACKAGE__ . "::$_";
        $log->debug( "BEGIN BLOCK: $_ $fn" );
        *{ $fn } = 
            App::Dochazka::Common::Model::make_accessor( $_, $attr{ $_ } ); 
    } keys %attr;

    *{ 'reset' } = sub {
        # process arguments
        my $self = shift;
        my %ARGS = validate( @_, \%attr ) if @_ and defined $_[0];

        # Wipe out current TIID
        $self->DESTROY;

        # Set attributes to run-time values sent in argument list.
        # Attributes that are not in the argument list will get set to undef.
        map { $self->{$_} = $ARGS{$_}; } keys %attr;

        # run the populate function, if any
        $self->populate() if $self->can( 'populate' );

        # return an appropriate throw-away value
        return;
    };

    *{ 'TO_JSON' } = sub {
        my $self = shift;
        my $unblessed_copy;
        map { $unblessed_copy->{$_} = $self->{$_}; } keys %attr;
        return $unblessed_copy;
    };

}

my %dow_to_num = (
    'MON' => 1,
    'TUE' => 2,
    'WED' => 3,
    'THU' => 4,
    'FRI' => 5,
    'SAT' => 6,
    'SUN' => 7,
);
my %num_to_dow = reverse %dow_to_num;



=head1 NAME

App::Dochazka::REST::Fillup - fillup routines




=head1 SYNOPSIS

    use App::Dochazka::REST::Fillup;

    ...




=head1 METHODS


=head2 populate

Get the next TIID and store in the object

=cut

sub populate {
    my $self = shift;
    if ( ! exists( $self->{tiid} ) or ! defined( $self->{tiid} ) or $self->{tiid} == 0 ) {
        my $ss = _next_tiid();
        $log->info( "Got next TIID: $ss" );
        $self->{tiid} = $ss;
    }
    return;
}


=head2 Accessors

Make accessors for all the attributes. Already done, above, in BEGIN block.

=cut


=head2 _vet_context

Performs various tests on the C<context> attribute. If the value of that
attribute is not what we're expecting, returns a non-OK status. Otherwise,
returns an OK status.

=cut

sub _vet_context {
    my $self = shift;
    my %ARGS = @_;
    return $CELL->status_not_ok unless $ARGS{context};
    return $CELL->status_not_ok unless $ARGS{context}->{dbix_conn};
    return $CELL->status_not_ok unless $ARGS{context}->{dbix_conn}->isa('DBIx::Connector');
    $self->context( $ARGS{context} );
    $self->{'vetted'}->{'context'} = 1;
    return $CELL->status_ok;
}


=head2 _vet_date_spec

The user can specify fillup dates either as a tsrange or as a list of
individual dates.

One or the other must be given, not neither and not both.

Returns a status object.

=cut

sub _vet_date_spec {
    my $self = shift;
    my %ARGS = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_vet_date_spec to enforce date specification policy" );

    if ( defined( $ARGS{date_list} ) and defined( $ARGS{tsrange} ) ) {
        $log->debug( "date_spec is NOT OK" );
        return $CELL->status_not_ok;
    }
    if ( ! defined( $ARGS{date_list} ) and ! defined( $ARGS{tsrange} ) ) {
        $log->debug( "date_spec is NOT OK" );
        return $CELL->status_not_ok;
    }
    $self->{'vetted'}->{'date_spec'} = 1;
    $log->debug( "date_spec is OK" );
    return $CELL->status_ok;
}


=head2 _vet_date_list

This function takes one named argument: date_list, the value of which must
be a reference to an array of dates, each in canonical YYYY-MM-DD form. For
example, this

    [ '2016-01-13', '2016-01-27', '2016-01-14' ]

is a legal C<date_list> argument.

This function performs various checks on the date list, sorts it, and
populates the C<tsrange> and C<tsranges> attributes based on it. For the
sample date list given above, the tsrange will be something like

    { tsrange => "[\"2016-01-13 00:00:00+01\",\"2016-01-28 00:00:00+01\")" }
    
This is used to make sure the employee's schedule and priv level did not
change during the time period represented by the date list, as well as in
C<fillup_tempintvls> to generate the C<tempintvl> working set.

Returns a status object.

=cut

sub _vet_date_list {
    my $self = shift;
    my ( %ARGS ) = validate( @_, {
        date_list => { type => ARRAYREF|UNDEF },
    } );
    $log->debug( "Entering " . __PACKAGE__ . "::_vet_date_list to vet/populate the date_list property" );
    if ( $ARGS{'date_list'} ) {
        $log->debug( "Date list is " . Dumper $ARGS{'date_list'} );
    }

    die "GOPHFQQ! tsrange property must not be populated in _vet_date_list()" if $self->tsrange;

    return $CELL->status_ok if not defined( $ARGS{date_list} );
    return $CELL->status_err( 'DOCHAZKA_EMPTY_DATE_LIST' ) if scalar( @{ $ARGS{date_list} } ) == 0;

    # check that dates are valid and in canonical form
    my @canonicalized_date_list = ();
    foreach my $date ( @{ $ARGS{date_list} } ) {
        my ( $y, $m, $d ) = canon_to_ymd( $date );
        if ( ! check_date( $y, $m, $d ) ) {
            return $CELL->status_err( 
                "DOCHAZKA_INVALID_DATE_IN_DATE_LIST",
                args => [ $date ],
            );
        }
        push @canonicalized_date_list, sprintf( "%04d-%02d-%02d", $y, $m, $d );
    }
    my @sorted_date_list = sort @canonicalized_date_list;
    $self->date_list( \@sorted_date_list );

    my $noof_entries = scalar( @{ $self->date_list } );
    if ( $noof_entries > $site->DOCHAZKA_INTERVAL_FILLUP_MAX_DATELIST_ENTRIES ) {
        return $CELL->status_err( 
            'DOCHAZKA_INTERVAL_FILLUP_DATELIST_TOO_LONG', 
            args => [ $noof_entries ],
        );
    }

    # populate tsrange
    if ( scalar @sorted_date_list == 0 ) {
        $self->tsrange( undef );
    } elsif ( scalar @sorted_date_list == 1 ) {
        my $t = "[ $sorted_date_list[0] 00:00, $sorted_date_list[0] 24:00 )";
        my $status = canonicalize_tsrange( $self->context->{dbix_conn}, $t );
        return $status unless $status->ok;
        $self->tsrange( { tsrange => $status->payload } );
    } else {
        my $t = "[ $sorted_date_list[0] 00:00, $sorted_date_list[-1] 24:00 )";
        my $status = canonicalize_tsrange( $self->context->{dbix_conn}, $t );
        return $status unless $status->ok;
        $self->tsrange( { tsrange => $status->payload } );
    }

    # populate tsranges
    if ( scalar @sorted_date_list == 0 ) {
        $self->tsranges( undef );
    } else {
        my @tsranges = ();
        foreach my $date ( @sorted_date_list ) {
            my $t = "[ $date 00:00, $date 24:00 )";
            my $status = canonicalize_tsrange(
                $self->context->{dbix_conn},
                $t,
            );
            return $status unless $status->ok;
            # push canonicalized tsrange onto result stack
            push @tsranges, { tsrange => $status->payload };
        }
        $self->tsranges( \@tsranges );
    }
 
    $self->{'vetted'}->{'date_list'} = 1;
    return $CELL->status_ok; 
}


=head2 _vet_tsrange

Takes constructor arguments. Checks the tsrange for sanity and populates
the C<tsrange>, C<lower_canon>, C<lower_ymd>, C<upper_canon>, C<upper_ymd>
attributes. Returns a status object.

=cut

sub _vet_tsrange {
    my $self = shift;
    my %ARGS = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_vet_tsrange to vet the tsrange " . 
                 ( defined( $ARGS{tsrange} ) ? $ARGS{tsrange} : "(undef)" ) );

    die "YAHOOEY! No DBIx::Connector in object" unless $self->context->{dbix_conn};

    # if a tsrange property was given in the arguments, that means no
    # date_list was given: convert the tsrange argument into an arrayref
    if ( my $t = $ARGS{tsrange} ) {
        my $status = canonicalize_tsrange(
            $self->context->{dbix_conn},
            $t,
        );
        return $status unless $status->ok;
        $self->tsrange( { tsrange => $status->payload } );
        $self->tsranges( [ { tsrange => $status->payload } ] );
    }

    foreach my $t_hash ( @{ $self->tsranges }, $self->tsrange ) {

        # split the tsrange
        my @parens = $t_hash->{tsrange} =~ m/[^\[(]*([\[(])[^\])]*([\])])/;
        my $status = split_tsrange( $self->context->{'dbix_conn'}, $t_hash->{tsrange} );
        $log->info( "split_tsrange() returned: " . Dumper( $status ) );
        return $status unless $status->ok;
        my $low = $status->payload->[0];
        my $upp = $status->payload->[1];
        my @low = canon_to_ymd( $low );
        my @upp = canon_to_ymd( $upp );

        # lower date bound = tsrange:begin_date minus one day
        @low = Add_Delta_Days( @low, -1 );
        $low = ymd_to_canon( @low );

        # upper date bound = tsrange:begin_date plus one day
        @upp = Add_Delta_Days( @upp, 1 );
        $upp = ymd_to_canon( @upp );

        # check DOCHAZKA_INTERVAL_FILLUP_LIMIT
        # - add two days to the limit to account for how we just stretched $low and $upp
        my $fillup_limit = $site->DOCHAZKA_INTERVAL_FILLUP_LIMIT + 2;
        if ( $fillup_limit < canon_date_diff( $low, $upp ) ) {
            return $CELL->status_err( 'DOCHAZKA_FILLUP_TSRANGE_TOO_LONG', args => [ $ARGS{tsrange} ] )
        }

        $t_hash->{'lower_ymd'} = \@low;
        $t_hash->{'upper_ymd'} = \@upp;
        $t_hash->{'lower_canon'} = $low;
        $t_hash->{'upper_canon'} = $upp;
    }

    $self->{'vetted'}->{'tsrange'} = 1;
    return $CELL->status_ok( 'SUCCESS' );
}


=head2 _vet_employee

Expects to be called *after* C<_vet_tsrange>.

Takes an employee object. First, retrieves
from the database the employee object corresponding to the EID. Second,
checks that the employee's privlevel did not change during the tsrange.
Third, retrieves the prevailing schedule and checks that the schedule does
not change at all during the tsrange. Returns a status object.

=cut

sub _vet_employee {
    my $self = shift;
    my ( %ARGS ) = validate( @_, {
        emp_obj => { 
            type => HASHREF, 
            isa => 'App::Dochazka::REST::Model::Employee', 
        },
    } );
    my $status;

    die 'AKLDWW###%AAAAAH!' unless $ARGS{emp_obj}->eid;
    $self->{'emp_obj'} = $ARGS{emp_obj};

    # check for priv and schedule changes during the tsrange
    if ( $self->{'emp_obj'}->priv_change_during_range( 
        $self->context->{'dbix_conn'}, 
        $self->tsrange->{'tsrange'},
    ) ) {
        return $CELL->status_err( 'DOCHAZKA_EMPLOYEE_PRIV_CHANGED' ); 
    }
    if ( $self->{'emp_obj'}->schedule_change_during_range(
        $self->context->{'dbix_conn'}, 
        $self->tsrange->{'tsrange'},
    ) ) {
        return $CELL->status_err( 'DOCHAZKA_EMPLOYEE_SCHEDULE_CHANGED' ); 
    }

    # get privhistory record prevailing at beginning of tsrange
    my $probj = $self->{emp_obj}->privhistory_at_timestamp( 
        $self->context->{'dbix_conn'}, 
        $self->tsrange->{'tsrange'},
    );
    if ( ! $probj->priv ) {
        return $CELL->status_err( 'DISPATCH_EMPLOYEE_NO_PRIVHISTORY' );
    }
    if ( $probj->priv eq 'active' or $probj->priv eq 'admin' ) {
        # all green
    } else {
        return $CELL->status_err( 'DOCHAZKA_INSUFFICIENT_PRIVILEGE', args => [ $probj->priv ] );
    }

    # get schedhistory record prevailing at beginning of tsrange
    my $shobj = $self->{emp_obj}->schedhistory_at_timestamp( 
        $self->context->{'dbix_conn'}, 
        $self->tsrange->{'tsrange'},
    );
    if ( ! $shobj->sid ) {
        return $CELL->status_err( 'DISPATCH_EMPLOYEE_NO_SCHEDULE' );
    }
    my $sched_obj = App::Dochazka::REST::Model::Schedule->load_by_sid(
        $self->context->{'dbix_conn'},
        $shobj->sid,
    )->payload;
    die "AGAHO-NO!" unless ref( $sched_obj) eq 'App::Dochazka::REST::Model::Schedule'
        and $sched_obj->schedule =~ m/high_dow/;
    $self->{'sched_obj'} = $sched_obj;

    $self->{'vetted'}->{'employee'} = 1;
    return $CELL->status_ok( 'SUCCESS' );
}


=head2 _vet_activity

Takes a C<DBIx::Connector> object and an AID. Verifies that the AID exists
and populates the C<activity_obj> attribute.

=cut

sub _vet_activity {
    my $self = shift;
    my ( %ARGS ) = validate( @_, {
        aid => { type => SCALAR|UNDEF, optional => 1 },
    } );
    my $status;

    if ( exists( $ARGS{aid} ) and defined( $ARGS{aid} ) ) {
        # load activity object from database into $self->{act_obj}
        $status = App::Dochazka::REST::Model::Activity->load_by_aid( 
            $self->context->{'dbix_conn'}, 
            $ARGS{aid}
        );
        if ( $status->ok and $status->code eq 'DISPATCH_RECORDS_FOUND' ) {
            # all green; fall thru to success
            $self->{'act_obj'} = $status->payload;
            $self->{'aid'} = $status->payload->aid;
        } elsif ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
            # non-existent activity
            return $CELL->status_err( 'DOCHAZKA_GENERIC_NOT_EXIST', args => [ 'activity', 'AID', $ARGS{aid} ] );
        } else {
            return $status;
        }
    } else {
        # if no aid given, try to look up "WORK"
        $status = App::Dochazka::REST::Model::Activity->load_by_code( 
            $self->context->{'dbix_conn'},
            'WORK'
        );
        if ( $status->ok and $status->code eq 'DISPATCH_RECORDS_FOUND' ) {
            # all green; fall thru to success
            $self->{'act_obj'} = $status->payload;
            $self->{'aid'} = $status->payload->aid;
        } elsif ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
            return $CELL->status_err( 'DOCHAZKA_GENERIC_NOT_EXIST', args => [ 'activity', 'code', 'WORK' ] );
        } else {
            return $status;
        }
    }

    $self->{'vetted'}->{'activity'} = 1;
    return $CELL->status_ok( 'SUCCESS' );
}


=head2 vetted

Returns boolean true if object has been completely vetted. Otherwise false.

=cut

sub vetted {
    my $self = shift;
    ( 
        $self->{'vetted'}->{'tsrange'} and 
        $self->{'tsrange'} and
        $self->{'vetted'}->{'employee'} and 
        $self->emp_obj and
        ref( $self->emp_obj ) eq 'App::Dochazka::REST::Model::Employee' and
        $self->{'vetted'}->{'activity'} and
        $self->act_obj and
        ref( $self->act_obj ) eq 'App::Dochazka::REST::Model::Activity'
    ) ? 1 : 0;
}


=head2 fillup_tempintvls

This method takes no arguments and expects to be called on a fully vetted
object (see C<vetted>, above).

This method creates (and attempts to INSERT records corresponding to) a
number of Tempintvl objects according to the C<tsrange> (as stored in the
Fillup object) and the employee's schedule.

Note that the purpose of this method is to generate a set of Tempintvl
objects that could potentially become attendance intervals. The
C<fillup_tempintvls> method only deals with Tempintvls. It is up to the 
C<fillup_commit> method to choose the right Tempintvls for the fillup
operation in question and to construct and insert the corresponding
Interval objects.

Returns a status object.

=cut

sub fillup_tempintvls {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::fillup_tempintvls" );

    die "FILLUP_OBJECT_NOT_VETTED" unless $self->vetted;

    my $rest_sched_hash_lower = _init_lower_sched_hash( $self->{sched_obj}->schedule );

    my $status;
    my @pushed_intervals;

    my $holidays = holidays_in_daterange(
        'begin' => $self->tsrange->{lower_canon},
        'end' => $self->tsrange->{upper_canon},
    );

    # create a bunch of Tempintvl objects
    my @tempintvls;

    my $d = $self->tsrange->{'lower_canon'};
    my $days_upper = Date_to_Days( @{ $self->tsrange->{upper_ymd} } );
    WHILE_LOOP: while ( $d ne get_tomorrow( $self->tsrange->{'upper_canon'} ) ) {
        if ( _is_holiday( $d, $holidays ) ) {
            $d = get_tomorrow( $d );
            next WHILE_LOOP;
        }

        my ( $ly, $lm, $ld ) = canon_to_ymd( $d );
        my $days_lower = Date_to_Days( $ly, $lm, $ld );
        my $ndow = Day_of_Week( $ly, $lm, $ld );

        # get schedule entries starting on that DOW
        foreach my $entry ( @{ $rest_sched_hash_lower->{ $ndow } } ) {
            my ( $days_high_dow, $hy, $hm, $hd );
            # convert "high_dow" into a number of days
            $days_high_dow = $days_lower + 
                ( $dow_to_num{ $entry->{'high_dow'} } - $dow_to_num{ $entry->{'low_dow'} } );
            if ( $days_high_dow <= $days_upper ) {

                # create a Tempintvl object
                my $to = App::Dochazka::REST::Model::Tempintvl->spawn( tiid => $self->tiid );
                die "COUGH! GAG! Tempintvl object tiid problem!" 
                   unless $to->tiid and $to->tiid == $self->tiid;

                # compile the intvl
                ( $hy, $hm, $hd ) = Days_to_Date( $days_high_dow );
                $to->intvl( "[ " . ymd_to_canon( $ly,$lm,$ld ) . " " . $entry->{'low_time'} . 
                            ", " . ymd_to_canon( $hy,$hm,$hd ) . " ".  $entry->{'high_time'} . " )" );

                # insert the object
                my $status = $to->insert( $self->context );
                return $status unless $status->ok;

                # push it onto results array
                push @tempintvls, $to;
            }
        }
        $d = get_tomorrow( $d );
    }

    $log->debug( "fillup_tempintvls completed successfully, " . scalar( @tempintvls ) . 
                 " tempintvl objects created and inserted into database" );
    $self->intervals( \@tempintvls );
    return $CELL->status_ok( 'DOCHAZKA_TEMPINTVLS_INSERT_OK' );
}


=head2 new

Constructor method. Returns an C<App::Dochazka::REST::Fillup>
object.

The constructor method does everything up to C<fillup>. It also populates the
C<constructor_status> attribute with an C<App::CELL::Status> object.

=cut

sub new {
    my $class = shift;
    my ( %ARGS ) = validate( @_, {
        context => { type => HASHREF },
        emp_obj => { 
            type => HASHREF,
            isa => 'App::Dochazka::REST::Model::Employee', 
        },
        aid => { type => SCALAR|UNDEF, optional => 1 },
        code => { type => SCALAR|UNDEF, optional => 1 },
        tsrange => { type => SCALAR, optional => 1 },
        date_list => { type => ARRAYREF, optional => 1 },
        long_desc => { type => SCALAR|UNDEF, optional => 1 },
        remark => { type => SCALAR|UNDEF, optional => 1 },
        clobber => { default => 0 },
        dry_run => { default => 0 },
    } );
    $log->debug( "Entering " . __PACKAGE__ . "::new" );

    my ( $self, $status );
    # (re-)initialize $self
    if ( $class eq __PACKAGE__ ) {
        $self = bless {}, $class;
        $self->populate();
    } else {
        die "AGHOOPOWDD@! Constructor must be called like this App::Dochazka::REST::Fillup->new()";
    }
    die "AGHOOPOWDD@! No tiid in Fillup object!" unless $self->tiid;

    map {
        if ( ref( $ARGS{$_} ) eq 'JSON::PP::Boolean' ) {
            $ARGS{$_} = $ARGS{$_} ? 1 : 0;
        }
        $self->$_( $ARGS{$_} ) if defined( $ARGS{$_} );
    } qw( long_desc remark clobber dry_run );

    # the order of the following checks is significant!
    $self->constructor_status( $self->_vet_context( context => $ARGS{context} ) );
    return $self unless $self->constructor_status->ok;
    $self->constructor_status( $self->_vet_date_spec( %ARGS ) );
    return $self unless $self->constructor_status->ok;
    $self->constructor_status( $self->_vet_date_list( date_list => $ARGS{date_list} ) );
    return $self unless $self->constructor_status->ok;
    $self->constructor_status( $self->_vet_tsrange( %ARGS ) );
    return $self unless $self->constructor_status->ok;
    $self->constructor_status( $self->_vet_employee( emp_obj => $ARGS{emp_obj} ) );
    return $self unless $self->constructor_status->ok;
    $self->constructor_status( $self->_vet_activity( aid => $ARGS{aid} ) );
    return $self unless $self->constructor_status->ok;
    die "AGHGCHKFSCK! should be vetted by now!" unless $self->vetted;

    $self->constructor_status( $self->fillup_tempintvls );
    return $self unless $self->constructor_status->ok;

    return $self;
}


=head2 commit

If the C<dry_run> attribute is true, merely SELECTs rows from the
C<tempintvls> table corresponding to the vetted tsrange(s).  This SELECT
will generate an array of C<interval> objects.

If the C<dry_run> attribute is false, all the intervals from the SELECT are
INSERTed into the intervals table.

=cut

sub commit {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::commit with dry_run " . ( $self->dry_run ? "TRUE" : "FALSE" ) );

    my ( $status, @result_set, @fail_set, $count, $ok_count, $not_ok_count, @deleted_set );

    $ok_count = 0;
    $not_ok_count = 0;
    foreach my $t_hash ( @{ $self->tsranges } ) {

        my $tempintvls = fetch_tempintvls_by_tiid_and_tsrange(
            $self->context->{dbix_conn},
            $self->tiid,
            $t_hash->{tsrange},
        );

        # For each tempintvl object, make a corresponding interval object
        TEMPINTVL_LOOP: foreach my $tempintvl ( @$tempintvls ) {

            # if clobber is true, we have to check each interval for
            # overlaps and delete those to avoid the trigger (note that
            # this does not actually delete anything if dry_run is true)
            push @deleted_set, @{ $self->_clobber_intervals( $tempintvl ) } if $self->clobber;

            my $int = App::Dochazka::REST::Model::Interval->spawn(
                          eid => $self->emp_obj->eid,
                          aid => $self->act_obj->aid,
                          code => $self->act_obj->code,
                          intvl => $tempintvl->intvl,
                          long_desc => $self->long_desc,
                          remark => $self->remark || 'fillup',
                          partial => 0,
                      );

            # INSERT only if not dry run
            if ( ! $self->dry_run ) {
                $status = $int->insert( $self->context );
                if ( $status->not_ok ) {
                    push @fail_set, {
                        interval => $int,
                        status => $status->expurgate,
                    };
                    $not_ok_count += 1;
                    next TEMPINTVL_LOOP;
                }
            }

            push @result_set, $int;
            $ok_count += 1;
        }

    }

    $count = $ok_count + $not_ok_count;
    my $pl = {
                "success" => {
                    count => $ok_count,
                    intervals => \@result_set, 
                },
                "failure" => {
                    count => $not_ok_count,
                    intervals => \@fail_set,
                },
            };
    $pl->{"clobbered"} = {
        count => scalar( @deleted_set ),
        intervals => \@deleted_set
    } if $self->clobber;
    if ( $count ) {
        return $CELL->status_ok( 
            'DISPATCH_FILLUP_INTERVALS_CREATED', 
            args => [ $count ],
            payload => $pl,
            count => $count, 
        );
    }
    return $CELL->status_ok( 'DISPATCH_FILLUP_NO_INTERVALS_CREATED', count => 0 );
}

# given a tempintvl object, clobbers any intervals that conflict with it,
# logs errors and returns reference to set of deleted interval objects
sub _clobber_intervals {
    my ( $self, $tempintvl ) = @_;

    my @clobbered_intervals = ();

    my $status = fetch_intervals_by_eid_and_tsrange_inclusive(
        $self->context->{'dbix_conn'},
        $self->emp_obj->eid,
        $tempintvl->intvl,
    );
    if ( $status->ok and $status->code eq 'DISPATCH_RECORDS_FOUND' ) {
        foreach my $int ( @{ $status->payload } ) {
            if ( $self->dry_run ) {
                push @clobbered_intervals, $int;
            } else {
                my $saved_int = $int->clone;
                my $status = $int->delete( $self->context );
                if ( $status->ok ) {
                    push @clobbered_intervals, $saved_int;
                } else {
                    $log->error( "Could not delete interval " . $int->intvl .
                                 " due to " .  $status->text );
                }
            }
        }
    } elsif ( $status->level eq 'NOTICE' and $status->code eq 'DISPATCH_NO_RECORDS_FOUND' ) {
        $log->debug( "Interval " . $tempintvl->intvl . 
                     " does not overlap with any existing intervals" );
    } else {
        $log->crit( "FILLUP COMMIT: " . $status->text );
    }
    return \@clobbered_intervals;
}


=head2 DESTROY

Instance destructor. Once we are done with the scratch intervals, they can be deleted.
Returns a status object.

=cut

sub DESTROY {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::DESTROY with arguments " .  join( ' ', @_ ) );

    $log->notice( "GLOBAL DESTRUCTION" ) if ${^GLOBAL_PHASE} eq 'DESTRUCT';

    my $status;
    try {
        $dbix_conn->run( fixup => sub {
            my $sth = $_->prepare( $site->SQL_TEMPINTVLS_DELETE_MULTIPLE );
            $sth->bind_param( 1, $self->tiid );
            $sth->execute;
            my $rows = $sth->rows;
            if ( $rows > 0 ) {
                $status = $CELL->status_ok( 'DOCHAZKA_RECORDS_DELETED', args => [ $rows ], count => $rows );
            } elsif ( $rows == 0 ) {
                $status = $CELL->status_warn( 'DOCHAZKA_RECORDS_DELETED', args => [ $rows ], count => $rows );
            } else {
                die( "\$sth->rows returned a weird value $rows" );
            }
        } );
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    $log->notice( "Fillup destructor says " . $status->level . ": " . $status->text );
    return $status if $status;
    return $CELL->status_ok;
}



=head1 FUNCTIONS

=head2 _next_tiid

Get next value from the temp_intvl_seq sequence

=cut

sub _next_tiid {
    my $val;
    my $status;
    try {
        $dbix_conn->run( fixup => sub {
            ( $val ) = $_->selectrow_array( $site->SQL_NEXT_TIID );
        } );    
    } catch {
        $status = $CELL->status_err( 'DOCHAZKA_DBI_ERR', args => [ $_ ] );
    };
    if ( $status ) {
        $log->crit( $status->text );
        return;
    }
    return $val;
}


=head2 Days_to_Date

Missing function in L<Date::Calc>

=cut

sub Days_to_Date {
    my $canonical = shift;
    my ( $year, $month, $day ) = Add_Delta_Days(1,1,1, $canonical - 1);
    return ( $year, $month, $day );
}


=head2 _init_lower_sched_hash 

Given schedule hash (JSON string from database), return schedule
hash keyed on the "low_dow" property. In other words, convert the
schedule to hash format keyed on numeric form of "low_dow" i.e. 1 for
MON, 2 for TUE, etc. The values are references to arrays containing
the entries beginning on the given DOW.

=cut

sub _init_lower_sched_hash {
    my $rest_sched_json = shift;

    # initialize
    my $rest_sched_hash_lower = {};
    foreach my $ndow ( 1 .. 7 ) {
        $rest_sched_hash_lower->{ $ndow } = [];
    }

    # fill up
    foreach my $entry ( @{ decode_json $rest_sched_json } ) {
        my $ndow = $dow_to_num{ $entry->{'low_dow'} };
        push @{ $rest_sched_hash_lower->{ $ndow } }, $entry;
    }

    return $rest_sched_hash_lower;
}


=head2 _is_holiday

Takes a date and a C<$holidays> hashref.  Returns true or false.

=cut

sub _is_holiday {
    my ( $datum, $holidays ) = @_;
    return exists( $holidays->{ $datum } );
}


=head1 AUTHOR

Nathan Cutler, C<< <presnypreklad@gmail.com> >>

=cut 

1;

