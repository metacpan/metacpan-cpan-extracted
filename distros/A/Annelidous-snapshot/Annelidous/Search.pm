#!/usr/bin/perl
#
# Annelidous - the flexibile cloud management framework
# Copyright (C) 2009  Eric Windisch <eric@grokthis.net>
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

package Annelidous::Search;

use strict;

#use DBI;

sub new {
	my $class=shift;
	my $self={
		subclass=>undef,
		@_
	};

	#
	# If we were given a subclass, then return an object of that
	# subclass instead.  This way, for instance, you can create a new
	# search based on the Annelidous::Search::XenCfgDir module with the
	# following code:
	#	
	# PERL> new Annelidous::Search(subclass=>'Annelidous::Search::XenCfgDir')
	#
	# While users could just do this directly, doing it this way allows
	# code based on this module to store the subclass as a configuration
	# variable and just pass the "hard" work to us.
	#
	if (defined($self->{subclass})) {
		eval { 
			require $self->{subclass};
			$self=$self->{subclass}->new;
		};
		if ($@) {
			return {};
		}
	} else {
		bless $self, $class;
	}

	if (defined($self->{'-dbh'})) {
		$self->{'dbh'}=$self->{'-dbh'};
	}

	return $self;
}

# DBI gives us a nice easy way to do this, but
# it is ugly, so I wrapped it up in a nice package.
sub db_fetch {
	my $self=shift;
    my $statement=shift;
    return @{$self->{-dbh}->selectall_arrayref($statement,{ Slice=>{} }, @_)};
}

#
# Generic function to find a group/batch,
# given a search method and a list of search terms...
#
sub find_group {
	my $self=shift;
    my $method=shift;
    my @terms=@_;
    my @result_set;
    foreach my $t (@terms) {
        eval("push \@result_set, find_".$method."(\$t);");
    }
    return @result_set;
}

1;
