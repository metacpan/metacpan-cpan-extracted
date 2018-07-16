package Boxer::Task::Classify;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;
use autodie qw(:all);
use IPC::System::Simple;

use File::BaseDir qw(data_dirs);
use Capture::Tiny qw(capture_stdout);
use YAML::XS;
use Boxer::World::Reclass;
use Boxer::Part::Reclass;

use Moo;
use Types::Standard qw( Maybe Str Undef );
use Boxer::Types qw( DataDir ClassDir NodeDir Suite );
extends 'Boxer::Task';

use namespace::autoclean 0.16;

=head1 VERSION

Version v1.1.8

=cut

our $VERSION = version->declare("v1.1.8");

# permit callers to sloppily pass undefined values
sub BUILDARGS
{
	my ( $class, %args ) = @_;
	delete @args{ grep !defined( $args{$_} ), keys %args };
	return {%args};
}

has datadir => (
	is       => 'lazy',
	isa      => Maybe [DataDir],
	coerce   => 1,
	required => 1,
	default  => sub {undef},
);

has suite => (
	is       => 'ro',
	isa      => Suite,
	required => 1,
	coerce   => 1,
	default  => sub {'wheezy'},
);

has classdir => (
	is       => 'lazy',
	isa      => ClassDir,
	coerce   => 1,
	required => 1,
	default  => sub {
		$_[0]->datadir
			? $_[0]->datadir->child('classes')
			: scalar( data_dirs( 'boxer', $_[0]->suite, 'classes' ) );
	},
);

has nodedir => (
	is       => 'lazy',
	isa      => NodeDir,
	coerce   => 1,
	required => 1,
	default  => sub { $_[0]->datadir ? $_[0]->datadir->child('nodes') : '.' },
);

sub run
{
	my $self = shift;

	my $data = Load(
		scalar(
			capture_stdout {
				system(
					'reclass',
					'-b',
					'',
					'-c',
					$self->classdir,
					'-u',
					$self->nodedir,
					'--inventory',
				);
			}
		)
	);

	my @parts;
	for ( keys %{ $data->{nodes} } ) {
		push @parts,
			Boxer::Part::Reclass->new(
			id    => $_,
			epoch => $self->suite,
			%{ $data->{nodes}{$_}{parameters} }
			);
	}

	return Boxer::World::Reclass->new(
		parts => \@parts,
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
