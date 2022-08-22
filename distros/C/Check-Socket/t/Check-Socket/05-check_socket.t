use strict;
use warnings;

use Check::Socket qw(check_socket);
use Config;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $ret = check_socket;
if ($ENV{PERL_CORE} and $Config{'extensions'} =~ /\bSocket\b/) {
	is($ret, 1, 'Test for successful socket communication (Socket extension).');
} elsif ($^O eq 'qnx') {
	is($ret, 0, 'Test the impossibility of socket communication (qnx).');
} elsif ($^O eq 'tos') {
	is($ret, 0, 'Test the impossibility of socket communication (tos).');
} elsif ($^O eq 'nto') {
	is($ret, 0, 'Test the impossibility of socket communication (nto).');
} else {
	ok(1, 'TODO: Support for other real examples.');
}
