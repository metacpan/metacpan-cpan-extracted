#########################

use Test;
BEGIN { plan tests => 11 };
use Config::Directory;

#########################

# Standard use testing, single directory, env

ok(-d "t/t2");
my $c = Config::Directory->new("t/t2", { env => 1, lines => 1 });
ok(ref $c);
ok(keys %$c == 3);
# Test values
ok($c->{APPLE} == 1);
ok($c->{BANANA} == 2);
ok($c->{PEAR} == 3);
ok(! exists $c->{ORANGE});
# Test environment
ok($ENV{APPLE} == 1);
ok($ENV{BANANA} == 2);
ok($ENV{PEAR} == 3);
ok(! exists $ENV{ORANGE});
