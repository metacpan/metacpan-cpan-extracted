use strict;
use warnings;
use Test::More tests => 31;
use File::Temp qw(tempdir);
use Apophis;

my $dir = tempdir(CLEANUP => 1);
my $ca = Apophis->new(namespace => 'test-ops', store_dir => $dir);

# --- Custom op creation ---

my $op_id = Apophis::_make_op('identify');
like($op_id, qr/^CUSTOM_OP\@apophis_identify/, 'identify op created');

my $op_st = Apophis::_make_op('store');
like($op_st, qr/^CUSTOM_OP\@apophis_store/, 'store op created');

my $op_ex = Apophis::_make_op('exists');
like($op_ex, qr/^CUSTOM_OP\@apophis_exists/, 'exists op created');

my $op_fe = Apophis::_make_op('fetch');
like($op_fe, qr/^CUSTOM_OP\@apophis_fetch/, 'fetch op created');

my $op_ve = Apophis::_make_op('verify');
like($op_ve, qr/^CUSTOM_OP\@apophis_verify/, 'verify op created');

my $op_rm = Apophis::_make_op('remove');
like($op_rm, qr/^CUSTOM_OP\@apophis_remove/, 'remove op created');

# --- op_identify matches identify ---

my $content = 'custom op test content';
my $id_method = $ca->identify(\$content);
my $id_op     = $ca->op_identify(\$content);
is($id_op, $id_method, 'op_identify matches identify');

# v5 format
like($id_op, qr/^[0-9a-f]{8}-[0-9a-f]{4}-5[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/,
     'op_identify returns valid UUID v5');

# Deterministic
my $id_op2 = $ca->op_identify(\$content);
is($id_op2, $id_op, 'op_identify is deterministic');

# --- op_store matches store ---

my $id_stored_op = $ca->op_store(\$content);
is($id_stored_op, $id_method, 'op_store returns same UUID as identify');

# Content actually stored
my $fetched = $ca->fetch($id_stored_op);
is($$fetched, $content, 'op_store writes correct content');

# CAS dedup — store again, no error
my $id_dup = $ca->op_store(\$content);
is($id_dup, $id_stored_op, 'op_store dedup works');

# --- op_exists ---

ok($ca->op_exists($id_stored_op), 'op_exists returns true for stored item');
ok(!$ca->op_exists('00000000-0000-5000-8000-000000000000'),
   'op_exists returns false for nonexistent');

# --- op_store + op_exists round-trip with new content ---

my $new_content = 'another piece of content';
my $new_id = $ca->op_store(\$new_content);
ok($ca->op_exists($new_id), 'op_exists confirms op_store');

# Verify with standard fetch
my $fetched2 = $ca->fetch($new_id);
is($$fetched2, $new_content, 'standard fetch reads op_store content');

# --- op methods interop with standard methods ---

$ca->remove($new_id);
ok(!$ca->op_exists($new_id), 'op_exists reflects standard remove');

# --- op_fetch ---

my $fetch_content = 'fetch op test data';
my $fetch_id = $ca->store(\$fetch_content);

my $op_fetched = $ca->op_fetch($fetch_id);
ok(defined $op_fetched, 'op_fetch returns defined for stored item');
is($$op_fetched, $fetch_content, 'op_fetch returns correct content');

# op_fetch matches standard fetch
my $std_fetched = $ca->fetch($fetch_id);
is($$op_fetched, $$std_fetched, 'op_fetch matches standard fetch');

# op_fetch returns undef for nonexistent
my $op_fetched_missing = $ca->op_fetch('00000000-0000-5000-8000-000000000000');
ok(!defined $op_fetched_missing, 'op_fetch returns undef for nonexistent');

# op_fetch reads op_store content
my $rt_content = 'round-trip via ops';
my $rt_id = $ca->op_store(\$rt_content);
my $rt_fetched = $ca->op_fetch($rt_id);
is($$rt_fetched, $rt_content, 'op_fetch reads op_store content');

# --- op_verify ---

ok($ca->op_verify($fetch_id), 'op_verify returns true for intact content');
ok($ca->op_verify($rt_id), 'op_verify returns true for op_store content');
ok(!$ca->op_verify('00000000-0000-5000-8000-000000000000'),
   'op_verify returns false for nonexistent');

# op_verify matches standard verify
my $std_verify = $ca->verify($fetch_id);
my $op_verify  = $ca->op_verify($fetch_id);
is(!!$op_verify, !!$std_verify, 'op_verify matches standard verify');

# --- op_remove ---

my $rm_content = 'content to remove via op';
my $rm_id = $ca->op_store(\$rm_content);
ok($ca->op_exists($rm_id), 'item exists before op_remove');

ok($ca->op_remove($rm_id), 'op_remove returns true for existing item');
ok(!$ca->op_exists($rm_id), 'op_exists false after op_remove');
ok(!$ca->op_remove($rm_id), 'op_remove returns false for already removed');

# Standard fetch confirms removal
ok(!defined $ca->fetch($rm_id), 'standard fetch confirms op_remove');
