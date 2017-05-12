# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::Element.pm
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
# 14/03/2006	0.02		mg		Fixed Class::STL::Element->new() function.
# ----------------------------------------------------------------------------------------------------
# TO DO:
# ----------------------------------------------------------------------------------------------------
require 5.005_62;
use strict;
use warnings;
use vars qw($VERSION $BUILD);
use Class::STL::ClassMembers::DataMember;
use Class::STL::ClassMembers::FunctionMember;
$VERSION = '0.19';
$BUILD = 'Saturday May 6 17:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::Element;
	use UNIVERSAL qw(isa can);
	use Carp qw(confess);
	use Class::STL::ClassMembers qw( data ),
		Class::STL::ClassMembers::DataMember->new(name => 'data_type', default => 'string',
			validate => '^(string|array|numeric|ref)$');
	use Class::STL::ClassMembers::Constructor;
	sub new_extra # static function
	{
		my $self = shift;
		while (@_)
		{
			my $p = shift;
			if (!ref($p) && exists(${$self->members()}{$p}))
			{
				shift;
			}
			elsif (!ref($p) && scalar @_ != 0) {
				shift;
			}
			else {
				$self->data($p); # new(<scalar>) called.
			}
		}
		return $self;
	}
	sub eq # (element)
	{
		my $self = shift;
		my $other = shift;
		return defined($self->data()) && ref($self->data()) && $self->data()->can('eq')
			? $self->data()->eq($other)
			: $self->data_type() eq 'string'
				? defined($self->data()) && defined($other->data()) && $self->data() eq $other->data()
				: defined($self->data()) && defined($other->data()) && $self->data() == $other->data();
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
		return defined($self->data()) && ref($self->data()) && $self->data()->can('gt')
			? $self->data()->gt($other)
			: $self->data_type() eq 'string'
				? defined($self->data()) && defined($other->data()) && $self->data() gt $other->data()
				: defined($self->data()) && defined($other->data()) && $self->data() > $other->data();
	}
	sub lt # (element)
	{
		my $self = shift;
		my $other = shift;
		return defined($self->data()) && ref($self->data()) && $self->data()->can('lt')
			? $self->data()->lt($other)
			: $self->data_type() eq 'string'
				? defined($self->data()) && defined($other->data()) && $self->data() lt $other->data()
				: defined($self->data()) && defined($other->data()) && $self->data() < $other->data();
	}
	sub ge # (element)
	{
		my $self = shift;
		my $other = shift;
		return defined($self->data()) && ref($self->data()) && $self->data()->can('ge')
			? $self->data()->ge($other)
			: $self->data_type() eq 'string'
				? defined($self->data()) && defined($other->data()) && $self->data() ge $other->data()
				: defined($self->data()) && defined($other->data()) && $self->data() >= $other->data();
	}
	sub le # (element)
	{
		my $self = shift;
		my $other = shift;
		return defined($self->data()) && ref($self->data()) && $self->data()->can('le')
			? $self->data()->le($other)
			: $self->data_type() eq 'string'
				? defined($self->data()) && defined($other->data()) && $self->data() le $other->data()
				: defined($self->data()) && defined($other->data()) && $self->data() <= $other->data();
	}
	sub cmp # (element)
	{
		my $self = shift;
		my $other = shift;
		return $self->eq($other) ? 0 : $self->lt($other) ? -1 : 1;
	}
	sub mod # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('mod')
			? $self->data()->mod($other)
			: $self->data($self->data() % $other->data());
	}
	sub add # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('add')
			? $self->data()->add($other)
			: $self->data($self->data() + $other->data());
	}
	sub subtract # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('subtract')
			? $self->data()->subtract($other)
			: $self->data($self->data() - $other->data());
	}
	sub mult # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('mult')
			? $self->data()->mult($other)
			: $self->data($self->data() * $other->data());
	}
	sub div # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('div')
			? $self->data()->div($other)
			: $self->data($self->data() / $other->data());
	}
	sub and # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('and')
			? $self->data()->and($other)
			: $self->data() && $other->data();
	}
	sub or # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('or')
			? $self->data()->or($other)
			: $self->data() || $other->data();
	}
	sub match # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('match')
			? $self->data()->match($other)
			: $self->data() =~ /@{[ $other->data() ]}/;
	}
	sub match_ic # (element)
	{
		my $self = shift;
		my $other = shift;
		return ref($self->data()) && $self->data()->can('match_ic')
			? $self->data()->match_ic($other)
			: $self->data() =~ /@{[ $other->data() ]}/i;
	}
	sub neg # (void)
	{
		my $self = shift;
		return ref($self->data()) && $self->data()->can('neg')
			? $self->data()->neg()
			: $self->data(-($self->data()));
	}
	sub print # (void)
	{
		my $self = shift;
		return ref($self->data()) && $self->data()->can('print')
			? $self->data()->print()
			: $self->data();
	}
}
# ----------------------------------------------------------------------------------------------------
1;
