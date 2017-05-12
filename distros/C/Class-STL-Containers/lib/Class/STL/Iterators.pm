# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::Iterators.pm
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
package Class::STL::Iterators;
require 5.005_62;
use strict;
use warnings;
use vars qw( $VERSION $BUILD @EXPORT_OK %EXPORT_TAGS );
use Exporter;
my @export_names = qw( 
	iterator 
	bidirectional_iterator 
	reverse_iterator 
	forward_iterator 
	distance 
	advance 
	back_insert_iterator 
	front_insert_iterator 
	back_inserter 
	front_inserter 
	insert_iterator 
	inserter 
);
@EXPORT_OK = (@export_names);
%EXPORT_TAGS = ( all => [@export_names] );
$VERSION = '0.18';
$BUILD = 'Thursday April 27 23:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Iterators;
	use vars qw( $AUTOLOAD );
	sub AUTOLOAD
	{
		(my $func = $AUTOLOAD) =~ s/.*:://;
		return Class::STL::Iterators::BiDirectional->new(@_) if ($func eq 'iterator');
		return Class::STL::Iterators::BiDirectional->new(@_) if ($func eq 'bidirectional_iterator');
		return Class::STL::Iterators::Forward->new(@_) if ($func eq 'forward_iterator');
		return Class::STL::Iterators::Reverse->new(@_) if ($func eq 'reverse_iterator');
		return Class::STL::Iterators::Abstract::distance(@_) if ($func eq 'distance');
		return Class::STL::Iterators::Abstract::advance(@_) if ($func eq 'advance');
		return Class::STL::Iterators::BackInsertIterator->new(@_) if ($func eq 'back_insert_iterator');
		return Class::STL::Iterators::FrontInsertIterator->new(@_) if ($func eq 'front_insert_iterator');
		return Class::STL::Iterators::Abstract::back_inserter(@_) if ($func eq 'back_inserter');
		return Class::STL::Iterators::Abstract::front_inserter(@_) if ($func eq 'front_inserter');
		return Class::STL::Iterators::InsertIterator->new(@_) if ($func eq 'insert_iterator');
		return Class::STL::Iterators::Abstract::inserter(@_) if ($func eq 'inserter');
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Iterators::Abstract;
	use base qw(Class::STL::Element); 
	use Carp qw(confess);
	use overload '++' => 'next', '--' => 'prev', '=' => 'clone', 'bool' => '_bool',
		'+' => 'advance', '+=' => 'advance', '-' => 'retreat', '-=' => 'retreat',
		'==' => 'eq', '!=' => 'ne', '>' => 'gt', '<' => 'lt', '>=' => 'ge', '<=' => 'le', '<=>' => 'cmp';
	use Class::STL::ClassMembers qw(p_container),
		Class::STL::ClassMembers::DataMember->new(name => 'arr_idx', default => -1);
	use Class::STL::ClassMembers::Constructor;
	sub p_element
	{
		my $self = shift;
		return $self->arr_idx() < 0 || $self->arr_idx() >= $self->p_container()->size()
			? 0
			: ${$self->p_container()->data()}[$self->arr_idx()]
	}
	sub idx_check # (void)
	{
		my $self = shift;
		$self->arr_idx($self->p_container()->size()-1) if ($self->arr_idx() >= $self->p_container()->size());
		$self->arr_idx(-1) if ($self->arr_idx() < 0);
		return;
	}
	sub at_end # (void)
	{
		my $self = shift;
		$self->idx_check();
		return $self->arr_idx() == -1 ? 1 : 0;
	}
	sub prev # (void)
	{
		my $self = shift;
		$self->idx_check();
		return $self->last() if ($self->arr_idx() == -1);
		(!$self->p_container()->size() || $self->arr_idx() == 0)
			? $self->arr_idx(-1)
			: $self->arr_idx($self->arr_idx() -1);
		return $self; # iterator
	}
	sub next # (void)
	{
		my $self = shift;
		$self->idx_check();
		return $self if ($self->arr_idx() == -1);
		(!$self->p_container()->size() || $self->arr_idx()+1 >= $self->p_container()->size())
			? $self->arr_idx(-1)
			: $self->arr_idx($self->arr_idx() +1);
		return $self; # iterator
	}
	sub first # (void)
	{
		my $self = shift;
		$self->idx_check();
		(!$self->p_container()->size())
			? $self->arr_idx(-1)
			: $self->arr_idx(0);
		return $self; # iterator
	}
	sub last # (void)
	{
		my $self = shift;
		$self->idx_check();
		(!$self->p_container()->size())
			? $self->arr_idx(-1)
			: $self->arr_idx($self->p_container()->size()-1);
		return $self; # iterator
	}
	sub front_inserter # (container) -- static function
	{
		my $c = shift;
		confess "A front_insert_iterator can only be used with a container that defines the push_front() member function\n"
			unless (ref($c) && $c->isa('Class::STL::Containers::Abstract') && $c->can('push_front'));
		return Class::STL::Iterators::FrontInsertIterator->new(p_container => $c);
	}
	sub back_inserter # (container) -- static function
	{
		my $c = shift;
		confess "A back_insert_iterator can only be used with a container that defines the push_back() member function\n"
			unless (ref($c) && $c->isa('Class::STL::Containers::Abstract') && $c->can('push_back'));
		return Class::STL::Iterators::BackInsertIterator->new(p_container => $c);
	}
	sub inserter # (container, iterator) -- static function
	{
		my $c = shift;
		my $i = shift;
		confess "Usage:inserter(container, iterator)"
			unless (ref($c) && $c->isa('Class::STL::Containers::Abstract')
				&& ref($i) && $i->isa('Class::STL::Iterators::Abstract'));
		return Class::STL::Iterators::InsertIterator->new(p_container => $c, arr_idx => $i->arr_idx());
	}
	sub distance # (iterator, iterator) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		confess "@{[ __PACKAGE__ ]}::distance usage:\ndistance( iterator-start, iterator-finish );"
			unless (
				defined($iter_start) && ref($iter_start) && $iter_start->isa('Class::STL::Iterators::Abstract')
				&& defined($iter_finish) && ref($iter_finish) && $iter_finish->isa('Class::STL::Iterators::Abstract')
				&& $iter_start->p_container() == $iter_finish->p_container()
			);
		return -1 if ($iter_start->at_end() && $iter_finish->at_end());
		return -1 if ($iter_start->at_end() || $iter_start->gt($iter_finish));
		return $iter_finish->p_container()->size()-1 - $iter_start->arr_idx() if ($iter_finish->at_end());
		return $iter_finish->arr_idx() - $iter_start->arr_idx();
	}
	sub advance # (size) -- static function
	{
		my $iter = shift;
		my $size = shift;
		if ($size >= 0)
		{
			for (my $i=0; $i<$size; ++$i) { $iter->next(); }
		}
		else
		{
			for (my $i=$size; $i!=0; ++$i) { $iter->prev(); }
		}
		return $iter;
	}
	sub retreat # (size) -- static function
	{
		my $iter = shift;
		my $size = shift;
		return $iter->advance(-$size);
		return $iter;
	}
	sub eq # (element)
	{
		my $self = shift;
		my $other = shift;
		return 
#?			$self->p_container() == $other->p_container()
			$self->arr_idx() == $other->arr_idx();
	}
	sub ne # (element)
	{
		my $self = shift;
		return $self->eq(shift) ? 0 : 1;
	}
	sub gt # (element)
	{
		my $self = shift;
		my $other = shift;
		return !$self->at_end() && !$other->at_end()
#?			&& $self->p_container() == $other->p_container()
			&& $self->arr_idx() > $other->arr_idx();
	}
	sub ge # (element)
	{
		my $self = shift;
		my $other = shift;
		return !$self->at_end() && !$other->at_end()
#?			&& $self->p_container() == $other->p_container()
			&& $self->arr_idx() >= $other->arr_idx();
	}
	sub lt # (element)
	{
		my $self = shift;
		my $other = shift;
		return !$self->at_end() && !$other->at_end()
#?			&& $self->p_container() == $other->p_container()
			&& $self->arr_idx() < $other->arr_idx();
	}
	sub le # (element)
	{
		my $self = shift;
		my $other = shift;
		return !$self->at_end() && !$other->at_end()
#?			&& $self->p_container() == $other->p_container() # -- don't want overloaded == !!
			&& $self->arr_idx() <= $other->arr_idx();
	}
	sub cmp # (element)
	{
		my $self = shift;
		my $other = shift;
		return $self->eq($other) ? 0 : $self->lt($other) ? -1 : 1;
	}
	sub _bool
	{
		my $self = shift;
		return $self;
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Iterators::BiDirectional;
	use base qw(Class::STL::Iterators::Abstract); 
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Iterators::Forward;
	use base qw(Class::STL::Iterators::BiDirectional); 
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	use Class::STL::ClassMembers::Disable qw(prev);
	use Class::STL::ClassMembers::Disable qw(last);
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Iterators::Reverse;
	use base qw(Class::STL::Iterators::BiDirectional); 
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub last # (void)
	{
		my $self = shift;
		return $self->SUPER::first(); # iterator
	}
	sub first # (void)
	{
		my $self = shift;
		return $self->SUPER::last(); # iterator
	}
	sub next # (void)
	{
		my $self = shift;
		return $self->SUPER::prev(); # iterator
	}
	sub prev # (void)
	{
		my $self = shift;
		return $self->SUPER::next(); # iterator
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Iterators::BackInsertIterator;
	use base qw(Class::STL::Iterators::Abstract); 
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub assign # (element)
	{
		my $self = shift;
		$self->p_container()->push_back(@_);
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Iterators::FrontInsertIterator;
	use base qw(Class::STL::Iterators::Abstract); 
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub assign # (element)
	{
		my $self = shift;
		$self->p_container()->push_front(@_);
	}
}
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Iterators::InsertIterator;
	use base qw(Class::STL::Iterators::Abstract); 
	use Class::STL::ClassMembers;
	use Class::STL::ClassMembers::Constructor;
	sub assign # (element)
	{
		my $self = shift;
		if (!$self->p_container()->size() || $self->at_end())
		{
			$self->p_container()->push(@_);
		}
		else
		{
			CORE::splice(@{$self->p_container()->data()}, $self->arr_idx(), 0, 
				grep(ref && $_->isa('Class::STL::Element'), @_));
		}
		return $self->next();
	}
}
# ----------------------------------------------------------------------------------------------------
1;
