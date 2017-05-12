# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::Trace.pm
#  Created	: 12 May 2006
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
package Class::STL::Trace;
require 5.005_62;
use strict;
use warnings;
use vars qw($VERSION $BUILD);
$VERSION = '0.24';
$BUILD = 'Saturday May 6 23:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Trace; # Singleton
	use UNIVERSAL qw(isa can);
	use Carp qw(confess);
	sub new {
		our $__class_stl_trace;
		return $__class_stl_trace if (defined($__class_stl_trace));
		use vars qw(@ISA);
		my $proto = shift;
		my $class = ref($proto) || $proto;
		$__class_stl_trace = int(@ISA) ? $class->SUPER::new(@_) : {};
		bless($__class_stl_trace, $class);
		$__class_stl_trace->members_init(@_);
		return $__class_stl_trace;
	}
	sub filename {
		my $self = shift;
		$self->{Class_STL_Trace}->{FILENAME} = shift if (@_);
		return $self->{Class_STL_Trace}->{FILENAME};
	}
	sub trace_level {
		my $self = shift;
		$self->{Class_STL_Trace}->{TRACE_LEVEL} = shift if (@_);
		return $self->{Class_STL_Trace}->{TRACE_LEVEL};
	}
	sub debug_on {
		my $self = shift;
		$self->{Class_STL_Trace}->{DEBUG_ON} = shift if (@_);
		return $self->{Class_STL_Trace}->{DEBUG_ON};
	}
	sub print {
		my $self = shift;
		my $caller = shift || '';
		open(DEBUG, ">>@{[ $self->filename() ]}");
		print DEBUG "# $caller\n"; # !!! need to get this as arg to print !!!
		print DEBUG @_, "\n";
		close(DEBUG);
	}
	sub members_init {
		my $self = shift;
		use vars qw(@ISA);
		if (int(@ISA) && (caller())[0] ne __PACKAGE__) {
			$self->SUPER::members_init(@_);
		}
		my @p;
		while (@_) { my $p=shift; push(@p, $p, shift) if (!ref($p)); }
		my %p = @p;
		$self->filename(exists($p{'filename'}) ? $p{'filename'} : "class_stl_dump$$");
		$self->trace_level(exists($p{'trace_level'}) ? $p{'trace_level'} : '0');
		$self->debug_on(exists($p{'debug_on'}) ? $p{'debug_on'} : '0');
	}
	sub member_print {
		my $self = shift;
		my $delim = shift || '|';
		return join("$delim",
			"debug_on=@{[ defined($self->debug_on()) ? $self->debug_on() : 'NULL' ]}",
			"filename=@{[ defined($self->filename()) ? $self->filename() : 'NULL' ]}",
			"trace_level=@{[ defined($self->trace_level()) ? $self->trace_level() : 'NULL' ]}",
		);
	}
	sub members_local { # static function
		return {
			debug_on=>[ '0', '' ],
			filename=>[ "class_stl_dump$$", '' ],
			trace_level=>[ '0', '' ],
		};
	}
	sub members {
		my $self = shift;
		use vars qw(@ISA);
		my $super = (int(@ISA)) ? $self->SUPER::members() : {};
		return keys(%$super)
		? {
			%$super,
			debug_on=>[ '0', '' ],
			filename=>[ "class_stl_dump$$", '' ],
			trace_level=>[ '0', '' ]
		}
		: {
			debug_on=>[ '0', '' ],
			filename=>[ "class_stl_dump$$", '' ],
			trace_level=>[ '0', '' ]
		};
	}
	sub swap {
		my $self = shift;
		my $other = shift;
		use vars qw(@ISA);
		my $tmp = $self->clone();
		$self->SUPER::swap($other) if (int(@ISA));
		$self->filename($other->filename());
		$self->trace_level($other->trace_level());
		$self->debug_on($other->debug_on());
		$other->filename($tmp->filename());
		$other->trace_level($tmp->trace_level());
		$other->debug_on($tmp->debug_on());
	}
	sub clone {
		my $self = shift;
		use vars qw(@ISA);
		my $clone = int(@ISA) ? $self->SUPER::clone() : $self->new();
		$clone->filename($self->filename());
		$clone->trace_level($self->trace_level());
		$clone->debug_on($self->debug_on());
		return $clone;
	}
}
1;
