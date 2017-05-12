use Test::More tests => 3;

my $package = 'Class::Accessor::Classy';
eval("use $package ();");
ok(! $@, 'use_ok') or BAIL_OUT("load failed: $@");
eval("use $package;");
ok($@);
like($@, qr/^cannot have accessors on the main package/);

eval {require version};
diag("Testing $package ", $package->VERSION);

# vi:syntax=perl:ts=2:sw=2:et:sta
