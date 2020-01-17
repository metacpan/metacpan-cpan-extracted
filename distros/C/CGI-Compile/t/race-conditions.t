#!perl

use strict;
use warnings;

use Test::More $^O eq 'MSWin32' ? (
    skip_all => 'no fork() on Win32')
: (
    tests => $ENV{AUTOMATED_TESTING} ? 3600 : 75
);
use CGI;
use CGI::Compile;
use POSIX ':sys_wait_h';
use Capture::Tiny qw/capture_stdout capture_stderr/;
use Try::Tiny;

my %children;

$SIG{CHLD} = sub {
    while ((my $child = waitpid(-1, WNOHANG)) > 0) {
        delete $children{$child};

        ok($? >> 8 == 0, "no race condition in child PID=$child");
    }
};

# 400 iterations when smoking, 25 otherwise.
for (1..($ENV{AUTOMATED_TESTING} ? 400 : 25)) {
    my $errors = capture_stderr {
        # Use 8 simultaneous processes when smoking, 2 otherwise.
        for (1..($ENV{AUTOMATED_TESTING} ? 8 : 2)) {
            defined(my $child = fork()) or die "fork() failed: $!";

            if ($child == 0) { # child
                try {
                    my $sub = CGI::Compile->compile("t/hello.cgi");

                    $ENV{REQUEST_METHOD} = 'GET';
                    $ENV{QUERY_STRING}   = 'name=foo';

                    capture_stdout { $sub->() } =~ /^Hello foo/m or exit(1);
                }
                catch {
                    print STDERR $_;
                    exit 1;
                };

                exit 0;
            }
            else { # parent
                $children{$child} = 1;
            }
        }

        # Wait for SIGCHLD reaper.
        select(undef, undef, undef, 0.005) while keys %children;
    };

    is $errors, '', 'no errors during compilation, runtime or global destruction';
}

done_testing;
