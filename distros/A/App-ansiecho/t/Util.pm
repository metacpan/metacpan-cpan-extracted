use v5.14;
use warnings;

use App::ansiecho;
use Command::Runner;

sub ansiecho {
    my @argv = @_;
    Command::Runner->new(
	command => sub { eval { App::ansiecho->new->run(@argv) } },
	stderr  => sub { warn "err: $_[0]\n" },
	)->run;
}

1;
