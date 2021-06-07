use v5.14;
use warnings;

use App::ansiecho;
use Command::Runner;

sub ansiecho {
    local @ARGV = @_;
    Command::Runner->new(
	command => sub { eval { App::ansiecho->new->run(@ARGV) } },
	stderr  => sub { warn "err: $_[0]\n" },
	)->run;
}

1;
