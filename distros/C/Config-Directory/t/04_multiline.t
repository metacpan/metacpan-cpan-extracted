#########################

use Test;
BEGIN { plan tests => 11 };
use Config::Directory;

#########################

# Multiline testing, prefixes

ok(-d "t/t4");
my $c = Config::Directory->new("t/t4", { prefix => 'FOO_', env => 1 });
ok(ref $c);
ok(keys %$c == 3);
# Test values
my @apple = split /\n/, $c->{FOO_APPLE};
ok(scalar(@apple) == 5 && $apple[4] eq 'apple5');
my @banana = split /\n/, $c->{FOO_BANANA};
ok(scalar(@banana) == 5 && $banana[4] == 5);
ok($c->{FOO_PEAR} == 3);
ok(! exists $c->{FOO_ORANGE});
# Test environment
ok(! exists $ENV{FOO_APPLE});
ok(! exists $ENV{FOO_BANANA});
ok($ENV{FOO_PEAR} == 3);
ok(! exists $ENV{FOO_ORANGE});
