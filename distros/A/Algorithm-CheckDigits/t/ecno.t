use Test;
BEGIN {
	plan(tests => 13);
};
use Algorithm::CheckDigits;

my $ecno = CheckDigits('ECNo');

#
ok(not $ecno->is_valid("200-001-0"));
ok(not $ecno->is_valid("200-001-1"));
ok(not $ecno->is_valid("200-001-2"));
ok(not $ecno->is_valid("200-001-3"));
ok(not $ecno->is_valid("200-001-4"));
ok(not $ecno->is_valid("200-001-5"));
ok(not $ecno->is_valid("200-001-6"));
ok(not $ecno->is_valid("200-001-7"));
ok($ecno->is_valid("200-001-8"));
ok(not $ecno->is_valid("200-001-9"));
ok($ecno->is_valid("220-001-1"));
ok($ecno->is_valid("230-001-3"));
ok($ecno->is_valid("310-001-0"));
