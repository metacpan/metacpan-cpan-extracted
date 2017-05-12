#########################

use Test::More;
use Config::Directory;

#########################

plan skip_all => "Skip symlink tests on Windows" if $^O eq 'MSWin32';

# Corner-cases (symlinks and case)

ok(-d "t/t5");
my $c = Config::Directory->new([ "t/t2", "t/t5"]);
ok(ref $c);
is(keys %$c, 4, 'no. of keys ok');
# Test values
my @apple = split /\n/, $c->{APPLE};
ok(scalar(@apple) == 4 && $apple[$#apple] eq 'apple4', 'apples ok');
# Symlink to APPLE
@apple = split /\n/, $c->{CRAB};
ok(scalar(@apple) == 4 && $apple[$#apple] eq 'apple4', 'apples via symlink ok');
# banana vs APPLE
@apple = split /\n/, $c->{banana};
ok(scalar(@apple) == 9 && $apple[$#apple] == 9);
ok($c->{BANANA} == 2);
ok(! exists $c->{peach});
# Zero symlink overrides t2/PEAR
ok(! exists $c->{PEAR});

done_testing;

