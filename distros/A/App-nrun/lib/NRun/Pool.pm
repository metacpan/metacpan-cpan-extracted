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
# Program: Pool.pm
# Author:  Timo Benk <benk@b1-systems.de>
# Date:    Wed Jul 17 19:44:13 2013 +0200
# Ident:   e81f2ed28d3a5b52045231c0700113b9349472fe
# Branch:  master
#
# Changelog:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s
# 
# Timo Benk : 2013-06-13 13:59:01 +0200 : process output handling refined
# Timo Benk : 2013-06-14 18:05:08 +0200 : deliver sig[int|term] to all pool processes
# Timo Benk : 2013-07-08 14:16:38 +0200 : callback() was continued on SIGALRM
# Timo Benk : 2013-07-11 14:02:09 +0200 : better cleanup handling in signal handlers
# Timo Benk : 2013-07-12 15:13:08 +0200 : queue targets instead of splitting them
#

###
# this module is responsible for the creation of the process pool.
#
# each dispatched process will be connected to the sink object which
# is responsible for passing the output from the worker modules to the
# filter/logger modules.
##

package NRun::Pool;

use strict;
use warnings;

###
# create a new pool object.
#
# $_obj - parameter hash where
# {
#   'timeout'  => timeout in seconds
#   'queue'    => the queue object
#   'nmax'     => maximum number of parallel login processes
#   'callback' => callback function to be executed in parallel
#                 signature: sub callback ($object)
#   'sink'     => the sink object
# }
# <- the new object
sub new {

    my $_pkg = shift;
    my $_obj = shift;

    my $self = {};
    bless $self, $_pkg;

    $self->{timeout} = $_obj->{timeout};
    $self->{nmax}    = $_obj->{nmax};
    $self->{queue}   = $_obj->{queue};
    $self->{sink}    = $_obj->{sink};

    $self->{callback} = $_obj->{callback};

    $self->init();

    return $self;
}

###
# deliver signal to all child processes
sub handler_int {

    my $_pids = shift;

    kill(INT => @$_pids);
}

###
# deliver signal to all child processes
sub handler_term {

    my $_pids = shift;

    kill(TERM => @$_pids);
}

###
# break out of callback()
sub handler_alrm {

    die("alarm\n");
}

###
# dispatch the worker processes.
sub init {

    my $_self = shift;

    my @pids;

    my $handler_int  = NRun::Signal::register('INT',  \&handler_int,  [ \@pids ], $$);
    my $handler_term = NRun::Signal::register('TERM', \&handler_term, [ \@pids ], $$);
    
    foreach my $process (1..$_self->{nmax}) {

        $_self->{sink}->connect();
        $_self->{queue}->connect();

        push(@pids, $_self->dispatch());
    }

    $_self->{queue}->start();
}

###
# dispatch a single worker process
sub dispatch {

    my $_self = shift;

    my $pid = fork();
    if (not defined $pid) {

        die("error: unable to fork");
    } elsif ($pid == 0) {

        $_self->work();

        exit(0);
    }

    return $pid;
}

###
# do the actual work
sub work {

    my $_self = shift;

    my $handler_alrm = NRun::Signal::register('ALRM', \&handler_alrm, [ ], $$);

    $_self->{sink}->open();
    while (my $object = $_self->{queue}->next()) {

        eval {

            alarm($_self->{timeout});
            $_self->{callback}->($object);
            alarm(0);
        };
        if ($@) {

            die($@) unless ($@ eq "alarm\n");
        }
    };
    $_self->{sink}->close();
}

1;
