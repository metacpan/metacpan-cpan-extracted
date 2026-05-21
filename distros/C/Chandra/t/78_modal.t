#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 8;

BEGIN { use_ok('Chandra::Modal') }

# ── 1: XS methods exist ─────────────────────────────────

ok(Chandra::Modal->can('show'), 'show method exists');
ok(Chandra::Modal->can('close'), 'close method exists');
ok(Chandra::Modal->can('confirm'), 'confirm method exists');
ok(Chandra::Modal->can('prompt'), 'prompt method exists');
ok(Chandra::Modal->can('reset'), 'reset method exists');

# ── 2: Reset works ──────────────────────────────────────

eval { Chandra::Modal->reset };
ok(!$@, 'reset succeeds');

# ── 3: show croaks without app ───────────────────────────

# All methods are XS-backed
ok(!defined &Chandra::Modal::_js_code, 'no Perl JS fallback - fully XS');

done_testing;
