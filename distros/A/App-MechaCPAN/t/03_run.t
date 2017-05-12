use strict;
use Test::More;

require q[./t/helper.pm];

my $ret;

$App::MechaCPAN::TIMEOUT = 3;
sub run { goto &App::MechaCPAN::run }

# Successful run
is(eval { run $^X, '-e', 'exit 0'; 1 }, 1, 'Can successfully run');

# Failed run
is(eval { run $^X, '-e', 'exit 1'; 1 }, undef, 'Can successfully fail');

# Output
my @lines = qw/line1 line2 line3/;
my @output = eval { run $^X, '-e', "print join(qq[\\n], qw[@lines]);" };
is_deeply(\@output, \@lines, 'Result from run is STDOUT');

# Timeout run
is(eval { run $^X, '-e', 'sleep 10'; 1 }, undef, 'Will timeout without output');
is(eval { run $^X, '-e', 'sleep 2; print STDERR "\n"; sleep 2;'; 1 }, 1, 'Output resets timeout');

done_testing;
