package CLITest;
use base 'Exporter';
our @EXPORT = qw(cliack clicheck);

our @STACK;

sub cliack {
    push @STACK, [(caller(0))[0],(caller(1))[3], @_];
}

sub clicheck {
    pop @STACK;
}

1;
