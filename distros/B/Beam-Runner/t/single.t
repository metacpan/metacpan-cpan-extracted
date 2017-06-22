
=head1 DESCRIPTION

This file tests the L<Beam::Runnable::Single> role to ensure it
writes PID files and prevents multiple instances from running.

=head1 SEE ALSO

L<Beam::Runnable::AllowUsers>

=cut

use strict;
use warnings;
use Test::More;
use Test::Fatal;
use Path::Tiny qw( tempdir );

{ package
        t::Single::Dies;
    use Moo;
    with 'Beam::Runnable', 'Beam::Runnable::Single';
    sub run { die }
}
{ package
        t::Single::Lives;
    use Moo;
    our $RUN;
    with 'Beam::Runnable', 'Beam::Runnable::Single';
    sub run { $RUN++ }
}

my $TMP_DIR = tempdir;
my $PID_FILE = $TMP_DIR->child( 'pidfile' );

subtest 'process dies' => sub {
    my $foo = t::Single::Dies->new(
        pid_file => $PID_FILE,
    );
    ok my $e = exception { $foo->run }, 'process dies';
    ok $PID_FILE->exists, 'pid file is not cleaned up by process dying';
    is $PID_FILE->slurp, $$, 'pid file contains current process ID';
};

subtest 'another process cannot run' => sub {
    my $foo = t::Single::Lives->new(
        pid_file => $PID_FILE,
    );
    is exception { $foo->run }, "Process already running (PID: $$)\n",
        "process throws exception with error message";
    ok !$t::Single::Lives::RUN, 'process is not run';
};

subtest 'path is coerced' => sub {
    my $foo = t::Single::Lives->new(
        pid_file => 'foo/bar',
    );
    isa_ok $foo->pid_file, 'Path::Tiny', 'pid path is coerced correctly';
    is $foo->pid_file, 'foo/bar', 'pid file path is correct';
};

done_testing;
