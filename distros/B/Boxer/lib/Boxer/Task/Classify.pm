package Boxer::Task::Classify;

=encoding UTF-8

=cut

use v5.20;
use utf8;
use Role::Commons -all;
use feature 'signatures';
no warnings "experimental::signatures";
use namespace::autoclean 0.16;
use autodie qw(:all);
use IPC::System::Simple;

use File::BaseDir qw(data_dirs);
use Boxer;

use Moo;
use MooX::StrictConstructor;
extends qw(Boxer::Task);

use Types::Standard qw(Maybe);
use Boxer::Types qw( WorldName DataDir ClassDir NodeDir Suite );

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.2

=cut

our $VERSION = "v1.4.2";

# permit callers to sloppily pass undefined values
sub BUILDARGS ( $class, %args )
{
	delete @args{ grep !defined( $args{$_} ), keys %args };
	return {%args};
}

has world => (
	is       => 'ro',
	isa      => WorldName,
	required => 1,
	default  => sub {'reclass'},
);

has datadir => (
	is      => 'lazy',
	isa     => Maybe [DataDir],
	coerce  => 1,
	default => sub {undef},
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

sub _build_classdir ($self)
{
	my $dir;
	if ( $self->datadir ) {
		$self->_logger->trace('Resolving classdir from datadir');
		$dir = $self->datadir->child('classes');
	}
	else {
		$self->_logger->trace('Resolving classdir from XDG_DATA_DIRS');
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

sub _build_nodedir ($self)
{
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

sub run ($self)
{
	my @args = (
		suite    => scalar $self->suite,
		classdir => scalar $self->classdir,
		nodedir  => scalar $self->nodedir,
	);
	$self->_logger->info(
		'Classifying with reclass',
		$self->_logger->is_debug() ? {@args} : (),
	);
	return Boxer->get_world( $self->world )->new(@args);
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
