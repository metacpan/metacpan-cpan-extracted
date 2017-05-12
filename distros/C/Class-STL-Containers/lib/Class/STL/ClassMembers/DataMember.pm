# vim:ts=4 sw=4
# ----------------------------------------------------------------------------------------------------
#  Name		: Class::STL::ClassMembers::DataMember.pm
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
use vars qw( $VERSION $BUILD );
$VERSION = '0.26';
$BUILD = 'Monday May 15 23:08:34 GMT 2006';
# ----------------------------------------------------------------------------------------------------
{
	package Class::STL::ClassMembers::DataMember;
	use Carp qw(confess);
	sub new
	{
		my $proto = shift;
		return $_[0]->clone() if (ref($_[0]) && $_[0]->isa(__PACKAGE__));
		my $class = ref($proto) || $proto;
		my $self = {};
		bless($self, $class);
		$self->members_init(_caller => (caller())[0], @_);
		return $self;
	}
	sub code_meminit
	{
		my $self = shift;
		my $n = $self->name();
		return defined($self->default())
			? "\$self->$n(exists(\$p{'$n'}) ? \$p{'$n'} : '@{[ $self->default() ]}');"
			: "\$self->$n(\$p{'$n'}) if (exists(\$p{'$n'}));";
	}
	sub code_memaccess
	{
		my $self = shift;
		my $member = shift;
		my $n = $self->name();
#<		my $c = $self->_caller_str();
		my $tab = ' ' x 4;
		my $code = "sub $n { # Data Member\n";
		$code .= "${tab}my \$self = shift;\n";
		$code .= "${tab}use Carp qw(confess);\n";
		$code .= "${tab}my \$v = shift;\n";
		$code .= "${tab}if (defined(\$v) && ref(\$v) eq 'ARRAY') {\n";
		$code .= "${tab}${tab}\$self->{@{[ uc($n) ]}} = [];\n";
		$code .= "${tab}${tab}foreach (\@{\$v}) {\n";
		if (defined($self->validate())) {
			$code .= "${tab}${tab}${tab}confess \"**Field '$n' value '\$_' failed validation ('\" . '@{[ $self->validate() ]}' . \"')\"\n";
			$code .= "${tab}${tab}${tab}${tab}unless (!defined(\$_) || \$_ =~ /@{[ $self->validate() ]}/);\n";
		}
		$code .= "${tab}${tab}${tab}push(\@{\$self->{@{[ uc($n) ]}}}, ref(\$_) && \$_->can('clone') ? \$_->clone() : \$_);\n";
		$code .= "${tab}${tab}}\n";
		$code .= "${tab}}\n";

		$code .= "${tab}else {\n";

		if (defined($self->validate())) {
			$code .= "${tab}${tab}confess \"**Field '$n' value '\$v' failed validation ('\" . '@{[ $self->validate() ]}' . \"')\"\n";
			$code .= "${tab}${tab}${tab}unless (!defined(\$v) || \$v =~ /@{[ $self->validate() ]}/);\n";
		}
		$code .= "${tab}${tab}\$self->{@{[ uc($n) ]}} = \$v if (defined(\$v));\n";
		$code .= "${tab}}\n";
	
		$code .= "${tab}return \$self->{@{[ uc($n) ]}};\n";
		$code .= "}\n";
		return $code;
	}
	sub code_memattr
	{
		my $self = shift;
		my $code = "@{[ $self->name() ]} => [ " 
			. "'@{[ defined($self->default()) ? $self->default() : q## ]}', "
			. "'@{[ defined($self->validate()) ? $self->validate() : q## ]}',"
			. "'@{[ ref($self) ]}'" 
			. " ]";
		return $code;	
	}
	sub code_memdata
	{
		my $self = shift;
		return "@{[ $self->name() ]} => \$self->{@{[ uc($self->name()) ]}}";
	}
	sub _caller_str
	{
		my $self = shift;
		my $str = $self->_caller();
		$str =~ s/[:]+/_/g;
		return $str;
	}
	sub name {
		my $self = shift;
		$self->{NAME} = shift if (@_);
		return $self->{NAME};
	}
	sub default {
		my $self = shift;
		$self->{DEFAULT} = shift if (@_);
		return $self->{DEFAULT};
	}
	sub validate {
		my $self = shift;
		$self->{VALIDATE} = shift if (@_);
		return $self->{VALIDATE};
	}
	sub _caller {
		my $self = shift;
		$self->{_CALLER} = shift if (@_);
		return $self->{_CALLER};
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
		$self->name($p{'name'}) if (exists($p{'name'}));
		$self->default($p{'default'}) if (exists($p{'default'}));
		$self->validate($p{'validate'}) if (exists($p{'validate'}));
		$self->_caller($p{'_caller'}) if (exists($p{'_caller'}));
	}
	sub member_print {
		my $self = shift;
		my $delim = shift || '|';
		return join("$delim",
			"name=@{[ defined($self->name()) ? $self->name() : 'NULL' ]}",
			"default=@{[ defined($self->default()) ? $self->default() : 'NULL' ]}",
			"validate=@{[ defined($self->validate()) ? $self->validate() : 'NULL' ]}",
			"_caller=@{[ defined($self->_caller()) ? $self->_caller() : 'NULL' ]}",
		);
	}
	sub members_local { # static function
		return {
			name=>[ ],
			default=>[ ],
			validate=>[ ],
			_caller=>[ ],
		};
	}
	sub members {
		my $self = shift;
		use vars qw(@ISA);
		my $super = (int(@ISA)) ? $self->SUPER::members() : {};
		return keys(%$super)
		? {
			%$super,
			name=>[ ],
			default=>[ ],
			validate=>[ ],
			_caller=>[ ],
		}
		: {
			name=>[ ],
			default=>[ ],
			validate=>[ ],
			_caller=>[ ],
		};
	}
	sub swap {
		my $self = shift;
		my $other = shift;
		use vars qw(@ISA);
		my $tmp = $self->clone();
		$self->SUPER::swap($other) if (int(@ISA));
		$self->name($other->name());
		$self->default($other->default());
		$self->validate($other->validate());
		$self->_caller($other->_caller());
		$other->name($tmp->name());
		$other->default($tmp->default());
		$other->validate($tmp->validate());
		$other->_caller($tmp->_caller());
	}
	sub clone {
		my $self = shift;
		use vars qw(@ISA);
		my $clone = int(@ISA) ? $self->SUPER::clone() : $self->new();
		$clone->name($self->name());
		$clone->default($self->default());
		$clone->validate($self->validate());
		$clone->_caller($self->_caller());
		return $clone;
	}
	sub undefine {
		my $self = shift;
		map($self->{"@{[ uc($_) ]}"} = undef, @_);
	}
}
1;
