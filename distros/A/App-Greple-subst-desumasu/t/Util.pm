use v5.14;
use warnings;
use utf8;
use open IO => ':utf8', ':std';

use Command::Runner;

sub desumasu {
    Command::Runner->new(
	command => [ $^X, '-Ilib', '-S', 'greple', '-Msubst::desumasu', @_ ],
	stderr  => sub { warn "err: $_[0]\n" },
	)->run;
}

1;
