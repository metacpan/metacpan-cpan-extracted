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



package Audio::LADSPA::Buffer;
use strict;
use base qw(DynaLoader);
our $VERSION = "0.021";
use Carp qw(croak);

sub get_words {
    my ($self,$amp) = @_;
    
    if ($self->filled) {
	unless ($amp) {
  	    return pack("v*",unpack("f*",$self->get_raw()));
	}
	else {
	    return pack("v*",map { $_ * $amp } unpack("f*",$self->get_raw()));
	}
    }
    return undef;
}

sub set_words {
    my ($self,$string,$amp) = @_;
    unless ($amp) {
       $self->set_raw(pack("f*",unpack("v*",$string)));
    }
    else {
       $self->set_raw(pack("f*",map { $_ * $amp } unpack("v*",$string)));
    }
    return undef;
}

sub set_list {
    my $self = shift;
    $self->set_raw(pack("f*",@_));
}

sub get_list {
    my ($self) = @_;
    if ($self->filled) {
	return unpack("f*",$self->get_raw);
    }
    return;
}

sub set {
    my $self = shift;
    if (@_ > 1) {
	$self->set_list(@_);
	return;
    }
    $self->set_1($_[0]);
}

sub get {
    my ($self) = @_;
    if (wantarray) {
	return $self->get_list();
    }
    else {
	return $self->get_1();
    }
}

__PACKAGE__->bootstrap($VERSION);

use overload 
    fallback => 1,
    '*=' => \&is_mult,
    '/=' => \&is_div,
    '*' => \&mult,
    '/' => \&divide;




1;

__END__

