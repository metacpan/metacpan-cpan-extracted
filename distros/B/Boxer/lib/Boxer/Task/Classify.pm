package Boxer::Task::Classify;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use strictures 2;
use Role::Commons -all;
use namespace::autoclean 0.16;
use autodie qw(:all);
use IPC::System::Simple;

use File::BaseDir qw(data_dirs);
use Boxer::World::Reclass;

use Moo;
use MooX::StrictConstructor;
extends qw(Boxer::Task);

use Types::Standard qw(Maybe);
use Boxer::Types qw( DataDir ClassDir NodeDir Suite );

=head1 VERSION

Version v1.4.0

=cut

our $VERSION = "v1.4.0";

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
	default  => sub {'buster'},
);

has classdir => (
	is       => 'lazy',
	isa      => ClassDir,
	coerce   => 1,
	required => 1,
);

sub _build_classdir
{
	my ($self) = @_;
	my $dir;
	if ( $self->datadir ) {
		$self->_logger->trace('Resolving nodedir from datadir');
		$dir = $self->datadir->child('classes');
	}
	else {
		$self->_logger->trace('Resolving nodedir from XDG_DATA_DIRS');
		$dir = scalar data_dirs( 'boxer', $_[0]->suite, 'classes' );
	}
	return $dir;
}

has nodedir => (
	is       => 'lazy',
	isa      => NodeDir,
	coerce   => 1,
	required => 1,
);

sub _build_nodedir
{
	my ($self) = @_;
	my $dir;
	if ( $self->datadir ) {
		$self->_logger->trace('Resolving nodedir from datadir');
		$dir = $self->datadir->child('nodes');
	}
	else {
		$self->_logger->trace('Setting nodedir to current directory');
		$dir = '.';
	}
	return $dir;
}

sub run
{
	my $self = shift;
	my @args = (
		suite    => scalar $self->suite,
		classdir => scalar $self->classdir,
		nodedir  => scalar $self->nodedir,
	);
	$self->_logger->info(
		'Classifying with reclass',
		$self->_logger->is_debug() ? {@args} : (),
	);
	return Boxer::World::Reclass->new(@args);
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
