## Babble/Theme/XML.pm
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

package Babble::Theme::XML;

use strict;

use Date::Manip;

use Babble::Theme;
use Babble::Output::TTk;

use vars qw(@ISA);
@ISA = qw(Babble::Theme);

=pod

=head1 NAME

Babble::Theme::XML - XML theme for Babble

=head1 DESCRIPTION

This theme provides an easy way to output FOAF and OPML subscription
rolls for a given Babble. Not needing any kind of style, this theme is
rather easy to configure.

=head1 TEMPLATE VARIABLES

The following variables are used by the template (variables coming
from Babble::Document or Babble::Document::Collection sources are not
listed here!)

=over 4

=item meta_title

The title of the Babble

=item meta_owner_email

E-Mail address of the Babble maintainer.

=item meta_owner

Name of the Babble maintainer.

=item meta_foafroll_link

Link to the FOAF feed the Babble provides.

=item meta_link

Link to the homepage of the Babble.

=item meta_image

An image associated with the feed. This must be a HASH reference,
containing at least the B<url> and B<link> keys. The B<title>,
B<width> ad B<height> keys are also recognised.

This is only supported by the I<rss10> and I<rss20> formats.

=back

=head1 METHODS

=over 4

=item output()

This method sets up parameters for the Babble::Output::TTK-E<gt>output
method. It recognises only the I<-format> option, which determines
which output format is used. Currently B<foaf>, B<opml>, B<rss10> and
B<rss20> are provided by the theme.

=cut

sub output {
	my ($self, $babble, $params) = @_;

	$self->_merge_params
		($babble, $params,
		 {
			 -template => $self->_find_template ('XML',
						     $params->{-format}),
			 UnixDate => \&UnixDate,
			 ParseDate => \&ParseDate,
		 }
	 );

	return Babble::Output::TTk->output ($babble, $params);
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble::Theme, Babble::Output::TTk

=cut

1;

# arch-tag: 68f59e2d-8761-4fbf-bece-d345690dea1e
