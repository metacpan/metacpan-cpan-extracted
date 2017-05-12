package App::perlrdf::Command::Commands;

use 5.010;
use strict;
use warnings;
use utf8;

BEGIN {
	$App::perlrdf::Command::Commands::AUTHORITY = 'cpan:TOBYINK';
	$App::perlrdf::Command::Commands::VERSION   = '0.006';
}

use App::perlrdf -command;
use namespace::clean;

require App::Cmd::Command::commands;
our @ISA;
unshift @ISA, 'App::Cmd::Command::commands';

use constant {
	abstract    => q[list installed perlrdf commands],
};

sub sort_commands
{
	my ($self, @commands) = @_;
	my $float = qr/^(?:help|commands|aliases|about)$/;
	my @head = sort grep { $_ =~ $float } @commands;
	my @tail = sort grep { $_ !~ $float } @commands;
	return (\@head, \@tail);
}
1;
