package Boxer::World::Reclass;

=encoding UTF-8

=head1 NAME

Boxer::World::Reclass - software as serialized by reclass

=cut

use v5.20;
use utf8;
use Role::Commons -all;
use feature 'signatures';
use namespace::autoclean 0.16;
use autodie;

use YAML::XS;
use List::MoreUtils qw(uniq);
use Hash::Merge qw(merge);
use Try::Tiny;

use Moo;
use MooX::StrictConstructor;
extends qw(Boxer::World);

use Types::Standard qw( ArrayRef InstanceOf Maybe );
use Boxer::Types qw( ClassDir NodeDir Suite );

use Boxer::Part::Reclass;
use Boxer::World::Flat;

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.2

=cut

our $VERSION = "v1.4.2";

=head1 DESCRIPTION

Outside the box is a world of software.

B<Boxer::World::Reclass> is a class describing a collection of software
available for installation into (or as) an operating system.

=head1 SEE ALSO

L<Boxer>.

=cut

has suite => (
	is       => 'ro',
	isa      => Suite,
	required => 1,
);

has classdir => (
	is       => 'lazy',
	isa      => ClassDir,
	coerce   => 1,
	required => 1,
);

sub _build_classdir ($self)
{
	if ( $self->data ) {
		return $self->data->child('classes');
	}
	return;
}

has nodedir => (
	is       => 'lazy',
	isa      => NodeDir,
	coerce   => 1,
	required => 1,
);

sub _build_nodedir ($self)
{
	if ( $self->data ) {
		return $self->data->child('nodes');
	}
	return;
}

has parts => (
	is       => 'lazy',
	isa      => ArrayRef [ InstanceOf ['Boxer::Part::Reclass'] ],
	init_arg => undef,
);

# process only matching types, and skip duplicates is arrays
my $merge_spec = {
	'SCALAR' => {
		'SCALAR' => sub { $_[0] },
		'ARRAY'  => sub { die 'bad input data' },
		'HASH'   => sub { die 'bad input data' },
	},
	'ARRAY' => {
		'SCALAR' => sub { die 'bad input data' },
		'ARRAY'  => sub { [ uniq @{ $_[0] }, @{ $_[1] } ] },
		'HASH'   => sub { die 'bad input data' },
	},
	'HASH' => {
		'SCALAR' => sub { die 'bad input data' },
		'ARRAY'  => sub { die 'bad input data' },
		'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) },
	},
};
Hash::Merge::add_behavior_spec($merge_spec);

sub _build_parts ($self)
{
	my $classdata = $self->classdir->visit(
		sub ( $path, $state ) {
			return if $path->is_dir;
			return unless ( $path->basename =~ /\.yml$/ );
			my $yaml  = Load( $path->slurp_utf8 );
			my $class = $path->relative( $self->classdir ) =~ tr/\//./r
				=~ s/\.yml$//r =~ s/\.init$//r;
			$state->{$class} = $yaml;
		},
		{ recurse => 1 },
	);
	my $nodedata = $self->nodedir->visit(
		sub ( $path, $state ) {
			return if $path->is_dir;
			return unless ( $path->basename =~ /\.yml$/ );
			my $yaml = Load( $path->slurp_utf8 );
			my $node = $path->basename(qr/\.yml$/);
			$state->{$node} = $yaml;
		},
	);
	my @parts;
	for ( sort keys %{$nodedata} ) {
		my %params = ();
		my @classes
			= $nodedata->{$_}{classes}
			? @{ $nodedata->{$_}{classes} }
			: ();
		while ( my $next = shift @classes ) {
			unless ( $classdata->{$next} ) {
				$self->_logger->debug(
					"Ignoring missing class $next for node $_.");
				next;
			}
			if ( $classdata->{$next}{classes} and !$params{_seen}{$next} ) {
				$params{_seen}{$next} = 1;
				unshift @classes, @{ $classdata->{$next}{classes} }, $next;
				next;
			}
			%params = %{ merge( \%params, $classdata->{$next}{parameters} ) }
				if $classdata->{$next}{parameters};
		}
		delete $params{_seen};
		%params = %{ merge( \%params, $nodedata->{$_}{parameters} ) }
			if $nodedata->{$_}{parameters};
		push @parts,
			Boxer::Part::Reclass->new(
			id    => $_,
			epoch => $self->suite,
			%params,
			);
	}
	return [@parts];
}

sub list_parts ($self)
{
	return map { $_->id } @{ $self->parts };
}

sub get_part ( $self, $id )
{
	unless ( @{ $self->parts } ) {
		$self->_logger->error("No parts exist.");
		return;
	}
	foreach ( @{ $self->parts } ) {
		if ( $_->id eq $id ) {
			return $_;
		}
	}
	$self->_logger->error("Part \"$id\" does not exist.");
	return;
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

sub map ( $self, $node_id, $nonfree )
{
	my $node = $self->get_part($node_id);
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
		push @pkg, @{ $node->{'pkg-nonfree'} } if ( $node->{'pkg-nonfree'} );
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
