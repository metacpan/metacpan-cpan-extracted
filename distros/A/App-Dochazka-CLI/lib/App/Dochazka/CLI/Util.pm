# ************************************************************************* 
# Copyright (c) 2014-2016, SUSE LLC
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
#
# Util module - reusable components
#
package App::Dochazka::CLI::Util;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::Dochazka::Common qw( $t $today $tomorrow $yesterday init_timepiece );
use App::Dochazka::CLI qw( 
    $current_emp 
    $current_priv 
    $debug_mode 
    $prompt_date 
    $prompt_century 
    $prompt_year 
    $prompt_month 
    $prompt_day 
);
use App::Dochazka::Common::Model::Employee;
use Data::Dumper;
use Date::Calc qw( check_date Add_Delta_Days );
use Exporter 'import';
use File::ShareDir;
use Log::Any::Adapter;
use Params::Validate qw( :all );
use Scalar::Util qw( looks_like_number );
use Try::Tiny;
use Web::MREST::CLI qw( normalize_filespec send_req );



=head1 NAME

App::Dochazka::CLI::Util - Various reusable components




=head1 PACKAGE VARIABLES AND EXPORTS

=cut

our @EXPORT_OK = qw( 
    authenticate_to_server 
    datelist_from_token
    determine_employee
    lookup_employee 
    init_logger
    init_prompt
    month_alpha_to_numeric
    normalize_date
    normalize_time
    parse_test
    refresh_current_emp 
    rest_error 
    truncate_to
);

our %month_map = (
    'jan' => 1,
    'feb' => 2,
    'mar' => 3,
    'apr' => 4,
    'may' => 5,
    'jun' => 6,
    'jul' => 7,
    'aug' => 8,
    'sep' => 9,
    'oct' => 10,
    'nov' => 11,
    'dec' => 12,
);



=head1 FUNCTIONS


=head2 authenticate_to_server

All communication between L<App::Dochazka::CLI> and the L<App::Dochazka::REST>
server goes via the C<send_req> routine in L<Web::MREST::CLI>. This
routine takes its connection parameters (address of REST server, nick and
password) from the following configuration parameters:

    $meta->MREST_CLI_URI_BASE
    $meta->CURRENT_EMPLOYEE_NICK
    $meta->CURRENT_EMPLOYEE_PASSWORD

The first parameter, C<MREST_CLI_URI_BASE>, is assumed to be set before this
routine is called. The second and third are meta parameters and are set by
this routine.

After setting the meta parameters, the routine causes a GET request for the
C<employee/self/priv> resource to be send to the server, and uses the response
to initialize the C<$current_emp> and C<$current_priv> variables which are
imported from the L<App::Dochazka::CLI> package.

Takes PROPLIST with two properties:

=over

=item C<< user >>

The username to authenticate as (defaults to 'demo')

=item C<< password >>

The password to use (defaults to the value of the C<user> parameter)

=back

Since this routine returns the status object returned by the "GET
employee/self/priv" request, it is actually a wrapper around C<send_req>.

=cut

sub authenticate_to_server {
    my %PROPLIST = ( 
        user => 'demo',
        @_,
    );
    $PROPLIST{'password'} = $PROPLIST{'password'} || $PROPLIST{'user'};

    $meta->set( 'CURRENT_EMPLOYEE_NICK', $PROPLIST{'user'} );
    $meta->set( 'CURRENT_EMPLOYEE_PASSWORD', $PROPLIST{'password'} );

    # get info about us
    my $status;
    try {
        $status = send_req( 'GET', '/employee/self/priv' );
    } catch {
        $status = $_;
    };
    if ( !ref( $status ) ) {
        die "AGHAUFF! $status\n";
    }
    return $status unless $status->ok;

    # authentication OK, initialize package variables
    $current_emp = App::Dochazka::Common::Model::Employee->spawn( %{ $status->payload->{'current_emp'} } );
    $current_priv = $status->payload->{'priv'};
    return $CELL->status_ok( 'DOCHAZKA_CLI_AUTHENTICATION_OK' );
}


=head2 datelist_from_token

Takes a numeric month and a _DATELIST token - e.g. "5,6,10-13,2".

Convert the token into an array of dates and return a reference. So, upon
success, the return value will look something like this:

    [ "2015-01-01", "2015-01-06", "2015-01-22" ]

If there's a problem, writes an error message to the log and returns
undef.

=cut

sub datelist_from_token {
    my ( $token ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::datelist_from_token with token " . Dumper( $token ) );

    if ( $prompt_month < 1 or $prompt_month > 12 ) {
        die "ASSERT ohayoa9I \$prompt_month set to illegal value";
    }

    my @datelist;
    #
    # loop as long as subtokens are left
    while ( defined( $token ) and my ( $subtoken ) = $token =~ m/^((\d{1,2})|(\d{1,2}-\d{1,2}))(?=(,|$))/ ) {

        #
        # 1. chew off the subtoken
        if ( $token =~ m/^$subtoken,/ ) {
            $token =~ s/^$subtoken,//;
        } elsif ( $token =~ m/^$subtoken$/ ) {
            $token =~ s/^$subtoken$//;
        } else {
            die "AGACDKDFLQERIIeee!";
        }

        #
        # 2. if it's a range, convert it into a list of individual dates
        if ( my ( $begin, $end ) = $subtoken =~ m/^(\d{1,2})-(\d{1,2})$/ ) {
            if ( $begin >= $end ) {
                die "AGHGGHSKSKDQ!!!!! Begin date must be less than end";
            }
            foreach my $n ( $begin..$end ) {
                my $canonical_date = sprintf( "%04d-%02d-%02d", $prompt_year, $prompt_month, $n );
                push @datelist, $canonical_date;
            }
        #
        # 3. if not, convert it into a date
        } else { # is a single date
            my $canonical_date = sprintf( "%04d-%02d-%02d", $prompt_year, $prompt_month, $subtoken );
            push @datelist, $canonical_date;
        }
   }

   return \@datelist;
}


=head2 determine_employee

Given what might possibly be an employee specification (as obtained from the
user from the EMPLOYEE_SPEC token of the command line), return a status object
that will either be an error (not OK) or contain the employee object in the
payload.

If the employee specification is empty or undefined, the payload will contain
the C<$current_emp> object.

=cut

sub determine_employee {
    my $s_key = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::determine_employee with \$s_key ->" .
        ( defined( $s_key ) ? $s_key : "undef" ) . "<-" );

    my $status = ( $s_key )
        ? lookup_employee( key => $s_key, minimal => 1 )
        : refresh_current_emp();
    return ( $status->ok )
        ? $CELL->status_ok( 'EMPLOYEE_LOOKUP', 
            payload => App::Dochazka::Common::Model::Employee->spawn( %{ $status->payload } ) )
        : rest_error( $status, "Employee lookup" );
}


=head2 lookup_employee

EMPLOYEE_SPEC may be "nick=...", "sec_id=...", "eid=...", or simply
"employee=...", in which case we use a clever algorithm to look up employees
(i.e. try looking up search key as nick, sec_id, and EID - in that order).

=cut

sub lookup_employee {
    my %ARGS = validate( @_, 
        {
            key => { type => SCALAR },
            minimal => { default => 0 },     
        }
    );
    print "Entering " . __PACKAGE__ . "::lookup_employee with search key " . Dumper( $ARGS{key} )
        if $debug_mode;

    die( "AH! Not an EMPLOYEE_SPEC" ) unless $ARGS{key} =~ m/=/;

    my ( $key_spec, $key ) = $ARGS{key} =~ m/^(.*)\=(.*)$/;
    my $minimal = $ARGS{minimal} ? '/minimal' : '';

    my $status;
    if ( $key_spec =~ m/^emp/i ) {
        $status = send_req( 'GET', "employee/nick/$key$minimal" );
        BREAK_OUT: {
            last BREAK_OUT if $status->not_ok and $status->payload and $status->payload->{'http_code'} == 403;
            if ( $status->not_ok and $status->payload and $status->payload->{'http_code'} == 404 ) {
                $status = send_req( 'GET', "employee/sec_id/$key$minimal" );
                if ( $status->not_ok and $status->payload and $status->payload->{'http_code'} != 500 and looks_like_number( $key ) ) {
                    $status = send_req( 'GET', "employee/eid/$key$minimal" );
                }
            }
        }
    } elsif ( $key_spec =~ m/^nic/i ) {
        $status = send_req( 'GET', "employee/nick/$key$minimal" );
    } elsif ( $key_spec =~ m/^sec/i ) {
        $status = send_req( 'GET', "employee/sec_id/$key$minimal" );
    } elsif ( $key_spec =~ m/^eid/i ) {
        $status = send_req( 'GET', "employee/eid/$key$minimal" );
    } else {
        die "AAAHAAAHHH!!! Invalid employee lookup key " . ( defined( $key_spec ) ? $key_spec : "undefined" )
    }

    return $status;
}


=head2 init_logger

Logger initialization routine

=cut

sub init_logger {
    my $log_file = normalize_filespec( $site->DOCHAZKA_CLI_LOG_FILE );
    unlink $log_file if $site->DOCHAZKA_CLI_LOG_FILE_RESET;
    print "Logging to $log_file\n";
    Log::Any::Adapter->set('File', $log_file );
    $log->init( ident => 'dochazka-cli', debug_mode => 1 );
    $log->debug( 'Logger initialized' );
}


=head2 init_prompt

(Re-)initialize the date/time-related package variables

=cut

sub init_prompt {
    #print "Entering " . __PACKAGE__ . "::init_prompt\n";
    init_timepiece();
    $prompt_date = $today unless $prompt_date;
    ( $prompt_year, $prompt_month, $prompt_day ) = 
        $prompt_date =~ m/^(\d{4,4})-(\d{1,2})-(\d{1,2})/;
    ( $prompt_century ) = $prompt_year =~ m/^(\d{2,2})/;
}


=head2 month_alpha_to_numeric

Given a month written in English (e.g. "January"), return the ordinal
number of that month (i.e. 1 for January) or undef if it cannot be
determined.

=cut

sub month_alpha_to_numeric {
    my $alpha = shift;
    return unless defined( $alpha );
    my ( $month ) = $alpha =~ m/\A(\S\S\S)/;
    $month = lc $month;
    return unless exists( $month_map{ $month } );
    return $month_map{ $month };
}


=head2 normalize_date

Normalize a date entered by the user. A date can take the following forms
(case is insignificant):

    YYYY-MM-DD
    YY-MM-DD
    MM-DD
    TODAY
    TOMORROW
    YESTERDAY
    +n
    -n

and any of the two-digit forms can be fulfilled by a single digit,
for example 2014-3-4 is March 4th, 2014.

All the forms except the first are converted into the YYYY-MM-DD form.
The last two forms listed, C<+n> and C<-n>, are calculated as offsets
from the "prompt date" (the date shown in the prompt), where C<n> is
interpreted as a number of days.

If an undefined or empty string is given, the prompt date is returned.

If the string does not match any of the forms, undef is returned.

Caveats:

=over

=item * two-digit years

If only YY is given, it is converted into YYYY by appending two digits
corresponding to the prompt century (e.g. 22 becomes 2022 during 2000-2099).

=item * special date forms

The special date forms "TODAY", "TOMORROW", and "YESTERDAY" are recognized,
and only the first three letters are significant, so "todMUMBOJUMBO" converts
to today's date.

=item * offsets

The C<n> in the offset can be any number in the range 0-999.

=item * no year

If no year is given, the prompt year is used.

=item * no date

If no date is given, the prompt date is used.

=item * single-digit forms

If a single-digit form is given for C<MM> or C<DD>, a leading zero is appended.

=back

=cut

sub normalize_date {
    my $rd = shift;  # rd == raw date
    my $nd;          # nd == normalized date

    # initialize timepiece so we can do things like $today, $tomorrow, etc.
    init_prompt();

    # return prompt date if no raw date provided
    unless ( defined( $rd ) and length( $rd ) > 0 ) {
        #print "normalize_date(): no date provided, returning prompt date\n";
        #print "Prompt date is " . ( $prompt_date || 'undefined' ) . "\n";
        return $prompt_date;
    }

    if ( $rd =~ m/\A\d{4,4}-\d{1,2}-\d{1,2}\z/ ) {
        $nd = $rd;
    } elsif ( $rd =~ m/\A\d{2,2}-\d{1,2}-\d{1,2}\z/ ) {
        # year has only two digits: add the prompt century
        $nd = $prompt_century . $rd;
    } elsif ( $rd =~ m/\A\d{1,2}-\d{1,2}\z/ ) {
        # year omitted: add the prompt year
        $nd = $prompt_year . '-' . $rd;
    } elsif ( $rd =~ m/\Atod/i ) {
        $nd = $today;
    } elsif ( $rd =~ m/\Atom/i ) {
        $nd = $tomorrow;
    } elsif ( $rd =~ m/\Ayes/i ) {
        $nd = $yesterday;
    } elsif ( $rd =~ m/\A[\+\-]\d{1,3}\z/ ) {
        # offset from prompt date
        $prompt_date =~ m/\A(?<yyyy>\d{4,4})-(?<mm>\d{1,2})-(?<dd>\d{1,2})\z/;
        if ( check_date( $+{'yyyy'}, $+{'mm'}, $+{'dd'} ) ) {
            # prompt date is OK, apply delta
            my ( $year, $month, $day ) = Add_Delta_Days(
                $+{'yyyy'}, $+{'mm'}, $+{'dd'},
                $rd,
            );
            $nd = "$year-$month-$day";
        } else {
            die "AAAAAAJAJAJAJADDEEEEE!!! Invalid prompt date $prompt_date";
        }
    } else {
        # anything else - invalid timestamp
        return undef;
    }

    # add leading zeroes to month and day, if necessary
    $nd =~ m/\A(?<yyyy>\d{4,4})-(?<mm>\d{1,2})-(?<dd>\d{1,2})\z/;
    return undef unless $+{yyyy} and $+{mm} and $+{dd};
    $nd = sprintf( "%d-%02d-%02d", $+{yyyy}, $+{mm}, $+{dd} );

    # sanity check to ensure no weird dates slip by
    my ( $year, $month, $day ) = $nd =~ m/\A(\d{4,4})-(\d{2,2})-(\d{2,2})\z/;
    return undef unless check_date( $year, $month, $day );

    return "$nd";
}


=head2 normalize_time

Normalize a time entered by the user. A time can take the following forms

    HH:MM:SS
    HH:MM

and any of the two-digit forms can be fulfilled by a single digit,
for example 6:4:9 is 6:04 a.m. and nine seconds

=over

=item * single-digit forms

If a single-digit form is given, a leading zero is appended.

=item * seconds

If seconds are given, they are ignored.

=item * no validation

No attempt is made to validate the time -- this is done later, by
PostgreSQL.

=back

=cut

sub normalize_time {
    my $rt = shift;  # rt == raw time

    return '00:00' unless $rt;

    # normalize time part
    $rt =~ m/\A(?<hh>\d{1,2}):(?<mm>\d{1,2})(:\d{1,2})?\z/;
    my ( $hours, $minutes ) = ( $+{hh}, $+{mm} );
    return undef unless defined( $hours ) and defined( $minutes );
    # handle single zeroes
    $hours = '00' if $hours eq '0';
    $minutes = '00' if $minutes eq '0';
    return undef unless $hours and $minutes;
    my $nt = sprintf( "%02d:%02d", $+{hh}, $+{mm} );
    
    return "$nt";
}


=head2 parse_test

Given a reference to the PARAMHASH a command handler was called with, check
if there is a PARSE_TEST property there, and if it is true return the
full subroutine name of the caller. 

=cut

sub parse_test {
    #print ( 'parse_test arg list: ' . join( ' ', @_ ) . "\n" );
    my ( %PARAMHASH ) = @_;
    if ( $PARAMHASH{'PARSE_TEST'} ) {
        return $CELL->status_ok( 'DOCHAZKA_CLI_PARSE_TEST', 
            payload => (caller(1))[3] );
    } 
    return $CELL->status_not_ok( 'DOCHAZKA_CLI_PARSE_TEST' );
}


=head2 refresh_current_emp

REST calls are cheap, so look up C<< $current_emp >> again just to make sure.

=cut

sub refresh_current_emp {
    my $status = send_req( 'GET', 'employee/eid/' . $current_emp->eid );
    if ( $status->not_ok ) {
        $log->crit( "Problem with data integrity (current employee)" );
        return $status;
    }
    $current_emp = App::Dochazka::Common::Model::Employee->spawn( %{ $status->payload } );
    return $status;
}


=head2 rest_error

Given a non-OK status object and a string briefly identifying (for the user)
the operation during which the error occurred, construct and return a new
L<App::CELL::Status> object bearing (in the payload) a string containing the
"error report" - perhaps suitable for displaying to the user.  The code of that
object is C<REST_ERROR> and its level is taken from the passed-in status
object. The other attributes of the original (passed-in) status object are
preserved in the returned status object as follows:

    payload -> rest_payload
    uri_path -> uri_path 
    http_status -> http_status

=cut

sub rest_error {
    my ( $status, $oper_desc ) = @_;
    my $rv = "\n";
    $rv .= "Entering " . __PACKAGE__ . "::rest_error ($oper_desc)"
        if $debug_mode;

    $rv .= "Error encountered on attempted operation \"$oper_desc\"\n";

    # special handling if payload is a string
    if ( ref( $status->payload ) eq '' ) {

        $rv .= $status->payload;
        $rv .= "\n";

    } elsif ( ref( $status->payload ) eq 'HASH' ) {

        my $http_status = $status->{'http_status'} || 
                          $status->payload->{'http_code'} || 
                          "Cannot be determined";
        my $method      = $status->payload->{'http_method'} || 
                          "Cannot be determined";
        my $uri_path    = $status->payload->{'uri_path'} || 
                          '';
        $rv .= "REST operation: $method $uri_path\n";
        $rv .= "HTTP status: $http_status\n";
        $rv .= "Explanation: ";
        $rv .= $status->code;
        $rv .= ( $status->code eq $status->text ) 
            ? "\n"
            : ': ' . $status->text . "\n";
        $rv .= "Permanent? ";
        $rv .= ( $status->payload->{'permanent'} )
            ? "YES\n"
            : "NO\n";

    } else {
        die "AH! in rest_error, payload is neither a hashref nor an ordinary scalar";
    }

    my $status_clone = App::CELL::Status->new( 
        level => $status->level,
        code => 'REST_ERROR',
        payload => $rv,
        rest_payload => $status->payload,
        uri_path => $status->{'uri_path'},
        http_status => $status->{'http_status'},
    );
    return $status_clone;
}


=head2 truncate_to

Given a string and a maximum length (defaults to 32), truncates to that length.
Returns a copy of the string. If any characters were actually removed in the
truncate operation, '...' is appended -- unless the maximum length is zero, in
which case the empty string is returned.

=cut

sub truncate_to {
    my ( $str, $mlen ) = validate_pos( @_, 
        { type => SCALAR|UNDEF },
        { 
            callbacks => {
                'greater than or equal to zero' => sub { shift() >= 0 },
            },
            optional => 1,
            type => SCALAR, 
        },
    );
    $mlen = 32 unless defined( $mlen );
    my $len = length $str || 0;  # $str might be undef
    return $str unless $len > $mlen;
    my $str_copy = substr( $str, 0, $mlen );
    $str_copy .= '...' if $len > $mlen;
    $str_copy = '' if $mlen == 0;
    return $str_copy;  # might be undef
}


1;
