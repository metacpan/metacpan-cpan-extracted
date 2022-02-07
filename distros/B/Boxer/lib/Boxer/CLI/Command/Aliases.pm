package Boxer::CLI::Command::Aliases;

=encoding UTF-8

=cut

use v5.20;
use utf8;
use Role::Commons -all;
use feature 'signatures';
use namespace::autoclean 0.16;

use match::simple qw(match);
use Boxer::CLI -command;

use strictures 2;
no warnings "experimental::signatures";

=head1 VERSION

Version v1.4.3

=cut

our $VERSION = "v1.4.3";

use constant {
	abstract   => q[show aliases for boxer commands],
	usage_desc => q[%c aliases],
};

sub description
{
	<<'DESCRIPTION';
Some boxer commands can be invoked with shorter aliases.

	boxer version
	boxer --version          # same thing

The aliases command (which, ironically, has no shorter alias) shows existing
aliases.
DESCRIPTION
}

sub command_names
{
	qw(
		aliases
	);
}

sub opt_spec
{
	return;
}

sub execute ( $self, $opt, $args )
{
	my $filter
		= scalar(@$args)
		? $args
		: sub { not( match( shift, [qw(aliases commands help)] ) ) };

	foreach my $cmd ( sort $self->app->command_plugins ) {
		my ( $preferred, @aliases ) = $cmd->command_names;
		printf( "%-16s: %s\n", $preferred, "@aliases" )
			if match( $preferred, $filter );
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
