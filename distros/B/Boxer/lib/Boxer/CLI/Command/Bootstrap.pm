package Boxer::CLI::Command::Bootstrap;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;
use namespace::autoclean 0.16;

use Path::Tiny;
use List::MoreUtils qw(before after);
use Module::Runtime qw/use_module/;
use Boxer::CLI -command;

=head1 VERSION

Version v1.3.0

=cut

our $VERSION = version->declare("v1.3.0");

use constant {
	abstract   => q[bootstrap system image from reclass node],
	usage_desc => q[%c bootstrap %o NODE [NODE...] [-- helper-options]],
};

sub description
{
	<<'DESCRIPTION';
Bootstrap a system image.

Generate a filesystem image.  Input is one or more reclass nodes
to resolve using a set of reclass classes, and output is one or more
images generated using a bootstrapping tool.

DESCRIPTION
}

sub command_names
{
	qw(
		bootstrap
	);
}

sub opt_spec
{
	return (
		[ "suite=s",    "suite of classes to use (buster)" ],
		[ "nodedir=s",  "location of nodes (current dir)" ],
		[ "classdir=s", "location of classes (XDG datadir + suite/classes)" ],
		[ "datadir=s",  "location containing nodes and classes" ],
		[ "skeldir=s",  "location of skeleton files (use builtin)" ],
		[ "helper=s",   "bootstrapping tool to use (mmdebstrap)" ],
		[ "nonfree",    "enable use of contrib and non-free code" ],
		[ "dryrun",     "only echo command, without executing it" ],
		[ "verbose|v",  "verbose output" ],
	);
}

sub execute
{
	my $self = shift;
	my ( $opt, $args ) = @_;

	my @args = before { $_ eq '--' } @{$args};
	my @helper_args = after { $_ eq '--' } @{$args};

	my $world = use_module('Boxer::Task::Classify')->new(
		suite    => $opt->{suite},
		nodedir  => $opt->{nodedir},
		classdir => $opt->{classdir},
		datadir  => $opt->{datadir},
	)->run;
	for my $node (@args) {
		use_module('Boxer::Task::Bootstrap')->new(
			world       => $world,
			helper      => $opt->{helper} || 'mmdebstrap',
			helper_args => [@helper_args],
			nonfree     => $opt->{nonfree},
			dryrun      => $opt->{dryrun},
			node        => $node,
		)->run;
	}
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
