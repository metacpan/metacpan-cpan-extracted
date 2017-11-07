package Boxer::World::Reclass;

=encoding UTF-8

=head1 NAME

Boxer::World::Reclass - software as serialized by reclass

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;
use autodie;
use Carp qw<croak>;

use Try::Tiny;

use Moo;
extends 'Boxer::World';
use Types::Standard qw(ArrayRef InstanceOf);
use Boxer::World::Flat;
with qw(MooX::Role::Logger);

use namespace::clean;

=head1 VERSION

Version v1.1.7

=cut

our $VERSION = version->declare("v1.1.7");

=head1 DESCRIPTION

Outside the box is a world of software.

B<Boxer::World::Reclass> is a class describing a collection of software
available for installation into (or as) an operating system.

=head1 SEE ALSO

L<Boxer>.

=cut

has parts => (
	is       => 'ro',
	isa      => ArrayRef [ InstanceOf ['Boxer::Part::Reclass'] ],
	required => 1,
);

sub get_node_by_id
{
	my ( $self, $id ) = @_;

	foreach ( @{ $self->parts } ) {
		if ( $_->id eq $id ) {
			return $_;
		}
	}
	croak "This world contains no node identified as \"" . $id . "\".";
}

my $pos           = 1;
my @section_order = qw(
	Administration
	Service
	Console
	Desktop
	Language
	Framework
	Task
	Hardware
);
my %section_order = map { $_ => $pos++ } @section_order;

sub flatten
{
	my ( $self, $node_id, $nonfree ) = @_;

	my $node = $self->get_node_by_id($node_id);

	( $node->epoch )
		or croak "Undefined epoch for node \"" . $self->node . "\".";

	my %desc;

	my @section_keys = sort {
		( $section_order{$a} // 1000 ) <=> ( $section_order{$b} // 1000 )
			|| $a cmp $b
	} keys %{ $node->{doc} };

	foreach my $key (@section_keys) {
		my $headline = $node->{doc}{$key}{headline}[0] || $key;
		if (( $node->{pkg} and $node->{doc}{$key}{pkg} )
			or (    $nonfree
				and $node->{'pkg-nonfree'}
				and $node->{doc}{$key}{'pkg-nonfree'} )
			)
		{
			push @{ $desc{pkg} }, "# $headline";
			if ( $node->{pkg} ) {
				foreach ( @{ $node->{doc}{$key}{pkg} } ) {
					push @{ $desc{pkg} }, "#  * $_";
				}
			}
			if ( $nonfree and $node->{'pkg-nonfree'} ) {
				foreach ( @{ $node->{doc}{$key}{'pkg-nonfree'} } ) {
					push @{ $desc{pkg} }, "#  * [non-free] $_";
				}
			}
		}
		if ( $node->{tweak} and $node->{doc}{$key}{tweak} ) {
			push @{ $desc{tweak} }, "# $headline";
			foreach ( @{ $node->{doc}{$key}{tweak} } ) {
				push @{ $desc{tweak} }, "#  * $_";
			}
		}
	}
	my $pkgdesc
		= defined( $desc{pkg} )
		? join( "\n", @{ $desc{pkg} } )
		: '';
	my $tweakdesc
		= defined( $desc{tweak} )
		? join( "\n", @{ $desc{tweak} } )
		: '';
	my @pkg = try { @{ $node->{pkg} } }
	catch {
		$self->_logger->warning('No packages resolved');
		return ();
	};
	my @pkgauto = try { @{ $node->{'pkg-auto'} } }
	catch {
		$self->_logger->warning('No package auto-markings resolved');
		return ();
	};
	my @pkgavoid = try { @{ $node->{'pkg-avoid'} } }
	catch {
		$self->_logger->warning('No package avoidance resolved');
		return ();
	};
	my @tweak = try { @{ $node->{tweak} } }
	catch {
		$self->_logger->warning('No tweaks resolved');
		return ();
	};
	if ($nonfree) {
		push @pkg, @{ $node->{'pkg-nonfree'} if ( $node->{'pkg-nonfree'} ) };
		push @pkgauto, @{ $node->{'pkg-nonfree-auto'} }
			if ( $node->{'pkg-nonfree-auto'} );
	}
	chomp(@tweak);

	return Boxer::World::Flat->new(
		node       => $node_id,
		epoch      => $node->epoch,
		pkgs       => \@pkg,
		pkgs_auto  => \@pkgauto,
		pkgs_avoid => \@pkgavoid,
		tweaks     => \@tweak,
		pkgdesc    => $pkgdesc,
		tweakdesc  => $tweakdesc,
		nonfree    => $nonfree,       # TODO: unset if none resolved
	);
}

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>.

=cut

our $AUTHORITY = 'cpan:JONASS';

=head1 COPYRIGHT AND LICENCE

Copyright © 2013-2016 Jonas Smedegaard

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
