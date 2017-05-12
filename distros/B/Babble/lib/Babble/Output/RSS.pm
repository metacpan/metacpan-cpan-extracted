## Babble/Output/RSS.pm
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

package Babble::Output::RSS;

use strict;
use XML::RSS;
use Date::Manip;

use Babble::Output;

use Exporter ();
use vars qw(@ISA);
@ISA = qw(Babble::Output);

=pod

=head1 NAME

Babble::Output::RSS - RSS output method for Babble

=head1 SYNOPSIS

 use Babble;

 my $babble = Babble->new ();
 ...
 print $babble->output (-type => "RSS",
			meta_title => "Example Babble",
			meta_desc => "This is an example babble");

=head1 DESCRIPTION

This module implements the RSS output method for C<Babble>, thus, it
only has one method: output(), which generates RSS 1.0 output from the
available items.

=head1 METHODS

=over 4

=item I<output>(B<$babble>, B<$params>)

This output method recognises the following arguments, either via the
passed C<Babble> objects ->{Params} hashref, or via %params:

=over 4

=item meta_title

The name of the Babble, used as the RSS channel title.

=item meta_desc

A short description of the Babble, used as the RSS channel
description.

=item meta_link

A link to the site for which the RSS is a feed, used as the RSS
channel link.

This is an optional argument.

=item meta_owner_email

The e-mail of the Babble owner, used as the RSS channel creator.

This too, is an optional argument.

=item meta_image

An image associated with the feed. This must be a HASH reference,
containing at least the B<url> and B<link> keys. The B<title>,
B<width> ad B<height> keys are also recognised.

=back

=cut

sub output {
	my ($self, $babble, $params) = @_;
	my %args;

	foreach ("meta_title", "meta_desc", "meta_link", "meta_owner_email",
		 "meta_subject", "meta_image") {
		$args{$_} = $params->{$_} || $$babble->{Params}->{$_} || "";
	}

	my $rss = new XML::RSS (version => '1.0', encode_output => 0);

	$rss->channel (title => "<![CDATA[" . $args{meta_title} . "]]>",
		       link => $args{meta_link},
		       description => "<![CDATA[" . $args{meta_desc} . "]]>",
		       dc => {
			      date => UnixDate ("today",
						"%Y-%m-%dT%H:%M:%S+00:00"),
			      creator =>
			       $args{meta_owner_email}
			     }
		      );
	$rss->image (%{$args{meta_image}}) if $args{meta_image};

	foreach my $item ($$babble->sort ()) {
		$rss->add_item (
			title => "<![CDATA[" . $item->{title} . "]]>",
			link => $item->{id},
			description => "<![CDATA[" . $item->{content} . "]]>",
			dc => {
				creator => $item->{author},
				subject => $item->{subject},
				date => $item->date_rss()
			}
		);
	}

	return $rss->as_string;
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble, Babble::Output, XML::RSS

=cut

1;

# arch-tag: f5e9f983-b02a-4c47-af6a-d7567eb0c8a8
