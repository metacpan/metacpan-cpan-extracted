use v5.14;
use Test::More;
use Test::Output;

my $exit;
sub run { system($^X, 'script/skos2jskos', @_); $exit = $? >> 8 }

output_like { run() } qr/^Usage:\n\s+skos2jskos/m, qr/^$/, 'help by default';
is $exit, 1, 'exit code';

stderr_is { run('-d','t/xxx','foo') } "output directory not found: t/xxx\n",
    'check directory';
is $exit, 2, 'exit code';

done_testing;
