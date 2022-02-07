package Boxer::Task::Bootstrap;

=encoding UTF-8

=cut

use v5.20;
use utf8;
use Role::Commons -all;
use feature 'signatures';
use namespace::autoclean 0.16;
use autodie qw(:all);
use IPC::System::Simple qw(runx);

use Moo;
use MooX::StrictConstructor;
extends qw(Boxer::Task);

use Types::Standard qw( Bool Str InstanceOf ArrayRef Maybe );

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.3

=cut

our $VERSION = "v1.4.3";

has world => (
	is       => 'ro',
	isa      => InstanceOf ['Boxer::World'],
	required => 1,
);

has node => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has helper => (
	is       => 'ro',
	isa      => Str,
	required => 1,
);

has mode => (
	is  => 'ro',
	isa => Maybe [Str],
);

has helper_args => (
	is  => 'ro',
	isa => ArrayRef,
);

has nonfree => (
	is       => 'ro',
	isa      => Bool,
	required => 1,
	default  => sub {0},
);

has apt => (
	is  => 'lazy',
	isa => Bool,
);

sub _build_apt ($self)
{
	my $flag;
	foreach my $helper (qw(mmdebstrap)) {
		if ( $self->{helper} eq $helper ) {
			$self->_logger->tracef(
				'Enabling apt mode needed by bootstrap helper %s',
				$helper,
			);
			return 1;
		}
	}
	return 0;
}

has dryrun => (
	is       => 'ro',
	isa      => Bool,
	required => 1,
	default  => sub {0},
);

sub run ($self)

{
	my $world = $self->world->map( $self->node, $self->nonfree, );
	my @opts;

	my @pkgs       = sort @{ $world->pkgs };
	my @pkgs_avoid = sort @{ $world->pkgs_avoid };

	if ( $self->apt ) {
		push @pkgs, sort map { $_ . '-' } @pkgs_avoid;
		@pkgs_avoid = ();
	}

	push @opts, '--include', join( ',', @pkgs )
		if (@pkgs);
	push @opts, '--exclude', join( ',', @pkgs_avoid )
		if (@pkgs_avoid);
	push @opts, $world->epoch, @{ $self->mode, $self->helper_args };

	my @command;
	if ( $self->mode and $self->mode eq 'sudo' ) {
		@command = ( 'sudo', '--', $self->helper, @opts );
	}
	else {
		@command = ( $self->helper, @opts );
	}

	$self->_logger->info(
		"Bootstrap with " . $self->helper,
		$self->_logger->is_debug() ? { commandline => [@command] } : (),
	);
	if ( $self->dryrun ) {
		$self->_logger->debug('Skip execute command in dry-run mode');
	}
	else {
		runx @command;
	}

	1;
}

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>.

=cut

our $AUTHORITY = 'cpan:JONASS';

=head1 COPYRIGHT AND LICENCE

Copyright © 2019 Jonas Smedegaard

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
