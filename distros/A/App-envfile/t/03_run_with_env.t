use strict;
use warnings;
use Test::More;
use t::Util;

plan skip_all => 'MSWin32 not process' if $^O eq 'MSWin32';

BEGIN {
    # capture exec()
    *CORE::GLOBAL::exec = sub {
        my @args = @_;
        my $pid = open my $pipe, '-|';
        if ($pid) {
            my $buf;
            while (defined (my $line = readline $pipe)) {
                $buf .= $line;
            }
            close $pipe;
            return $buf;
        }
        else {
            CORE::exec @args or die $!;
        }
    };
}

use App::envfile;

sub test_run_with_env {
    my %specs = @_;
    my ($input, $expects, $desc) = @specs{qw/input expects desc/};
    my $command = join ',', map { "\$ENV{$_}" } sort keys %$input;

    runtest $desc => sub {
        my $envf = App::envfile->new;
        my $buf = $envf->run_with_env($input, [$^X, '-e', "print qq|$command|"]);
        is $buf, $expects, 'child ok';
    };
}

test_run_with_env(
    input   => { FOO => 'bar' },
    expects => 'bar',
    desc    => 'with FOO',
);

test_run_with_env(
    input   => { FOO => 'bar', BAR => 'baz' },
    expects => 'baz,bar',
    desc    => 'with FOO, BAR',
);

done_testing;
