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
# Program: FilterSync.pm
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
#

###     
# this filter provides synchronious command output.
###

package NRun::Filters::FilterSync;

use strict;
use warnings;

use File::Basename;
use NRun::Filter;

our @ISA = qw(NRun::Filter);

BEGIN {

    NRun::Filter::register ( {

        'FILTER' => "sync",
        'DESC'   => "dump the command output synchroniously",
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
# initialize this filter module.
sub init {

    my $_self = shift;
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

    if ($data[5] =~ /output|error|info/) {

        push(@{$_self->{data}->{$data[0]}}, $message);
    } elsif ($data[5] eq "end") { 

        $_self->{end_stdout}->{$data[0]} = 1;

        if (defined($_self->{end_stderr}->{$data[0]})) {

            $_self->end($data[0]);
        }
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

    my @data = split(/;/, $_data);

    my ($message) = ($_data =~ m/[^"]"(.*)"[^"]*/);

    if ($data[5] =~ /output|error|info/) {

        push(@{$_self->{data}->{$data[0]}}, $message);
    } elsif ($data[5] eq "end") { 

        $_self->{end_stderr}->{$data[0]} = 1;

        if (defined($_self->{end_stdout}->{$data[0]})) {

            $_self->end($data[0]);
        }
    }
}

###
# when both stderr and stdout have signaled end for $_host, dump
# the collected data for this host.
#
# $_host - the host that has finished execution
sub end {

    my $_self = shift;
    my $_host = shift;

    my $output = delete($_self->{data}->{$_host});

    if (defined($output)) {

        print STDOUT "$_host: " . join("\n$_host: ", @$output) . "\n";
    } else { 

        print STDOUT "$_host:\n";
    }
}

1;
