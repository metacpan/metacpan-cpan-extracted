## Babble/DataSource.pm
## Copyright (C) 2004 Gergely Nagy <algernon@bonehunter.rulez.org>
##
## This file is part of Babble.
##
## Babble is free software; you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation; version 2 dated June, 1991.
##
## Babble is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
## FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
## for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

package Babble::DataSource;

use strict;
use Carp;

use Exporter ();
use vars qw(@ISA);
@ISA = qw(Exporter);

=pod

=head1 NAME

Babble::DataSource - Base data source class for Babble

=head1 DESCRIPTION

Babble::DataSource is a base class, a class which should never ever
be used directly by applications (as it does nothing useful).

This class is merely provided to be a base to inherit from. All
descendants must implement at least the methods this class implements.

=head1 METHODS

The following methods are required to be implemented by all
Babble::DataSource descendants:

=over 4

=item I<new>(B<%params>)

Obviously, this creates a new object. The new object should in all
cases, call SUPER::new, as to get their params stored. Then, it can go
an interpret them as it sees fit.

=cut

sub new {
	my $type = shift;
	my %params = @_;
	my $self = \%params;

	croak "$type->new() called without -location argument"
		unless $self->{-location};

	bless $self, $type;
}

=pod

=item I<collect>(B<$babble>)

This method does whatever is necessary to collect the data from the
source, and then return a Babble::Document::Collection object.

The only paramater passed, is a Babble object reference.

=cut

sub collect () {
	croak "collect() unimplemented in this class!";
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble::Document::Collection, Babble::DataSource::HTML,
Babble::DataSource::FlatFile

=cut

1;

# arch-tag: 6622810e-6e45-47e9-9e90-d243135e163b
