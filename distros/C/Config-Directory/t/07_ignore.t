#########################

use Test;
BEGIN { plan tests => 9 };
use Config::Directory;

#########################

# 'Ignore' testing

ok(-d "t/t7");
my $c = Config::Directory->new([ "t/t7", ], { ignore => '^P' });
ok(ref $c);
ok(keys %$c == 3);
# Test values
ok($c->{APPLE});
ok($c->{BANANA});
ok($c->{GRAPE});
ok(! exists $c->{ORANGE});
ok(! exists $c->{PEACH});
ok(! exists $c->{PEAR});
