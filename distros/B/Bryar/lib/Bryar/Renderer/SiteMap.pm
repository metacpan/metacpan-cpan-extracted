package Bryar::Renderer::SiteMap;

use warnings;
use strict;

use WWW::Google::SiteMap;

=head1 NAME

Bryar::Renderer::SiteMap - Generate an XML sitemap using WWW::Google::SiteMap

=head1 SYNOPSIS

	my $blog = Bryar->new(
		renderer => 'Bryar::Renderer::SiteMap',
		sitemap_static_files => [ qw(blogroll.opml foaf.rdf) ],
		sitemap_static_basedir => $basedir,
	);

	my @documents = $blog->config->source->all_documents($blog->config);
	print $blog->config->renderer->generate('object', $blog, @documents);

=head1 DESCRIPTION

This Bryar renderer generates a Google sitemap for the dynamic content
of the blog and optionally for a specified list of static files.

=head1 METHODS

=head2 generate

    $self->generate(undef, $bryar, @documents)

    Returns a Google sitemap from the documents provided by the Bryar object.

=cut

sub generate {
	my ($class, $format, $bryar, @documents) = @_;
	$format ||= '';

	my $map = WWW::Google::SiteMap->new;

	$map->add(WWW::Google::SiteMap::URL->new(
		loc			=> $bryar->config->baseurl . '/',
		lastmod		=> $documents[0]->epoch,
		changefreq	=> 'daily',
		priority	=> 1.0,
	));

	# static files
	foreach my $file (@{$bryar->config->{sitemap_static_files}}) {
		-e $bryar->config->{sitemap_static_basedir} . $file || next;

		$map->add(WWW::Google::SiteMap::URL->new(
			loc			=> $bryar->config->baseurl . '/' . $file,
			lastmod		=> (stat(_))[9],
			changefreq	=> 'monthly',
			priority	=> 0.8,
		));
	}

	# articles
	$map->add(map {
		WWW::Google::SiteMap::URL->new(
			loc			=> $bryar->config->baseurl . $_->url,
			lastmod		=> $_->epoch,
			changefreq	=> 'never',
			priority	=> 0.5,
		)
	} @documents);

	return $map if $format eq 'object';
	$map->pretty(1) if $format eq 'pretty';

	return $map->xml;
}

=head1 LICENSE

This module is free software, and may be distributed under the same
terms as Perl itself.

=head1 AUTHOR

Copyright (C) 2008, Marco d'Itri <md@Linux.IT>

=cut

1;
