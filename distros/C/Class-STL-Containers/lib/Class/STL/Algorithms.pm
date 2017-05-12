# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::Alogorithms.pm
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
require 5.005_62;
use strict;
use attributes qw(get reftype);
use warnings;
use vars qw($VERSION $BUILD);
$VERSION = '0.21';
$BUILD = 'Monday May 8 23:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Algorithms;
	use UNIVERSAL qw(isa can);
	use vars qw( @EXPORT_OK %EXPORT_TAGS );
	use Exporter;
	my @export_names = qw( 
		find 
		find_if 
		for_each 
		transform 
		count 
		count_if 
		copy 
		copy_backward
		remove 
		remove_if 
		remove_copy 
		remove_copy_if
		replace 
		replace_if 
		replace_copy 
		replace_copy_if 
		generate 
		generate_n 
		fill 
		fill_n 
		equal 
		reverse 
		reverse_copy
		rotate 
		rotate_copy
		partition 
		stable_partition 
		min_element 
		max_element 
		unique 
		unique_copy
		adjacent_find
		_sort
		stable_sort
		qsort
		stable_qsort
		accumulate
	);
	@EXPORT_OK = (@export_names);
	%EXPORT_TAGS = ( all => [@export_names] );
	sub new
	{
		use Carp qw(confess);
		confess "@{[ __PACKAGE__ ]} contains STATIC functions only!\n";
	}
	sub accumulate  # (iterator-start, iterator-finish, element [, binary-function ] )
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $element = shift;
		my $binary_op = shift || undef;
		$element = $iter_start->p_container()->factory($element);
		defined($binary_op) 
			? _usage_check('accumulate', 'IIEB', $iter_start, $iter_finish, $element, $binary_op)
			: _usage_check('accumulate', 'IIE', $iter_start, $iter_finish, $element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				accumulate($iter->p_element()->begin(), $iter->p_element()->end(), $element, $binary_op); # its a tree -- recurse
			}
			else 
			{
				defined($binary_op) 
					? $element = $binary_op->function_operator($element, $iter->p_element())
					: $element->add($iter->p_element());
			}
		}
		return $element;
	}
	sub BEGIN
	{
		eval "use sort qw(stable)";
		my $have_sort = !$@;
		my $eval =
			"
			sub qsort # (iterator-start, iterator-finish [, binary-function ] )
			{
				@{[ $have_sort ? 'use sort qw(_qsort);' : '' ]}
				_sort(\@_);
			}
			sub stable_qsort # (iterator-start, iterator-finish [, binary-function ] )
			{
				@{[ $have_sort ? 'use sort qw(stable _qsort);' : '' ]}
				_sort(\@_);
			}
			sub stable_sort # (iterator-start, iterator-finish [, binary-function ] )
			{
				@{[ $have_sort ? 'use sort qw(stable);' : '' ]}
				_sort(\@_);
			}
			"
		;
		eval($eval);
		confess "@{[ __PACKAGE__ ]} Invalid sort pragma usage!\n" if ($@);

	}
	sub _sort # (iterator-start, iterator-finish [, binary-function ] )
	{
		use Class::STL::Iterators qw(distance);
		int(@_) == 2 ? _usage_check('sort(1)', 'II', @_) : _usage_check('sort(2)', 'IIB', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $binary_op = shift || undef;
		defined($binary_op) 
			? CORE::splice(@{$iter_start->p_container()->data()}, $iter_start->arr_idx(), distance($iter_start, $iter_finish)+1,
				CORE::sort { $binary_op->function_operator($a, $b) } 
					(@{$iter_start->p_container()->data()}[$iter_start->arr_idx()..$iter_finish->arr_idx()]))
			: CORE::splice(@{$iter_start->p_container()->data()}, $iter_start->arr_idx(), distance($iter_start, $iter_finish)+1,
				CORE::sort { $a->cmp($b) } 
					(@{$iter_start->p_container()->data()}[$iter_start->arr_idx()..$iter_finish->arr_idx()]));
		return; # void
	}
	sub transform 
	{
		return @_ == 5 ? transform_2(@_) : transform_1(@_);
	}
	sub transform_1 # (iterator-start, iterator-finish, iterator-result, unary-function-object)
	{
		_usage_check('transform(1)', 'IIIU', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		my $unary_op = shift; # unary-function
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::AbstracTree'))
			{
				transform_1($iter->p_element()->begin(), $iter->p_element()->end(), $iter_result, $unary_op); # its a tree -- recurse
			}
			elsif ($unary_op->isa('Class::STL::Utilities::FunctionObject::UnaryPredicate'))
			{
				# Need to check this!
				my $e = $iter->p_element()->clone();
				$e->data($unary_op->function_operator($iter->p_element()) ? 1 : 0);
				$iter_result->p_container()->insert($iter_result, $e);
			}
			else # $unary_op->isa('Class::STL::Utilities::FunctionObject::UnaryFunction')
			{
				$iter_result->p_container()->insert($iter_result, 
					$unary_op->function_operator($iter->p_element()));
			}
		}
		return;
	}
	sub transform_2 # (iterator-start, iterator-finish, iterator-start2, iterator-result, binary-function-object)
	{
		_usage_check('transform(2)', 'IIIIB', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_start2 = shift;
		my $iter_result = shift;
		my $binary_op = shift; # binary-function
		for 
		(
			my $iter=$iter_start->clone(), my $iter2=$iter_start2->clone(); 
			$iter <= $iter_finish && !$iter2->at_end(); 
			++$iter, ++$iter2
		)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::AbstracTree'))
			{
				transform_2($iter->p_element()->begin(), $iter->p_element()->end(), $iter_start2, $iter_result, $binary_op); # its a tree -- recurse
			}
			elsif ($binary_op->isa('Class::STL::Utilities::FunctionObject::BinaryPredicate'))
			{
				my $e = $iter->p_element()->clone();
#>				$e->negate($binary_op->function_operator($iter->p_element(), $iter2->p_element()) ? 0 : 1);
				$e->data($binary_op->function_operator($iter->p_element(), $iter2->p_element()) ? 1 : 0);
				$iter_result->p_container()->insert($iter_result, $e);
			}
			else # $binary_op->isa('Class::STL::Utilities::FunctionObject::BinaryFunction')
			{
				$iter_result->p_container()->insert($iter_result, 
					$binary_op->function_operator($iter->p_element(), $iter2->p_element()));
			}
		}
		return;
	}
	sub unique # (iterator, iterator [, binary-predicate ] ) -- static function
	{
		int(@_) == 2 ? _usage_check('unique(1)', 'II', @_) : _usage_check('unique(2)', 'IIB', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $binary_op = shift || undef;
		my $iter_prev = $iter_start->clone();
		for (my $iter = $iter_start->clone()+1; $iter != $iter_prev && $iter <= $iter_finish; )
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				unique($iter->p_element()->begin(), $iter->p_element()->end(), $binary_op); # its a tree -- recurse
				++$iter;
				++$iter_prev;
			}
			elsif 
			(
				(defined($binary_op) && $binary_op->function_operator($iter_prev->p_element(), $iter->p_element()))
				|| (!defined($binary_op) && $iter_prev->p_element()->eq($iter->p_element()))
			)
			{
				$iter = $iter->p_container()->erase($iter)
			}
			else
			{
				++$iter;
				++$iter_prev;
			}
		}
		return $iter_finish; # iterator
	}
	sub unique_copy # (iterator, iterator, iterator [, binary-predicate ] ) -- static function
	{
		int(@_) == 3 ? _usage_check('unique_copy(1)', 'III', @_) : _usage_check('unique_copy(2)', 'IIIB', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		my $binary_op = shift || undef;
		my $iter_prev = $iter_start->clone();
		$iter_result->p_container()->insert($iter_result, 1, $iter_prev->p_element());
		for (my $iter = $iter_start->clone()+1; $iter != $iter_prev && $iter <= $iter_finish; ++$iter, ++$iter_prev)
		{
			if 
			(
				(defined($binary_op) && !$binary_op->function_operator($iter_prev->p_element(), $iter->p_element()))
				|| (!defined($binary_op) && !$iter_prev->p_element()->eq($iter->p_element()))
			)
			{
				$iter_result->p_container()->insert($iter_result, 1, $iter->p_element());
			}
		}
		return $iter_result-1; # iterator
	}
	sub adjacent_find # (iterator, iterator [, binary-predicate ] ) -- static function
	{
		int(@_) == 2 ? _usage_check('adjacent_find(1)', 'II', @_) : _usage_check('adjacent_find(2)', 'IIB', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $binary_op = shift || undef;
		my $iter_next = $iter_start->clone()+1;
		for (my $iter = $iter_start->clone(); $iter_next <= $iter_finish; ++$iter, ++$iter_next)
		{
			return $iter
			if 
			(
				(defined($binary_op) && $binary_op->function_operator($iter->p_element(), $iter_next->p_element()))
				|| (!defined($binary_op) && $iter_next->p_element()->eq($iter->p_element()))
			);
		}
		return $iter_finish; # iterator
	}
	sub partition # (iterator, iterator, unary-predicate) -- static function
	{
		stable_partition(@_);
	}
	sub stable_partition # (iterator, iterator, unary-predicate) -- static function
	{
		_usage_check('stable_partition', 'IIU', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $function = shift;
		my $position = $iter_start->clone();
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if ($function->function_operator($iter->p_element()))
			{
				$iter->p_container()->insert($position, 1, $iter->p_element());
				$iter->p_container()->erase($iter+1);
			}
		}
		return;
	}
	sub min_element # (iterator, iterator, [, binary-function] ) -- static function
	{
		int(@_) == 3 ? _usage_check('min_element(1)', 'IIB', @_) : _usage_check('min_element(2)', 'II', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $binary_op = shift || undef;
		my $iter_min = $iter_start;
		for (my $iter=$iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{ 
			$iter_min = $iter 
			if 
			(
				(defined($binary_op) && $binary_op->function_operator($iter->p_element(), $iter_min->p_element()))
				|| (!defined($binary_op) && $iter->p_element()->lt($iter_min->p_element()))
			);
		}
		return $iter_min; 
	}
	sub max_element # (iterator, iterator, [, binary-function] ) -- static function
	{
		int(@_) == 3 ? _usage_check('max_element(1)', 'IIB', @_) : _usage_check('max_element(2)', 'II', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $binary_op = shift || undef;
		my $iter_min = $iter_start;
		for (my $iter=$iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{ 
			$iter_min = $iter 
			if 
			(
				(defined($binary_op) && !$binary_op->function_operator($iter->p_element(), $iter_min->p_element()))
				|| (!defined($binary_op) && !$iter->p_element()->lt($iter_min->p_element()))
			);
		}
		return $iter_min; 
	}
	sub equal # (iterator, iterator, iterator [, binary-function] ) -- static function
	{
		int(@_) == 3 ? _usage_check('equal(1)', 'III', @_) : _usage_check('equal(2)', 'IIIB', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_start2 = shift;
		my $binary_op = shift || undef;
		for 
		(
			my $iter=$iter_start->clone(), my $iter2=$iter_start2->clone(); 
			$iter <= $iter_finish; 
			++$iter, ++$iter2
		)
		{ 
		 	return 0 if # bool false
			(
				$iter2->at_end() 
				|| (defined($binary_op) && $binary_op->function_operator($iter->p_element(), $iter2->p_element()) == 0) 
				|| (!defined($binary_op) && $iter->p_element()->eq($iter2->p_element()) == 0)
			); 
		}
		return 1; # bool true
	}
	sub rotate_copy # (iterator, iterator, iterator, iterator) -- static function
	{
		_usage_check('rotate_copy', 'IIII', @_);
		my $iter_start = shift;
		my $iter_mid = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		copy($iter_mid, $iter_finish, $iter_result);
		copy($iter_start, $iter_mid-1, $iter_result);
		return;
	}
	sub rotate # (iterator, iterator, iterator) -- static function
	{
		_usage_check('rotate', 'III', @_);
		my $iter_start = shift;
		my $iter_mid = shift;
		my $iter_finish = shift;
		my $iter_end = $iter_finish; ++$iter_end;
		for (my $iter = $iter_start->clone(); $iter < $iter_mid; ++$iter)
		{
			$iter->p_container()->insert($iter_end, 1, $iter->p_element());
		}
		$iter_start->p_container()->erase($iter_start, --$iter_mid);
		return;
	}
	sub reverse # (iterator, iterator) -- static function
	{
		_usage_check('reverse', 'II', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		for (my $i1=$iter_start->clone(), my $i2=$iter_finish->clone(); $i1 < $i2; ++$i1, --$i2)
		{
			$i1->p_element()->swap($i2->p_element());
		}
		return;
	}
	sub reverse_copy # (iterator, iterator, iterator) -- static function
	{
		_usage_check('reverse_copy', 'III', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			$iter_result->p_container()->insert($iter_result, 1, $iter->p_element());
			$iter_result--;
		}
		return;
	}
	sub for_each # (iterator, iterator, unary-function-object) -- static function
	{
		_usage_check('for_each', 'IIF', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $function = shift; # unary-function
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree')
				? for_each($iter->p_element()->begin(), $iter->p_element()->end(), $function) # its a tree -- recurse
				: $function->function_operator($iter->p_element());
		}
		return;
	}
	sub generate # (iterator, iterator, generator-function-object) -- static function
	{
		_usage_check('generate', 'IIG', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $function = shift; # generator-function
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree')
				? generate($iter->p_element()->begin(), $iter->p_element()->end(), $function) # its a tree -- recurse
				: $iter->p_element()->swap($function->function_operator());
		}
		return;
	}
	sub generate_n # (iterator, size, generator-function-object) -- static function
	{
		_usage_check('generate_n', 'ISG', @_);
		my $iter_start = shift;
		my $size = shift;
		my $function = shift; # generator-function
		my $iter = $iter_start->clone(); 
		my $start_idx = $iter->arr_idx();
		for (; $iter->arr_idx() - $start_idx < $size; ++$iter)
		{
			ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree')
				? generate_n($iter->p_element()->begin(), $size, $function) # its a tree -- recurse
				: $iter->p_element()->swap($function->function_operator());
		}
		return;
	}
	sub fill # (iterator, iterator, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $element = shift;
		$element = $iter_start->p_container()->factory(data => $element)
			unless (ref($element) && $element->isa('Class::STL::Element'));
		_usage_check('fill', 'IIE', $iter_start, $iter_finish, $element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree')
				? fill($iter->p_element()->begin(), $iter->p_element()->end(), $element) # its a tree -- recurse
				: $iter->p_element()->swap($element->clone());
		}
		return;
	}
	sub fill_n # (iterator, size, element-ref) -- static function
	{
		my $iter_start = shift;
		my $size = shift;
		my $element = shift;
		$element = $iter_start->p_container()->factory(data => $element)
			unless (ref($element) && $element->isa('Class::STL::Element'));
		_usage_check('fill_n', 'ISE', $iter_start, $size, $element);
		my $iter = $iter_start->clone(); 
		my $start_idx = $iter->arr_idx();
		for (; $iter->arr_idx() - $start_idx < $size; ++$iter)
		{
			ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree')
				? fill_n($iter->p_element()->begin(), $size, $element) # its a tree -- recurse
				: $iter->p_element()->swap($element->clone());
		}
		return;
	}
	sub find_if # (iterator, iterator, unary-function-object) -- static function
	{
		_usage_check('find_if', 'IIF', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $function = shift; # unary-function 
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{	# its a tree -- recurse
				if (my $i = find_if($iter->p_element()->begin(), $iter->p_element()->end(), $function))
				{
					return $i; # Need to check this !!
				}
			}
			elsif ($function->function_operator($iter->p_element()))
			{
				return $iter->clone(); # iterator
			}
		}
		return 0;
	}
	sub find # (iterator, iterator, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $element = shift; # element-ref
		$element = $iter_start->p_container()->factory(data => $element)
			unless (ref($element) && $element->isa('Class::STL::Element'));
		_usage_check('find', 'IIE', $iter_start, $iter_finish, $element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				if (my $i = find($iter->p_element()->begin(), $iter->p_element()->end(), $element)) # its a tree -- recurse
				{
					return $i;
				}
			}
			elsif ($element->eq($iter->p_element()))
			{
				return $iter->clone();
			}
		}
		return 0;
	}
	sub count_if # (iterator, iterator, unary-function-object) -- static function
	{
		_usage_check('count_if', 'IIF', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $function = shift; # unary-function 
		my $count=0;
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			$count +=
				ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree')
					? count_if($iter->p_element()->begin(), $iter->p_element()->end(), $function) # its a tree -- recurse
					: ($function->function_operator($iter->p_element()) ? 1 : 0);
		}
		return $count;
	}
	sub count # (iterator, iterator, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $element = shift;
		$element = $iter_start->p_container()->factory(data => $element)
			unless (ref($element) && $element->isa('Class::STL::Element'));
		_usage_check('count', 'IIE', $iter_start, $iter_finish, $element);
		my $count=0;
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			$count +=
				ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree')
					? count($iter->p_element()->begin(), $iter->p_element()->end(), $element) # its a tree -- recurse
					: ($element->eq($iter->p_element()) ? 1 : 0);
		}
		return $count;
	}
	sub remove_if # (iterator, iterator, unary-function-object) -- static function
	{
		_usage_check('remove_if', 'IIF', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $function = shift; # unary-function or class-member-name
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; )
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				remove_if($iter->p_element()->begin(), $iter->p_element()->end(), $function); # its a tree -- recurse
				++$iter;
				next;
			}
			$function->function_operator($iter->p_element())
				? $iter->p_container()->erase($iter)
				: ++$iter;
		}
		return;
	}
	sub remove # (iterator, iterator, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $element = shift; # element-ref
		$element = $iter_start->p_container()->factory(data => $element)
			unless (ref($element) && $element->isa('Class::STL::Element'));
		_usage_check('remove', 'IIE', $iter_start, $iter_finish, $element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; )
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				remove($iter->p_element()->begin(), $iter->p_element()->end(), $element); # its a tree -- recurse
				++$iter;
				next;
			}
			$element->eq($iter->p_element())
				? $iter->p_container()->erase($iter)
				: ++$iter;
		}
		return;
	}
	sub remove_copy_if # (iterator, iterator, iterator, unary-function-object) -- static function
	{
		_usage_check('remove_copy_if', 'IIIF', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		my $function = shift; # unary-function or class-member-name
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				remove_copy_if($iter->p_element()->begin(), $iter->p_element()->end(), $iter_result, $function); # its a tree -- recurse
			}
			elsif (!$function->function_operator($iter->p_element()))
			{
				$iter_result->p_container()->insert($iter_result, 1, $iter->p_element());
			}
		}
		return;
	}
	sub remove_copy # (iterator, iterator, iterator, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		my $element = shift; # element-ref
		$element = $iter_start->p_container()->factory(data => $element)
			unless (ref($element) && $element->isa('Class::STL::Element'));
		_usage_check('remove_copy', 'IIIE', $iter_start, $iter_finish, $iter_result, $element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				remove_copy($iter->p_element()->begin(), $iter->p_element()->end(), $iter_result, $element); # its a tree -- recurse
			}
			elsif (!$element->eq($iter->p_element()))
			{
				$iter_result->p_container()->insert($iter_result, 1, $iter->p_element());
			}
		}
		return;
	}
	sub copy # (iterator, iterator, iterator) -- static function
	{
		_usage_check('copy', 'III', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			$iter_result->p_container()->insert($iter_result, 1, $iter->p_element());
		}
		return;
	}
	sub copy_backward # (iterator, iterator, iterator) -- static function
	{
		_usage_check('copy_backward', 'III', @_);
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		for (my $iter = $iter_finish->clone(); $iter >= $iter_start; --$iter)
		{
			$iter_result->p_container()->insert($iter_result, 1, $iter->p_element());
		}
		return;
	}
	sub replace_if # (iterator, iterator, unary-function, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $function = shift; 
		my $new_element = shift; # element-ref
		$new_element = $iter_start->p_container()->factory(data => $new_element)
			unless (ref($new_element) && $new_element->isa('Class::STL::Element'));
		_usage_check('replace_if', 'IIFE', $iter_start, $iter_finish, $function, $new_element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; )
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				replace_if($iter->p_element()->begin(), $iter->p_element()->end(), $function, $new_element); # its a tree -- recurse
			}
			elsif ($function->function_operator($iter->p_element()))
			{
				$iter->p_container()->erase($iter);
				$iter->p_container()->insert($iter, 1, $new_element);
			}
			else
			{
				++$iter;
			}
		}
		return;
	}
	sub replace # (iterator, iterator, element-ref, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $old_element = shift; # element-ref
		my $new_element = shift; # element-ref
		$old_element = $iter_start->p_container()->factory(data => $old_element)
			unless (ref($old_element) && $old_element->isa('Class::STL::Element'));
		$new_element = $iter_start->p_container()->factory(data => $new_element)
			unless (ref($new_element) && $new_element->isa('Class::STL::Element'));
		_usage_check('replace', 'IIEE', $iter_start, $iter_finish, $old_element, $new_element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; )
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				replace($iter->p_element()->begin(), $iter->p_element()->end(), $old_element, $new_element); # its a tree -- recurse
			}
			elsif ($iter->p_element()->eq($old_element))
			{
				$iter->p_container()->erase($iter);
				$iter->p_container()->insert($iter, 1, $new_element);
			}
			else
			{
				++$iter;
			}
		}
		return;
	}
	sub replace_copy_if # (iterator, iterator, iterator, unary-function, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		my $function = shift; 
		my $new_element = shift; # element-ref
		$new_element = $iter_start->p_container()->factory(data => $new_element)
			unless (ref($new_element) && $new_element->isa('Class::STL::Element'));
		_usage_check('replace_copy_if', 'IIIFE', $iter_start, $iter_finish, $iter_result, $function, $new_element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
#? 				Insert tree here???
				replace_copy_if($iter->p_element()->begin(), $iter->p_element()->end(), $iter_result, $function, $new_element); # its a tree -- recurse
			}
			else
			{
				$iter_result->p_container()->insert($iter_result, 1, 
					($function->function_operator($iter->p_element()) ? $new_element : $iter->p_element()));
			}
		}
		return;
	}
	sub replace_copy # (iterator, iterator, iterator, element-ref, element-ref) -- static function
	{
		my $iter_start = shift;
		my $iter_finish = shift;
		my $iter_result = shift;
		my $old_element = shift; # element-ref
		my $new_element = shift; # element-ref
		$old_element = $iter_start->p_container()->factory(data => $old_element)
			unless (ref($old_element) && $old_element->isa('Class::STL::Element'));
		$new_element = $iter_start->p_container()->factory(data => $new_element)
			unless (ref($new_element) && $new_element->isa('Class::STL::Element'));
		_usage_check('replace_copy', 'IIIEE', $iter_start, $iter_finish, $iter_result, $old_element, $new_element);
		for (my $iter = $iter_start->clone(); $iter <= $iter_finish; ++$iter)
		{
			if (ref($iter->p_element()) && $iter->p_element()->isa('Class::STL::Containers::Tree'))
			{
				replace_copy($iter->p_element()->begin(), $iter->p_element()->end(), $iter_result, $old_element, $new_element); # its a tree -- recurse
			}
			else
			{
				$iter_result->p_container()->insert($iter_result, 1, 
					($iter->p_element()->eq($old_element) ? $new_element : $iter->p_element()));
			}
		}
		return;
	}
#TODO:sub sort
#TODO:{
#TODO:}
#TODO:sub random_shuffle # ( [ random_number_generator ] )
#TODO:{
#TODO:}
#TODO:sub lower_bound
#TODO:{
#TODO:}
#TODO:sub upper_bound
#TODO:{
#TODO:}
	sub _usage_check
	{
		use Carp qw(confess);
		my $function_name = shift;
		my @format = split(//, shift);
		my $check=0;
		foreach my $arg (0..$#_) {
			confess "Undefined arg $arg"
				if ($format[$arg] ne 'S' && !ref($_[$arg]));
			++$check 
				if 
				(
					defined($_[$arg]) 
					&& 
					(
						($format[$arg] eq 'I' && $_[$arg]->isa('Class::STL::Iterators::Abstract'))
						|| ($format[$arg] eq 'F' && $_[$arg]->isa('Class::STL::Utilities::FunctionObject'))
						|| ($format[$arg] eq 'B' && $_[$arg]->isa('Class::STL::Utilities::FunctionObject::BinaryFunction'))
						|| ($format[$arg] eq 'U' && $_[$arg]->isa('Class::STL::Utilities::FunctionObject::UnaryFunction'))
						|| ($format[$arg] eq 'G' && $_[$arg]->isa('Class::STL::Utilities::FunctionObject::Generator'))
						|| ($format[$arg] eq 'E' && $_[$arg]->isa('Class::STL::Element'))
						|| ($format[$arg] eq 'S' && !ref($_[$arg])) # Scalar
					)
				)
		}
		if ($check != int(@_)) {
			use Carp qw(confess);
			my @anames;
			foreach (@format) { 
				push(@anames, 'scalar') if (/S/);
				push(@anames, 'iterator') if (/I/);
				push(@anames, 'function-object') if (/F/);
				push(@anames, 'unary-function-object') if (/U/);
				push(@anames, 'generator-function-object') if (/G/);
				push(@anames, 'binary-function-object') if (/B/);
				push(@anames, 'element-ref') if (/E/);
			}
			confess "@{[ __PACKAGE__]}::$function_name usage:\n$function_name( @{[ join(', ', @anames) ]});\n"
		}
		return 1;
	}
}
# ----------------------------------------------------------------------------------------------------
1;
