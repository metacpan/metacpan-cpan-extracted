#!perl

use Capture::Tiny 'capture_stdout';
use CGI::Compile;
use POSIX qw(:signal_h);

use Test::More $^O eq 'MSWin32' ? (
    skip_all => 'not supported on Win32') 
: (
    tests => 1
);

unless (defined sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new(SIGQUIT))) {
    die "Could not unblock SIGQUIT\n";
}

my $sub = CGI::Compile->compile(\<<'EOF');
$SIG{QUIT} = sub{print "QUIT\n"};
kill QUIT => $$;
print "END\n";
EOF

is capture_stdout { $sub->() }, "QUIT\nEND\n", 'caught signal';
