use strict;
use warnings;

use Test::More;
my $tests;
plan tests => $tests;

use Config::Any::Log4perl;

BEGIN { $tests = 2; }

ok(defined $Config::Any::Log4perl::VERSION);
ok($Config::Any::Log4perl::VERSION =~ /^\d{1}.\d{6}$/);

BEGIN { $tests += 1; }

can_ok('Config::Any::Log4perl', qw(extensions load));
