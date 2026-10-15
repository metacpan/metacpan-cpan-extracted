#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Arrays and hashes as context variables: every ordinary operation.
use Context::Vars qw(@trail %seen);

# S1
ok(eval q{package S1::A; use strict; use Context::Vars qw(@trail %seen); push @trail, 1; $seen{x} = 1; 1}, 'S1: @ and % compile under strict') or diag $@;
ok(!eval q{package S1::B; use strict; push @trail, 1; 1}, 'S1: not in a package that did not import them');
{ package S1::C; use Context::Vars qw(@trail); sub look { scalar @trail } }

Context::Vars::_t_scope(sub {
    # S2 hashes
    %seen = ();
    $seen{a} = 1; $seen{b} = 2;
    is($seen{a}, 1, 'S2: element read after write');
    ok(exists $seen{b}, 'S2: exists');
    is(join(',', sort keys %seen), 'a,b', 'S2: keys');
    is(join(',', sort { $a <=> $b } values %seen), '1,2', 'S2: values');
    my %copy; while (my ($k, $v) = each %seen) { $copy{$k} = $v }
    is_deeply(\%copy, { a => 1, b => 2 }, 'S2: each');
    is(delete $seen{a}, 1, 'S2: delete returns the value');
    ok(!exists $seen{a}, 'S2: and the key is gone');
    is(scalar(%seen) ? 1 : 0, 1, 'S2: a hash in boolean context');
    %seen = (x => 1, y => 2);
    is(join(',', sort keys %seen), 'x,y', 'S2: whole assignment');
    my @sl = @seen{qw(x y)};
    is("@sl", '1 2', 'S2: hash slice read');
    @seen{qw(p q)} = (8, 9);
    is($seen{q}, 9, 'S2: hash slice write');
    %seen = ();
    is(scalar(keys %seen), 0, 'S2: cleared');

    # S2 arrays
    @trail = (1, 2, 3);
    is(scalar(@trail), 3, 'S2: scalar @a');
    is($#trail, 2, 'S2: $#a');
    is($trail[1], 2, 'S2: element read');
    $trail[1] = 'two';
    is("@trail", '1 two 3', 'S2: element write');
    push @trail, 4, 5;
    is("@trail", '1 two 3 4 5', 'S2: push');
    is(pop @trail, 5, 'S2: pop');
    is(shift @trail, 1, 'S2: shift');
    unshift @trail, 'zero';
    is("@trail", 'zero two 3 4', 'S2: unshift');
    my @gone = splice @trail, 1, 2, 'x', 'y', 'z';
    is("@gone|@trail", 'two 3|zero x y z 4', 'S2: splice');
    $trail[7] = 'far';
    is(scalar(@trail), 8, 'S2: writing past the end grows it');
    $#trail = 1;
    is("@trail", 'zero x', 'S2: $#a = n truncates');
    is(S1::C::look(), 2, 'S1: another importer sees the same array');
    my @s = @trail[0, 1];
    is("@s", 'zero x', 'S2: array slice');
    is(join(',', map { uc } @trail), 'ZERO,X', 'S2: map over it');
    my $n = 0; $n++ for @trail;
    is($n, 2, 'S2: for over it');
    @trail = ();
    is(scalar(@trail), 0, 'S2: cleared');
});

done_testing;
