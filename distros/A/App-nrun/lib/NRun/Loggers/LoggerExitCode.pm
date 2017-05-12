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
# Program: LoggerExitCode.pm
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
# Timo Benk : 2013-06-20 13:15:16 +0200 : unbuffer writes to LOG
#

###
# this logger logs the exit codes.
###

package NRun::Loggers::LoggerExitCode;

use strict;
use warnings;

use File::Basename;
use NRun::Logger;

our @ISA = qw(NRun::Logger);

BEGIN {

    NRun::Logger::register ( {

        'LOGGER' => "result",
        'DESC'   => "log only the exit code",
        'NAME'   => __PACKAGE__,
    } );
}

###
# create a new object.
#
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    return $self;
}

###
# initialize this logger module.
#
# $_cfg - parameter hash where
# {
#   'log_directory' - the base directory the logfile should be created in
# }
# <- the new object
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->{log_directory} = $_cfg->{log_directory};
    $_self->{logfile} = "$_self->{log_directory}/result.log";

    select(LOG);
    $| = 1;
    select(STDOUT);

    open(LOG, ">>$_self->{logfile}") or die("$_self->{logfile}: $!");

    $_self->{LOG} = \*LOG;
}

###
# handle one line of data written on stdout.
#
# expected data format:
#
# HOSTNAME;[stdout|stderr];TSTAMP;PID;PID(CHILD);[debug|error|exit|output|end];"OUTPUT"
#
# $_data - the data to be handled
sub stdout {

    my $_self = shift;
    my $_data = shift;

    my @data = split(/;/, $_data);

    my ($message) = ($_data =~ m/[^"]"(.*)"[^"]*/);

    if ($data[5] eq "exit") {

        $_self->{data}->{$data[0]} = $message;
    } elsif ($data[5] eq "end") {

        my $code = delete($_self->{data}->{$data[0]});

        print {$_self->{LOG}} "$data[0]: $code\n" if (defined($code));
    }
}

###
# handle one line of data written on stderr.
#
# expected data format:
#
# HOSTNAME;[stdout|stderr];TSTAMP;PID;PID(CHILD);[debug|error|exit|output|end];"OUTPUT"
#
# $_data - the data to be handled
sub stderr {

    my $_self = shift;
    my $_data = shift;
}

DESTROY {

    my $_self = shift;

    close($_self->{LOG});
};

1;
