# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::ClassMembers::FunctionMember.pm
#  Created	: 27 April 2006
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
$VERSION = '0.18';
$BUILD = 'Thursday April 27 23:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::ClassMembers::FunctionMember::Abstract;
	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {};
		bless($self, $class);
		return $self;
	}
	sub code
	{
		# must override
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::ClassMembers::FunctionMember::New;
	use base qw(Class::STL::ClassMembers::FunctionMember::Abstract);
	sub code
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code = "sub new\n";
		$code .= "{\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}my \$proto = shift;\n";
		$code .= "${tab}my \$class = ref(\$proto) || \$proto;\n";
		$code .= "${tab}my \$self = int(\@ISA) ? \$class->SUPER::new(\@_) : {};\n";
		$code .= "${tab}bless(\$self, \$class);\n";
		$code .= "${tab}\$self->members_init(\@_);\n";
		$code .= "${tab}\$self->new_extra(\@_) if (\$self->can('new_extra'));\n";
		$code .= "${tab}return \$self;\n";
		$code .= "}\n";
		return $code;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::ClassMembers::FunctionMember::Disable;
	use base qw(Class::STL::ClassMembers::FunctionMember::Abstract);
	use Class::STL::ClassMembers qw( function_name );
	use Carp qw(confess);
	sub new
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {};
		bless($self, $class);
		$self->members_init(function_name => shift);
		return $self;
	}
	sub code
	{
		my $self = shift;
		my $caller = shift;
		my $tab = ' ' x 4;
		my $code;
		$code .= "sub @{[ $self->function_name() ]} {\n";
		$code .= "${tab}use Carp qw(confess);\n";
		$code .= "${tab}confess \"Function '@{[ $self->function_name() ]}' not available for $caller!\";\n";
		$code .= "}\n";
		return $code;
	}
}
# ----------------------------------------------------------------------------------------------------
1;
