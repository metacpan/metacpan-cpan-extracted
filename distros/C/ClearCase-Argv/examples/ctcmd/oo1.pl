use ClearCase::CtCmd;

my $ct = ClearCase::CtCmd->new;

# Returns an array containing three scalars: (exit status, stdout, stderr)
my @results = $ct->exec('pwv');

# Now distribute stdout to stdout, stderr to stderr, and return the exit code.
print STDOUT $results[1];
print STDERR $results[2];
exit $results[0];
