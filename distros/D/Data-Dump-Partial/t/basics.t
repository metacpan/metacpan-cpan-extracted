#!perl -T

use strict;
use warnings;

use Test::More 0.98;
use Data::Dump::Partial qw(dump_partial dumpp);

#use lib "./t";
#require "testlib.pl";

is(dump_partial(1), 1, "export dump_partial");
is(dumpp(1), 1, "export dumpp");

# needs to be longer than the default max_len (32)
my $str = "KATA SIAPA ORANG SUNDA GAK BISA BILANG F ??? ITU PITNAH !!!";

is(dumpp($str, {max_total_len=>10}), '"' . substr($str, 0, 6) . '...', "option max_total_len=10");
is(dumpp($str, {max_total_len=>0, max_len=>0}), '"' . $str . '"', "option max_total_len=0");

is(dumpp(substr($str, 0, 10)), '"' . substr($str, 0, 10) . '"', "untruncated scalar");
is(dumpp($str), '"' . substr($str, 0, 29) . '..."', "truncated scalar");
is(dumpp($str, {max_len=>10}), '"' . substr($str, 0, 7) . '..."', "option max_len=10");
is(dumpp($str, {max_len=>0}), '"' . $str . '"', "option max_len=0");

is(dumpp([qw/q w e r t/]), '["q", "w", "e", "r", "t"]', "untruncated array");
is(dumpp([qw/q w e r t y/]), '["q", "w", "e", "r", "t", ...]', "truncated array");
is(dumpp([qw/q w e r t y/], {max_elems=>3}), '["q", "w", "e", ...]', "option max_elems=3");
is(dumpp([qw/q w e r t y/], {max_elems=>0}), '["q", "w", "e", "r", "t", "y"]', "option max_elems=0");

is(dumpp({qw/q 1 w 1 e 1 r 1 t 1/}), '{ e => 1, q => 1, r => 1, t => 1, w => 1 }', "untruncated hash");
is(dumpp({qw/q 1 w 1 e 1 r 1 t 1 y 1/}), '{ e => 1, q => 1, r => 1, t => 1, w => 1, ... }', "truncated hash");
is(dumpp({qw/q 1 w 1 e 1 r 1 t 1 y 1/}, {max_keys=>3}), '{ e => 1, q => 1, r => 1, ... }', "option max_keys=3");
is(dumpp({qw/q 1 w 1 e 1 r 1 t 1 y 1/}, {max_keys=>0}), '{ e => 1, q => 1, r => 1, t => 1, w => 1, y => 1 }', "option max_keys=0");

is(dumpp({qw/q 1 w 1 e 1 r 1 t 1 y 1/}, {max_keys=>3, worthless_keys=>[qw/q w e/]}), '{ r => 1, t => 1, y => 1, ... }', "option worthless_keys");
is(dumpp({qw/q 1 w 1 e 1 r 1 t 1 y 1/}, {max_keys=>3, precious_keys=>[qw/q w/]}), '{ e => 1, q => 1, w => 1, ... }', "option precious_keys (2)");
is(dumpp({qw/q 1 w 1 e 1 r 1 t 1 y 1/}, {max_keys=>3, precious_keys=>[qw/q w e/]}), '{ e => 1, q => 1, w => 1, ... }', "option precious_keys (3)");
is(dumpp({qw/q 1 w 1 e 1 r 1 t 1 y 1/}, {max_keys=>3, precious_keys=>[qw/q w e r/]}), '{ e => 1, q => 1, r => 1, w => 1, ... }', "option precious_keys (4)");
is(dumpp({qw/q 1 w 1 e 1 r 1 t 1 y 1/}, {max_keys=>3, hide_keys=>[qw/q w e/], worthless_keys=>[qw/r/]}), '{ r => 1, t => 1, y => 1, ... }', "option hide_keys");

is(dumpp({qw/q 1 password foo/}, {mask_keys_regex=>qr/pass/}), '{ password => "***", q => 1 }', "option mask_keys_regex");
is(dumpp({qw/q 1 password foo/, w=>{qw/e 1 pass barbaz/}}, {mask_keys_regex=>qr/pass/}), '{ password => "***", q => 1, w => { e => 1, pass => "***" } }', "option mask_keys_regex (nested)");

my $filter;
$filter = sub { my ($k, $v) = @_; if ($k =~ /pass/) { $v =~ s/./x/g } return ($k, $v); };
is(dumpp({qw/q 1 password foo/}, {pair_filter=>$filter}), '{ password => "xxx", q => 1 }', "option pair_filter (returns 1 pair)");
is(dumpp({qw/q 1 password foo/, w=>{qw/e 1 pass barbaz/}}, {pair_filter=>$filter}), '{ password => "xxx", q => 1, w => { e => 1, pass => "xxxxxx" } }', "option pair_filter (returns 1 pair, nested)");
$filter = sub { my ($k, $v) = @_; if ($k =~ /q/) { return () } else { return ($k, $v) } };
is(dumpp({qw/q 1 w 1/}, {pair_filter=>$filter}), '{ w => 1 }', "option pair_filter (returns 0 pair)");
$filter = sub { my ($k, $v) = @_; if ($k =~ /q/) { return ($k, $v, $k.2, $v) } else { return ($k, $v) } };
is(dumpp({qw/q 1 w 1/}, {pair_filter=>$filter}), '{ q => 1, q2 => 1, w => 1 }', "option pair_filter (returns 2 pairs)");

is(dumpp({qw/q 1 w 1 e 1 r 1 t 1/}, {max_keys=>1, dd_filter=>sub { return {dump=>"QWERT"}}}), 'QWERT', "option dd_filter");

is(dumpp([2, 4, 6, 8, $str, 12]), '[2, 4, 6, 8, "'.substr($str, 0, 29).'...", ...]', "nested scalar");
is(dumpp([2, 4, 6, 8, [2, 4, 6, 8, 10, 12], 12]), '[2, 4, 6, 8, [2, 4, 6, 8, 10, ...], ...]', "nested array");
is(dumpp([2, 4, 6, 8, {qw/q 1 w 1 e 1 r 1 t 1 y 1/}, 12]), '[2, 4, 6, 8, { e => 1, q => 1, r => 1, t => 1, w => 1, ... }, ...]', "nested hash");

my $a = {a=>1}; $a->{b} = $a; is(dumpp($a), q|do { my $a = { a => 1, b => 'fix' }; $a->{b} = $a; $a; }|, "remove newlines & indents");

done_testing;
