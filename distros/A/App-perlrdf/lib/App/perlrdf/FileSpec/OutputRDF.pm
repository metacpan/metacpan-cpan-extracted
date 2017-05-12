package App::perlrdf::FileSpec::OutputRDF;

use 5.010;
use autodie;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::FileSpec::OutputRDF::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::FileSpec::OutputRDF::VERSION   = '0.006';
}

use Moose;
use RDF::Trine;
use RDF::TriN3;
use RDF::TrineX::Functions -all => { -prefix => 'rdf_' };

use namespace::clean;

extends 'App::perlrdf::FileSpec::OutputFile';

has serializer => (
	is         => 'ro',
	isa        => 'Object|Undef',
	lazy_build => 1,
);

sub _build_format
{
	my $self = shift;
	
	if (lc $self->uri->scheme eq 'file')
	{
		return 'RDF::TrineX::Parser::Pretdsl'
			if $self->uri->file =~ /\.(pret|pretdsl)/i;
		
		return RDF::Trine::Parser
			-> guess_parser_by_filename($self->uri->file);
	}
	
	if ($self->can('response'))
	{
		return $self->response->content_type
			if $self->response->content_type;
		
		return 'RDF::TrineX::Parser::Pretdsl'
			if (($self->response->base // $self->uri) =~ /\.(pret|pretdsl)/i);
			
		return RDF::Trine::Parser->guess_parser_by_filename(
			$self->response->base // $self->uri,
		);
	}

	return 'RDF::TrineX::Parser::Pretdsl'
		if $self->uri =~ /\.(pret|pretdsl)/i;

	return RDF::Trine::Parser->guess_parser_by_filename($self->uri);
}

sub _build_serializer
{
	my $self = shift;
	my $P = 'RDF::Trine::Serializer';
	
	if (blessed $self->format and $self->format->isa($P))
	{
		return $self->format;
	}
	
	if ($self->format =~ m{/})
	{
		my (undef, $s) = $P->negotiate(
			request_headers => HTTP::Headers->new(
				Accept => $self->format,
			),
		);
		return $s;
	}

	if ($self->format =~ m{::})
	{
		(my $class = $self->format)
			=~ s/::Parser/::Serializer/;
		$class = 'RDF::Trine::Serializer::Turtle'
			if $class eq 'RDF::TrineX::Serializer::Pretdsl';
		return $class->new;
	}
	
	return $P->new($self->format);
}

sub serialize_model
{
	my ($self, $model) = @_;
	
	rdf_serialize(
		$model,
		as   => $self->serializer,
		to   => $self->handle,
	)
}

1;
