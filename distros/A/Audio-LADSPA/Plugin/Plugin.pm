# Audio::LADSPA perl modules for interfacing with LADSPA plugins
# Copyright (C) 2003  Joost Diepenmaat.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# See the COPYING file for more information.

package Audio::LADSPA::Plugin;
use strict;
our $VERSION = "0.021";
use Carp;
use constant ABOVE_ZERO => 0.00000000000000000000000000000000000000000000000000000001;
use Data::Uniqid qw();

sub ports {
    my $self = shift;
    return map $self->port_name($_), 0 .. $self->port_count - 1;
}

sub disconnect_all {
    my ($self) = @_;
    for ($self->ports) {
        $self->disconnect($_);
    }
}

sub set {
    my $self = shift;
    my $port_id = shift;
    ref($self) or croak "Audio::LADSPA::Buffer->set() is an object method!";
    my $buffer = $self->get_buffer($port_id) or croak "No buffer for port $port_id";
    $buffer->set(@_);
}

sub get {
    my $self = shift;
    my $port_id = shift;
    ref($self) or croak "Audio::LADSPA::Buffer->get() is an object method!";
    my $buffer = $self->get_buffer($port_id) or croak "No buffer for port $port_id";
    return $buffer->get();
}


sub default_value {
    my ($self,$port) = @_;
    my $lower = $self->lower_bound($port);
    defined($lower) or $lower = -1;
    my $upper = $self->upper_bound($port);
    defined($upper) or $upper = 1;
    if ($lower > $upper) {
	croak "Plugin has only defined upper_bound or lower_bound and it's out of range (-1,1)";
    }
    my $log = $self->is_logarithmic($port);
    my $sr = $self->is_sample_rate($port);
    for ($self->default($port)) {
	local $_ = $_;
	$_ = 'middle' unless defined $_;
	if ($_ eq 'minimum') {
	    return $lower;
	}
	if ($_ eq 'low') {
	    return exp(log($lower || ABOVE_ZERO) * 0.75 + log($upper || ABOVE_ZERO) * 0.25) if $log;
	    return ($lower * 0.75 + $upper * 0.25); 
	}
	if ($_ eq 'middle') {
	    return exp(log($lower || ABOVE_ZERO) * 0.5 + log($upper || ABOVE_ZERO) * 0.5) if $log;
	    return ($lower * 0.5 + $upper * 0.5); 
	}
	if ($_ eq 'high') {
	    return exp(log($lower || ABOVE_ZERO) * 0.25 + log($upper || ABOVE_ZERO) * 0.75) if $log;
	    return ($lower * 0.25 + $upper * 0.75); 
	}
	if ($_ eq 'maximum') {
	    return $upper;
	}
	if ($_ eq '0') {
	    return 0;
	}
	if ($_ eq '1') {
	    return 1;
	}
	if ($_ eq '100') {
	    return 100;
	}
	if ($_ eq '440') {
	    return 440;
	}
    }
    die "Logic error: port = '$port', default ='".$self->default($port)."', lower='".$self->lower_bound($port)."', upper='".$self->upper_bound($port)."'";
}

sub connect {
    my ($self,$port,$buffer) = @_;
    if ($self->callback('cb_connect',$self, $port, $buffer )) {
	if (defined ($self->get_buffer($port))) {
	    $self->disconnect($port);
	}
	$self->_unregistered_connect($port,$buffer);
	return 1;
    }
    return 0;
}

sub disconnect {
    my ($self,$port) = @_;
    $self->callback( 'cb_disconnect', $self, $port );
    $self->_unregistered_disconnect( $port);
}

sub callback {
    my ($self, $method, @args) = @_;
    if (my $monitor = $self->monitor) {
        if (my $mref = $monitor->can($method)) {
	   return $monitor->$mref(@args);
	}
    }
    return 1;
}

sub generate_uniqid {
    my ($self) = shift;
    return Data::Uniqid::luniqid;
}


1;

