# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::ClassMembers.pm
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
$VERSION = '0.26';
$BUILD = 'Monday May 15 23:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::ClassMembers;
	use UNIVERSAL qw(isa can);
	use Carp qw(confess);
	use Class::STL::Trace;
	sub import
	{
		my $proto = shift;
		my $class = ref($proto) || $proto;
		my $self = {};
		bless($self, $class);
		$self->_caller((caller())[0]);
		$self->_trace(Class::STL::Trace->new(debug_on => 0));
		$self->{MEMBERS} = { };
		$self->_members(grep(!ref($_) || (ref($_) && !$_->isa('Class::STL::ClassMembers::FunctionMember::Abstract')), @_));
		$self->_code([]);
		push(@{$self->_code()}, 
			map($_->code($self->_caller()), 
				grep(ref($_) && $_->isa('Class::STL::ClassMembers::FunctionMember::Abstract'), @_))); 
		$self->_prepare();
		return $self;
	}
	sub memlist
	{
		my $self = shift;
		return values(%{$self->_members()});
	}
	# ----------------------------------------------------------------------------------------------------
	# PRIVATE
	# ----------------------------------------------------------------------------------------------------
	sub _prepare
	{
		my $self = shift;
		$self->code_members_access();
		$self->code_members_init();
		$self->code_members_print();
		$self->code_members_local();
		$self->code_members_data();
		$self->code_members();
		$self->code_swap();
		$self->code_clone();
		$self->code_undefine();
#<		$self->code_factory();

		unshift(@{$self->_code()}, "{\npackage @{[ $self->_caller() ]};\n");
		push(@{$self->_code()}, "}\n");

		$self->_trace()->print($self->_caller(), join("", @{$self->_code()})) if ($self->_trace()->debug_on());
		eval(join("", @{$self->_code()}));
		confess "**Error in eval for @{[ $self->_caller() ]} ClassMembers functions creation:\n$@" if ($@);
	}
	sub _code
	{
		my $self = shift;
		$self->{CODE} = shift if (@_);
		return $self->{CODE};
	}
	sub _trace
	{
		my $self = shift;
		$self->{_TRACE} = shift if (@_);
		return $self->{_TRACE};
	}
	sub _caller
	{
		my $self = shift;
		$self->{CALLER} = shift if (@_);
		return $self->{CALLER};
	}
	sub _caller_str
	{
		my $self = shift;
		my $str = $self->_caller();
		$str =~ s/[:]+/_/g;
		return $str;
	}
	sub _members
	{
		my $self = shift;
		foreach (@_) {
			my $m = ref($_) ? $_
				: Class::STL::ClassMembers::DataMember->new(name => $_, _caller => $self->_caller());
			$self->{MEMBERS}->{$m->name()} = $m;
		}
		return $self->{MEMBERS};
	}
#>	sub code_get_set
#>	{
#>		#TODO: get(<member name list>) -- returns array with mebers' values
#>		#		set(<member>, <value>, ...) -- sets member(s) value(s)
#>	}
	sub code_members_access
	{
		my $self = shift;
		map(push(@{$self->_code()}, $_->code_memaccess($_)), values(%{$self->_members()}));
		return;
	}
	sub code_members_init
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code = "sub members_init {\n";	# --> BUILDALL
		$code .= "${tab}my \$self = shift;\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}if (int(\@ISA) && (caller())[0] ne __PACKAGE__) {\n";
		$code .= "${tab}${tab}\$self->SUPER::members_init(\@_);\n";
		$code .= "${tab}}\n";
		if (keys(%{$self->_members()})) {
			$code .= "${tab}my \@p;\n";
			$code .= "${tab}while (\@_) { my \$p=shift; push(\@p, \$p, shift) if (!ref(\$p)); }\n";
			$code .= "${tab}my \%p = \@p;\n";
			$code .= "${tab}@{[ join(\"\n    \", map($_->code_meminit(), values( %{$self->_members()} ))) ]}\n";
		}
		$code .= "}\n";
		push(@{$self->_code()}, $code);
		return;
	}
	sub code_members_print
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code = "sub members_print {\n";
		$code .= "${tab}my \$self = shift;\n";
		$code .= "${tab}my \$delim = shift || '|';\n";
		if (keys(%{$self->_members()})) {
			$code .= "${tab}return join(\"\$delim\",\n${tab}${tab}";
			$code .= 
				join(qq/,\n$tab$tab/, 
					map
					(
						qq/"$_=\@{[ defined(\$self->$_()) ? \$self->$_() : 'NULL' ]}"/, 
						sort(keys(%{$self->_members()}))
					)
				);
			$code .= "\n${tab});\n";
		} else {
			$code .= "${tab}return '';\n";
		}
		$code .= "}\n";
		push(@{$self->_code()}, $code);
		return;
	}
	sub code_members_local
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code = "sub members_local { # static function\n";
		if (keys(%{$self->_members()})) {
			$code .= "${tab}return {\n${tab}${tab}";
			$code .= join(",\n${tab}${tab}", map($_->code_memattr(), values(%{$self->_members()})));
			$code .= "\n${tab}};\n";
		} else {
			$code .= "${tab}return {};\n";
		}
		$code .= "}\n";
		push(@{$self->_code()}, $code);
		return;
	}
	sub code_members_data
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code = "sub memdata {\n";
		$code .= "${tab}my \$self = shift;\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}my \$super = (int(\@ISA))";
		$code .= " ? \$self->SUPER::memdata() : {};\n";
		if (keys(%{$self->_members()})) {
			$code .= "${tab}return {\n${tab}${tab}";
			$code .= "\%\$super,\n${tab}${tab}";
			$code .= join(",\n${tab}${tab}", map($_->code_memdata(), values(%{$self->_members()})));
			$code .= "\n${tab}};\n";
		} else {
			$code .= "${tab}return {\%\$super};\n";
		}
		$code .= "}\n";
		push(@{$self->_code()}, $code);
		return;
	}
	sub code_members
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code = "sub members {\n";
		$code .= "${tab}my \$self = shift;\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}my \$super = (int(\@ISA))";
		$code .= " ? \$self->SUPER::members() : {};\n";
    	$code .= "${tab}return keys(\%\$super)\n${tab}? {\n${tab}${tab}";
		$code .= "\%\$super,\n${tab}${tab}";
		$code .= join(",\n${tab}${tab}", map($_->code_memattr(), values(%{$self->_members()})));
		$code .= "\n${tab}}\n";
    	$code .= "${tab}: {\n${tab}${tab}";
		$code .= join(",\n${tab}${tab}", map($_->code_memattr(), values(%{$self->_members()})));
		$code .= "\n${tab}};\n";
		$code .= "}\n";
		push(@{$self->_code()}, $code);
		return;
	}
	sub code_swap
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code = "sub swap {\n";
		$code .= "${tab}my \$self = shift;\n";
		$code .= "${tab}my \$other = shift;\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}my \$tmp = \$self->clone();\n";
		$code .= "${tab}\$self->SUPER\::swap(\$other) if (int(\@ISA));\n";
		if (keys(%{$self->_members()})) {
			$code .= "${tab}@{[ join(qq#\n${tab}#, 
				map(qq#\$self->$_(\$other->$_());#, keys( %{$self->_members()} ) )) ]}\n";
			$code .= "${tab}@{[ join(qq#\n${tab}#, 
				map(qq#\$other->$_(\$tmp->$_());#, keys( %{$self->_members()} ) )) ]}\n";
		}
		$code .= "}\n";
		push(@{$self->_code()}, $code);
		return;
	}
	sub code_clone
	{
		my $self = shift;
		my $tab = ' ' x 4;
		my $code = "sub _clone {\n";
		$code .= "${tab}my \$self = shift;\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}my \$clone = int(\@ISA) ? \$self->SUPER\::_clone() : \$self->_new();\n";
		if (keys(%{$self->_members()})) {
			$code .= "${tab}@{[ join(qq#\n${tab}#, 
				map(qq#\$clone->$_(\$self->$_());#, keys( %{$self->_members()} ) )) ]}\n";
		}
		$code .= "${tab}return \$clone;\n";
		$code .= "}\n";
		$code .= "sub clone {\n";
		$code .= "${tab}my \$self = shift;\n";
		$code .= "${tab}use vars qw(\@ISA);\n";
		$code .= "${tab}my \$clone = int(\@ISA) ? \$self->SUPER\::clone() : \$self->new();\n";
		if (keys(%{$self->_members()})) {
			$code .= "${tab}@{[ join(qq#\n${tab}#, 
				map(qq#\$clone->$_(\$self->$_());#, keys( %{$self->_members()} ) )) ]}\n";
		}
		$code .= "${tab}return \$clone;\n";
		$code .= "}\n";
		push(@{$self->_code()}, $code);
		return;
	}
	sub code_undefine
	{
		my $self = shift;
		my $tab = ' ' x 4;
#<		my $c = $self->_caller_str();
		my $code = "sub undefine {\n${tab}my \$self = shift;\n";
		$code .= "${tab}map(\$self->{\"\@{[ uc(\$_) ]}\"} = undef, \@_);\n";
		$code .= "}\n";
		push(@{$self->_code()}, $code);
		return;
	}
#?	sub code_factory
#?	{
#?		my $self = shift;
#?		return unless exists ${$self->_members()}{'element_type'};
#?		my $m = $self->_members()->{'element_type'};
#?		my $tab = ' ' x 4;
#?		my $code = "sub factory {\n";
#?		$code .= "${tab}my \$self = shift;\n";
#?		$code .= "${tab}return @{[ $m->default() ]}->new(\@_);\n";
#?		$code .= "}\n";
#?		push(@{$self->_code()}, $code);
#?		return;
#?	}
}
# ----------------------------------------------------------------------------------------------------
1;
