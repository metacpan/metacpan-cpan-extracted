#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($top $other);

# Code outside any entered context. A read there stores nothing; the first
# assignment there makes the program context, which such code then shares.

ok(!defined $top, 'at the top level a variable reads undef');
ok(Context::Vars::_t_is_empty(), 'and the empty context is current');
$top = undef;
ok(!Context::Vars::_has_program(), 'assigning undef where nothing is set makes nothing');

sub reads_top { $top }

$top = 'file';
ok(Context::Vars::_has_program(), 'the first assignment at the top level makes the program context');
ok(!Context::Vars::_t_is_empty(), 'which is now current');
is($top, 'file', 'a later statement reads it');
is(reads_top(), 'file', 'and so does a sub called from the top level');
is(Context::Vars::_live_holders(), 0, 'the program context is not counted as a holder that was handed out');

my $program = Context::Vars::_t_current();
$other = 'second';
is(Context::Vars::_t_current(), $program, 'a second assignment uses the same program context');
is(Context::Vars::_t_count(), 2, 'which holds both');

# An entered context does not see the program's values unless it began from them.
my $empty_cap;
{
    my $seen;
    Context::Vars::_t_scope(sub { $seen = $top; $top = 'scoped' });
    is($seen, 'file', 'a scope opened at the top level starts from the program context');
    is($top, 'file', 'and its assignment stays inside it');
}

# A capture of nothing, taken before the program context existed, is the
# empty one. Entering it and assigning gives that frame a holder of its own.
{
    my $r = system($^X, (map { "-I$_" } grep { !ref } @INC), '-e', q{
        use strict; use Context::Vars qw($x);
        my $base = Context::Vars::_empty_refcnt();
        my $cap = Context::Vars::_t_capture();
        my @out;
        Context::Vars::_t_enter($cap, sub { $x = 'inside'; push @out, $x });
        push @out, defined $x ? $x : 'undef';
        push @out, Context::Vars::_has_program() ? 'program' : 'no program';
        push @out, Context::Vars::_t_is_empty() ? 'empty' : 'not empty';
        Context::Vars::_t_release($cap);
        push @out, Context::Vars::_live_holders();
        push @out, Context::Vars::_empty_refcnt() - $base;
        exit(join(',', @out) eq 'inside,undef,no program,empty,0,0' ? 0 : 1);
    });
    is($r, 0, 'an entered capture of nothing takes a holder of its own on the first assignment, gives it back, '
            . 'and leaves the empty context with the references it had before');
}

is(Context::Vars::_depth(), 0, 'nothing is left entered');

done_testing;
