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
# REST test parsing tests ("do REST test commands parse?")

#!perl
use 5.012;
use strict;
use warnings;

use App::Dochazka::CLI::Parser qw( look_up_command parse );
use Data::Dumper;
use Test::More;
use Test::Warnings;

my ( $cmd, $res, $r, $e );

#
# piecemeal tests
#

$res = parse( "get" );
is( $res->{nc}, 'GET' );
is( $res->{th}->{_REST}, '' );

$res = parse( "get activi" );
is( $res->{nc}, 'GET ACTIVITY' );
is( $res->{th}->{_REST}, '' );

$res = parse( "del history" );
is( $res->{nc}, 'DELETE' );
is( $res->{th}->{_REST}, 'history' );

$res = parse( "get inter iid 123" );
is( $res->{nc}, 'GET INTERVAL IID _NUM' );
is( $res->{th}->{_NUM}, 123 );
is( $res->{th}->{_REST}, '' );

$res = parse( "post docu pod activity/eid/:eid" );
is( $res->{nc}, 'POST DOCU POD _DOCU' );
is( $res->{th}->{_DOCU}, 'activity/eid/:eid' );

$res = parse( "post docu html \"activity/eid/:eid\"" );
is( $res->{nc}, 'POST DOCU HTML _DOCU' );
is( $res->{th}->{_DOCU}, "\"activity/eid/:eid\"" );

#
# systematic tests
#

my %map = (

    # Top-level commands
    'GET' => [ 'GET', '' ],
    'PUT' => [ 'PUT', '' ],
    'POST' => [ 'POST', '' ],
    'DELETE' => [ 'DELETE', '' ],
    "GET BUGREPORT" => [ 'GET', 'bugreport' ],
    "PUT BUGREPORT" => [ 'PUT', 'bugreport' ],
    "POST BUGREPORT" => [ 'POST', 'bugreport' ],
    "DELETE BUGREPORT" => [ 'DELETE', 'bugreport' ],
#    "GET COOKIEJAR" => [ 'GET', 'cookiejar' ],
#    "PUT COOKIEJAR" => [ 'PUT', 'cookiejar' ],
#    "POST COOKIEJAR" => [ 'POST', 'cookiejar' ],
#    "DELETE COOKIEJAR" => [ 'DELETE', 'cookiejar' ],
    "GET DBSTATUS" => [ 'GET', 'dbstatus' ],
    "PUT DBSTATUS" => [ 'PUT', 'dbstatus' ],
    "POST DBSTATUS" => [ 'POST', 'dbstatus' ],
    "DELETE DBSTATUS" => [ 'DELETE', 'dbstatus' ],
    "GET DOCU" => [ 'GET', 'docu' ],
    "PUT DOCU" => [ 'PUT', 'docu' ],
    "POST DOCU" => [ 'POST', 'docu' ],
    "DELETE DOCU" => [ 'DELETE', 'docu' ],
    "GET DOCU POD" => [ 'GET', 'docu/pod' ],
    "PUT DOCU POD" => [ 'PUT', 'docu/pod' ],
    "POST DOCU POD" => [ 'POST', 'docu/pod' ],
    "DELETE DOCU POD" => [ 'DELETE', 'docu/pod' ],
    "GET DOCU HTML" => [ 'GET', 'docu/html' ],
    "PUT DOCU HTML" => [ 'PUT', 'docu/html' ],
    "POST DOCU HTML" => [ 'POST', 'docu/html' ],
    "DELETE DOCU HTML" => [ 'DELETE', 'docu/html' ],
    "GET DOCU TEXT" => [ 'GET', 'docu/text' ],
    "PUT DOCU TEXT" => [ 'PUT', 'docu/text' ],
    "POST DOCU TEXT" => [ 'POST', 'docu/text' ],
    "DELETE DOCU TEXT" => [ 'DELETE', 'docu/text' ],
    "GET ECHO" => [ 'GET', 'echo' ],
    "PUT ECHO" => [ 'PUT', 'echo' ],
    "POST ECHO" => [ 'POST', 'echo' ],
    "DELETE ECHO" => [ 'DELETE', 'echo' ],
    "GET FORBIDDEN" => [ 'GET', 'forbidden' ],
    "PUT FORBIDDEN" => [ 'PUT', 'forbidden' ],
    "POST FORBIDDEN" => [ 'POST', 'forbidden' ],
    "DELETE FORBIDDEN" => [ 'DELETE', 'forbidden' ],
    "GET NOOP" => [ 'GET', 'noop' ],
    "PUT NOOP" => [ 'PUT', 'noop' ],
    "POST NOOP" => [ 'POST', 'noop' ],
    "DELETE NOOP" => [ 'DELETE', 'noop' ],
    "GET PARAM" => [ 'GET', 'param' ],
    "PUT PARAM" => [ 'PUT', 'param' ],
    "POST PARAM" => [ 'POST', 'param' ],
    "DELETE PARAM" => [ 'DELETE', 'param' ],
    "GET PARAM CORE FOOBAR" => [ 'GET', 'param/core/FOOBAR' ],
    "PUT PARAM CORE FOOBAR" => [ 'PUT', 'param/core/FOOBAR' ], 
    "POST PARAM CORE FOOBAR" => [ 'POST', 'param/core/FOOBAR' ],
    "DELETE PARAM CORE FOOBAR" => [ 'DELETE', 'param/core/FOOBAR' ],
    "GET PARAM META FOOBAR" => [ 'GET', 'param/meta/FOOBAR' ],
    "PUT PARAM META FOOBAR" => [ 'PUT', 'param/meta/FOOBAR' ], 
    "POST PARAM META FOOBAR" => [ 'POST', 'param/meta/FOOBAR' ],
    "DELETE PARAM META FOOBAR" => [ 'DELETE', 'param/meta/FOOBAR' ],
    "GET PARAM SITE FOOBAR" => [ 'GET', 'param/site/FOOBAR' ],
    "PUT PARAM SITE FOOBAR" => [ 'PUT', 'param/site/FOOBAR' ], 
    "POST PARAM SITE FOOBAR" => [ 'POST', 'param/site/FOOBAR' ],
    "DELETE PARAM SITE FOOBAR" => [ 'DELETE', 'param/site/FOOBAR' ],
    "GET SESSION" => [ 'GET', 'session' ],
    "PUT SESSION" => [ 'PUT', 'session' ],
    "POST SESSION" => [ 'POST', 'session' ],
    "DELETE SESSION" => [ 'DELETE', 'session' ],
    "GET VERSION" => [ 'GET', 'version' ],
    "PUT VERSION" => [ 'PUT', 'version' ],
    "POST VERSION" => [ 'POST', 'version' ],
    "DELETE VERSION" => [ 'DELETE', 'version' ],
    "GET WHOAMI" => [ 'GET', 'whoami' ],
    "PUT WHOAMI" => [ 'PUT', 'whoami' ],
    "POST WHOAMI" => [ 'POST', 'whoami' ],
    "DELETE WHOAMI" => [ 'DELETE', 'whoami' ],
    
    # Activity commands
    "GET ACTIVITY AID 123" => [ 'GET', 'activity/aid/123' ],
    "PUT ACTIVITY AID 123" => [ 'PUT', 'activity/aid/123' ],
    "POST ACTIVITY AID 123" => [ 'POST', 'activity/aid/123' ],
    "DELETE ACTIVITY AID 123" => [ 'DELETE', 'activity/aid/123' ],
    "GET ACTIVITY ALL" => [ 'GET', 'activity/all' ],
    "PUT ACTIVITY ALL" => [ 'PUT', 'activity/all' ],
    "POST ACTIVITY ALL" => [ 'POST', 'activity/all' ],
    "DELETE ACTIVITY ALL" => [ 'DELETE', 'activity/all' ],
    "GET ACTIVITY ALL DISABLED" => [ 'GET', 'activity/all/disabled' ],
    "PUT ACTIVITY ALL DISABLED" => [ 'PUT', 'activity/all/disabled' ],
    "POST ACTIVITY ALL DISABLED" => [ 'POST', 'activity/all/disabled' ],
    "DELETE ACTIVITY ALL DISABLED" => [ 'DELETE', 'activity/all/disabled' ],
    "GET ACTIVITY CODE FOOBAR" => [ 'GET', 'activity/code/FOOBAR' ],
    "PUT ACTIVITY CODE FOOBAR" => [ 'PUT', 'activity/code/FOOBAR' ],
    "POST ACTIVITY CODE FOOBAR" => [ 'POST', 'activity/code/FOOBAR' ],
    "DELETE ACTIVITY CODE FOOBAR" => [ 'DELETE', 'activity/code/FOOBAR' ],

    # Employee commands
    "GET EMPLOYEE" => [ 'GET', 'employee' ],
    "PUT EMPLOYEE" => [ 'PUT', 'employee' ],
    "POST EMPLOYEE" => [ 'POST', 'employee' ],
    "DELETE EMPLOYEE" => [ 'DELETE', 'employee' ],
    "GET EMPLOYEE COUNT" => [ 'GET', 'employee/count' ],
    "PUT EMPLOYEE COUNT" => [ 'PUT', 'employee/count' ],
    "POST EMPLOYEE COUNT" => [ 'POST', 'employee/count' ],
    "DELETE EMPLOYEE COUNT" => [ 'DELETE', 'employee/count' ],
    "GET EMPLOYEE COUNT PRIV" => [ 'GET', 'employee/count/priv' ],
    "PUT EMPLOYEE COUNT PRIV" => [ 'PUT', 'employee/count/priv' ],
    "POST EMPLOYEE COUNT PRIV" => [ 'POST', 'employee/count/priv' ],
    "DELETE EMPLOYEE COUNT PRIV" => [ 'DELETE', 'employee/count/priv' ],
    "GET EMPLOYEE CURRENT" => [ 'GET', 'employee/current' ],
    "PUT EMPLOYEE CURRENT" => [ 'PUT', 'employee/current' ],
    "POST EMPLOYEE CURRENT" => [ 'POST', 'employee/current' ],
    "DELETE EMPLOYEE CURRENT" => [ 'DELETE', 'employee/current' ],
    "GET EMPLOYEE CURRENT PRIV" => [ 'GET', 'employee/current/priv' ],
    "PUT EMPLOYEE CURRENT PRIV" => [ 'PUT', 'employee/current/priv' ],
    "POST EMPLOYEE CURRENT PRIV" => [ 'POST', 'employee/current/priv' ],
    "DELETE EMPLOYEE CURRENT PRIV" => [ 'DELETE', 'employee/current/priv' ],
    "GET EMPLOYEE SEARCH" => [ 'GET', 'employee/search' ],
    "PUT EMPLOYEE SEARCH" => [ 'PUT', 'employee/search' ],
    "POST EMPLOYEE SEARCH" => [ 'POST', 'employee/search' ],
    "DELETE EMPLOYEE SEARCH" => [ 'DELETE', 'employee/search' ],
    "GET EMPLOYEE SEARCH NICK foobar" => [ 'GET', 'employee/search/nick/foobar' ],
    "PUT EMPLOYEE SEARCH NICK foobar" => [ 'PUT', 'employee/search/nick/foobar' ],
    "POST EMPLOYEE SEARCH NICK foobar" => [ 'POST', 'employee/search/nick/foobar' ],
    "DELETE EMPLOYEE SEARCH NICK foobar" => [ 'DELETE', 'employee/search/nick/foobar' ],
    "GET EMPLOYEE SELF" => [ 'GET', 'employee/self' ],
    "PUT EMPLOYEE SELF" => [ 'PUT', 'employee/self' ],
    "POST EMPLOYEE SELF" => [ 'POST', 'employee/self' ],
    "DELETE EMPLOYEE SELF" => [ 'DELETE', 'employee/self' ],
    "GET EMPLOYEE SELF PRIV" => [ 'GET', 'employee/self/priv' ],
    "PUT EMPLOYEE SELF PRIV" => [ 'PUT', 'employee/self/priv' ],
    "POST EMPLOYEE SELF PRIV" => [ 'POST', 'employee/self/priv' ],
    "DELETE EMPLOYEE SELF PRIV" => [ 'DELETE', 'employee/self/priv' ],
    "GET EMPLOYEE EID" => [ 'GET', 'employee/eid' ],
    "PUT EMPLOYEE EID" => [ 'PUT', 'employee/eid' ],
    "POST EMPLOYEE EID" => [ 'POST', 'employee/eid' ],
    "DELETE EMPLOYEE EID" => [ 'DELETE', 'employee/eid' ],
    "GET EMPLOYEE EID 1" => [ 'GET', 'employee/eid/1' ],
    "PUT EMPLOYEE EID 1" => [ 'PUT', 'employee/eid/1' ],
    "POST EMPLOYEE EID 1" => [ 'POST', 'employee/eid/1' ],
    "DELETE EMPLOYEE EID 1" => [ 'DELETE', 'employee/eid/1' ],
    "GET EMPLOYEE NICK" => [ 'GET', 'employee/nick' ],
    "PUT EMPLOYEE NICK" => [ 'PUT', 'employee/nick' ],
    "POST EMPLOYEE NICK" => [ 'POST', 'employee/nick' ],
    "DELETE EMPLOYEE NICK" => [ 'DELETE', 'employee/nick' ],
    "GET EMPLOYEE NICK FOOBAR" => [ 'GET', 'employee/nick/FOOBAR' ],
    "PUT EMPLOYEE NICK FOOBAR" => [ 'PUT', 'employee/nick/FOOBAR' ],
    "POST EMPLOYEE NICK FOOBAR" => [ 'POST', 'employee/nick/FOOBAR' ],
    "DELETE EMPLOYEE NICK FOOBAR" => [ 'DELETE', 'employee/nick/FOOBAR' ],

    # Interval commands
    "GET INTERVAL" => [ 'GET', 'interval' ],
    "PUT INTERVAL" => [ 'PUT', 'interval' ],
    "POST INTERVAL" => [ 'POST', 'interval' ],
    "DELETE INTERVAL" => [ 'DELETE', 'interval' ],
    "GET INTERVAL EID 123" => [ 'GET', 'interval/eid/123' ],
    "PUT INTERVAL EID 123" => [ 'PUT', 'interval/eid/123' ],
    "POST INTERVAL EID 123" => [ 'POST', 'interval/eid/123' ],
    "DELETE INTERVAL EID 123" => [ 'DELETE', 'interval/eid/123' ],
    "GET INTERVAL EID 123 [,)" => [ 'GET', 'interval/eid/123/[,)' ],
    "PUT INTERVAL EID 123 [,)" => [ 'PUT', 'interval/eid/123/[,)' ],
    "POST INTERVAL EID 123 [,)" => [ 'POST', 'interval/eid/123/[,)' ],
    "DELETE INTERVAL EID 123 [,)" => [ 'DELETE', 'interval/eid/123/[,)' ],
    "GET INTERVAL IID 123" => [ 'GET', 'interval/iid/123' ],
    "PUT INTERVAL IID 123" => [ 'PUT', 'interval/iid/123' ],
    "POST INTERVAL IID 123" => [ 'POST', 'interval/iid/123' ],
    "DELETE INTERVAL IID 123" => [ 'DELETE', 'interval/iid/123' ],
    "GET INTERVAL NEW" => [ 'GET', 'interval/new' ],
    "PUT INTERVAL NEW" => [ 'PUT', 'interval/new' ],
    "POST INTERVAL NEW" => [ 'POST', 'interval/new' ],
    "DELETE INTERVAL NEW" => [ 'DELETE', 'interval/new' ],
    "GET INTERVAL NICK 123" => [ 'GET', 'interval/nick/123' ],
    "PUT INTERVAL NICK 123" => [ 'PUT', 'interval/nick/123' ],
    "POST INTERVAL NICK 123" => [ 'POST', 'interval/nick/123' ],
    "DELETE INTERVAL NICK 123" => [ 'DELETE', 'interval/nick/123' ],
    "GET INTERVAL NICK 123 [,)" => [ 'GET', 'interval/nick/123/[,)' ],
    "PUT INTERVAL NICK 123 [,)" => [ 'PUT', 'interval/nick/123/[,)' ],
    "POST INTERVAL NICK 123 [,)" => [ 'POST', 'interval/nick/123/[,)' ],
    "DELETE INTERVAL NICK 123 [,)" => [ 'DELETE', 'interval/nick/123/[,)' ],
    "GET INTERVAL SELF" => [ 'GET', 'interval/self' ],
    "PUT INTERVAL SELF" => [ 'PUT', 'interval/self' ],
    "POST INTERVAL SELF" => [ 'POST', 'interval/self' ],
    "DELETE INTERVAL SELF" => [ 'DELETE', 'interval/self' ],
    'GET INTERVAL SELF [,)' => [ 'GET', 'interval/self/[,)' ],
    'PUT INTERVAL SELF [,)' => [ 'PUT', 'interval/self/[,)' ],
    'POST INTERVAL SELF [,)' => [ 'POST', 'interval/self/[,)' ],
    'DELETE INTERVAL SELF [,)' => [ 'DELETE', 'interval/self/[,)' ],
    'GET INTERVAL SELF [ "2015-02-05 10:00", "2015-02-05 16:00" )' => [ 'GET', 'interval/self/[ "2015-02-05 10:00", "2015-02-05 16:00" )' ],
    'PUT INTERVAL SELF [ "2015-02-05 10:00", "2015-02-05 16:00" )' => [ 'PUT', 'interval/self/[ "2015-02-05 10:00", "2015-02-05 16:00" )' ],
    'POST INTERVAL SELF [ "2015-02-05 10:00", "2015-02-05 16:00" )' => [ 'POST', 'interval/self/[ "2015-02-05 10:00", "2015-02-05 16:00" )' ],
    'DELETE INTERVAL SELF [ "2015-02-05 10:00", "2015-02-05 16:00" )' => [ 'DELETE', 'interval/self/[ "2015-02-05 10:00", "2015-02-05 16:00" )' ],

    # Lock commands
    "GET LOCK" => [ 'GET', 'lock' ],
    "PUT LOCK" => [ 'PUT', 'lock' ],
    "POST LOCK" => [ 'POST', 'lock' ],
    "DELETE LOCK" => [ 'DELETE', 'lock' ],
    "GET LOCK EID 123" => [ 'GET', 'lock/eid/123' ],
    "PUT LOCK EID 123" => [ 'PUT', 'lock/eid/123' ],
    "POST LOCK EID 123" => [ 'POST', 'lock/eid/123' ],
    "DELETE LOCK EID 123" => [ 'DELETE', 'lock/eid/123' ],
    "GET LOCK EID 123 [,)" => [ 'GET', 'lock/eid/123/[,)' ],
    "PUT LOCK EID 123 [,)" => [ 'PUT', 'lock/eid/123/[,)' ],
    "POST LOCK EID 123 [,)" => [ 'POST', 'lock/eid/123/[,)' ],
    "DELETE LOCK EID 123 [,)" => [ 'DELETE', 'lock/eid/123/[,)' ],
    "GET LOCK LID 123" => [ 'GET', 'lock/lid/123' ],
    "PUT LOCK LID 123" => [ 'PUT', 'lock/lid/123' ],
    "POST LOCK LID 123" => [ 'POST', 'lock/lid/123' ],
    "DELETE LOCK LID 123" => [ 'DELETE', 'lock/lid/123' ],
    "GET LOCK NEW" => [ 'GET', 'lock/new' ],
    "PUT LOCK NEW" => [ 'PUT', 'lock/new' ],
    "POST LOCK NEW" => [ 'POST', 'lock/new' ],
    "DELETE LOCK NEW" => [ 'DELETE', 'lock/new' ],
    "GET LOCK NICK 123" => [ 'GET', 'lock/nick/123' ],
    "PUT LOCK NICK 123" => [ 'PUT', 'lock/nick/123' ],
    "POST LOCK NICK 123" => [ 'POST', 'lock/nick/123' ],
    "DELETE LOCK NICK 123" => [ 'DELETE', 'lock/nick/123' ],
    "GET LOCK NICK 123 [,)" => [ 'GET', 'lock/nick/123/[,)' ],
    "PUT LOCK NICK 123 [,)" => [ 'PUT', 'lock/nick/123/[,)' ],
    "POST LOCK NICK 123 [,)" => [ 'POST', 'lock/nick/123/[,)' ],
    "DELETE LOCK NICK 123 [,)" => [ 'DELETE', 'lock/nick/123/[,)' ],
    "GET LOCK SELF" => [ 'GET', 'lock/self' ],
    "PUT LOCK SELF" => [ 'PUT', 'lock/self' ],
    "POST LOCK SELF" => [ 'POST', 'lock/self' ],
    "DELETE LOCK SELF" => [ 'DELETE', 'lock/self' ],
    'GET LOCK SELF [,)' => [ 'GET', 'lock/self/[,)' ],
    'PUT LOCK SELF [,)' => [ 'PUT', 'lock/self/[,)' ],
    'POST LOCK SELF [,)' => [ 'POST', 'lock/self/[,)' ],
    'DELETE LOCK SELF [,)' => [ 'DELETE', 'lock/self/[,)' ],
    'GET LOCK SELF [ "2015-02-05 10:00", "2015-02-05 16:00" )' => [ 'GET', 'lock/self/[ "2015-02-05 10:00", "2015-02-05 16:00" )' ],
    'PUT LOCK SELF [ "2015-02-05 10:00", "2015-02-05 16:00" )' => [ 'PUT', 'lock/self/[ "2015-02-05 10:00", "2015-02-05 16:00" )' ],
    'POST LOCK SELF [ "2015-02-05 10:00", "2015-02-05 16:00" )' => [ 'POST', 'lock/self/[ "2015-02-05 10:00", "2015-02-05 16:00" )' ],
    'DELETE LOCK SELF [ "2015-02-05 10:00", "2015-02-05 16:00" )' => [ 'DELETE', 'lock/self/[ "2015-02-05 10:00", "2015-02-05 16:00" )' ],

    # Priv commands
    "GET PRIV" => [ 'GET', 'priv' ],
    "PUT PRIV" => [ 'PUT', 'priv' ],
    "POST PRIV" => [ 'POST', 'priv' ],
    "DELETE PRIV" => [ 'DELETE', 'priv' ],
    "GET PRIV EID 123" => [ 'GET', 'priv/eid/123' ],
    "PUT PRIV EID 123" => [ 'PUT', 'priv/eid/123' ],
    "POST PRIV EID 123" => [ 'POST', 'priv/eid/123' ],
    "DELETE PRIV EID 123" => [ 'DELETE', 'priv/eid/123' ],
    "GET PRIV EID 123 1999-12-31 23:59" => [ 'GET', 'priv/eid/123/1999-12-31 23:59' ],
    "PUT PRIV EID 123 1999-12-31 23:59" => [ 'PUT', 'priv/eid/123/1999-12-31 23:59' ],
    "POST PRIV EID 123 1999-12-31 23:59" => [ 'POST', 'priv/eid/123/1999-12-31 23:59' ],
    "DELETE PRIV EID 123 1999-12-31 23:59" => [ 'DELETE', 'priv/eid/123/1999-12-31 23:59' ],
    "GET PRIV HISTORY EID 123" => [ 'GET', 'priv/history/eid/123' ],
    "PUT PRIV HISTORY EID 123" => [ 'PUT', 'priv/history/eid/123' ],
    "POST PRIV HISTORY EID 123" => [ 'POST', 'priv/history/eid/123' ],
    "DELETE PRIV HISTORY EID 123" => [ 'DELETE', 'priv/history/eid/123' ],
    "GET PRIV HISTORY EID 123 [,)" => [ 'GET', 'priv/history/eid/123/[,)' ],
    "PUT PRIV HISTORY EID 123 [,)" => [ 'PUT', 'priv/history/eid/123/[,)' ],
    "POST PRIV HISTORY EID 123 [,)" => [ 'POST', 'priv/history/eid/123/[,)' ],
    "DELETE PRIV HISTORY EID 123 [,)" => [ 'DELETE', 'priv/history/eid/123/[,)' ],
    "GET PRIV HISTORY NICK foobar" => [ 'GET', 'priv/history/nick/foobar' ],
    "PUT PRIV HISTORY NICK foobar" => [ 'PUT', 'priv/history/nick/foobar' ],
    "POST PRIV HISTORY NICK foobar" => [ 'POST', 'priv/history/nick/foobar' ],
    "DELETE PRIV HISTORY NICK foobar" => [ 'DELETE', 'priv/history/nick/foobar' ],
    "GET PRIV HISTORY NICK foobar [,)" => [ 'GET', 'priv/history/nick/foobar/[,)' ],
    "PUT PRIV HISTORY NICK foobar [,)" => [ 'PUT', 'priv/history/nick/foobar/[,)' ],
    "POST PRIV HISTORY NICK foobar [,)" => [ 'POST', 'priv/history/nick/foobar/[,)' ],
    "DELETE PRIV HISTORY NICK foobar [,)" => [ 'DELETE', 'priv/history/nick/foobar/[,)' ],
    "GET PRIV HISTORY PHID 123" => [ 'GET', 'priv/history/phid/123' ],
    "PUT PRIV HISTORY PHID 123" => [ 'PUT', 'priv/history/phid/123' ],
    "POST PRIV HISTORY PHID 123" => [ 'POST', 'priv/history/phid/123' ],
    "DELETE PRIV HISTORY PHID 123" => [ 'DELETE', 'priv/history/phid/123' ],
    "GET PRIV HISTORY SELF" => [ 'GET', 'priv/history/self' ],
    "PUT PRIV HISTORY SELF" => [ 'PUT', 'priv/history/self' ],
    "POST PRIV HISTORY SELF" => [ 'POST', 'priv/history/self' ],
    "DELETE PRIV HISTORY SELF" => [ 'DELETE', 'priv/history/self' ],
    "GET PRIV HISTORY SELF [,)" => [ 'GET', 'priv/history/self/[,)' ],
    "PUT PRIV HISTORY SELF [,)" => [ 'PUT', 'priv/history/self/[,)' ],
    "POST PRIV HISTORY SELF [,)" => [ 'POST', 'priv/history/self/[,)' ],
    "DELETE PRIV HISTORY SELF [,)" => [ 'DELETE', 'priv/history/self/[,)' ],
    "GET PRIV NICK foobar" => [ 'GET', 'priv/nick/foobar' ],
    "PUT PRIV NICK foobar" => [ 'PUT', 'priv/nick/foobar' ],
    "POST PRIV NICK foobar" => [ 'POST', 'priv/nick/foobar' ],
    "DELETE PRIV NICK foobar" => [ 'DELETE', 'priv/nick/foobar' ],
    "GET PRIV NICK foobar 2015-02-03 33:99" => [ 'GET', 'priv/nick/foobar/2015-02-03 33:99' ],
    "PUT PRIV NICK foobar 2015-02-03 33:99" => [ 'PUT', 'priv/nick/foobar/2015-02-03 33:99' ],
    "POST PRIV NICK foobar 2015-02-03 33:99" => [ 'POST', 'priv/nick/foobar/2015-02-03 33:99' ],
    "DELETE PRIV NICK foobar 2015-02-03 33:99" => [ 'DELETE', 'priv/nick/foobar/2015-02-03 33:99' ],
    "GET PRIV SELF" => [ 'GET', 'priv/self' ],
    "PUT PRIV SELF" => [ 'PUT', 'priv/self' ],
    "POST PRIV SELF" => [ 'POST', 'priv/self' ],
    "DELETE PRIV SELF" => [ 'DELETE', 'priv/self' ],
    "GET PRIV SELF 2015-02-03 33:99" => [ 'GET', 'priv/self/2015-02-03 33:99' ],
    "PUT PRIV SELF 2015-02-03 33:99" => [ 'PUT', 'priv/self/2015-02-03 33:99' ],
    "POST PRIV SELF 2015-02-03 33:99" => [ 'POST', 'priv/self/2015-02-03 33:99' ],
    "DELETE PRIV SELF 2015-02-03 33:99" => [ 'DELETE', 'priv/self/2015-02-03 33:99' ],

    # Schedule commands
    "GET SCHEDULE" => [ 'GET', 'schedule' ],
    "PUT SCHEDULE" => [ 'PUT', 'schedule' ],
    "POST SCHEDULE" => [ 'POST', 'schedule' ],
    "DELETE SCHEDULE" => [ 'DELETE', 'schedule' ],
    "GET SCHEDULE ALL" => [ 'GET', 'schedule/all' ],
    "PUT SCHEDULE ALL" => [ 'PUT', 'schedule/all' ],
    "POST SCHEDULE ALL" => [ 'POST', 'schedule/all' ],
    "DELETE SCHEDULE ALL" => [ 'DELETE', 'schedule/all' ],
    "GET SCHEDULE ALL DISABLED" => [ 'GET', 'schedule/all/disabled' ],
    "PUT SCHEDULE ALL DISABLED" => [ 'PUT', 'schedule/all/disabled' ],
    "POST SCHEDULE ALL DISABLED" => [ 'POST', 'schedule/all/disabled' ],
    "DELETE SCHEDULE ALL DISABLED" => [ 'DELETE', 'schedule/all/disabled' ],
    "GET SCHEDULE EID 123" => [ 'GET', 'schedule/eid/123' ],
    "PUT SCHEDULE EID 123" => [ 'PUT', 'schedule/eid/123' ],
    "POST SCHEDULE EID 123" => [ 'POST', 'schedule/eid/123' ],
    "DELETE SCHEDULE EID 123" => [ 'DELETE', 'schedule/eid/123' ],
    "GET SCHEDULE EID 123 1999-12-31 23:59" => [ 'GET', 'schedule/eid/123/1999-12-31 23:59' ],
    "PUT SCHEDULE EID 123 1999-12-31 23:59" => [ 'PUT', 'schedule/eid/123/1999-12-31 23:59' ],
    "POST SCHEDULE EID 123 1999-12-31 23:59" => [ 'POST', 'schedule/eid/123/1999-12-31 23:59' ],
    "DELETE SCHEDULE EID 123 1999-12-31 23:59" => [ 'DELETE', 'schedule/eid/123/1999-12-31 23:59' ],
    "GET SCHEDULE HISTORY EID 123" => [ 'GET', 'schedule/history/eid/123' ],
    "PUT SCHEDULE HISTORY EID 123" => [ 'PUT', 'schedule/history/eid/123' ],
    "POST SCHEDULE HISTORY EID 123" => [ 'POST', 'schedule/history/eid/123' ],
    "DELETE SCHEDULE HISTORY EID 123" => [ 'DELETE', 'schedule/history/eid/123' ],
    "GET SCHEDULE HISTORY EID 123 [,)" => [ 'GET', 'schedule/history/eid/123/[,)' ],
    "PUT SCHEDULE HISTORY EID 123 [,)" => [ 'PUT', 'schedule/history/eid/123/[,)' ],
    "POST SCHEDULE HISTORY EID 123 [,)" => [ 'POST', 'schedule/history/eid/123/[,)' ],
    "DELETE SCHEDULE HISTORY EID 123 [,)" => [ 'DELETE', 'schedule/history/eid/123/[,)' ],
    "GET SCHEDULE HISTORY NICK foobar" => [ 'GET', 'schedule/history/nick/foobar' ],
    "PUT SCHEDULE HISTORY NICK foobar" => [ 'PUT', 'schedule/history/nick/foobar' ],
    "POST SCHEDULE HISTORY NICK foobar" => [ 'POST', 'schedule/history/nick/foobar' ],
    "DELETE SCHEDULE HISTORY NICK foobar" => [ 'DELETE', 'schedule/history/nick/foobar' ],
    "GET SCHEDULE HISTORY NICK foobar [,)" => [ 'GET', 'schedule/history/nick/foobar/[,)' ],
    "PUT SCHEDULE HISTORY NICK foobar [,)" => [ 'PUT', 'schedule/history/nick/foobar/[,)' ],
    "POST SCHEDULE HISTORY NICK foobar [,)" => [ 'POST', 'schedule/history/nick/foobar/[,)' ],
    "DELETE SCHEDULE HISTORY NICK foobar [,)" => [ 'DELETE', 'schedule/history/nick/foobar/[,)' ],
    "GET SCHEDULE HISTORY SELF" => [ 'GET', 'schedule/history/self' ],
    "PUT SCHEDULE HISTORY SELF" => [ 'PUT', 'schedule/history/self' ],
    "POST SCHEDULE HISTORY SELF" => [ 'POST', 'schedule/history/self' ],
    "DELETE SCHEDULE HISTORY SELF" => [ 'DELETE', 'schedule/history/self' ],
    "GET SCHEDULE HISTORY SELF [,)" => [ 'GET', 'schedule/history/self/[,)' ],
    "PUT SCHEDULE HISTORY SELF [,)" => [ 'PUT', 'schedule/history/self/[,)' ],
    "POST SCHEDULE HISTORY SELF [,)" => [ 'POST', 'schedule/history/self/[,)' ],
    "DELETE SCHEDULE HISTORY SELF [,)" => [ 'DELETE', 'schedule/history/self/[,)' ],
    "GET SCHEDULE HISTORY SHID 123" => [ 'GET', 'schedule/history/shid/123' ],
    "PUT SCHEDULE HISTORY SHID 123" => [ 'PUT', 'schedule/history/shid/123' ],
    "POST SCHEDULE HISTORY SHID 123" => [ 'POST', 'schedule/history/shid/123' ],
    "DELETE SCHEDULE HISTORY SHID 123" => [ 'DELETE', 'schedule/history/shid/123' ],
    "GET SCHEDULE NICK foobar" => [ 'GET', 'schedule/nick/foobar' ],
    "PUT SCHEDULE NICK foobar" => [ 'PUT', 'schedule/nick/foobar' ],
    "POST SCHEDULE NICK foobar" => [ 'POST', 'schedule/nick/foobar' ],
    "DELETE SCHEDULE NICK foobar" => [ 'DELETE', 'schedule/nick/foobar' ],
    "GET SCHEDULE NICK foobar 2015-02-03 33:99" => [ 'GET', 'schedule/nick/foobar/2015-02-03 33:99' ],
    "PUT SCHEDULE NICK foobar 2015-02-03 33:99" => [ 'PUT', 'schedule/nick/foobar/2015-02-03 33:99' ],
    "POST SCHEDULE NICK foobar 2015-02-03 33:99" => [ 'POST', 'schedule/nick/foobar/2015-02-03 33:99' ],
    "DELETE SCHEDULE NICK foobar 2015-02-03 33:99" => [ 'DELETE', 'schedule/nick/foobar/2015-02-03 33:99' ],
    "GET SCHEDULE SCODE bubba" => [ 'GET', 'schedule/scode/bubba' ],
    "PUT SCHEDULE SCODE bubba" => [ 'PUT', 'schedule/scode/bubba' ],
    "POST SCHEDULE SCODE bubba" => [ 'POST', 'schedule/scode/bubba' ],
    "DELETE SCHEDULE SCODE bubba" => [ 'DELETE', 'schedule/scode/bubba' ],
    "GET SCHEDULE SELF" => [ 'GET', 'schedule/self' ],
    "PUT SCHEDULE SELF" => [ 'PUT', 'schedule/self' ],
    "POST SCHEDULE SELF" => [ 'POST', 'schedule/self' ],
    "DELETE SCHEDULE SELF" => [ 'DELETE', 'schedule/self' ],
    "GET SCHEDULE SELF 2015-02-03 33:99" => [ 'GET', 'schedule/self/2015-02-03 33:99' ],
    "PUT SCHEDULE SELF 2015-02-03 33:99" => [ 'PUT', 'schedule/self/2015-02-03 33:99' ],
    "POST SCHEDULE SELF 2015-02-03 33:99" => [ 'POST', 'schedule/self/2015-02-03 33:99' ],
    "DELETE SCHEDULE SELF 2015-02-03 33:99" => [ 'DELETE', 'schedule/self/2015-02-03 33:99' ],
    "GET SCHEDULE SID 93" => [ 'GET', 'schedule/sid/93' ],
    "PUT SCHEDULE SID 93" => [ 'PUT', 'schedule/sid/93' ],
    "POST SCHEDULE SID 93" => [ 'POST', 'schedule/sid/93' ],
    "DELETE SCHEDULE SID 93" => [ 'DELETE', 'schedule/sid/93' ],
);

# run look_up_command for each key in %map and execute the resulting coderef
# its return value should == map value
# (this tests basic command lookup functionality)
my %map1 = map { $_ => [ $map{ $_ }->[0], $map{ $_ }->[1], '' ] } keys( %map );

foreach my $cmd ( sort keys %map1 ) {
    $r = parse( $cmd );
    #diag "$cmd";
    #diag "parse structure: " . Dumper( $r );
    $e = look_up_command( $r->{nc} );
    is( ref( $e ), 'CODE', "look_up_command with " . $r->{nc} . " is a coderef" );
    my $f =  $e->( $r->{ts}, $r->{th} ); 
    is_deeply( 
        $f,
        $map1{$cmd}, 
        "$cmd coderef returns correct value (no JSON)" 
    );
}

# make a new %map2 identical to %map except undef is replaced with a JSON string
my $json = '{ "foobar" : 123 }';
my %map2 = map { $_ => [ $map{ $_ }->[0], $map{ $_ }->[1], $json ] } keys( %map );

# run look_up_command for each key in %map2 and execute the resulting coderef
# it should die with exception == map2 value
# (this tests that arbitrary JSON string comes back in the exception)
foreach my $cmd ( sort keys %map2) {
    my $cmd_with_json = "$cmd $json";
    #diag $cmd_with_json;
    $r = parse( $cmd_with_json );
    $e = look_up_command( $r->{nc} );
    is( ref( $e ), 'CODE', "look_up_command with " . $r->{nc} . " is a coderef" );
    is_deeply( 
        $e->( $r->{ts}, $r->{th} ), 
        $map2{$cmd}, 
        "$cmd coderef returns correct value (including JSON)" 
    );
}

done_testing;
