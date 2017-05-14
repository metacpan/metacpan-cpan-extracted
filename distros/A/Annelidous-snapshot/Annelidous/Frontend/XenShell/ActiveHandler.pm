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

package Annelidous::Frontend::XenShell::ActiveHandler;
use Data::Dumper;

sub TIESCALAR {
	my $invocant=shift;
    my $self={};
    bless $self, $invocant;
    $self->{_frontend_obj}=shift;
    return $self;
}

sub STORE {
    my $self=shift;
    my $id=shift;

    $self->{vm}=$self->{_frontend_obj}->new_vm(    
		$id
        #$self->{_frontend_obj}->search->by_id($id)
    );
	#print $self->{_frontend_obj}->search->by_id($id);
	#print Dumper $self->{vm};
    $self->{connector}=$self->{_frontend_obj}->new_connector(
        $self->{vm}
    );
    return $self->{vm}->id;
}

sub FETCH {
    my $self=shift;
    return $self->{vm}->id;
}

sub vm {
    my $self=shift;
    return $self->{vm};
}

sub connector {
    my $self=shift;
    return $self->{connector};
}


1;
