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
# Program: WorkerLocal.pm
# Author:  Timo Benk <benk@b1-systems.de>
# Date:    Wed Jul 17 19:44:13 2013 +0200
# Ident:   e81f2ed28d3a5b52045231c0700113b9349472fe
# Branch:  master
#
# Changelog:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s
# 
# Timo Benk : 2013-04-28 17:27:31 +0200 : initial checkin
# Timo Benk : 2013-04-29 18:53:21 +0200 : introducing ncopy
# Timo Benk : 2013-05-08 09:55:24 +0200 : TARGET_HOST is now visible in ps output
# Timo Benk : 2013-05-21 18:47:43 +0200 : parameter --async added
# Timo Benk : 2013-05-23 17:26:57 +0200 : comment fixed for delete()
# Timo Benk : 2013-05-24 08:03:19 +0200 : generic mode added
# Timo Benk : 2013-06-13 13:59:01 +0200 : process output handling refined
# Timo Benk : 2013-06-13 20:32:17 +0200 : using __PACKAGE__ is less error-prone
# Timo Benk : 2013-06-14 12:53:08 +0200 : $_self->{O|E} must be used instead of STD{OUT|ERR}
# Timo Benk : 2013-06-21 09:44:13 +0200 : reverse copy support added
#

###
# this worker executes the given script locally and sets the environment
# variable TARGET_HOST on each execution
###

package NRun::Worker::WorkerLocal;

use strict;
use warnings;

use File::Basename;

use NRun::Worker;

our @ISA = qw(NRun::Worker);

BEGIN {

    NRun::Worker::register ( {

        'MODE' => "local",
        'DESC' => "execute the script locally, set TARGET_HOST on each execution",
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

# initialize this worker module.
#
# $_cfg - parameter hash where
# {
#   'hostname'   - hostname this worker should act on
#   'local_exec' - commandline for the exec command (COMMAND, ARGUMENTS, HOSTNAME will be replaced)
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->SUPER::init($_cfg);

    $_self->{local_exec}   = $_cfg->{local_exec};
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

    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;error;\"not implemented\"\n";

    return 1;
}

###
# copy a file to $_self->{hostname}.
#
# $_source - source file to be copied
# $_target - destination $_source should be copied to
# <- the return code
sub copy {

    my $_self   = shift;
    my $_source = shift;
    my $_target = shift;

    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;error;\"not implemented\"\n";

    return 1;
}

###
# execute the command locally and set environment variable TARGET_HOST
# to $_self->{hostname}.
#
# $_command - the command that should be executed
# $_args    - arguments that should be supplied to $_command
# <- the return code
sub execute {

    my $_self    = shift;
    my $_command = shift;
    my $_args    = shift;

    my $cmdline = $_self->{local_exec};

    $cmdline =~ s/COMMAND/$_command/g;
    $cmdline =~ s/ARGUMENTS/$_args/g;
    $cmdline =~ s/HOSTNAME/$_self->{hostname}/g;

    return $_self->do($cmdline);
}

###
# delete a file on $_self->{hostname}.
#
# $_file - the file that should be deleted
# <- the return code
sub delete {

    my $_self = shift;
    my $_file = shift;

    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;error;\"not implemented\"\n";

    return 1;
}

1;
