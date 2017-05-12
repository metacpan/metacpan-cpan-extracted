## Babble/Theme.pm
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

package Babble::Theme;

use strict;
use Babble::Output;

use Exporter ();
use vars qw(@ISA);
@ISA = qw(Babble::Output);

=pod

=head1 NAME

Babble::Theme - Base class for Babble themes

=head1 DESCRIPTION

This class is the base of all other themes. It provides methods to
make it easier to write themes. It shouldn't be used directly, ever.

=head1 METHODS

=over 4

=item _find_template()

Tries to find the filename of the template belonging to the theme
specified. The function goes through @INC to try and find
C<Babble/Theme/$theme/$theme.tmpl>. Returns the filename if found,
undef otherwise.

=cut

sub _find_template ($;$) {
	my ($self, $theme, $ext) = @_;
	if ($ext) {
		$ext = "." . $ext;
	} else {
		$ext = "";
	}

	foreach (@INC) {
		my $loc = $_ . "/Babble/Theme/" . $theme .
			"/" . $theme . $ext. ".tmpl";
		return $loc if -e $loc;
	}
	return undef;
}

=pod

=item _merge_params ()

Given a Babble object, and hashrefs of old and new params, attempts to
merge the three. That is, if a key in the new params hash is set, and
is not set in neither the old param hash, nor in the Babble object,
the old param set will be updated. Otherwise it is left untouched.

This way, one can set defaults for a theme.

=cut

sub _merge_params ($$$) {
	my ($self, $babble, $op, $np) = @_;

	foreach (keys %{$np}) {
		$op->{$_} = $np->{$_}
			unless $op->{$_} || $$babble->{Params}->{$_};
	}
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble::Output

=cut

1;

# arch-tag: d3bd6430-26af-4a25-821c-621e26ad4f93
