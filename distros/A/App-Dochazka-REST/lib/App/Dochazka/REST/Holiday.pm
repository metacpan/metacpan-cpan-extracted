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

package App::Dochazka::REST::Holiday;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log );
use Date::Calc qw( 
    Add_Delta_Days 
    Date_to_Days
    Day_of_Week 
);
use Date::Holidays::CZ qw( holidays );
use Params::Validate qw( :all );




=head1 NAME

App::Dochazka::REST::Holiday - non-database holiday and date routines




=head1 SYNOPSIS

    use App::Dochazka::REST::Holiday qw( holidays_in_daterange );

    my $holidays1 = holidays_in_daterange( 
        begin => '2001-01-02',
        end => '2001-12-24',
    );
    my $holidays2 = holidays_in_daterange( 
        begin => '2001-01-02',
        end => '2002-12-24',
    );

*WARNING*: C<holidays_in_daterange()> makes no attempt to validate the date
range. It assumes this validation has already taken place, and that the dates
are in YYYY-MM-DD format!




=head1 EXPORTS

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( 
    calculate_hours
    canon_date_diff
    canon_to_ymd
    get_tomorrow 
    holidays_and_weekends
    holidays_in_daterange 
    is_weekend 
    tsrange_to_dates_and_times
    ymd_to_canon
);



=head1 FUNCTIONS


=head2 calculate_hours

Given a canonicalized tsrange, return the number of hours. For example, if
the range is [ 2016-01-06 08:00, 2016-01-06 09:00 ), the return value will
be 1. If the range is [ 2016-01-06 08:00, 2016-01-07 09:00 ), the return
value will 25.

Returns 0 if there's a problem with the tsrange argument.

=cut

sub calculate_hours {
    my $tsr = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::calculate_hours with tsr $tsr" );

    my ( $begin_date, $begin_time, $end_date, $end_time ) = 
        $tsr =~ m/(\d{4}-\d{2}-\d{2}).+(\d{2}:\d{2}):\d{2}.+(\d{4}-\d{2}-\d{2}).+(\d{2}:\d{2}):\d{2}/;

    return 0 unless $begin_date and $begin_time and $end_date and $end_time;

    my $days = canon_date_diff( $begin_date, $end_date );

    if ( $days == 0 ) {
        return _single_day_hours( $begin_time, $end_time )
    }
    
    return _single_day_hours( $begin_time, '24:00' ) +
           ( ( $days - 1 ) * 24 ) +
           _single_day_hours( '00:00', $end_time );
}


=head2 canon_date_diff

Compute difference (in days) between two canonical dates

=cut

sub canon_date_diff {
    my ( $date, $date1 ) = @_;
    my ( $date_days, $date1_days ) = (
        Date_to_Days( canon_to_ymd( $date ) ),
        Date_to_Days( canon_to_ymd( $date1 ) ),
    );
    return abs( $date_days - $date1_days );
}


=head2 canon_to_ymd

Takes canonical date YYYY-MM-DD and returns $y, $m, $d

=cut

sub canon_to_ymd {
    my ( $date ) = @_;
    return unless $date;

    return ( $date =~ m/(\d+)-(\d+)-(\d+)/ );
}


=head2 holidays_in_daterange

Given a PARAMHASH containing two properties, C<begin> and C<end>, the values of
which are canonicalized dates (possibly produced by the C<split_tsrange()>
function), determine the holidays that fall within this range. The function will
always return a status object. Upon success, the payload will contain a hashref
with the following structure:

{
    '2015-01-01' => '',
    '2015-05-01' => '',
}

The idea is that this hash can be used to quickly look up if a given date is a
holiday.

=cut

sub holidays_in_daterange {
    my ( %ARGS ) = validate( @_, {
        begin => { type => SCALAR },
        end => { type => SCALAR },
    } );

    my $begin_year = _extract_year( $ARGS{begin} );
    my $end_year = _extract_year( $ARGS{end} );

    # transform daterange into an array of hashes containing "begin", "end"
    # in other words: 
    # INPUT: { begin => '1901-06-30', end => '1903-03-15' } 
    # becomes
    # OUTPUT: [
    #     { begin => '1901-06-30', end => '1901-12-31' },
    #     { begin => '1902-01-01', end => '1902-12-31' },
    #     { begin => '1903-01-01', end => '1903-03-15' },
    # ]
    my $daterange_by_year = _daterange_by_year(
        begin_year => $begin_year,
        end_year => $end_year,
        begin_date => $ARGS{begin},
        end_date => $ARGS{end},
    );
    
    my %retval;

    foreach my $year ( sort( keys %{ $daterange_by_year } ) ) {
        my $holidays = holidays( YEAR => $year, FORMAT => '%Y-%m-%d', WEEKENDS => 1 );
        if ( $year eq $begin_year and $year eq $end_year ) {
            my $tmp_holidays = _eliminate_dates( $holidays, $ARGS{begin}, "before" );
            $holidays = _eliminate_dates( $tmp_holidays, $ARGS{end}, "after" );
            map { $retval{$_} = ''; } @$holidays;
        } elsif ( $year eq $begin_year ) {
            map { $retval{$_} = ''; } @{ _eliminate_dates( $holidays, $ARGS{begin}, "before" ) };
        } elsif ( $year eq $end_year ) {
            map { $retval{$_} = ''; } @{ _eliminate_dates( $holidays, $ARGS{end}, "after" ) };
        } else {
            map { $retval{$_} = ''; } @$holidays;
        }
    }

    return \%retval;
}


=head2 is_weekend

Simple function that takes a canonicalized date string in 
the format YYYY-MM-DD and returns a true or false value 
indicating whether or not the date falls on a weekend.

=cut

sub is_weekend {
    my $cdate = shift;  # cdate == Canonicalized Date String YYYY-MM-DD
    my ( $year, $month, $day ) = $cdate =~ m/(\d{4})-(\d{2})-(\d{2})/;
    my $dow = Day_of_Week( $year, $month, $day );
    return ( $dow == 6 or $dow == 7 )
        ? 1
        : 0;
}


=head2 get_tomorrow

Given a canonicalized date string in the format YYYY-MM-DD, return 
the next date (i.e. "tomorrow" from the perspective of the given date).

=cut

sub get_tomorrow {
    my $cdate = shift;  # cdate == Canonicalized Date String YYYY-MM-DD
    my ( $year, $month, $day ) = $cdate =~ m/(\d{4})-(\d{2})-(\d{2})/;
    my ( $tyear, $tmonth, $tday ) = Add_Delta_Days( $year, $month, $day, 1 );
    return "$tyear-" . sprintf( "%02d", $tmonth ) . "-" . sprintf( "%02d", $tday );
}


=head2 holidays_and_weekends

Given a date range (same as in C<holidays_in_daterange>, above), return
a reference to a hash of hashes that looks like this (for sample dates):

    {
        '2015-01-01' => { holiday => 1 },
        '2015-01-02' => {},
        '2015-01-03' => { weekend => 1 },
        '2015-01-04' => { weekend => 1 },
        '2015-01-05' => {},
        '2015-01-06' => {},
    }

Note that the range is always considered inclusive -- i.e. the bounding
dates of the range will be included in the hash.

=cut

sub holidays_and_weekends {
    my ( %ARGS ) = validate( @_, {
        begin => { type => SCALAR },
        end => { type => SCALAR },
    } );
    my $holidays = holidays_in_daterange( %ARGS );
    my $res = {};
    my $d = $ARGS{begin};
    $log->debug( "holidays_and_weekends \$d == $d" );
    while ( $d ne get_tomorrow( $ARGS{end} ) ) {
        $res->{ $d } = {};
        if ( is_weekend( $d ) ) {
            $res->{ $d }->{ 'weekend' } = 1;
        }
        if ( exists( $holidays->{ $d } ) ) {
            $res->{ $d }->{ 'holiday' } = 1;
        }
        $d = get_tomorrow( $d );
    }
    return $res;
}


=head2 tsrange_to_dates_and_times

Takes a string that might be a canonicalized tsrange. Attempts to extract
beginning and ending dates (YYYY-MM-DD) from it. If this succeeds, an OK status
object is returned, the payload of which is a hash suitable for passing to
holidays_and_weekends().

=cut

sub tsrange_to_dates_and_times {
    my ( $tsrange ) = @_;

    my ( $begin_date, $begin_time, $end_date, $end_time ) = 
        $tsrange =~ m/(\d{4}-\d{2}-\d{2}).+(\d{2}:\d{2}):\d{2}.+(\d{4}-\d{2}-\d{2}).+(\d{2}:\d{2}):\d{2}/;

    # if begin_time is 24:00 convert it to 00:00
    if ( $begin_time eq '24:00' ) {
        my ( $y, $m, $d ) = canon_to_ymd( $begin_date );
        $log->debug( "Before Add_Delta_Days $y $m $d" );
        ( $y, $m, $d ) = Add_Delta_Days( $y, $m, $d, 1 );
        $begin_date = ymd_to_canon( $y, $m, $d );
    }
    # if end_time is 00:00 convert it to 24:00
    if ( $end_time eq '00:00' ) {
        my ( $y, $m, $d ) = canon_to_ymd( $end_date );
        $log->debug( "Before Add_Delta_Days $y-$m-$d" );
        ( $y, $m, $d ) = Add_Delta_Days( $y, $m, $d, -1 );
        $end_date = ymd_to_canon( $y, $m, $d );
    }

    return $CELL->status_ok( 'DOCHAZKA_NORMAL_COMPLETION',
        payload => { begin => [ $begin_date, $begin_time ], 
                     end => [ $end_date, $end_time ] } );
}


=head2 ymd_to_canon

Takes $y, $m, $d and returns canonical date YYYY-MM-DD

=cut

sub ymd_to_canon {
    my ( $y, $m, $d ) = @_;

    if ( $y < 1 or $y > 9999 or $m < 1 or $m > 99 or $d < 1 or $d > 99 ) {
        die "AUCKLANDERS! ymd out of range!!";
    }

    return sprintf( "%04d-%02d-%02d", $y, $m, $d );
}


# HELPER FUNCTIONS

sub _daterange_by_year {
    my ( %ARGS ) = validate( @_, {
        begin_year => { type => SCALAR },
        end_year => { type => SCALAR },
        begin_date => { type => SCALAR },
        end_date => { type => SCALAR },
    } );
    my $year_delta = $ARGS{end_year} - $ARGS{begin_year};
    if ( $year_delta == 0 ) {
        return { $ARGS{begin_year} => { begin => $ARGS{begin}, end => $ARGS{end} } };
    }
    if ( $year_delta == 1 ) {
        return {
            $ARGS{begin_year} => { begin => $ARGS{begin}, end => "$ARGS{begin_year}-12-31" },
            $ARGS{end_year} => { begin => "$ARGS{end_year}-01-01", end => $ARGS{end} },
        };
    }
    my @intervening_years = ( ($ARGS{begin_year}+1)..($ARGS{end_year}-1) );
    my %retval = ( 
        $ARGS{begin_year} => { begin => $ARGS{begin}, end => "$ARGS{begin_year}-12-31" },
        $ARGS{end_year} => { begin => "$ARGS{end_year}-01-01", end => $ARGS{end} },
    );
    foreach my $year ( @intervening_years ) {
        $retval{ $year } = { begin => "$year-01-01", end => "$year-12-31" };
    }
    return \%retval;
}

# $inequality can be "before" or "after"
sub _eliminate_dates {
    my ( $holidays, $date, $inequality ) = @_;
    my @retval;
    foreach my $holiday ( @$holidays ) {
        if ( $inequality eq 'before' ) {
            push @retval, $holiday if $holiday ge $date; 
        } elsif ( $inequality eq 'after' ) {
            push @retval, $holiday if $holiday le $date;
        } else {
            die 'AG@D##KDW####!!!';
        }
    }
    return \@retval;
}

sub _extract_year {
    my $date = shift;
    my ( $year ) = $date =~ m/(\d+)-\d+-\d+/;
    return $year;
}

# Given two strings in the format HH:MM representing a starting and an ending
# time, calculate and return the number of hours.
sub _single_day_hours {
    my ( $begin, $end ) = @_;
    my ( $bh, $begin_minutes ) = $begin =~ m/(\d+):(\d+)/;
    my $begin_hours = $bh + $begin_minutes / 60;
    my ( $eh, $end_minutes ) = $end =~ m/(\d+):(\d+)/;
    my $end_hours = $eh + $end_minutes / 60;
    return $end_hours - $begin_hours;
}

1;
