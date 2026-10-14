#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($c);

# Opening a scope changes nothing about what the sub returns, in any context,
# or about what it is given.

sub plain  { my @r = (1, 2, 3); return wantarray ? @r : defined(wantarray) ? 'scalar' : do { $main::void_plain++; () } }
sub scoped { $c = 'x'; my @r = (1, 2, 3); return wantarray ? @r : defined(wantarray) ? 'scalar' : do { $main::void_scoped++; () } }
ok(Context::Vars::_scope_kind(\&scoped), 'the sub under test has a scope');

is_deeply([scoped()], [plain()], 'list context');
is(scalar(scoped()), scalar(plain()), 'scalar context');
plain(); scoped();
is($main::void_scoped, $main::void_plain, 'void context');

sub args { $c = 'x'; join '-', @_ }
is(args(qw(a b c)), 'a-b-c', '@_ arrives as it was passed');
sub shifts { $c = 'x'; my ($x, $y) = @_; "$x$y" }
is(shifts(1, 2), '12', 'and can be unpacked');
sub implicit { $c = 'x'; my @l = (4, 5); @l }
is_deeply([implicit()], [4, 5], 'an implicit list return');
sub last_expr { $c = 'x'; 7 * 6 }
is(last_expr(), 42, 'an implicit scalar return');
sub empty_return { $c = 'x'; return }
is_deeply([empty_return()], [], 'a bare return in list context');
ok(!defined scalar(empty_return()), 'and in scalar context');
my $store = 0;
sub lv :lvalue { $c = 'x'; $store }
lv() = 9;
is($store, 9, 'an lvalue sub');
sub with_proto($$) { $c = 'x'; $_[0] + $_[1] }
is(with_proto(2, 3), 5, 'a sub with a prototype');
sub returns_c { $c = 'mine'; $c }
is(returns_c(), 'mine', 'returning the variable itself returns its value at the time');
my $ref = sub { $c = 'x'; [@_] }->(1, 2);
is_deeply($ref, [1, 2], 'an anonymous sub called at once');
if ($] >= 5.020) {
    my $sig = eval q{ use feature 'signatures'; no warnings; sub ($x, $y = 10) { $c = 'x'; $x + $y } };
    is($sig->(1), 11, 'a sub with a signature and a default');
}
is(Context::Vars::_depth(), 0, 'no scope is left open');

done_testing;
