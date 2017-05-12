use Test::More;

plan tests => 4;

sub partyin { return 1; };
my $fun = \&partyin;

ok(partyin && partyin, "Yeah.");
ok(partyin && partyin, "Yeah.");
ok($fun, "Fun.");
ok($fun, "Fun.");

