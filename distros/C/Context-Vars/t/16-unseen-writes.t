#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Context::Vars qw($u);

# Writes the compile pass cannot see. Each lands in whatever context is
# current. Pinned, so that a change to any of them is noticed.

sub held { (Context::Vars::_t_fetch('u'))[0] }

Context::Vars::_t_scope(sub {
    Context::Vars::_t_store(u => 'scope');

    sub through_arg { $_[0] = 'via @_' }
    through_arg($u);
    is(held(), 'via @_', 'a write through @_ lands in the caller\'s context: the sub passing it has no scope from that');
    is(Context::Vars::_scope_kind(\&through_arg), 0, 'and the sub that wrote it has none');

    my $writer = sub { for my $x ($u) { $x = 'via for alias' } };
    $writer->();
    is(held(), 'via for alias', 'a write through a for alias is not seen');
    is(Context::Vars::_scope_kind($writer), 0, 'and gives the sub no scope');

    my $globber = sub { no strict 'refs'; ${"main::u"} = 'via symbolic ref' };
    $globber->();
    is(held(), 'via symbolic ref', 'a write through a symbolic reference is not seen');

    my $mapper = sub { $_ = 'via map alias' for grep { 1 } $u };
    $mapper->();
    is(held(), 'via map alias', 'a write through a grep alias is not seen');

    my $evaller = sub { eval q{ $u = 'via string eval'; 1 } or die $@ };
    $evaller->();
    is(held(), 'via string eval', 'a write in a string eval inside a sub that has no write of its own is not scoped');

    my $ref_taker = sub { my $r = \$u; $$r = 'via a reference taken here' };
    my $was = held();
    $ref_taker->();
    is(held(), $was, 'a sub that takes a reference to the variable IS given a scope, so its write through it ends with it');
    ok(Context::Vars::_scope_kind($ref_taker), 'it has one');
});

# BEGIN is never given a scope: an assignment there is the program's.
our $begin_saw;
BEGIN { $u = 'from BEGIN'; $begin_saw = $u }
is($begin_saw, 'from BEGIN', 'an assignment in BEGIN is read inside it');
is($u, 'from BEGIN', 'and holds for the program afterwards');

is(Context::Vars::_depth(), 0, 'no scope is left open');

done_testing;
