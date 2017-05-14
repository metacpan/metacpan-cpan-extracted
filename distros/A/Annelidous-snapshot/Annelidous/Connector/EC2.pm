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
# TODO: Finish Connector::EC2
# STUB: This file is only a stub! Untested, unworking!
#
package Annelidous::Connector::EC2;
use base 'Annelidous::Connector';

sub new {
	my $self={
	    transport=>'Annelidous::Transport::EC2',
	    ec2_settings=>{
            AWSAccessKeyId => 'PUBLIC_KEY_HERE', 
            SecretAccessKey => 'SECRET_KEY_HERE'
	    },
	    account=>undef,
	    @_
	};
	bless $self, shift;
	
	# Initialize a new transport.
	$self->{_transport}=exec "new $self->{transport} (account=>".'$self->{account}, %{$self->{ec2_settings}})};';
	return $self;
}

# Launch client guest OS...
# takes a client_pool as argument 
sub boot {
    my $self=shift;
    $self->transport->run_instances(ImageId => $self->{account}->{username}, MinCount => 1, MaxCount => 1);
}

sub shutdown {
    my $self=shift;
    return $self->transport->terminate_instances(InstanceId => $self->instance->{id});
}

# Not likely to work quite yet, but our EC2 module has the best
# attempt at an implementation for this yet.
sub console {
    my $self=shift;
    my $tty=$self->get_console_output(InstanceId => $self->instance->{id});
    my $cap=new Annelidous::Capabilities;
    $cap->add("tty");
    return {tty=>$tty, capabilities=>$cap};
}
 
1;