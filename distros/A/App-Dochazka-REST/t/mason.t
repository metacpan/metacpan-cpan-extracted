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
#
# Mason tests
#

#!perl
use 5.012;
use strict;
use warnings;

#use App::CELL::Test::LogToFile;
use App::CELL qw( $CELL $site );
use App::Dochazka::REST;
use App::Dochazka::REST::Mason qw( $interp );
use Data::Dumper;
use Test::More;
use Test::Warnings;
use Web::MREST;


my $status;

note( 'initialize' );
$status = Web::MREST::init( 
    distro => 'App-Dochazka-REST', 
    sitedir => '/etc/dochazka-rest', 
);
plan skip_all => "Web::MREST::init failed: " . $status->text unless $status->ok;

note( 'DOCHAZKA_STATE_DIR is readable, writable, executable by us' );
my $sd = $site->DOCHAZKA_STATE_DIR;
plan skip_all => "State directory $sd is missing" unless -e $sd;
plan skip_all => "State directory $sd not readable" unless -r $sd;
plan skip_all => "State directory $sd not writable" unless -w $sd;
plan skip_all => "State directory $sd not executable" unless -x $sd;

note( 'attempt to initialize Mason singleton with invalid arguments' );
$status = App::Dochazka::REST::Mason::init_singleton();
is( $status->level, 'CRIT' );
$status = App::Dochazka::REST::Mason::init_singleton( 1, 2 );
is( $status->level, 'CRIT' );
$status = App::Dochazka::REST::Mason::init_singleton( data_dir => 'bubba' );
is( $status->level, 'CRIT' );

note( 'attempt to initialize Mason singleton with nominally valid, but non-existent arguments' );
$status = App::Dochazka::REST::Mason::init_singleton( comp_root => 'bubba', data_dir => 'bubba' );
is( $status->level, 'CRIT' );

note( 'prepare real comp_root and data_dir' );
ok( ! defined( $interp ) );
$status = App::Dochazka::REST::reset_mason_dir();
is( $status->level, 'OK' );
is( ref( $interp ), 'Mason::Interp' );

done_testing;
