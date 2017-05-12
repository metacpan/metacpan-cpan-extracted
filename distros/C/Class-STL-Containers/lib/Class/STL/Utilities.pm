# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::Utilities.pm
#  Created	: 22 February 2006
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
package Class::STL::Utilities;
require 5.005_62;
use strict;
use warnings;
use vars qw( $VERSION $BUILD @EXPORT_OK %EXPORT_TAGS );
use Exporter;
my @export_names = qw( 
	equal_to not_equal_to greater greater_equal less less_equal compare bind1st bind2nd 
	mem_fun ptr_fun ptr_fun_binary matches matches_ic logical_and logical_or 
	multiplies divides plus minus modulus not1 not2 negate not_null
);
@EXPORT_OK = (@export_names);
%EXPORT_TAGS = ( all => [@export_names] );
$VERSION = '0.18';
$BUILD = 'Thursday April 27 23:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities;
	use vars qw( $AUTOLOAD );
	sub AUTOLOAD
	{
		(my $func = $AUTOLOAD) =~ s/.*:://;
		return Class::STL::Utilities::EqualTo->new(@_) 			if ($func eq 'equal_to');
		return Class::STL::Utilities::NotEqualTo->new(@_) 		if ($func eq 'not_equal_to');
		return Class::STL::Utilities::Greater->new(@_) 			if ($func eq 'greater');
		return Class::STL::Utilities::GreaterEqual->new(@_) 	if ($func eq 'greater_equal');
		return Class::STL::Utilities::Less->new(@_) 			if ($func eq 'less');
		return Class::STL::Utilities::LessEqual->new(@_) 		if ($func eq 'less_equal');
		return Class::STL::Utilities::Compare->new(@_) 			if ($func eq 'compare');
		return Class::STL::Utilities::Matches->new(@_) 			if ($func eq 'matches');
		return Class::STL::Utilities::MatchesIC->new(@_) 		if ($func eq 'matches_ic');
		return Class::STL::Utilities::LogicalAnd->new(@_) 		if ($func eq 'logical_and');
		return Class::STL::Utilities::LogicalOr->new(@_) 		if ($func eq 'logical_or');
		return Class::STL::Utilities::Multiplies->new(@_) 		if ($func eq 'multiplies');
		return Class::STL::Utilities::Divides->new(@_) 			if ($func eq 'divides');
		return Class::STL::Utilities::Plus->new(@_) 			if ($func eq 'plus');
		return Class::STL::Utilities::Minus->new(@_) 			if ($func eq 'minus');
		return Class::STL::Utilities::Modulus->new(@_) 			if ($func eq 'modulus');
		return Class::STL::Utilities::Binder1st->new(@_) 		if ($func eq 'bind1st');
		return Class::STL::Utilities::Binder2nd->new(@_) 		if ($func eq 'bind2nd');
		return Class::STL::Utilities::MemberFunction->new(@_) 	if ($func eq 'mem_fun');
		return Class::STL::Utilities::PointerToUnaryFunction->new(@_)if ($func eq 'ptr_fun');
		return Class::STL::Utilities::PointerToBinaryFunction->new(@_)if ($func eq 'ptr_fun_binary');
		return Class::STL::Utilities::UnaryNegate->new(@_)		if ($func eq 'not1');
		return Class::STL::Utilities::BinaryNegate->new(@_)		if ($func eq 'not2');
		return Class::STL::Utilities::Negate->new(@_)			if ($func eq 'negate');
		return Class::STL::Utilities::NotNull->new(@_)			if ($func eq 'not_null');
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::FunctionObject;
	use Class::STL::ClassMembers qw(result_type);
	use Class::STL::ClassMembers::Constructor;
	sub function_operator
	{
		my $self = shift;
		use Carp qw(confess);
		confess "@{[ __PACKAGE__ ]} abstract class must be derived!\n";
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::FunctionObject::Generator;
	use base qw(Class::STL::Utilities::FunctionObject);
	sub function_operator
	{
		my $self = shift;
		use Carp qw(confess);
		confess "@{[ __PACKAGE__ ]} abstract class must be derived!\n";
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::FunctionObject::UnaryFunction;
	use base qw(Class::STL::Utilities::FunctionObject);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		use Carp qw(confess);
		confess "@{[ __PACKAGE__ ]} abstract class must be derived!\n";
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::FunctionObject::BinaryFunction;
	use base qw(Class::STL::Utilities::FunctionObject);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift;
		use Carp qw(confess);
		confess "@{[ __PACKAGE__ ]} abstract class must be derived!\n";
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::FunctionObject::UnaryPredicate;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	sub new_extra
	{
		my $self = shift;
		$self->result_type('bool');
		return $self;
	}
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		use Carp qw(confess);
		confess "@{[ __PACKAGE__ ]} abstract class must be derived!\n";
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::FunctionObject::BinaryPredicate;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
	sub new_extra
	{
		my $self = shift;
		$self->result_type('bool');
		return $self;
	}
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift;
		use Carp qw(confess);
		confess "@{[ __PACKAGE__ ]} abstract class must be derived!\n";
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::MemberFunction;
	use base qw(Class::STL::Utilities::FunctionObject);
	use Class::STL::ClassMembers qw(function_name); 
	sub new
	{
		my $self = shift;
		my $class = ref($self) || $self;
		$self = $class->SUPER::new();
		bless($self, $class);
		$self->members_init(function_name => shift);
		return $self;
	}
	sub function_operator
	{
		my $self = shift;
		my $element = shift;
		my $fname = $self->function_name();
		return $element->$fname(@_);
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::PointerToUnaryFunction;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	use Carp qw(confess);
	use Class::STL::ClassMembers qw(function_name); 
	sub new
	{
		my $self = shift;
		my $class = ref($self) || $self;
		$self = $class->SUPER::new();
		bless($self, $class);
		$self->members_init(function_name => shift);
		return $self->factory();
	}
	sub factory
	{
		my $self = shift;
		our %__dynfun;
		if (!exists($__dynfun{$self->function_name()}))
		{
			$__dynfun{$self->function_name()} = eval("
			{
				package Class::STL::Utilities::PointerToUnaryFunction::__@{[ $self->function_name() ]};
				use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
				sub function_operator
				{
					my \$self = shift;
					my \$arg = shift;
					my \$tmp;
					if (ref(\$arg) && \$arg->isa('Class::STL::Element'))
					{
						\$tmp = \$arg->clone();
						\$tmp->data(@{[ $self->function_name() ]}(\$tmp->data()));
					}
					return \$tmp;
				}
			}
			Class::STL::Utilities::PointerToUnaryFunction::__@{[ $self->function_name() ]}->new();
			");
			confess "**Error in eval for @{[ __PACKAGE__ ]} ptr_fun dynamic class creation:\n$@" if ($@);
		}
		return $__dynfun{$self->function_name()};
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::PointerToBinaryFunction;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
	use Carp qw(confess);
	use Class::STL::ClassMembers qw(function_name); 
	sub new
	{
		my $self = shift;
		my $class = ref($self) || $self;
		$self = $class->SUPER::new();
		bless($self, $class);
		$self->members_init(function_name => shift);
		return $self->factory();
	}
	sub factory
	{
		my $self = shift;
		our %__dynfun;
		if (!exists($__dynfun{$self->function_name()}))
		{
			$__dynfun{$self->function_name()} = eval("
			{
				package Class::STL::Utilities::PointerToBinaryFunction::__@{[ $self->function_name() ]};
				use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
				sub function_operator
				{
					my \$self = shift;
					my \$arg1 = shift;
					my \$arg2 = shift; 
					my \$tmp;
					if (ref(\$arg1) && \$arg1->isa('Class::STL::Element') && ref(\$arg2) && \$arg2->isa('Class::STL::Element'))
					{
						\$tmp = \$arg1->clone();
						\$tmp->data(@{[ $self->function_name() ]}(\$arg1->data(), \$arg2->data()));
					}
					elsif (ref(\$arg2) && \$arg2->isa('Class::STL::Element'))
					{
						\$tmp = \$arg2->clone();
						\$tmp->data(@{[ $self->function_name() ]}(\$arg1, \$arg2->data()));
					}
					elsif (ref(\$arg1) && \$arg1->isa('Class::STL::Element'))
					{
						\$tmp = \$arg1->clone();
						\$tmp->data(@{[ $self->function_name() ]}(\$arg1->data(), \$arg2));
					}
					return \$tmp;
				}
			}
			Class::STL::Utilities::PointerToBinaryFunction::__@{[ $self->function_name() ]}->new();
			");
			confess "**Error in eval for @{[ __PACKAGE__ ]} ptr_fun_binary dynamic class creation:\n$@" if ($@);
		}
		return $__dynfun{$self->function_name()};
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::UnaryNegate;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryPredicate);
	use Class::STL::ClassMembers qw(predicate); 
	sub new
	{
		my $self = shift;
		my $class = ref($self) || $self;
		$self = $class->SUPER::new();
		bless($self, $class);
		$self->members_init(predicate => shift);
		return $self;
	}
	sub function_operator
	{
		my $self = shift;
		my $arg = shift;
		return !($self->predicate()->function_operator($arg));
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::BinaryNegate;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	use Class::STL::ClassMembers qw(predicate); 
	sub new
	{
		my $self = shift;
		my $class = ref($self) || $self;
		$self = $class->SUPER::new();
		bless($self, $class);
		$self->members_init(predicate => shift);
		return $self;
	}
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift;
		return !($self->predicate()->function_operator($arg1, $arg2));
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Binder1st;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	use Class::STL::ClassMembers qw(operation first_argument); 
	sub new
	{
		my $self = shift;
		my $class = ref($self) || $self;
		$self = $class->SUPER::new();
		bless($self, $class);
		$self->members_init(operation => shift, first_argument => shift);
		return $self;
	}
	sub function_operator
	{
		my $self = shift;
		my $arg = shift; # element object
		return $self->operation()->function_operator($self->first_argument(), $arg);
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Binder2nd;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	use Class::STL::ClassMembers qw(operation second_argument); 
	sub new
	{
		my $self = shift;
		my $class = ref($self) || $self;
		$self = $class->SUPER::new();
		bless($self, $class);
		$self->members_init(operation => shift, second_argument => shift);
		return $self;
	}
	sub function_operator
	{
		my $self = shift;
		my $arg = shift; # element object
		return $self->operation()->function_operator($arg, $self->second_argument());
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::EqualTo;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift; 
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->eq($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? ($arg2->data_type() eq 'string') ? $arg1 eq $arg2->data() : $arg1 == $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? ($arg1->data_type() eq 'string') ? $arg1->data() eq $arg2 : $arg1->data() == $arg2
					: $arg1 == $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::NotEqualTo;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift; 
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->ne($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? ($arg2->data_type() eq 'string') ? $arg1 ne $arg2->data() : $arg1 != $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? ($arg1->data_type() eq 'string') ? $arg1->data() ne $arg2 : $arg1->data() != $arg2
					: $arg1 != $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::NotNull;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg = shift; 
		return defined($arg) && (ref($arg) || $arg != 0);
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Greater;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; # element or scalar
		my $arg2 = shift; # element or scalar
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->gt($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? ($arg2->data_type() eq 'string') ? $arg1 gt $arg2->data() : $arg1 > $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? ($arg1->data_type() eq 'string') ? $arg1->data() gt $arg2 : $arg1->data() > $arg2
					: $arg1 > $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::GreaterEqual;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift; 
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->ge($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? ($arg2->data_type() eq 'string') ? $arg1 ge $arg2->data() : $arg1 >= $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? ($arg1->data_type() eq 'string') ? $arg1->data() ge $arg2 : $arg1->data() >= $arg2
					: $arg1 >= $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Less;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift; 
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->lt($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? ($arg2->data_type() eq 'string') ? $arg1 lt $arg2->data() : $arg1 < $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? ($arg1->data_type() eq 'string') ? $arg1->data() lt $arg2 : $arg1->data() < $arg2
					: $arg1 < $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::LessEqual;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift; 
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->le($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? ($arg2->data_type() eq 'string') ? $arg1 le $arg2->data() : $arg1 <= $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? ($arg1->data_type() eq 'string') ? $arg1->data() le $arg2 : $arg1->data() <= $arg2
					: $arg1 <= $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Compare;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift; 
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->cmp($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? ($arg2->data_type() eq 'string') ? $arg1 cmp $arg2->data() : $arg1 <=> $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? ($arg1->data_type() eq 'string') ? $arg1->data() cmp $arg2 : $arg1->data() <=> $arg2
					: $arg1 <=> $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::LogicalAnd;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift; 
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->and($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? $arg1 && $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? $arg1->data() && $arg2
					: $arg1 && $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::LogicalOr;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift; 
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->or($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? $arg1 || $arg2->data()
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? $arg1->data() || $arg2
					: $arg1 || $arg2;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Matches;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift;
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->match($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? $arg1 =~ /@{[ $arg2->data() ]}/
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? $arg1->data() =~ /@{[ $arg2 ]}/ 
					: $arg1 =~ /$arg2/;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::MatchesIC;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryPredicate);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift; 
		my $arg2 = shift;
		return
		(ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
			? $arg1->match_ic($arg2)
			: (ref($arg2) && $arg2->isa('Class::STL::Element'))
				? $arg1 =~ /@{[ $arg2->data() ]}/i
				: (ref($arg1) && $arg1->isa('Class::STL::Element'))
					? $arg1->data() =~ /@{[ $arg2 ]}/i
					: $arg1 =~ /$arg2/i;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Multiplies;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift; 
		my $tmp;
		if (ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->mult($arg2);
		}
		elsif (ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg2->clone();
			$tmp->data($tmp->data() * $arg1);
		}
	   	elsif (ref($arg1) && $arg1->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->data($tmp->data() * $arg2);
		}
		return $tmp;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Plus;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift; 
		my $tmp;
		if (ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->add($arg2);
		}
		elsif (ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg2->clone();
			$tmp->data($tmp->data() + $arg1);
		}
	   	elsif (ref($arg1) && $arg1->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->data($tmp->data() + $arg2);
		}
		return $tmp;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Minus;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift; 
		my $tmp;
		if (ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->subtract($arg2);
		}
		elsif (ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg2->clone();
			$tmp->data($arg1 - $arg2->data());
		}
	   	elsif (ref($arg1) && $arg1->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->data($arg1->data() - $arg2);
		}
		return $tmp;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Modulus;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift; 
		my $tmp;
		if (ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->mod($arg2);
		}
		elsif (ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg2->clone();
			$tmp->data($arg1 % $arg2->data());
		}
	   	elsif (ref($arg1) && $arg1->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->data($arg1->data() % $arg2);
		}
		return $tmp;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Divides;
	use base qw(Class::STL::Utilities::FunctionObject::BinaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg1 = shift;
		my $arg2 = shift; 
		my $tmp;
		if (ref($arg1) && $arg1->isa('Class::STL::Element') && ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->div($arg2);
		}
		elsif (ref($arg2) && $arg2->isa('Class::STL::Element'))
		{
			$tmp = $arg2->clone();
			$tmp->data($arg1 / $arg2->data());
		}
	   	elsif (ref($arg1) && $arg1->isa('Class::STL::Element'))
		{
			$tmp = $arg1->clone();
			$tmp->data($arg1->data() / $arg2);
		}
		return $tmp;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Utilities::Negate;
	use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
	sub function_operator
	{
		my $self = shift;
		my $arg = shift;
		my $tmp;
		if (ref($arg) && $arg->isa('Class::STL::Element'))
		{
			$tmp = $arg->clone();
			$tmp->neg();
		}
		else
		{
			$tmp = Class::STL::Element->new(data => -$arg, data_type => 'numeric');
		}
		return $tmp;
	}
}
# ----------------------------------------------------------------------------------------------------
1;
