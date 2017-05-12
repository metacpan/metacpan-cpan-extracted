# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::ClassMembers::Disable.pm
#  Created	: 8 May 2006
#  Author	: Mario Gaffiero (gaffie)
#
# Copyright 2006-2007 Mario Gaffiero.
# 
# This file is part of Class::STL::Containers(TM).
# 
# Class::STL::Containers is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
# 
# Class::STL::Containers is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Class::STL::Containers; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# ----------------------------------------------------------------------------------------------------
# Modification History
# When          Version     Who     What
# ----------------------------------------------------------------------------------------------------
# TO DO:
# ----------------------------------------------------------------------------------------------------
require 5.005_62;
use strict;
use warnings;
use vars qw($VERSION $BUILD);
$VERSION = '0.21';
$BUILD = 'Monday May 8 23:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::ClassMembers::Disable;
	use Class::STL::ClassMembers qw( function_name _caller );
	use Carp qw(confess);
	sub import
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {};
		bless($self, $class);
		$self->_caller((caller())[0]);
		$self->function_name(shift);
		eval($self->code());
		confess "**Error in eval for @{[ $self->_caller() ]} FunctionMemeber disable function creation:\n$@" if ($@);
		return $self;
	}
	sub code
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code;
		$code = "{\npackage @{[ $self->_caller() ]};\n";
		$code .= "sub @{[ $self->function_name() ]} {\n";
		$code .= "${tab}use Carp qw(confess);\n";
		$code .= "${tab}confess \"Function '@{[ $self->function_name() ]}' not available for @{[ $self->_caller() ]}!\";\n";
		$code .= "}\n";
		$code .= "}\n";
		return $code;
	}
}
# ----------------------------------------------------------------------------------------------------
1;
