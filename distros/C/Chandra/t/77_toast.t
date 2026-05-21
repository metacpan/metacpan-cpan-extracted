#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 7;

BEGIN { use_ok('Chandra::Toast') }

# ── 1: XS methods exist ─────────────────────────────────

ok(Chandra::Toast->can('show'), 'show method exists');
ok(Chandra::Toast->can('dismiss'), 'dismiss method exists');
ok(Chandra::Toast->can('reset'), 'reset method exists');

# ── 2: Reset works ──────────────────────────────────────

eval { Chandra::Toast->reset };
ok(!$@, 'reset succeeds');

# ── 3: Class method signatures ───────────────────────────

# show() should croak without an app object
eval { Chandra::Toast->show("not_an_app", "hello") };
like($@, qr/Chandra::Toast/, 'show croaks without valid app');

# dismiss is a class method
ok(Chandra::Toast->can('dismiss'), 'dismiss is callable');

done_testing;
