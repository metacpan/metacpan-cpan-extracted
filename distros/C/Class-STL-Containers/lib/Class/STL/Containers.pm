# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::Containers.pm
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
package Class::STL::Containers;
require 5.005_62;
use strict;
use warnings;
use vars qw( $VERSION $BUILD @EXPORT_OK %EXPORT_TAGS );
use Exporter;
@EXPORT_OK = qw( vector list deque queue priority_queue stack tree );
%EXPORT_TAGS = ( all => [qw( vector list deque queue priority_queue stack tree )] );
$VERSION = '0.35';
$BUILD = 'Tue April 3 19:33:14 GMT 2007';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers;
	use vars qw( $AUTOLOAD );
	sub AUTOLOAD
	{
		(my $func = $AUTOLOAD) =~ s/.*:://;
		return Class::STL::Containers::Vector->new(@_) if ($func eq 'vector');
		return Class::STL::Containers::List->new(@_) if ($func eq 'list');
		return Class::STL::Containers::Deque->new(@_) if ($func eq 'deque');
		return Class::STL::Containers::Queue->new(@_) if ($func eq 'queue');
		return Class::STL::Containers::PriorityQueue->new(@_) if ($func eq 'priority_queue');
		return Class::STL::Containers::Stack->new(@_) if ($func eq 'stack');
		return Class::STL::Containers::Tree->new(@_) if ($func eq 'tree');
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::Abstract;
	use base qw(Class::STL::Element); # container is also an element
	use overload '+' => 'append', '+=' => 'append', '=' => 'clone', '""' => 'str', '==' => 'eq', '!=' => 'ne';
	use Class::STL::Iterators qw(:all);
	use UNIVERSAL qw(isa can);
	use Carp qw(confess);
	use Class::STL::ClassMembers
		Class::STL::ClassMembers::DataMember->new(
			name => 'element_type', default => 'Class::STL::Element');
	use Class::STL::ClassMembers::Constructor;
	# new(named-argument-list);
	# new(container-ref); -- copy ctor
	# new(element [, ...]); -- initialise new container with element(s).
	# new(iterator-start); -- initialise new container with copy of elments from other container.
	# new(iterator-start, iterator-finish); -- initialise new container with copy of elments from other container.
	# new(raw-data, [...]); -- 
	sub new_extra # static function
	{
		my $self = shift;
		use vars qw(@ISA);
		my @copy_elements;
		my @copy_iterators;
		my @raw_data;
		my @params;
		while (@_)
		{
			my $p = shift;
			if (!ref($p) && int(@_) && (exists(${$self->members()}{$p}) || $self->can($p)))
			{
				shift;
			}
			elsif (ref($p) && $p->isa('Class::STL::Iterators::Abstract')) 
			{
				CORE::push(@copy_iterators, $p);
			}
			elsif (ref($p) && $p->isa(__PACKAGE__))
			{
#?				shift; # ??? why???
			}
			elsif (ref($p) && $p->isa('Class::STL::Element'))
			{
				CORE::push(@copy_elements, $p);
			}
			else {
				CORE::push(@raw_data, $p);
			}
		}
		confess "element_type (@{[ $self->element_type() ]}) must be derived from Class::STL::Element!"
			unless (UNIVERSAL::isa($self->element_type(), 'Class::STL::Element'));
		$self->data_type('array');
		$self->data([]); # Array of (base) type Class::STL::Element
		foreach (@copy_elements) { $self->push($_); }
		while (@raw_data) { $self->push($self->factory(data => shift(@raw_data))); }
		if (@copy_iterators) {
			@copy_iterators >= 2 
				? $self->insert($self->begin(), $copy_iterators[0], $copy_iterators[1])
				: $self->insert($self->begin(), $copy_iterators[0]);
		}
		return $self;
	}
	sub append # (container-ref) -- append other to this container;
	{
		my $self = shift;
		my $other = shift;
		$self->push($other->to_array());
		return $self;
	}
	sub factory # (@params) -- construct an element object and return it;
	{
		my $self = shift;
		return Class::STL::Element->new(@_) if	($self->element_type() eq 'Class::STL::Element');
		our %__factfun;
		if (!exists($__factfun{$self->element_type()}))
		{
			$__factfun{$self->element_type()} = eval("
			{
				package @{[ ref($self) ]}\::Factory::__@{[ do{my $f=uc($self->element_type());$f=~s/\W+/_/g;$f} ]};
				use base qw(Class::STL::Element);
				sub _FACTORY
				{
					my \$self = shift;
					return @{[ $self->element_type() ]}\->new(\@_);
				}
			}
			@{[ ref($self) ]}\::Factory::__@{[ do{my $f=uc($self->element_type());$f=~s/\W+/_/g;$f} ]}->new();
			");
			confess "**Error in eval for @{[ __PACKAGE__ ]} ptr_fun dynamic class creation:\n$@" if ($@);
		}
		return $__factfun{$self->element_type()}->_FACTORY(@_);

#<		return Class::STL::Element->new(@_) if	($self->element_type() eq 'Class::STL::Element');
#<		my $e = eval("@{[ $self->element_type() ]}->new(\@_);"); # TODO: pre-gen factory sub code instead!
#<		confess "**Error in eval for @{[ $self->element_type() ]} factory creation:\n$@" if ($@);
#<		return $e;
	}
	sub push # (element [, ...] ) -- append elements to container...
	{
		my $self = shift;
		my $curr_sz = $self->size();
		CORE::push(@{$self->data()}, grep(ref && $_->isa('Class::STL::Element'), @_));
		return $self->size() - $curr_sz; # number of new elements inserted.
	}
	sub pop # (void)
	{
		my $self = shift;
		CORE::pop(@{$self->data()});
		return; # void return
	}
	sub top # (void) -- top() and pop() refer to same element.
	{
		my $self = shift;
		return ${$self->data()}[$self->size()-1];
	}
	sub clear # (void)
	{
		my $self = shift;
		$self->data([]);
		return; # void return
	}
	sub insert # 
	{
		my $self = shift;
		my $position = shift;
		confess $self->_insert_errmsg()
		unless (defined($position) && ref($position) 
			&& $position->isa('Class::STL::Iterators::Abstract'));
		my $size = $self->size();

		# insert(position, iterator-start, iterator-finish);# insert copies 
		if (defined($_[0]) && ref($_[0]) && $_[0]->isa('Class::STL::Iterators::Abstract')
			&& defined($_[1]) && ref($_[1]) && $_[1]->isa('Class::STL::Iterators::Abstract'))
		{ 
			my $iter_start = shift;
			my $iter_finish = shift;
			my $pos = $self->size() ? $position->arr_idx() : 0;
			for (my $i = $iter_finish->new($iter_finish); $i >= $iter_start; --$i) 
			{# insert copies
				$position->can('assign')
					? $position->assign($i->p_element()->clone())
					: CORE::splice(@{$self->data()}, $pos, 0, $i->p_element()->clone()); 
			}
		}
		# insert(position, iterator-start);# insert copies 
		elsif (defined($_[0]) && ref($_[0]) && $_[0]->isa('Class::STL::Iterators::Abstract'))
		{ 
			my $iter_start = shift;
			for (my $i = $iter_start->new($iter_start); !$i->at_end(); ++$i) 
			{# insert copies
				if ($position->can('assign'))
				{
					$position->assign($i->p_element()->clone());
				}
#?				elsif (!$size || !$position->at_end())
				elsif (!$size || $position->at_end())
				{
					$self->push($i->p_element()->clone());
				}
				else
				{
					CORE::splice(@{$self->data()}, $position->arr_idx(), 0, $i->p_element()->clone());
					$position++;
				}
			}
		}
		# insert(position, element [, ...]); # insert references (not copies)
		elsif (defined($_[0]) && ref($_[0]) && $_[0]->isa('Class::STL::Element'))
		{ 
			return $position->assign(@_) if ($position->can('assign'));
			!$size || $position->at_end()
				? $self->push(@_)
				: CORE::splice(@{$self->data()}, $position->arr_idx(), 0, 
					grep(ref && $_->isa('Class::STL::Element'), @_));
			$position->first() if (!$size);
			$position->next();
			return $position->clone()-1; # iterator points to inserted element
		}
		# insert(position, size, element);# insert copies 
		elsif (defined($_[0]) && defined($_[1]) && ref($_[1]) && $_[1]->isa('Class::STL::Element'))
		{ 
			my $num_repeat = shift;
			my $element = shift;
			my @elems;
			foreach (1..$num_repeat) { CORE::push(@elems, $element->clone()); } # insert copies 
			return $position->assign(@elems) if ($position->can('assign'));
			!$size || $position->at_end()
				? $self->push(@elems)
				: CORE::splice(@{$self->data()}, $position->arr_idx(), 0, @elems);
		}
		else
		{
			confess $self->_insert_errmsg();
		}
		$position->first() if (!$size);
		$position->next();
		return; # void
	}
	sub erase # ( iterator | iterator-start, iterator-finish )
	{
		my $self = shift;
		my $iter_start = shift;
		my $iter_finish = shift || $iter_start->clone();
		my $count=0;
		CORE::splice(@{$self->data()}, $iter_start->arr_idx(), $count)
			if (($count=distance($iter_start, $iter_finish)+1) > 0);
		$iter_start->last() if ($iter_start->at_end());
		return $iter_start; # iterator
	}
	sub _insert_errmsg
	{
		return "@{[ __PACKAGE__ ]}::insert usage:\ninsert( position, element [, ...] );\n"
			. "insert( position, iterator-start, iterator-finish );\n"
			. "insert( position, size, element );\n";
	}
	sub begin # (void)
	{
		my $self = shift;
		return iterator(p_container => $self)->first();
	}
	sub end # (void)
	{
		# WARNING: end() points to last element unlike C++/STL-end() which points to AFTER last element!!
		# See examples/iterator.pl for correct iterator traversal example.
		my $self = shift;
		return iterator(p_container => $self)->last();
	}
	sub rbegin # (void)
	{
		my $self = shift;
		return reverse_iterator(p_container => $self)->first();
	}
	sub rend # (void)
	{
		my $self = shift;
		return reverse_iterator(p_container => $self)->last();
	}
	sub size # (void)
	{
		my $self = shift;
		return defined($self->data()) ? int(@{$self->data()}) : 0;
	}
	sub empty # return bool
	{
		my $self = shift;
		return $self->size() ? 0 : 1; # 1==true; 0==false
	}
	sub to_array # (void) 
	{
		my $self = shift;
		my $level = shift || undef;

		return (@{$self->data()}) # array of data
			unless (defined($level));

		my @nodes;
		foreach (@{$self->data()}) { # traverse tree...
			($_->isa('Class::STL::Containers::Abstract'))
				? CORE::push(@nodes, $_->to_array($level+1)) 
				: CORE::push(@nodes, $_);
		}
		return @nodes;
	}
	sub join # (delimiter)
	{
		my $self = shift;
		my $delim = shift || '';
		return CORE::join($delim, map($_->print(), $self->to_array())); # string
	}
	sub eq # (container-ref)
	{
		my $self = shift;
		my $other = shift;
		return 0 unless $self->size() == $other->size();
		for (my $i1=$self->begin(), my $i2=$other->begin(); !$i1->at_end() && !$i2->at_end(); ++$i1, ++$i2)
		{
			return 0 unless ($i1->p_element()->eq($i2->p_element())); # not equal
		}
		return 1; # containers are equal
	}
	sub ne 
	{
		my $self = shift;
		return $self->eq(shift) ? 0 : 1;
	}
	sub str 
	{
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::Vector;
	use base qw(Class::STL::Containers::Abstract); # vector is also an element
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	use Class::STL::ClassMembers::Disable qw(push_front);
	sub push_back # (element [, ...])
	{
		my $self = shift;
		return $self->push(@_); # number of new elements inserted.
	}
	sub pop_back # (void)
	{
		my $self = shift;
		$self->pop();
		return; # void return
	}
	sub back # (void)
	{
		my $self = shift;
		return ${$self->data()}[$self->size()-1]; # element ref
	}
	sub front # (void)
	{
		my $self = shift;
		return ${$self->data()}[0]; # element ref
	}
	sub at # (idx)
	{
		my $self = shift;
		my $idx = shift || 0;
		return ${$self->data()}[$idx]; # element ref
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::Deque;
	use base qw(Class::STL::Containers::Vector);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub push_front # (element [, ...])
	{
		my $self = shift;
		my $curr_sz = $self->size();
		unshift(@{$self->data()}, grep(ref && $_->isa("Class::STL::Element"), @_));
		return $self->size() - $curr_sz; # number of new elements inserted.
	}
	sub pop_front # (void)
	{
		my $self = shift;
		my $front = shift(@{$self->data()});
		return; # void return
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::Queue;
	use base qw(Class::STL::Containers::Abstract);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	use Class::STL::ClassMembers::Disable qw(push_back);
	use Class::STL::ClassMembers::Disable qw(pop_back);
	sub back # (void)
	{
		my $self = shift;
		return $self->SUPER::top();
	}
	sub front # (void)
	{
		my $self = shift;
		return ${$self->data()}[0]; # element ref
	}
	sub push # (element [,...]) -- push to back
	{
		my $self = shift;
		$self->SUPER::push(@_);
		return; # void return
	}
	sub pop # (void) -- pop from front
	{
		my $self = shift;
		shift(@{$self->data()});
		return; # void return
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::Stack;
	use base qw(Class::STL::Containers::Abstract);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	use Class::STL::ClassMembers::Disable qw(push_back);
	use Class::STL::ClassMembers::Disable qw(pop_back);
	use Class::STL::ClassMembers::Disable qw(front);
	sub top # (void)
	{
		my $self = shift;
		return $self->SUPER::top();
	}
	sub push # (element [,...])
	{
		my $self = shift;
		$self->SUPER::push(@_);
	}
	sub pop # (void)
	{
		my $self = shift;
		$self->SUPER::pop();
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::Tree;
	use base qw(Class::STL::Containers::Deque);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub new_extra
	{
		my $self = shift;
		$self->element_type(__PACKAGE__);
		return $self;
	}
	sub to_array # (void)
	{
		my $self = shift;
		$self->SUPER::to_array(1);
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::List;
	use base qw(Class::STL::Containers::Deque);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	use Class::STL::ClassMembers::Disable qw(at);
	sub reverse # (void)
	{
		my $self = shift;
		$self->data([ CORE::reverse(@{$self->data()}) ]);
	}
	sub sort # (void | cmp)
	{
		my $self = shift;
		$self->data([ CORE::sort { $a->cmp($b) } (@{$self->data()}) ]);
		# sort according to cmp 
	}
	sub splice
	{
		#TODO
	}
	sub merge
	{
		#TODO
	}
	sub remove # (element)
	{
		#TODO
	}
	sub unique # (void | predicate)
	{
		#TODO
		#Erases consecutive elements matching a true condition of the binary_pred. The first occurrence is not removed.
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Element::Priority;
	use base qw(Class::STL::Element);
	use Class::STL::ClassMembers qw(priority);
	use Class::STL::ClassMembers::Constructor;
	sub cmp
	{
		my $self = shift;
		my $other = shift;
		return $self->eq($other) ? 0 : $self->lt($other) ? -1 : 1;
	}
	sub eq # (element)
	{
		my $self = shift;
		my $other = shift;
		return $self->priority() == $other->priority();
	}
	sub ne # (element)
	{
		my $self = shift;
		return !$self->eq(shift);
	}
	sub gt # (element)
	{
		my $self = shift;
		my $other = shift;
		return $self->priority() > $other->priority();
	}
	sub lt # (element)
	{
		my $self = shift;
		my $other = shift;
		return $self->priority() < $other->priority();
	}
	sub ge # (element)
	{
		my $self = shift;
		my $other = shift;
		return $self->priority() >= $other->priority();
	}
	sub le # (element)
	{
		my $self = shift;
		my $other = shift;
		return $self->priority() <= $other->priority();
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::PriorityQueue;
	use base qw(Class::STL::Containers::Vector);
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	use Class::STL::ClassMembers::Disable qw(push_back);
	use Class::STL::ClassMembers::Disable qw(pop_back);
	use Class::STL::ClassMembers::Disable qw(front);
	sub new_extra
	{
		my $self = shift;
		$self->element_type('Class::STL::Element::Priority');
		return $self;
	}
	sub push
	{
		my $self = shift;
		while (my $d = shift)
		{
			if (!$self->size() || $d->ge($self->top()))
			{
				$self->SUPER::push($d);
				next;
			}
			for (my $i=$self->begin(); !$i->at_end(); ++$i)
			{
				if ($i->p_element()->gt($d))
				{
					$self->insert($i, $d);
					last;
				}
			}
		}
	}
	sub pop
	{
		my $self = shift;
		$self->SUPER::pop();
	}
	sub top
	{
		my $self = shift;
		return $self->SUPER::top();
	}
	sub refresh
	{
		# If the priority values were modified then a refresh() is required to re-order the elements.
		my $self = shift;
		$self->data([ CORE::sort { $a->cmp($b) } (@{$self->data()}) ]);
		# sort according to cmp 
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::Set;
	use base qw(Class::STL::Containers::Abstract);
	#TODO
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::MultiSet;
	use base qw(Class::STL::Containers::Set);
	#TODO
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::Map;
	use base qw(Class::STL::Containers::Abstract);
	#TODO
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::MultiMap;
	use base qw(Class::STL::Containers::Map);
	#TODO
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Containers::MakeFind;
	use UNIVERSAL qw(isa can);
	use Carp qw(cluck confess);
	sub new # --> import...
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {};
		bless($self, $class);
		my $package = (caller())[0];
		confess "**Error: MakeFind is only available to classes derived from Class::STL::Containers::Abstract!\n"
			unless UNIVERSAL::isa($package, 'Class::STL::Containers::Abstract');
		my $this = $package;
		$this =~ s/[:]+/_/g;
		my $member_name = shift;
		my $code = "
			sub $package\::find 
			{
				my \$self = shift;
				my \$what = shift;
				return Class::STL::Algorithms::find_if
				(
					\$self->begin(), \$self->end(),
			   		$package\::Find@{[ uc($member_name) ]}->new(what => \$what)
				);
			}
			{
				package $package\::Find@{[ uc($member_name) ]};
				use base qw(Class::STL::Utilities::FunctionObject::UnaryFunction);
                use Class::STL::ClassMembers qw(what);
				use Class::STL::ClassMembers::Constructor;
				sub function_operator
				{
					my \$self = shift;
					my \$arg = shift; # element object
					return \$arg->$member_name() eq \$self->what() ? \$arg : 0;
				}
			}";
		eval($code);
		cluck "**MakeFind Error:$@\n$code" if ($@);
	}
}
# ----------------------------------------------------------------------------------------------------
1;
