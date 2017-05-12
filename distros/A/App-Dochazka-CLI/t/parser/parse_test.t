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
# test parsing of various command strings

#!perl
use 5.012;
use strict;
use warnings;

use App::Dochazka::CLI::Parser qw( parse $semantic_tree );
use App::Dochazka::CLI::Test qw( do_parse_test );
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $cmd, $r, $r_should_be, $coderef );



#================================
# REST Test commands
#================================
# just one example -- for the full suite see t/parser/rest_test.t
#
$cmd = "GET employee nick worker";
$r = parse( $cmd );
is_deeply( $r, {
    'th' => {
              'GET' => 'GET',
              '_TERM' => 'worker',
              '_REST' => '',
              'EMPLOYEE' => 'employee',
              'NICK' => 'nick'
            },
    'ts' => [
              'GET',
              'EMPLOYEE',
              'NICK',
              '_TERM'
            ],
    'nc' => 'GET EMPLOYEE NICK _TERM'
} );



#================================
# Activity commands
#================================

$cmd = "ACTIVITY";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'ACTIVITY'
            ],
    'th' => {
              'ACTIVITY' => 'ACTIVITY',
              '_REST' => ''
            },
    'nc' => 'ACTIVITY'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Activity::activity_all' );

$cmd = "ACTIVITY ALL";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'ACTIVITY',
              'ALL'
            ],
    'th' => {
              'ACTIVITY' => 'ACTIVITY',
              'ALL' => 'ALL',
              '_REST' => ''
            },
    'nc' => 'ACTIVITY ALL'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Activity::activity_all' );

$cmd = "ACTIVITY ALL DISABLED";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'ACTIVITY',
              'ALL',
              'DISABLED'
            ],
    'th' => {
              'ACTIVITY' => 'ACTIVITY',
              'ALL' => 'ALL',
              'DISABLED' => 'DISABLED',
              '_REST' => ''
            },
    'nc' => 'ACTIVITY ALL DISABLED'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Activity::activity_all' );



#================================
# Employee commands
#================================

$cmd = "EMPLOYEE";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE',
            ],
    'th' => {
              'EMPLOYEE' => 'EMPLOYEE',
              '_REST' => ''
            },
    'nc' => 'EMPLOYEE'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::employee_profile' );

$cmd = "EMPLOYEE PROFILE";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE',
              'PROFILE'
            ],
    'th' => {
              'EMPLOYEE' => 'EMPLOYEE',
              'PROFILE' => 'PROFILE',
              '_REST' => ''
            },
    'nc' => 'EMPLOYEE PROFILE'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::employee_profile' );

$cmd = "EMPLOYEE SHOW";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE',
              'SHOW'
            ],
    'th' => {
              'EMPLOYEE' => 'EMPLOYEE',
              'SHOW' => 'SHOW',
              '_REST' => ''
            },
    'nc' => 'EMPLOYEE SHOW'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::employee_profile' );

$cmd = "EMPLOYEE=worker";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE_SPEC',
            ],
    'th' => {
              'EMPLOYEE_SPEC' => 'EMPLOYEE=worker',
              '_REST' => ''
            },
    'nc' => 'EMPLOYEE_SPEC'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::employee_profile' );

$cmd = "EMPLOYEE=worker PROFILE";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE_SPEC',
              'PROFILE'
            ],
    'th' => {
              'EMPLOYEE_SPEC' => 'EMPLOYEE=worker',
              'PROFILE' => 'PROFILE',
              '_REST' => ''
            },
    'nc' => 'EMPLOYEE_SPEC PROFILE'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::employee_profile' );

$cmd = "EMPLOYEE=worker SHOW";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE_SPEC',
              'SHOW'
            ],
    'th' => {
              'EMPLOYEE_SPEC' => 'EMPLOYEE=worker',
              'SHOW' => 'SHOW',
              '_REST' => ''
            },
    'nc' => 'EMPLOYEE_SPEC SHOW'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::employee_profile' );

$cmd = "EMPLOYEE SEC_ID foobar";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::set_employee_self_sec_id' );

$cmd = "EMPLOYEE SET SEC_ID foobar";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE',
              'SET',
              'SEC_ID',
              '_TERM'
            ],
    'th' => {
              'SEC_ID' => 'SEC_ID',
              'SET' => 'SET',
              'EMPLOYEE' => 'EMPLOYEE',
              '_TERM' => 'foobar',
              '_REST' => ''
            },
    'nc' => 'EMPLOYEE SET SEC_ID _TERM'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::set_employee_self_sec_id' );

$cmd = "EMPLOYEE=orc63 SEC_ID foobar";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::set_employee_other_sec_id' );

$cmd = "EMPLOYEE=orc63 SET SEC_ID foobar";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE_SPEC',
              'SET',
              'SEC_ID',
              '_TERM'
            ],
    'th' => {
              'SEC_ID' => 'SEC_ID',
              'SET' => 'SET',
              'EMPLOYEE_SPEC' => 'EMPLOYEE=orc63',
              '_TERM' => 'foobar',
              '_REST' => ''
            },
    'nc' => 'EMPLOYEE_SPEC SET SEC_ID _TERM'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::set_employee_other_sec_id' );

$cmd = "EMPLOYEE FULLNAME Johannes Runner";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::set_employee_self_fullname' );

$cmd = "EMPLOYEE SET FULLNAME Johannes Runner";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE',
              'SET',
              'FULLNAME'
            ],
    'th' => {
              'EMPLOYEE' => 'EMPLOYEE',
              'SET' => 'SET',
              'FULLNAME' => 'FULLNAME',
              '_REST' => 'Johannes Runner'
            },
    'nc' => 'EMPLOYEE SET FULLNAME'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::set_employee_self_fullname' );

$cmd = "EMPLOYEE=orc63 FULLNAME Just Another Orc in the Rye";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::set_employee_other_fullname' );

$cmd = "EMPLOYEE=orc63 SET FULLNAME Just Another Orc in the Rye";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE_SPEC',
              'SET',
              'FULLNAME'
            ],
    'th' => {
              'EMPLOYEE_SPEC' => 'EMPLOYEE=orc63',
              'SET' => 'SET',
              'FULLNAME' => 'FULLNAME',
              '_REST' => 'Just Another Orc in the Rye'
            },
    'nc' => 'EMPLOYEE_SPEC SET FULLNAME'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Employee::set_employee_other_fullname' );



#================================
# History commands
#================================

$cmd = "PRIV HISTORY";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::dump_priv_history' );

$cmd = "EMPLOYEE=orc63 PRIV HISTORY";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::dump_priv_history' );

note( "SCHEDULE HISTORY" );
$cmd = "SCHEDULE HISTORY";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::dump_schedule_history' );

note( "EMPLOYEE_SPEC SCHEDULE HISTORY" );
$cmd = "EMPLOYEE=orc63 SCHEDULE HISTORY";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::dump_schedule_history' );

note( "EMPLOYEE_SPEC PRIV_SPEC _DATE" );
$cmd = "EMPLOYEE=63 active 2000-01-01 00:00";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE_SPEC',
              'PRIV_SPEC',
              '_DATE'
            ],
    'th' => {
              'EMPLOYEE_SPEC' => 'EMPLOYEE=63',
              'PRIV_SPEC' => 'active',
              '_DATE' => '2000-01-01',
              '_REST' => '00:00',
            },
    'nc' => 'EMPLOYEE_SPEC PRIV_SPEC _DATE'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::add_priv_history' );

note( "EMPLOYEE_SPEC PRIV_SPEC EFFECTIVE _DATE" );
$cmd = "EMPLOYEE=63 active EFFECTIVE 2000-01-01 00:00";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE_SPEC',
              'PRIV_SPEC',
              'EFFECTIVE',
              '_DATE'
            ],
    'th' => {
              'EMPLOYEE_SPEC' => 'EMPLOYEE=63',
              'PRIV_SPEC' => 'active',
              'EFFECTIVE' => 'EFFECTIVE',
              '_DATE' => '2000-01-01',
              '_REST' => '00:00',
            },
    'nc' => 'EMPLOYEE_SPEC PRIV_SPEC EFFECTIVE _DATE'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::add_priv_history' );

note( "EMPLOYEE_SPEC SET PRIV_SPEC _DATE" );
$cmd = "EMPLOYEE=63 SET active 2000-01-01 00:00";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::add_priv_history' );

note( "EMPLOYEE_SPEC SET PRIV_SPEC EFFECTIVE _DATE" );
$cmd = "EMPLOYEE=63 SET active EFFECTIVE 2000-01-01 00:00:01";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::add_priv_history' );

note( "EMPLOYEE_SPEC SCHEDULE_SPEC _DATE" );
$cmd = "EMPLOYEE=orc63 SCODE=FOO_SCHED 1955-04-27";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::add_schedule_history' );

note( "EMPLOYEE_SPEC SCHEDULE_SPEC EFFECTIVE _DATE" );
$cmd = "EMPLOYEE=orc63 SCODE=FOO_SCHED EFFECTIVE 1955-04-27";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::add_schedule_history' );

note( "EMPLOYEE_SPEC SET SCHEDULE_SPEC _DATE" );
$cmd = "EMPLOYEE=orc63 SET SCODE=FOO_SCHED 1955-04-27";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::add_schedule_history' );

note( "EMPLOYEE_SPEC SET SCHEDULE_SPEC EFFECTIVE _DATE" );
$cmd = "EMPLOYEE=orc63 SET SCODE=FOO_SCHED EFFECTIVE 1955-04-27";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::add_schedule_history' );

$cmd = "PHID=534 REMARK Not the longest remark in the world";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::set_history_remark' );

$cmd = "PHID=534 SET REMARK Not the longest remark in the world";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::set_history_remark' );

$cmd = "SHID=534 REMARK Not the longest remark in the world";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::set_history_remark' );

$cmd = "SHID=534 SET REMARK Not the longest remark in the world";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::History::set_history_remark' );


#================================
# Interval commands
#================================

note( "Interval fetch and fillup" );

note( $cmd = "INTERVAL your text here or there" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_promptdate' ); 

note( $cmd = "EMPLOYEE=orc6e INTERVAL your text here or there" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_promptdate' ); 

note( $cmd = "INTERVAL FETCH" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_promptdate' ); 

note( $cmd = "EMPLOYEE=orc6e INTERVAL FETCH" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_promptdate' ); 

note( $cmd = "INTERVAL FILLUP" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_promptdate' ); 

note( $cmd = "EMPLOYEE=orc6e INTERVAL FILLUP" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_promptdate' ); 

note( $cmd = "INTERVAL TOMORROW" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date' ); 

note( $cmd = "EMPLOYEE=orc6e INTERVAL TOMORROW" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date' ); 

note( $cmd = "INTERVAL FETCH 77-1-3" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date' ); 

note( $cmd = "EMPLOYEE=orc6e INTERVAL FETCH 77-1-3" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date' ); 

note( $cmd = "INTERVAL FILLUP 77-1-3" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date' ); 

note( $cmd = "EMPLOYEE=orc6e INTERVAL FILLUP 77-1-3" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date' ); 

note( $cmd = "INTERVAL 77-1-3 78-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "EMPLOYEE=33 INTERVAL +1 2078-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "INTERVAL FETCH 77-1-3 78-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "EMPLOYEE=33 INTERVAL FETCH +1 2078-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "INTERVAL FILLUP 77-1-3 78-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "EMPLOYEE=33 INTERVAL FILLUP +1 2078-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "INTERVAL 77-1-3 - 78-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "EMPLOYEE=33 INTERVAL +1 - -1" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "INTERVAL FETCH 77-1-3 - 78-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "EMPLOYEE=33 INTERVAL FETCH -15 - +0" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "INTERVAL FILLUP 77-1-3 - 78-12-15" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "EMPLOYEE=33 INTERVAL FILLUP -15 - +0" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_date_date1' ); 

note( $cmd = "INTERVAL JUNE" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL JUNE" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "INTERVAL FETCH decmer" ); # only the first three characters
                                        # of the month are significant
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL FETCH JUNE" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "INTERVAL FILLUP decmer" ); # only the first three characters
                                        # of the month are significant
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL FILLUP JUNE" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "INTERVAL JUNE 2015" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL JUNE 1933" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "INTERVAL FETCH decmer 33" ); # only the first three characters
                                        # of the month are significant
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL FETCH JUNE 43523" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "INTERVAL FILLUP decmer 33" ); # only the first three characters
                                        # of the month are significant
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL FILLUP JUNE 43523" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_month' ); 

note( $cmd = "INTERVAL 6" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL 6" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "INTERVAL FETCH 12" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL FETCH 34" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "INTERVAL FILLUP 12" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL FILLUP 34" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "INTERVAL 6 2015" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL 6 1933" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "INTERVAL FETCH 12 33" ); # only the first three characters
                                        # of the month are significant
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL FETCH 6 43523" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "INTERVAL FILLUP 12 33" ); # only the first three characters
                                        # of the month are significant
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 

note( $cmd = "EMPLOYEE=0 INTERVAL FILLUP 6 43523" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_num_num1' ); 


note( "Interval adding" );

note( $cmd = "INTERVAL 00:00 5:1 WORK my heart's content" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL 00:00  - 5:1 WORK my heart's content" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL 00:00-5:1 WORK my heart's content" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_timerange' );

note( $cmd = "INTERVAL TODAY 00:00 5:1 WORK my heart's content" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL tomROWOR 00:00 5:1 WORK my heart's content" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL yesterYEAR 00:00 5:1 WORK my heart's content" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL 44-53-1 00:00  - 5:1 WORK my heart's content" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL 1956-07-2 00:00-5:1 WORK my heart's content" );
$r = parse( $cmd );
is_deeply( $r, {
           'ts' => [
                     'INTERVAL',
                     '_DATE',
                     '_TIMERANGE',
                     '_TERM'
                   ],
           'th' => {
                     '_DATE' => '1956-07-2',
                     '_TIMERANGE' => '00:00-5:1',
                     'INTERVAL' => 'INTERVAL',
                     '_REST' => 'my heart\'s content',
                     '_TERM' => 'WORK'
                   },
           'nc' => 'INTERVAL _DATE _TIMERANGE _TERM'
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_timerange' );

note( $cmd = "INTERVAL +3 00:00-5:1 WORK my heart's content" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_timerange' );

note( $cmd = "INTERVAL YESTERDAY 04:35 TOMORROW 14:00 FOO_BAR_PUSS Working my butt off" ); 
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_date_time_date1_time1' );

note( $cmd = "INTERVAL 1944-01-26 04:35 1944-01-26 14:00 FOO_BAR_PUSS Working my butt off" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_date_time_date1_time1' );

note( $cmd = "INTERVAL 1944-01-26 04:35 14:0 WORK Different test string" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL 1944-01-26 04:35 - 14:00 FOO_BAR_PUSS Working my butt off" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL -1 04:35 - 14:00 FOO_BAR_PUSS Working my butt off" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_time_time1' );

note( $cmd = "INTERVAL 4:35-14:00 FOO_BAR_PUSS Working my butt off" );
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Interval::interval_new_timerange' );


#================================
# Priv commands
#================================

$cmd = "PRIV";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Priv::show_priv_as_at' );

$cmd = "EMPLOYEE=porg PRIV";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Priv::show_priv_as_at' );


#================================
# Schedule commands
#================================

$cmd = "SCHEDULE";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              '_REST' => '',
            },
    'nc' => "SCHEDULE"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::show_schedule_as_at' );

$cmd = "EMPLOYEE=orc63 SCHEDULE";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'EMPLOYEE_SPEC',
              'SCHEDULE',
            ],
    'th' => {
              'EMPLOYEE_SPEC' => 'EMPLOYEE=orc63',
              'SCHEDULE' => 'SCHEDULE',
              '_REST' => '',
            },
    'nc' => "EMPLOYEE_SPEC SCHEDULE"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::show_schedule_as_at' );

$cmd = "SCHEDULE MON 33:33 TUE 23:00";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE',
              '_DOW',
              '_TIME',
              '_DOW1',
              '_TIME1',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              '_DOW' => 'MON',
              '_TIME' => '33:33',
              '_DOW1' => 'TUE',
              '_TIME1' => '23:00',
              '_REST' => '',
            },
    'nc' => "SCHEDULE _DOW _TIME _DOW1 _TIME1"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::add_memsched_entry' );

$cmd = "SCHEDULE MON 33:33 - TUE 23:00";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE',
              '_DOW',
              '_TIME',
              '_HYPHEN',
              '_DOW1',
              '_TIME1',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              '_DOW' => 'MON',
              '_TIME' => '33:33',
              '_DOW1' => 'TUE',
              '_HYPHEN' => '-',
              '_TIME1' => '23:00',
              '_REST' => '',
            },
    'nc' => "SCHEDULE _DOW _TIME _HYPHEN _DOW1 _TIME1"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::add_memsched_entry' );

$cmd = "SCHEDULE MON 33:33-23:00";
$r_should_be = {
    'ts' => [
              'SCHEDULE',
              '_DOW',
              '_TIMERANGE',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              '_DOW' => 'MON',
              '_TIMERANGE' => '33:33-23:00',
              '_REST' => '',
            },
    'nc' => "SCHEDULE _DOW _TIMERANGE"
};
$r = parse( $cmd );
is_deeply( $r, $r_should_be );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::add_memsched_entry' );

$cmd = "SCHEDULE ALL 33:33-23:00";
$r_should_be = {
    'ts' => [
              'SCHEDULE',
              'ALL',
              '_TIMERANGE',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              'ALL' => 'ALL',
              '_TIMERANGE' => '33:33-23:00',
              '_REST' => '',
            },
    'nc' => "SCHEDULE ALL _TIMERANGE"
};
$r = parse( $cmd );
is_deeply( $r, $r_should_be );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::replicate_memsched_entry' );

$cmd = "SCHEDULE CLEAR";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::clear_memsched_entries' );

$cmd = "SCHEDULE DUMP";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::dump_memsched_entries' );

$cmd = "SCHEDULE FETCH ALL";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE',
              'FETCH',
              'ALL',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              'FETCH' => 'FETCH',
              'ALL' => 'ALL',
              '_REST' => '',
            },
    'nc' => "SCHEDULE FETCH ALL",
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::fetch_all_schedules' );

$cmd = "SCHEDULE FETCH ALL DISABLED";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE',
              'FETCH',
              'ALL',
              'DISABLED',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              'FETCH' => 'FETCH',
              'ALL' => 'ALL',
              'DISABLED' => 'DISABLED',
              '_REST' => '',
            },
    'nc' => "SCHEDULE FETCH ALL DISABLED",
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::fetch_all_schedules' );

$cmd = "SCHEDULE MEMORY";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE',
              'MEMORY',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              'MEMORY' => 'MEMORY',
              '_REST' => '',
            },
    'nc' => "SCHEDULE MEMORY"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::dump_memsched_entries' );

$cmd = "SCHEDULE NEW";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE',
              'NEW',
            ],
    'th' => {
              'SCHEDULE' => 'SCHEDULE',
              'NEW' => 'NEW',
              '_REST' => '',
            },
    'nc' => "SCHEDULE NEW"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::schedule_new' );

$cmd = "SCHEDULE SCODE barney";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::assign_memsched_scode' );

$cmd = "SID=99";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE_SPEC',
            ],
    'th' => {
              'SCHEDULE_SPEC' => 'SID=99',
              '_REST' => '',
            },
    'nc' => "SCHEDULE_SPEC"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::schedulespec' );

$cmd = "SID=99 SHOW";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE_SPEC',
              'SHOW',
            ],
    'th' => {
              'SCHEDULE_SPEC' => 'SID=99',
              'SHOW' => 'SHOW',
              '_REST' => '',
            },
    'nc' => "SCHEDULE_SPEC SHOW"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::schedulespec' );

$cmd = "SID=99 REMARK";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE_SPEC',
              'REMARK',
            ],
    'th' => {
              'SCHEDULE_SPEC' => 'SID=99',
              'REMARK' => 'REMARK',
              '_REST' => '',
            },
    'nc' => "SCHEDULE_SPEC REMARK"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::schedulespec_remark' );

$cmd = "SCODE=FOO_BAR_BAZ SET REMARK";
$r = parse( $cmd );
is_deeply( $r, {
    'ts' => [
              'SCHEDULE_SPEC',
              'SET',
              'REMARK',
            ],
    'th' => {
              'SCHEDULE_SPEC' => 'SCODE=FOO_BAR_BAZ',
              'SET' => 'SET',
              'REMARK' => 'REMARK',
              '_REST' => '',
            },
    'nc' => "SCHEDULE_SPEC SET REMARK"
} );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::schedulespec_remark' );

$cmd = "SID=99 SCODE FOO_BAR_BAZ";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::schedulespec_scode' );

$cmd = "SID=99 SET SCODE FOO_BAR_BAZ";
$r = parse( $cmd );
do_parse_test( $r->{'nc'}, 'App::Dochazka::CLI::Commands::Schedule::schedulespec_scode' );

done_testing;
