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
# Program: WorkerNsh.pm
# Author:  Timo Benk <benk@b1-systems.de>
# Date:    Wed Jul 17 19:44:13 2013 +0200
# Ident:   e81f2ed28d3a5b52045231c0700113b9349472fe
# Branch:  master
#
# Changelog:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s
# 
# Timo Benk : 2013-04-28 17:27:31 +0200 : initial checkin
# Timo Benk : 2013-04-28 20:02:52 +0200 : options --skip-ping-check and --skip-ns-check added
# Timo Benk : 2013-04-28 22:01:00 +0200 : ping and ns check moved into Main::callback_action
# Timo Benk : 2013-04-29 18:53:21 +0200 : introducing ncopy
# Timo Benk : 2013-05-21 18:47:43 +0200 : parameter --async added
# Timo Benk : 2013-05-23 17:26:57 +0200 : comment fixed for delete()
# Timo Benk : 2013-05-24 08:03:19 +0200 : generic mode added
# Timo Benk : 2013-06-13 13:59:01 +0200 : process output handling refined
# Timo Benk : 2013-06-13 20:32:17 +0200 : using __PACKAGE__ is less error-prone
# Timo Benk : 2013-06-15 07:33:51 +0200 : wrong variable was used in delete() and copy()
# Timo Benk : 2013-06-21 09:44:13 +0200 : reverse copy support added
#

###
# this worker implements nsh based remote execution
###

package NRun::Worker::WorkerNsh;

use strict;
use warnings;

use File::Basename;
use NRun::Worker;
use NRun::Constants;

our @ISA = qw(NRun::Worker);

BEGIN {

    NRun::Worker::register ( {

        'MODE' => "nsh",
        'DESC' => "nsh based remote execution",
        'NAME'   => __PACKAGE__,
    } );
}

###
# create a new object.
#
# <- the new object
sub new {

    my $_pkg = shift;

    my $self = {};
    bless $self, $_pkg;

    return $self;
}

###
# initialize this worker module.
#
# $_cfg - parameter hash where
# {
#   'hostname'   - hostname this worker should act on
#   'nsh_rcopy'  - commandline for the rcopy command (SOURCE, TARGET, HOSTNAME will be replaced)
#   'nsh_copy'   - commandline for the copy command (SOURCE, TARGET, HOSTNAME will be replaced)
#   'nsh_exec'   - commandline for the exec command (COMMAND, ARGUMENTS, HOSTNAME will be replaced)
#   'nsh_delete' - commandline for the delete command (FILE, HOSTNAME will be replaced)
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->SUPER::init($_cfg);

    $_self->{nsh_rcopy}  = $_cfg->{nsh_rcopy};
    $_self->{nsh_copy}   = $_cfg->{nsh_copy};
    $_self->{nsh_exec}   = $_cfg->{nsh_exec};
    $_self->{nsh_delete} = $_cfg->{nsh_delete};
}

###
# copy a file from $_self->{hostname}.
#
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- the return code
sub rcopy {

    my $_self   = shift;
    my $_source = shift;
    my $_target = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my $cmdline = $_self->{nsh_rcopy};

    $cmdline =~ s/SOURCE/$_source/g;
    $cmdline =~ s/TARGET/$_target/g;
    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    return $_self->do($cmdline);
}

###
# copy a file using nsh to $_self->{hostname}.
#
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- the return code (-128 indicates too many parallel connections)
sub copy {

    my $_self   = shift;
    my $_source = shift;
    my $_target = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my $cmdline = $_self->{nsh_copy};

    $cmdline =~ s/SOURCE/$_source/g;
    $cmdline =~ s/TARGET/$_target/g;
    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    return $_self->do($cmdline);
}

###
# execute the command using nsh on $_self->{hostname}.
#
# $_command - the command that should be executed
# $_args    - arguments that should be supplied to $_command
# <- the return code (-128 indicates too many parallel connections)
sub execute {

    my $_self    = shift;
    my $_command = shift;
    my $_args    = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my $cmdline = $_self->{nsh_exec};

    $cmdline =~ s/COMMAND/$_command/g;
    $cmdline =~ s/ARGUMENTS/$_args/g;
    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    return $_self->do($cmdline);
}

###
# delete a file using nsh on $_self->{hostname}.
#
# $_file - the file that should be deleted
# <- the return code (-128 indicates too many parallel connections)
sub delete {

    my $_self = shift;
    my $_file = shift;

    # nexec "steals" STDIN otherwise - no CTRL+C possible
    close(STDIN);
    open(STDIN, "/dev/null");

    my $cmdline = $_self->{nsh_delete};

    $cmdline =~ s/FILE/$_file/g;
    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    return $_self->do($cmdline);
}

1;
