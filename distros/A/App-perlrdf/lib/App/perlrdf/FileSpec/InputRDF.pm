package App::perlrdf::FileSpec::InputRDF;

use 5.010;
use autodie;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::FileSpec::InputRDF::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::FileSpec::InputRDF::VERSION   = '0.006';
}

use Moose;
use RDF::Trine;
use RDF::TriN3;
use RDF::TrineX::Parser::Pretdsl;
use RDF::TrineX::Parser::RDFa;
use RDF::TrineX::Functions -all => { -prefix => 'rdf_' };

use namespace::clean;

extends 'App::perlrdf::FileSpec::InputFile';

has parser => (
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

sub _build_parser
{
	my $self = shift;
	my $P = 'RDF::Trine::Parser';
	
	if (blessed $self->format and $self->format->isa($P))
	{
		return $self->format;
	}
	
	if ($self->format =~ m{/})
	{
		return $P->parser_by_media_type($self->format)->new;
	}

	if ($self->format =~ m{::})
	{
		return $self->format->new;
	}

	if ($self->format =~ m{(pret|pretdsl)}i)
	{
		return RDF::TrineX::Parser::Pretdsl->new;
	}

	return $P->new($self->format);
}

sub parse_into_model
{
	my ($self, $model, %args) = @_;

	rdf_parse(
		$self->handle,
		base  => $self->base,
		using => $self->parser,
		into  => $model,
		%args,
	)
}

1;
