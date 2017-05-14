#!/usr/bin/perl
#
# Annelidous - the flexibile cloud management framework
# Copyright (C) 2009  Eric Windisch <eric@grokthis.net>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

#
# TODO: Finish Connector::Vertebra::Xen
# STUB: This file is only a stub! Untested, unworking!
#
package Annelidous::Connector::Vertebra::Xen;
use base 'Annelidous::Connector';

sub new {
	my $self={
	    transport=>'Annelidous::Transport::Vertebra',
	    account=>undef,
	    @_
	};
	bless $self, shift;
	
	# Initialize a new transport.
	$self->{_transport}=exec "new $self->{transport} (".'$self->{account})};';
	return $self;
}

# Launch client guest OS...
# takes a client_pool as argument 
sub boot {
    my $self=shift;
    $self->transport->exec('/slice/create',{slice=>$self->{account}->{username}});
}

sub shutdown {
    my $self=shift;
    $self->transport->exec('/slice/shutdown',{slice=>$self->{account}->{username}});
}

# Not implemented in vertebra-xen.
sub console {
    my $self=shift;
    my $cap=new Annelidous::Capabilities;
    $cap->add("noop");
    return {capabilities=>$cap};
}

1;