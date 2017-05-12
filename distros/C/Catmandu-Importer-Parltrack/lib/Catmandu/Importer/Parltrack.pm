package Catmandu::Importer::Parltrack;

use strict;
use warnings;

use Catmandu::Sane;
use Moo;
use Types::Standard qw( Bool );
use URI::Template;

extends 'Catmandu::Importer::getJSON';

our $AUTHORITY = 'cpan:JONASS';
our $VERSION   = '0.001';

has api => (
	is      => 'ro',
	default => sub {'http://parltrack.euwiki.org'}
);

has '+url' => (
	is      => 'ro',
	lazy    => 1,
	builder => sub {
		URI::Template->new( $_[0]->api . '{/topic,reference}?format=json' );
	}
);

has '+from' => (
	is      => 'ro',
	lazy    => 1,
	builder => \&_build_from,
);

has dossier => (
	is => 'ro',
);

has meps => (
	is  => 'ro',
	isa => Bool,
);

has mep => (
	is => 'ro',
);

has committee => (
	is => 'ro',
);

sub _build_from
{
	my ($self) = @_;

	my $vars;

	if ( $self->dossier ) {
		$vars = { topic => 'dossier', reference => $self->dossier };
	}
	elsif ( $self->meps ) {
		$vars = { topic => 'meps', reference => '' };
	}
	elsif ( $self->mep ) {
		$vars = { topic => 'mep', reference => $self->mep };
	}
	elsif ( $self->committee ) {
		$vars = { topic => 'committee', reference => $self->committee };
	}

	return ( $vars ? $self->url->process($vars) : undef );
}

sub request_hook
{
	my ( $self, $line ) = @_;

	if ( $line =~ /^\/([a-z]+)\/(.+)$/ ) {
		return { topic => $1, reference => $2 };
	}
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Catmandu::Importer::Parltrack - Import from Parltrack

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    catmandu convert Parltrack --dossier "2011/0167(NLE)"
    catmandu convert Parltrack --mep "Rebecca HARMS"
    catmandu convert Parltrack --meps 1

    echo '/dossier/2011/0167(NLE)' | catmandu convert Parltrack
    echo '/mep/Rebecca HARMS' | catmandu convert Parltrack

=head1 DESCRIPTION

This L<Catmandu::Importer> queries Parltrack for entities.

=head1 CONFIGURATION

This importer extends L<Catmandu::Importer::getJSON>, so it can be configured
with options C<agent>, C<timeout>, C<headers>, C<proxy>, and C<dry>. Additional
options include:

=over

=item api

Parltrack API base URL. Default is C<http://parltrack.euwiki.org>.

=item dossier

=item meps

=item committee

=back

=head1 AUTHOR

Jonas Smedegaard

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Jonas Smedegaard.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
