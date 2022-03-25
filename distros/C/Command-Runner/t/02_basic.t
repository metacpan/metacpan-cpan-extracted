use strict;
use warnings;
use Test::More;
use Command::Runner;
use File::Temp ();

my $windows = $^O eq 'MSWin32';

subtest basic => sub {
    my @test = (
        [$^X, '-e', '$|++; print "1\n"; warn 1; print "2\n"; warn 2'],
        sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; return 0 },
    );

    for my $test (@test) {
        note "test for $test";
        my $cmd = Command::Runner->new(command => $test, keep => 0);
        my @stdout; $cmd->stdout(sub { push @stdout, @_ });
        my @stderr; $cmd->stderr(sub { push @stderr, @_ });
        my $res = $cmd->run;
        is $res->{result}, 0;
        ok !$res->{timeout};
        is @stdout, 2;
        is @stderr, 2;
        ok !$res->{stdout};
        ok !$res->{stderr};
    }
};

subtest basic => sub {
    my @test = (
        [$^X, '-e', '$|++; print "1\n"; warn 1; print "2\n"; warn 2'],
        sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; return 0 },
    );

    for my $test (@test) {
        note "test for $test";
        my $cmd = Command::Runner->new(command => $test);
        my @stdout; $cmd->stdout(sub { push @stdout, @_ });
        my @stderr; $cmd->stderr(sub { push @stderr, @_ });
        my $res = $cmd->run;
        is $res->{result}, 0;
        ok !$res->{timeout};
        is @stdout, 2;
        is @stderr, 2;
        is $res->{stdout}, "1\n2\n";
        like $res->{stderr}, qr{^1 at .* line \d+\.\n2 at .* line \d+\.\n$};
    }
};

subtest timeout => sub {
    my @test = (
        [$^X, '-e', '$|++; print "1\n"; warn 1; print "2\n"; warn 2; sleep 2'],
        sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; sleep 2; return 0 },
    );

    for my $test (@test) {
        note "test for $test";
        my $cmd = Command::Runner->new(command => $test, timeout => 1);
        my @stdout; $cmd->stdout(sub { push @stdout, @_ });
        my @stderr; $cmd->stderr(sub { push @stderr, @_ });
        my $res = $cmd->run;
        ok $res->{timeout};
        is $res->{result}, 15 if !$windows && (ref $test ne 'CODE'); # SIGTERM

        next if $windows;
        is @stdout, 2;
        is @stderr, 2;
    }
};

done_testing;
