#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($b1);

# A block does not end the scope: an assignment made anywhere in a sub holds
# until the sub returns.

$b1 = 'base';
sub in_if     { if ($_[0]) { $b1 = 'if' } $b1 }
sub in_else   { if (!$_[0]) { 1 } else { $b1 = 'else' } $b1 }
sub in_unless { unless (0) { $b1 = 'unless' } $b1 }
sub in_for    { for my $i (1 .. 2) { $b1 = "for$i" } $b1 }
sub in_cfor   { for (my $i = 1; $i <= 2; $i++) { $b1 = "cfor$i" } $b1 }
sub in_while  { my $n = 0; while ($n++ < 2) { $b1 = "while$n" } $b1 }
sub in_until  { my $n = 0; until ($n++ >= 2) { $b1 = "until$n" } $b1 }
sub in_bare   { { $b1 = 'bare' } $b1 }
sub in_do     { do { $b1 = 'do' }; $b1 }
sub in_mod    { $b1 = 'modifier' if 1; $b1 }
sub in_nested { for my $i (1) { if (1) { { $b1 = 'nested' } } } $b1 }
sub in_map    { my @x = map { $b1 = "map$_"; $_ } 1 .. 2; $b1 }
sub in_grep   { my @x = grep { $b1 = "grep$_"; 1 } 1 .. 2; $b1 }
sub in_sort   { my @x = sort { $b1 = 'sort'; $a <=> $b } 2, 1; $b1 }
sub in_map_expr { my @x = map { ($b1 = "mx$_") } 1 .. 2; $b1 }

for my $c ([in_if => \&in_if, 1, 'if'], [in_else => \&in_else, 1, 'else'], [in_unless => \&in_unless, 0, 'unless'],
           [in_for => \&in_for, 0, 'for2'], [in_cfor => \&in_cfor, 0, 'cfor2'], [in_while => \&in_while, 0, 'while2'],
           [in_until => \&in_until, 0, 'until2'], [in_bare => \&in_bare, 0, 'bare'], [in_do => \&in_do, 0, 'do'],
           [in_mod => \&in_mod, 0, 'modifier'], [in_nested => \&in_nested, 0, 'nested'], [in_map => \&in_map, 0, 'map2'],
           [in_grep => \&in_grep, 0, 'grep2'], [in_sort => \&in_sort, 0, 'sort'], [in_map_expr => \&in_map_expr, 0, 'mx2']) {
    my ($name, $code, $arg, $want) = @$c;
    is($code->($arg), $want, "$name: the write holds after its block, to the end of the sub");
    is($b1, 'base', "$name: and is gone when the sub returns");
    is(Context::Vars::_scope_kind($code), 1, "$name: the sub has a scope");
}
is(Context::Vars::_depth(), 0, 'no scope is left open');

done_testing;
