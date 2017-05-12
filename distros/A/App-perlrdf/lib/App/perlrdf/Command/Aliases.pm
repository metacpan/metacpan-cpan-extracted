package App::perlrdf::Command::Aliases;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::Aliases::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::Aliases::VERSION   = '0.006';
}

use App::perlrdf -command;
use match::simple qw(match);
use namespace::clean;

use constant {
	abstract    => q[show aliases for perlrdf commands],
	usage_desc  => q[%c aliases],
};

sub description
{
<<'DESCRIPTION'
Most perlrdf commands can be invoked with shorter aliases.

	perlrdf translate -s rdfxml input.ttl
	perlrdf tr -s rdfxml input.ttl          # same thing

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

sub execute
{
	my ($self, $opt, $args) = @_;
	
	my $filter = scalar(@$args)
		? $args
		: sub { not match($_[0], [qw(aliases commands help)]) };
	
	foreach my $cmd (sort $self->app->command_plugins)
	{
		my ($preferred, @aliases) = $cmd->command_names;
		printf("%-16s: %s\n", $preferred, "@aliases")
			if match($preferred, $filter);
	}
}

1;
