package App::perlrdf::Command::About;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::About::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::About::VERSION   = '0.006';
}

use App::perlrdf -command;

use namespace::clean;

use constant {
	abstract    => q[list which perlrdf plugins are installed],
	usage_desc  => q[%c about],
};

use constant FORMAT_STR => "%-36s%10s %s\n";

sub command_names
{
	qw(
		about
		credits
	);
}

sub opt_spec
{
	return;
}

sub execute
{
	my ($self, $opt, $args) = @_;
	
	my $auth = $self->app->can('AUTHORITY');
	printf(
		FORMAT_STR,
		ref($self->app),
		$self->app->VERSION,
		$auth ? $self->app->$auth : '???',
	);
	
	foreach my $cmd (sort $self->app->command_plugins)
	{
		my $auth = $cmd->can('AUTHORITY');
		printf(
			FORMAT_STR,
			$cmd,
			$cmd->VERSION,
			$auth ? $cmd->$auth : '???',
		);
	}
}

1;
