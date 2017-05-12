#
# Copyright 2013 Timo Benk
# 
# This file is part of nrun.
# 
# nrun is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# nrun is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with nrun.  If not, see <http://www.gnu.org/licenses/>.
#
# Program: CheckPing.pm
# Author:  Timo Benk <benk@b1-systems.de>
# Date:    Wed Jul 17 19:44:13 2013 +0200
# Ident:   e81f2ed28d3a5b52045231c0700113b9349472fe
# Branch:  master
#
# Changelog:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s
# 
# Timo Benk : 2013-06-13 13:59:01 +0200 : process output handling refined
# Timo Benk : 2013-06-13 20:32:17 +0200 : using __PACKAGE__ is less error-prone
# Timo Benk : 2013-06-14 17:38:58 +0200 : --no-hostname option removed
# Timo Benk : 2013-06-15 07:40:46 +0200 : STDOUT and STDERR were misplaced
#

###
# this check checks whether the provide hostname is pinging.
###

package NRun::Checks::CheckPing;

use strict;
use warnings;

use File::Basename;
use NRun::Check;
use Net::Ping;

our @ISA = qw(NRun::Check);

BEGIN {

    NRun::Check::register ( {

        'CHECK' => "ping",
        'DESC'  => "check if host answers to ping",
        'NAME'  => __PACKAGE__,
    } );
}

###
# create a new object.
#
# <- the new object
sub new {

    my $_pkg = shift;
    my $_cfg = shift;

    my $self = {};
    bless $self, $_pkg;

    return $self;
}

###
# initialize this check module.
#
# $_cfg - parameter hash where
# {
#   'hostname' - hostname this check should act on
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->{hostname} = $_cfg->{hostname};
}

###
# execute the check on $_self->{hostname}.
#
# on error, the following string will be printed on stderr:
#
# HOSTNAME;stderr;PID;n/a;error;"OUTPUT"
#
# <- 1 on success and 0 on error
sub execute {

    my $_self = shift;

    if (not Net::Ping->new()->ping($_self->{hostname})) {

        print STDERR "$_self->{hostname};stderr;" . time() . ";$$;n/a;error;\"no ping reply from $_self->{hostname}\"\n";
        print STDOUT "$_self->{hostname};stdout;" . time() . ";$$;n/a;exit;\"exit code $NRun::Constants::CHECK_FAILED_PING\"\n";

        return 0;
    }

    return 1;
}

1;
