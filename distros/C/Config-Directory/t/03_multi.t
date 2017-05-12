#########################

use Test;
BEGIN { plan tests => 13 };
use Config::Directory;

#########################

# Multiple directory testing, env

ok(-d "t/t2" && -d "t/t3");
my $c = Config::Directory->new([ "t/t2", "t/t3" ], { env => 'TEST_', lines => 1 });
ok(ref $c);
ok(keys %$c == 3);
# Test values
ok($c->{APPLE} eq 'apple');
ok(! exists $c->{BANANA});
ok($c->{PEAR} == 3);
ok($c->{GRAPE} eq 'grape');
ok(! exists $c->{ORANGE});
# Test environment
ok($ENV{TEST_APPLE} eq 'apple');
ok(! exists $ENV{TEST_BANANA});
ok($ENV{TEST_PEAR} == 3);
ok($ENV{TEST_GRAPE} eq 'grape');
ok(! exists $ENV{TEST_ORANGE});
