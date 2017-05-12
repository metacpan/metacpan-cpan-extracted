## Babble/Processors/Extra.pm
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

package Babble::Processors::Extra;

use strict;
use Babble::Encode;
use Date::Manip;
use Data::Dumper;

=pod

=head1 NAME

Babble::Processors::Extra - Extra processors for Babble

=head1 SYNOPSIS

 use Babble;
 use Babble::Processors::Extra;

 my $babble = Babble->new
    (-processors => [ \&Babble::Processors::Extra::creator_map ]);
 $babble->add_sources (Babble::DataSource::RSS->new (
    -location => $some_location,
    -creator_map => { joe => { author => "Joe R. Blogger" } }));

=head1 DESCRIPTION

C<Babble::Processors::Extra> is a collection of optional, yet useful
processors for Babble. In some circumstances, one might wish to use
them. However, none of these are enabled by default, since they
usually require some configuration.

=head1 METHODS

=over 4

=item creator_map()

This processor takes the B<-creator_map> field of the I<source> and if
an items creator matches a key of it, adds all the keys from the hash
pointed to by the source's key to the item.

=cut

sub creator_map {
	my ($item, $channel, $source, undef) = @_;

	return unless defined $$source->{-creator_map}->{$$item->{author}};

	map {
		$$item->{$_} = to_utf8
			($$source->{-creator_map}->{$$item->{author}}->{$_});
	} keys (%{$$source->{-creator_map}->{$$item->{author}}});
}

=pod

=item parent_map()

This processor takes the B<-parent_map> field of the I<source> and
copies all fields listed in B<-parent_map> from the I<channel>, to the
current I<item>.

=cut

sub parent_map {
	my ($item, $channel, $source) = @_;

	return unless defined $$source->{-parent_map};

	map {
		$$item->{parent}->{$_} = to_utf8 ($$channel->{$_});
	} @{$$source->{-parent_map}};
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble, Babble::Processors

=cut

1;

# arch-tag: 11829b85-9461-43b2-86b3-436a3a84eb35
