package Boxer::CLI::Command::Compose;

=encoding UTF-8

=cut

use v5.20;
use utf8;
use Role::Commons -all;
use feature 'signatures';
use namespace::autoclean 0.16;

use Path::Tiny;
use Module::Runtime qw/use_module/;
use Boxer::CLI -command;

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.3

=cut

our $VERSION = "v1.4.3";

use constant {
	abstract   => q[compose system recipe from abstract node],
	usage_desc => q[%c compose %o NODE [NODE...]],
};

sub description
{
	<<'DESCRIPTION';
Compose a system recipe.

Resolve a recipe to build a system.  Input is one or more abstract nodes
to resolve using a set of abstract classes, and output is one or more
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
		[ "suite=s",    "suite of classes to use (bullseye)" ],
		[ "nodedir=s",  "location of nodes (current dir)" ],
		[ "classdir=s", "location of classes (XDG datadir + suite/classes)" ],
		[ "datadir=s",  "location containing nodes and classes" ],
		[ "skeldir=s",  "location of skeleton files (use builtin)" ],
		[ "format=s",   "serialize into these formats (preseed script)" ],
		[ "nonfree",    "enable use of contrib and non-free code" ],
		[ "verbose|v",  "verbose output" ],
	);
}

sub execute ( $self, $opt, $args )
{
	Log::Any::Adapter->set( 'Screen', default_level => 'info' )
		if ( $opt->{verbose} );

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
			format  => $opt->{format} || 'preseed script',
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
