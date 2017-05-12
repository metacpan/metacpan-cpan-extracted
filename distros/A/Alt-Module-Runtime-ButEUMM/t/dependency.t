# This test checks that M:R doesn't load any other modules.  Hence this
# script cannot itself use warnings, Test::More, or any other module.

BEGIN { print "1..1\n"; }
our(%preloaded, @extraloaded);
BEGIN { %preloaded = %INC; }
use Module::Runtime qw(require_module);
BEGIN { @extraloaded = sort grep { !exists($preloaded{$_}) } keys %INC; }
print join(" ", @extraloaded) eq "Module/Runtime.pm" ? "" : "not ", "ok 1\n";

1;
