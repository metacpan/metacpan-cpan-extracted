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
# Program: Queue.pm
# Author:  Timo Benk <benk@b1-systems.de>
# Date:    Wed Jul 17 19:44:13 2013 +0200
# Ident:   e81f2ed28d3a5b52045231c0700113b9349472fe
# Branch:  master
#
# Changelog:--reverse --grep '^tags.*relevant':-1:%an : %ai : %s
# 
# Timo Benk : 2013-07-12 15:13:08 +0200 : queue targets instead of splitting them
#

###
# this module implements a simple queueing process. each time next()
# is called, the next object waiting in the queue will be returned.
###

package NRun::Queue;

use strict;
use warnings;

use IO::Select;
use IO::Handle;
use Socket;

###
# create a new object.
sub new {

    my $_pkg = shift;

    my $self = {};
    bless $self, $_pkg;

    return $self;
}

###
# initialize this queue.
#
# $_cfg - parameter hash where
# {
#   'objects' - array reference of objects names
# }
sub init {

    my $_self = shift;
    my $_cfg  = shift;

    $_self->{objects} = $_cfg->{objects};

    $_self->{pipes} = [];
}

###
# connect the currently running process to this queue.
#
# - must be called once before each fork() 
# - must be called before start() and next()
# - must be called in the parent's context
sub connect() {

    my $_self = shift;

    my ( $child, $parent );

    socketpair($child, $parent, AF_UNIX, SOCK_STREAM, PF_UNSPEC) or die "socketpair: $!";

    $child->autoflush(1);
    $parent->autoflush(1);

    push(@{$_self->{pipes}}, $parent);

    $_self->{CHILD} = $child;
}

###
# start the queue.
#
# - must be called in the parent's context
# - must be called before next()
sub start {

    my $_self = shift;

    my $pid = fork();
    if (not defined $pid) {

        die("error: unable to fork");
    } elsif ($pid == 0) {

        close($_self->{CHILD});
        
        my $selector = IO::Select->new();
        $selector->add(@{$_self->{pipes}});
               
        while (scalar(@{$_self->{objects}}) and $selector->can_read()) {
            
            foreach my $fh ($selector->can_read()) {

                if (my $line = <$fh>) {

                    print {$fh} pop(@{$_self->{objects}}) . "\n";
                } else {

                    $selector->remove($fh);
                    close($fh);
                }

                last if (not scalar(@{$_self->{objects}}));
            }
        }

        exit(0);
    } else {

       close($_self->{CHILD});

       while (my $parent = pop (@{$_self->{pipes}})) {

           close($parent);
       }
    }
}

###
# return the next object in the queue
#
# - must be called in the childs context
sub next {

    my $_self = shift;

    while (my $parent = pop(@{$_self->{pipes}})) {

        close($parent);
    }

    print {$_self->{CHILD}} "next [$$]\n";

    my $object = readline($_self->{CHILD});

    chomp($object) if (defined($object));

    return $object;
}

1;
