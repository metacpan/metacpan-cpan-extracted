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
# Program: Worker.pm
# Author:  Timo Benk <benk@b1-systems.de>
# Date:    Wed Jul 17 19:44:13 2013 +0200
# Ident:   e81f2ed28d3a5b52045231c0700113b9349472fe
# Branch:  HEAD, v1.1.2, origin/master, origin/HEAD, master
#
# Changelog:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s
# 
# Timo Benk : 2013-04-28 17:27:31 +0200 : initial checkin
# Timo Benk : 2013-04-29 18:53:21 +0200 : introducing ncopy
# Timo Benk : 2013-05-03 13:52:25 +0200 : no output was returned on timeout
# Timo Benk : 2013-05-03 19:16:11 +0200 : no output was returned on SIGINT
# Timo Benk : 2013-05-08 10:05:39 +0200 : better signal handling implemented
# Timo Benk : 2013-05-08 13:46:36 +0200 : skip empty output when signaled USR1/USR2
# Timo Benk : 2013-05-09 07:31:52 +0200 : fix race condition in semaphore cleanup code
# Timo Benk : 2013-05-21 18:47:43 +0200 : parameter --async added
# Timo Benk : 2013-05-22 13:09:13 +0200 : option --no-logfile was broken
# Timo Benk : 2013-05-22 13:20:36 +0200 : --skip-ping-check and --skip-ns-check enabled
# Timo Benk : 2013-05-24 08:03:19 +0200 : generic mode added
# Timo Benk : 2013-06-13 13:59:01 +0200 : process output handling refined
# Timo Benk : 2013-06-14 12:38:19 +0200 : open3 will never return undef
# Timo Benk : 2013-06-20 19:33:33 +0200 : raise condition in signal handling code fixed
# Timo Benk : 2013-07-11 14:02:09 +0200 : better cleanup handling in signal handlers
#

###
# this is the base module for all worker implementations and
# it is responsible for loading the available implementations
# at runtime.
#
# a worker implements a a single remote access mechanism like ssh
# which will be used to execute commands on the remote host,
# delete files on the remote host and to copy files to the remote host.
#
# derived modules must implement the following subs's
#
# - init($cfg)
# - execute($cmd, $args)
# - delete($file)
# - copy($source, $target)
# - rcopy($source, $target)
#
# a derived module must call register() in BEGIN{}, otherwise it will not
# be available.
#
# a derived module must always write to $_self->{E} (STDERR) and
# $_self->{O} (STDOUT).
#
# all output produced by the derived worker modules must match the
# following format:
#
# HOSTNAME;[stdout|stderr];TSTAMP;PID;PID(CHILD);[debug|error|exit|output|end];"OUTPUT"
#
# this is the string which will be passed to the logger/filter implementations.
###

package NRun::Worker;

use strict;
use warnings;

use File::Basename;
use IPC::Open3;

###
# automagically load all available modules
INIT {

    my $basedir = dirname($INC{"NRun/Worker.pm"}) . "/Workers";

    opendir(DIR, $basedir) or die("$basedir: $!");
    while (my $module = readdir(DIR)) {

        if ($module =~ /\.pm$/i) {

            require "$basedir/$module";
        }
    }
    close DIR;
}

###
# all available workers will be registered here
my $workers = {};

###
# will be called by the worker modules on INIT.
#
# $_cfg - parameter hash where
# {
#   'MODE' - mode name
#   'DESC' - mode description
#   'NAME' - module name
# }
sub register {

    my $_cfg = shift;

    $workers->{$_cfg->{MODE}} = $_cfg;
}

###
# return all available worker modules
sub workers {

    return $workers;
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
#   'hostname' - hostname this worker should act on
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->{hostname} = $_cfg->{hostname};

    $_self->{pid} = "n/a";

    $_self->{handler_alrm} = NRun::Signal::register('ALRM', \&handler_alrm, [ \$_self ], $$);
    $_self->{handler_int}  = NRun::Signal::register('INT',  \&handler_int,  [ \$_self ], $$);
    $_self->{handler_term} = NRun::Signal::register('TERM', \&handler_term, [ \$_self ], $$);

    $_self->{O} = \*STDOUT;
    $_self->{E} = \*STDERR;
}

###
# kill the currently running command
sub kill {

    my $_self = shift;

    if ($_self->{pid} ne "n/a") {

        kill(KILL => $_self->{pid});
    }
}

###
# SIGTERM signal handler.
sub handler_term {

    my $_self = shift;

    $$_self->kill();

    print {$$_self->{O}} "$$_self->{hostname};stdout;" . time() . ";$$;$$_self->{pid};exit;\"exit code $NRun::Constants::CODE_SIGTERM;\"\n";
    print {$$_self->{E}} "$$_self->{hostname};stderr;" . time() . ";$$;$$_self->{pid};error;\"SIGTERM received\"\n";
}

###
# SIGINT signal handler.
sub handler_int {

    my $_self = shift;

    $$_self->kill();

    print {$$_self->{O}} "$$_self->{hostname};stdout;" . time() . ";$$;$$_self->{pid};exit;\"exit code $NRun::Constants::CODE_SIGINT;\"\n";
    print {$$_self->{E}} "$$_self->{hostname};stderr;" . time() . ";$$;$$_self->{pid};error;\"SIGINT received\"\n";
}


###
# SIGALRM signal handler.
sub handler_alrm {

    my $_self = shift;

    $$_self->kill();

    print {$$_self->{O}} "$$_self->{hostname};stdout;" . time() . ";$$;$$_self->{pid};exit;\"exit code $NRun::Constants::CODE_SIGALRM;\"\n";
    print {$$_self->{E}} "$$_self->{hostname};stderr;" . time() . ";$$;$$_self->{pid};error;\"SIGALRM received\"\n";
}

###
# execute $_cmd.
#
# command output will be formatted the following way, line by line:
#
# HOSTNAME;[stdout|stderr];TSTAMP;PID;PID(CHILD);[debug|error|exit|output|end];"OUTPUT"
#
# $_cmd - the command to be executed
# <- the return code 
sub do {

    my $_self = shift;
    my $_cmd  = shift;

    chomp($_cmd);

    eval{

        $_self->{pid} = open3(\*CMDIN, \*CMDOUT, \*CMDERR, "$_cmd");
    };
    if ($@) {

        print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;debug;\"exec $_cmd\"\n";
        print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;error;\"$@\"\n";
        print {$_self->{O}} "$_self->{hostname};stdout;" . time() . ";$$;n/a;exit;\"exit code $NRun::Constants::EXECUTION_FAILED\"\n";

        return $NRun::Constants::EXECUTION_FAILED;
    }
    
    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;$_self->{pid};debug;\"exec $_cmd\"\n";

    my $selector = IO::Select->new();
    $selector->add(\*CMDOUT, \*CMDERR);

    while (my @ready = $selector->can_read()) {

        foreach my $fh (@ready) {

            if (fileno($fh) == fileno(CMDOUT)) {

                while (my $line = <$fh>) {

                    chomp($line);
                    print {$_self->{O}} "$_self->{hostname};stdout;" . time() . ";$$;$_self->{pid};output;\"$line\"\n";
                }
            } elsif (fileno($fh) == fileno(CMDERR)) {

                while (my $line = <$fh>) {

                    chomp($line);
                    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;$_self->{pid};output;\"$line\"\n";
                }
            }

            $selector->remove($fh) if eof($fh);
        }
    }
    close(CMDIN);
    close(CMDOUT);
    close(CMDERR);

    waitpid($_self->{pid}, 0);

    print {$_self->{O}} "$_self->{hostname};stdout;" . time() . ";$$;$_self->{pid};exit;\"exit code " . ($? >> 8) . "\"\n";

    $_self->{pid} = "n/a";

    return ($? >> 8);
}

###
# send a message to stdout indicating that no more executions
# will be done by this worker.
#
# in fact, execution is still possible, but all output to stdout/stderrr
# will be suppressed.
#
# HOSTNAME;stdout;TSTAMP;PID;n/a;end;
# HOSTNAME;stderr;TSTAMP;PID;n/a;end;
sub end {

    my $_self   = shift;

    print {$_self->{O}} "$_self->{hostname};stdout;" . time() . ";$$;n/a;end;\n";
    print {$_self->{E}} "$_self->{hostname};stderr;" . time() . ";$$;n/a;end;\n";

    NRun::Signal::deregister('ALRM', $_self->{handler_alrm});
    NRun::Signal::deregister('INT',  $_self->{handler_int});
    NRun::Signal::deregister('TERM', $_self->{handler_term});
    
    open(NULL, ">/dev/null");

    $_self->{O} = \*NULL;
    $_self->{E} = \*NULL;
}

1;
