#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# What is converted and what is shared; captures; what a proxy is; writes the
# compile pass does not see; autovivification.
use Context::Vars qw(%seen @trail $variable);

# S6: objects and code are kept as they are.
my $obj  = bless { n => 1 }, 'S6::Obj';
my $code = sub { 'code' };
Context::Vars::_t_scope(sub {
    %seen = (obj => $obj, code => $code, nested => { obj => $obj });
    is($seen{obj}, $obj, 'S6: an object comes back as the same reference');
    is($seen{code}, $code, 'S6: so does code');
    is($seen{nested}{obj}, $obj, 'S6: and an object inside a nested hash');
    $seen{obj}{n} = 2;
    is($obj->{n}, 2, 'S6: an object\'s insides are shared, as with any reference');
});

# S7: a capture sees the containers of its moment, at every level.
my $cap;
sub take {
    %seen = (a => { b => 1 });
    @trail = (1);
    $cap = Context::Vars->capture;
    $seen{a}{b} = 2;
    push @trail, 2;
    return;
}
take();
my @seen_in_cap = $cap->run(sub { ($seen{a}{b}, scalar @trail) });
is_deeply(\@seen_in_cap, [1, 1], 'S7: a capture reads its moment, nested level included, not later writes');
my $w;
sub wrap_it { %seen = (k => 'wrapped'); $w = Context::Vars->wrap(sub { $seen{k} }) }
wrap_it();
is($w->(), 'wrapped', 'S7: a wrapped callback reads its moment');

# S9: what a proxy is.
Context::Vars::_t_scope(sub {
    %seen = (a => { x => 1, y => 2 });
    is(ref $seen{a}, 'HASH', 'S9: a nested hash reads as a HASH reference');
    is(join(',', sort keys %{ $seen{a} }), 'x,y', 'S9: keys through it');
    ok($seen{a} != $seen{a}, 'S9: two reads of $seen{a} are two references, not ==');
    sub writes_through { $_[0]{z} = 3 }
    writes_through($seen{a});
    is($seen{a}{z}, 3, 'S9: a sub given $seen{a} that writes through $_[0] is not scoped: the write lands in the current context');
    my $plain = { %{ $seen{a} } };
    ok(!tied(%$plain), 'S9: copying it out gives a plain hash');
});

# S10: a write the pass cannot see, through a proxy kept in a lexical.
Context::Vars::_t_scope(sub {
    %seen = (a => { b => 1 });
    my $sub = sub { my $h = $seen{a}; $h->{b} = 'through a lexical'; 1 };
    $sub->();
    is($seen{a}{b}, 'through a lexical', 'S10: a write through a proxy kept in a lexical is not scoped');
    is(Context::Vars::_scope_kind($sub), 0, 'S10: and gives the sub no scope');
});

# Autovivification through the proxies.
Context::Vars::_t_scope(sub {
    %seen = ();
    $seen{new}{deeper} = 1;
    is($seen{new}{deeper}, 1, 'autovivification through a proxy keeps the value');
    push @{ $seen{list} }, 'x';
    is(scalar @{ $seen{list} || [] }, 1, 'autovivification of an array through a proxy keeps the value');
});

done_testing;
