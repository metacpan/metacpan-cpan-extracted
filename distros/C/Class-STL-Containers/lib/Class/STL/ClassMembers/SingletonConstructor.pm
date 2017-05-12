# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::ClassMembers::SingletonConstructor.pm
#  Created	: 9 May 2006
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
$VERSION = '0.27';
$BUILD = 'Tuesday May 16 23:08:34 GMT 2006';
use Class::STL::ClassMembers::DataMember;
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::ClassMembers::SingletonConstructor;
	use Class::STL::ClassMembers qw( _caller _trace ),
		Class::STL::ClassMembers::DataMember->new(name => 'debug_on', default => 0),
		Class::STL::ClassMembers::DataMember->new(name => 'ctor_name', default => 'new');
	use Carp qw(confess);
	use Class::STL::Trace;
	sub import
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {};
		bless($self, $class);
		$self->members_init(@_, _caller => (caller())[0]);
		$self->_trace(Class::STL::Trace->new());
		$self->_trace()->debug_on($self->debug_on()) if ($self->debug_on());
		eval($self->code());
		confess "**Error in eval for @{[ $self->_caller() ]} FunctionMember singleton constructor function creation:\n$@" if ($@);
		return $self;
	}
	sub code
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code;
		my $c = $self->_caller();

		# Extract named parameter/value pairs and pass on...
		my @p;
		while (@_) { my $p=shift; push(@p, $p, shift) if (!ref($p) && @_); }
		my %p = @p;

		my $sname = '__' . lc($c);
		$sname =~ s/:+/_/g;

		$code = "{\npackage $c;\n";
		$code .= "sub _@{[ $self->ctor_name() ]}\n";
		$code .= "{\n";
		$code .= "${tab}our \$$sname;\n";
		$code .= "${tab}return \$$sname if (defined(\$$sname));\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}my \$proto = shift;\n";
		$code .= "${tab}my \$class = ref(\$proto) || \$proto;\n";
		$code .= "${tab}\$$sname = int(\@ISA) ? \$class->SUPER::_@{[ $self->ctor_name() ]}(\@_) : {};\n";
		$code .= "${tab}bless(\$$sname, \$class);\n";
		$code .= "${tab}\$$sname->members_init(@{[ @p ? join(', ', '@_', map(qq/'$_'/, %p)) : '@_' ]});\n";
		$code .= "${tab}return \$$sname;\n";
		$code .= "}\n";
		$code .= "}\n";

		$code .= "{\npackage $c;\n";
		$code .= "sub @{[ $self->ctor_name() ]}\n";
		$code .= "{\n";
		$code .= "${tab}our \$$sname;\n";
		$code .= "${tab}return \$$sname if (defined(\$$sname));\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}my \$proto = shift;\n";
		$code .= "${tab}my \$class = ref(\$proto) || \$proto;\n";
		$code .= "${tab}\$$sname = int(\@ISA) ? \$class->SUPER::@{[ $self->ctor_name() ]}(\@_) : {};\n";
		$code .= "${tab}bless(\$$sname, \$class);\n";
		$code .= "${tab}\$$sname->members_init(@{[ @p ? join(', ', '@_', map(qq/'$_'/, %p)) : '@_' ]});\n";
		$code .= "${tab}$c\::new_extra(\$$sname, @{[ @p ? join(', ', '@_', map(qq/'$_'/, %p)) : '@_' ]})\n";
	   	$code .= "${tab}${tab}if (defined(&$c\::new_extra));\n";
		$code .= "${tab}return \$$sname;\n";
		$code .= "}\n";
		$code .= "}\n";
		$self->_trace()->print($c, $code) if ($self->_trace()->debug_on());
		return $code;
	}
}
# ----------------------------------------------------------------------------------------------------
1;
