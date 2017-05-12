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
# Program: Signal.pm
# Author:  Timo Benk <benk@b1-systems.de>
# Date:    Wed Jul 17 19:44:13 2013 +0200
# Ident:   e81f2ed28d3a5b52045231c0700113b9349472fe
# Branch:  master
#
# Changelog:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s
# 
# Timo Benk : 2013-05-21 18:47:43 +0200 : parameter --async added
# Timo Benk : 2013-06-13 13:59:01 +0200 : process output handling refined
# Timo Benk : 2013-07-08 14:16:38 +0200 : callback() was continued on SIGALRM
#

###
# this module is responsible for signal handling.
#
# multiple signal handlers for the same signal may be registered which will be 
# called sequential in the opposite order the handlers were registered.
###

package NRun::Signal;

###
# all handlers will be registered here
my $HANDLERS = {};
my $LOCK = 0;

###
# local signal handler.
#
# calls all registered handlers in $HANDLERS.
#
# $_signal - the signal that triggered this call
sub _handler {

    my $_signal = shift;

    return if ($LOCK == 1);

    $LOCK = 1;
    eval {

        foreach my $handler (reverse(@{$HANDLERS->{$_signal}})) {

            my $sub = $handler->{callback};
            my $arg = $handler->{arguments};
            my $pid = $handler->{pid};

            if (not defined($pid) or $pid == $$ ) {

                $sub->(@$arg);
            }
        }
     };
     if ($@) {

         $LOCK = 0;
         die ($@);
     }
     $LOCK = 0;
}

###
# register a signal handler.
#
# $_signal    - signal to be registered
# $_callback  - callback function to be registered (function ref)
# $_arguments - argument list handed over to the callback function (array ref)
# $_pid       - pid for which this handler is valid (or undef)
# <- the handler refernce to be used in deregister()
sub register {

    my $_signal    = shift;
    my $_callback  = shift;
    my $_arguments = shift;
    my $_pid       = shift;

    my $handler = {

        callback  => $_callback,
	pid       => $_pid,
        arguments => $_arguments,
    };

    push(@{$HANDLERS->{$_signal}}, $handler);

    $SIG{$_signal} = \&_handler;

    return $handler;
}

###
# deregister a signal handler.
#
# $_signal  - signal to be registered
# $_handler - argument list handed over to the callback function (array ref)
sub deregister {

    my $_signal  = shift;
    my $_handler = shift;

    my $handlers = $HANDLERS->{$_signal};

    my %index;
    @index{@$handlers} = (0..scalar(@$handlers));
    my $index = $index{$_handler};

    if (defined($index)) {

        splice(@$handlers, $index, 1);

        if (scalar(@$handlers) == 0) {

            $SIG{$_signal} = 'DEFAULT';
        }
    }
}

1;
