package Boxer::CLI::Command::Compose;

=encoding UTF-8

=cut

use v5.14;
use utf8;
use strictures 2;
use version;
use Role::Commons -all;

use Path::Tiny;
use Module::Runtime qw/use_module/;
use Boxer::CLI -command;

use namespace::autoclean 0.16;

=head1 VERSION

Version v1.1.11

=cut

our $VERSION = version->declare("v1.1.11");

use constant {
	abstract   => q[compose system recipe from reclass node],
	usage_desc => q[%c compose %o NODE [NODE...]],
};

sub description
{
	<<'DESCRIPTION';
Compose a system recipe.

Resolve a recipe to build a system.  Input is one or more reclass nodes
to resolve using a set of reclass classes, and output is one or more
recipies serialized in one or more formats.

DESCRIPTION
}

sub command_names
{
	qw(
		compose
	);
}

sub opt_spec
{
	return (
		[ "suite=s",    "suite of classes to use (wheezy)" ],
		[ "nodedir=s",  "location of nodes (XDG datadir + suite/nodes)" ],
		[ "classdir=s", "location of classes (XDG datadir + suite/classes)" ],
		[ "datadir=s",  "location containing nodes and classes" ],
		[ "skeldir=s",  "location of skeleton files (use builtin)" ],
		[ "format=s", "serialize recipe(s) in this format (preseed script)" ],
		[ "nonfree",  "enable use of contrib and non-free code" ],
		[ "verbose|v", "verbose output" ],
	);
}

sub execute
{
	my $self = shift;
	my ( $opt, $args ) = @_;

	my $world = use_module('Boxer::Task::Classify')->new(
		suite    => $opt->{suite},
		nodedir  => $opt->{nodedir},
		classdir => $opt->{classdir},
		datadir  => $opt->{datadir},
	)->run;
	for my $node (@$args) {
		use_module('Boxer::Task::Serialize')->new(
			world   => $world,
			skeldir => $opt->{skeldir},
			nonfree => $opt->{nonfree},
			node    => $node,
		)->run;
	}
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
