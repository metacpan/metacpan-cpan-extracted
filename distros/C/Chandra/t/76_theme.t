#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 15;

BEGIN { use_ok('Chandra::Theme') }

# ── 1: Built-in theme list ───────────────────────────────

my @themes = Chandra::Theme->themes;
ok(scalar(@themes) >= 2, 'at least 2 built-in themes');
ok((grep { $_ eq 'light' } @themes), 'light theme exists');
ok((grep { $_ eq 'dark' } @themes), 'dark theme exists');

# ── 2: Get theme tokens ─────────────────────────────────

my $light = Chandra::Theme->get('light');
ok($light, 'get light returns hashref');
is($light->{bg}, '#ffffff', 'light bg is white');
ok($light->{primary}, 'light has primary colour');
ok($light->{font}, 'light has font family');

my $dark = Chandra::Theme->get('dark');
ok($dark, 'get dark returns hashref');
is($dark->{bg}, '#14181b', 'dark bg is dark');

# ── 3: Unknown theme ────────────────────────────────────

my $nope = Chandra::Theme->get('nope');
ok(!$nope, 'unknown theme returns undef');

# ── 4: CSS vars generation ──────────────────────────────

my $vars = Chandra::Theme->_vars_css($light);
like($vars, qr/--chandra-primary/, 'vars contains --chandra-primary');
like($vars, qr/--chandra-bg:\s*#ffffff/, 'vars contains --chandra-bg value');
like($vars, qr/--chandra-radius/, 'vars contains --chandra-radius');

# ── 5: Component CSS ────────────────────────────────────

my $comp_css = Chandra::Theme->_component_css;
like($comp_css, qr/chandra-table/, 'component CSS includes table styles');

done_testing;
