## Babble/DataSource/RSS.pm
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

package Babble::DataSource::RSS;

use strict;
use Encode;
use Carp;

use Babble::Encode;
use Babble::DataSource;
use Babble::Document;
use Babble::Document::Collection;
use Babble::Transport;

use XML::RSS;
use Date::Manip;

use vars qw(@ISA);
@ISA = qw(Babble::DataSource);

=pod

=head1 NAME

Babble::DataSource::RSS - RSS source fetcher for Babble

=head1 SYNOPSIS

 use Babble;
 use Babble::DataSource::RSS;

 my $babble = Babble->new ();
 $babble->add_sources (
	Babble::DataSource::RSS->new (
		-id => "Gergely Nagy",
		-location => "http://midgard.debian.net/~algernon/blog/index.xml"
	)
 );
 ...

=head1 DESCRIPTION

Babble::DataSource::RSS implements a Babble data source class that
parses an arbitary RSS feed.

=head1 METHODS

=over 4

=item _rss_date_parse($date)

Attempts to parse a few date formats found in RSS feeds with which
Date::Manip can't do anything with.

Returns the date either in the new format, or the original.

=cut

sub _rss_date_parse ($) {
	my ($self, $date) = @_;

	if ($date =~ /(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}):(\d{2})Z/) {
		$date = "$1 $2:00+$3:00";
	} elsif ($date =~ /(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})+(\d{2}:\d{2})/) {
		$date = "$1 $2+$3";
	}

	return $date;
}

=pod

=item collect_rss([$babble])

Collects the RSS feed, either from the network, or from the cache.

If a I<-cache_parsed> option was set when creating the object, the
parsed data will be stored in the cache. This can speed up processing
considreably, yet it needs much more memory too.

The only - optional - argument is a reference to a Babble object.

Returns the source feed (a string scalar) or undef on error.

=cut

sub collect_rss (;$)
{
	my ($self, $babble) = @_;
	my $feed;

	$feed = Babble::Transport->get ($self, $babble);
	return undef unless $feed;

	if ($self->{-cache_parsed} && $babble &&
	    Date_Cmp ($$babble->Cache->get ('Feeds', $self->{-location},
					    'time'),
		      $$babble->Cache->get ('Parsed', $self->{-location},
					    'time')) < 0) {
		# We should use the cache...
		return $$babble->Cache->get ('Parsed',
					     $self->{-location}, 'data');
	}
	return $feed;
}

=pod

=item feed_parse ($feed[, $babble])

Attempt to parse the feed, and store it in the cache, if so need be.

The first parameter passed to this method is a reference to the source
feed (a string scalar). The second, optional argument, is a reference
to a Babble object. Used to access the cache.

Returns an XML::RSS object, or undef on error.

=cut

sub feed_parse ($;$)
{
	my ($self, $feed, $babble) = @_;

	my $rss = XML::RSS->new ();

	eval { $rss->parse ($$feed) };
	if ($@) {
		carp $@;

		return undef unless $babble;

		# Right, so parsing failed. Lets see the cache.
		$feed = $$babble->Cache->get ('Feeds', $self->{-location},
					      'feed');
		eval { $rss->parse ($$feed) };
		if ($@) {
			# Ok, even the cache sucks, giving up.
			return undef;
		} else {
			carp "Cache contained valid data, using it.";
		}
	}

	# Cache the stuff
	if ($babble) {
		$$babble->Cache->set ('Feeds', $self->{-location}, 'feed',
				      $$feed);
		$$babble->Cache->set ('Feeds', $self->{-location}, 'time',
				      UnixDate ("now",
						"%a, %d %b %Y %H:%M:%S GMT"));
	}

	return $rss;
}

=pod

=item rss_channel_to_collection ($rss[, $babble])

Takes an XML::RSS object, and extracts information from it into a
Babble::Document::Collection object.

The first parameter to this method is a reference to an XML::RSS
object, the second - optional - one is a reference to a Babble object.

Returns a Babble::Document::Collection object.

=cut

sub rss_channel_to_collection ($;$)
{
	my ($self, $rss, $babble) = @_;
	my ($date, $subject, $author, $collection);
	my $image = {};

	if ($$rss->channel ('dc')) {
		$date = $$rss->channel ('dc')->{date} ||
			$$rss->channel ('pubDate') ||
			$$rss->channel ('dc')->{pubDate} ||
			"today";
		$author = $$rss->channel ('dc')->{creator} || $self->{-id};
		$subject = $$rss->channel ('dc')->{subject};
	} else {
		$date = $$rss->channel ('pubDate') || "today";
		$author = $self->{-id};
	}
	$date = $self->_rss_date_parse ($date);

	$image = {
		title => to_utf8 ($$rss->image ('title')),
		url => $$rss->image ('url'),
		link => $$rss->image ('link'),
		width => $$rss->image ('width'),
		height => $$rss->image ('height'),
	} if $$rss->image ('url');

	$collection = Babble::Document::Collection->new (
		author => to_utf8 ($author),
		title => to_utf8 ($$rss->channel ('title')),
		content => to_utf8 ($$rss->channel ('description')),
		subject => to_utf8 ($subject),
		id => $$rss->channel ('link'),
		link => $self->{-location},
		date => ParseDate ($date),
		name => to_utf8 ($self->{-id}),
		image => $image,
	);

	return $collection;
}

=pod

=item rss_item_to_document ($collection, $item[, $babble])

Converts an item, as stored by XML::RSS, to a Babble::Document.

The first parameter is a reference to a Babble::Document::Collection,
the second is a hash reference, and the last, optional argument is a
reference to a Babble object.

Returns a Babble::Document object.

=cut

sub rss_item_to_document ($$;$)
{
	my ($self, $collection, $item, $babble) = @_;
	my ($date, $author, $subject, $content, $doc);

	$date = $$item->{dc}->{date} || $$item->{pubDate} || $$item->{date} ||
		$$collection->{date};
	$date = $self->_rss_date_parse ($date);

	$author = $$item->{dc}->{creator} || $self->{-id};
	$subject = $$item->{dc}->{subject};

	$content = $$item->{description} ||
		$$item->{'http://purl.org/rss/1.0/modules/content/'}->{encoded};

	$doc = Babble::Document->new (
		author => to_utf8 ($author),
		date => ParseDate ($date),
		content => to_utf8 ($content),
		title => to_utf8 ($$item->{title}),
		id => $$item->{link},
		subject => to_utf8 ($subject),
	);

	return $doc;
}

=pod

=item rss_to_collection ($rss[, $babble])

Converts an XML::RSS object to a Babble::Document::Collection,
extracting meaningful data on the way.

This is mostly a wrapper around B<rss_channel_to_collection> and
B<rss_item_to_document>.

As such, the first parameter is a reference to an XML::RSS object,
while the optional second one is a reference to a Babble object.

Returns a Babble::Document::Collection object.

=cut

sub rss_to_collection ($$)
{
	my ($self, $rss, $babble) = @_;
	my $collection = $self->rss_channel_to_collection ($rss, $babble);

	foreach my $item (@{$$rss->{items}}) {
		push (@{$collection->{documents}},
		      $self->rss_item_to_document (\$collection, \$item,
					   $babble));
	}

	return $collection;
}

=pod

=item I<collect>([$babble])

This one does the bulk of the job, fetching the feed and parsing it,
then returning a Babble::Document::Collection object.

However, most of the work is delegated to B<collect_rss>,
B<feed_parse> and B<rss_to_collection>, for easier code reuse in
sub-classes.

=cut

sub collect ($) {
	my ($self, $babble) = @_;
	my ($rss, $collection, $feed);

	$feed = $self->collect_rss ($babble);
	return undef unless $feed;
	$rss = $self->feed_parse (\$feed, $babble);
	return undef unless $rss;

	$collection = $self->rss_to_collection (\$rss, $babble);

	$$babble->Cache->update (
		'Parsed', $self->{-location},
		{
			time => UnixDate ("now", "%a, %d %b %Y %H:%M:%S GMT"),
			data => $collection
		}, 'data') if $self->{-cache_parsed};

	return $collection;
}

=pod

=back

=head1 AUTHOR

Gergely Nagy, algernon@bonehunter.rulez.org

Bugs should be reported at L<http://bugs.bonehunter.rulez.org/babble>.

=head1 SEE ALSO

Babble::Document, Babble::Document::Collection,
Babble::DataSource, Babble::Transport

=cut

1;

# arch-tag: 0009f92d-09c9-40b7-b651-62c586f529fc
