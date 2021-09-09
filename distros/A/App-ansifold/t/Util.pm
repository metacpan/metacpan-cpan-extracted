use v5.14;
use warnings;

use Data::Dumper;
use Command::Runner;

$ENV{PERL5LIB} = join ':', @INC;

sub run {
    my($script, @args) = @_;
    my @command = ($^X, '-Ilib', "./script/$script", @args);
    Command::Runner->new(
	command => \@command,
	stderr  => sub { warn "err: $_[0]\n" },
	)->run;
}

sub ansifold { run 'ansifold', @_ }

1;
