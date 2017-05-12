# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: stl.pm
#  Created	: 28 April 2006
#  Author	: Mario Gaffiero (gaffie)
#
# Copyright 2006 Mario Gaffiero.
# 
# This file is part of Class::STL::Containers(TM).
# 
# Class::STL::Containers is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# 
# Class::STL::Containers is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Class::CodeStyler; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
# ----------------------------------------------------------------------------------------------------
# Modification History
# When          Version     Who     What
# ----------------------------------------------------------------------------------------------------
package stl;
require 5.005_62;
use strict;
use warnings;
use vars qw( $VERSION $BUILD @EXPORT_OK %EXPORT_TAGS);
use Exporter;
my @containers = qw(
	vector list deque queue priority_queue stack tree
);
my @utilities = qw(
	equal_to not_equal_to greater greater_equal less 
	less_equal compare bind1st bind2nd mem_fun ptr_fun 
	ptr_fun_binary matches matches_ic logical_and logical_or 
	multiplies divides plus minus modulus not1 not2 negate not_null
);
my @algorithms = qw(
	find find_if for_each transform count count_if copy 
	copy_backward remove remove_if remove_copy remove_copy_if replace 
	replace_if replace_copy replace_copy_if generate generate_n 
	fill fill_n equal reverse reverse_copy rotate rotate_copy partition 
	stable_partition min_element max_element unique unique_copy adjacent_find
	_sort stable_sort qsort stable_qsort accumulate
);
my @iterators = qw(
	iterator bidirectional_iterator reverse_iterator forward_iterator 
	distance advance back_insert_iterator front_insert_iterator 
	back_inserter front_inserter insert_iterator inserter 
);

@EXPORT_OK = ( @containers, @utilities, @algorithms, @iterators );
%EXPORT_TAGS = (
	algorithms => [@algorithms],
	containers => [@containers],
	utilities => [@utilities],
	iterators => [@iterators],
);
use Class::STL::Containers qw(:all);
use Class::STL::Utilities qw(:all);
use Class::STL::Algorithms qw(:all);
use Class::STL::Iterators qw(:all);
$VERSION = $Class::STL::Containers::VERSION;
$BUILD = $Class::STL::Containers::BUILD;
# ----------------------------------------------------------------------------------------------------
1;
