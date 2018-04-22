use strict;
use warnings;
use Test::More;
use Command::Runner;
use File::Temp ();
use Test::Needs 'Win32::ShellQuote';
use Test::Needs 'String::ShellQuote';

my $windows = $^O eq 'MSWin32';

subtest basic => sub {
    my @command = ($^X, '-e', '$|++; print "1\n"; warn 1; print "2\n"; warn 2');

    my @test;
    if ($windows) {
        push @test, [Win32::ShellQuote::quote_system(@command)];
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; return 0 };
    } else {
        push @test, \@command;
        push @test, String::ShellQuote::shell_quote_best_effort(@command);
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; return 0 };

    }
    for my $test (@test) {
        note "test for $test";
        my $cmd = Command::Runner->new(command => $test);
        my @stdout; $cmd->on(stdout => sub { push @stdout, @_ });
        my @stderr; $cmd->on(stderr => sub { push @stderr, @_ });
        my $res = $cmd->run;
        is $res->{result}, 0;
        ok !$res->{timeout};
        is @stdout, 2;
        is @stderr, 2;
    }
};

subtest basic => sub {
    my @command = ($^X, '-e', '$|++; print "1\n"; warn 1; print "2\n"; warn 2');

    my @test;
    if ($windows) {
        push @test, [Win32::ShellQuote::quote_system(@command)];
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; return 0 };
    } else {
        push @test, \@command;
        push @test, String::ShellQuote::shell_quote_best_effort(@command);
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; return 0 };

    }
    for my $test (@test) {
        note "test for $test";
        my $cmd = Command::Runner->new(command => $test, keep => 1);
        my @stdout; $cmd->on(stdout => sub { push @stdout, @_ });
        my @stderr; $cmd->on(stderr => sub { push @stderr, @_ });
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
    my @command = ($^X, '-e', '$|++; print "1\n"; warn 1; print "2\n"; warn 2; sleep 2');

    my @test;
    if ($windows) {
        push @test, [Win32::ShellQuote::quote_system(@command)];
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; sleep 2; return 0 };
    } else {
        push @test, \@command;
        push @test, String::ShellQuote::shell_quote_best_effort(@command);
        push @test, sub { local $| = 1; print "1\n"; warn 1; print "2\n"; warn 2; sleep 2; return 0 };

    }
    for my $test (@test) {
        note "test for $test";
        my $cmd = Command::Runner->new(command => $test, timeout => 1);
        my @stdout; $cmd->on(stdout => sub { push @stdout, @_ });
        my @stderr; $cmd->on(stderr => sub { push @stderr, @_ });
        my $res = $cmd->run;
        ok $res->{timeout};
        is $res->{result}, 15 if !$windows && (ref $test ne 'CODE'); # SIGTERM

        next if $windows;
        is @stdout, 2;
        is @stderr, 2;
    }
};

subtest pipe => sub {
    my @command1 = ($^X,  "-le", q{print "2";});
    my @command2 = ($^X, "-nle", "print");
    my ($command1, $command2);
    if ($windows) {
        $command1 = Win32::ShellQuote::quote_system_string(@command1);
        $command2 = Win32::ShellQuote::quote_system_string(@command2);
    } else {
        $command1 = String::ShellQuote::shell_quote_best_effort(@command1);
        $command2 = String::ShellQuote::shell_quote_best_effort(@command2);
    }
    my $command = "$command1 | $command2";
    note "test for $command";

    my (@stdout, @stderr);
    my $cmd = Command::Runner->new(
        command => $command,
        on => {
            stdout => sub { push @stdout, @_ },
            stderr => sub { push @stderr, @_ },
        },
    );
    my $res = $cmd->run;
    is $res->{result}, 0;
    is @stdout, 1;
    is $stdout[0], 2;
    is @stderr, 0;
};

done_testing;
