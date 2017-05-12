#########################

use Test;
BEGIN { plan tests => 9 };
use Config::Directory;

#########################

# Maxsize testing

ok(-d "t/t6");
my $c = Config::Directory->new([ "t/t6", ], { env => 1, maxsize => 200 });
ok(ref $c);
ok(keys %$c == 2);
# Test values
ok($c->{APPLE} eq 'apple');
ok(! exists $c->{BANANA});
ok(length($c->{ORANGE}) < 200);
# Test environment
ok($ENV{APPLE} eq 'apple');
ok(! exists $ENV{TEST_BANANA});
ok(! exists $ENV{TEST_ORANGE});
