## Babble/Theme/advogato.pm
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

package Babble::Theme::advogato;

use strict;
use Babble::Theme;
use Babble::Output::TTk;

use vars qw(@ISA);
@ISA = qw(Babble::Theme);

=pod

=head1 NAME

Babble::Theme::advogato - Advogato inspired theme for Babble

=head1 DESCRIPTION

The advogato theme was inspired by the L<http://advogato.org/> theme,
and builds upon that style heavily. It provides quite a few features,
but is more suited for smaller collections.

=head1 TEMPLATE VARIABLES

The following variables are used by the template (variables coming
from Babble::Document or Babble::Document::Collection sources are not
listed here!)

=over 4

=item meta_title

The title of the Babble

=item meta_blurb_text

Optional extra text in the banner are.

=item meta_desc

Optional description of the babble.

=item meta_css_link

Optional, but recommended, link to the CSS stylesheet to use. Defaults
to I<advogato.css>.

=item meta_charset

Optional charset.

=item meta_about_text

A few words about the Babble. If not specified, a default text is
used.

=item meta_owner_email

E-Mail address of the Babble maintainer.

=item meta_owner

Name of the Babble maintainer.

=item meta_feed_text

Optional text in the feed area. If not specified, a default text is
used.

=item meta_feed_link

Link to the feed the Babble provides.

=back

=head1 TEMPLATE KNOBS

=over 4

=item template_knob_no_sources

Turn off generating the I<Subscriptions> area in the sidebar.

=item template_knob_planetarium

Enables the Planetarium, a link collection to related or unrelated
sites (Babbles, planets and the like). When enabled, a I<planetarium>
paramater must be made available to the template. This should contain
an array of hashes. The layout should be as follows:

  planetarium => [ { name => 'Example', url => 'http://example.org/' } ]

=item template_knob_no_content_links

Disables linking to the entry sources. This is very handy when one
wants to generate a front page with news items, or when one is using
Babble to generate an original blog, instead of an aggregation.

=item template_knob_no_date

By default, after each entry, this theme places its submission
date. This can be turned off with this knob.

=back

=cut

sub output {
	my ($self, $babble, $params) = @_;

	$params->{-format} = "html" unless $params->{-format};

	$self->_merge_params
		($babble, $params,
		 {
			 -template => $self->_find_template ('advogato',
						     $params->{-format}),
			 meta_css_link => "advogato.css",
		 }
	 );

	return Babble::Output::TTk->output ($babble, $params);
}

=pod

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble::Theme, Babble::Output::TTk

=cut

1;

# arch-tag: c52c2c92-e0de-4ad3-a958-8ca6ecc70c69
