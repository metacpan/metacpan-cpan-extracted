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
# TODO: Finish Transport::EC2
# STUB: This file is only a stub!
#
package Annelidous::Transport::Vertebra;
use base ('Annelidous::Transport','Net::Amazon::EC2');

use Net::Amazon::EC2;

#
# We're actually subclassing Net::Amazon::EC2
# so there isn't a whole lot this module has to do directly (yet)
#
sub new {
	my $self={
	    account=>undef,
	    @_
	};
	bless $self, shift;
	return $self;
}

1;