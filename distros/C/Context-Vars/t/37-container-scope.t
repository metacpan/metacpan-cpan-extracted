#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# One scope rule for arrays, hashes, nested levels and a scalar holding a
# structure: a change in a sub is undone when the sub returns.
use Context::Vars qw(@trail %seen $variable);

sub kind { Context::Vars::_scope_kind($_[0]) }

@trail = ('top');
%seen = (top => 1);
$variable = { top => { k => 1 } };

# S3: each write form in a sub is undone when it returns.
my %forms = (
    push        => sub { push @trail, 'x'; scalar @trail },
    pop         => sub { pop @trail; scalar @trail },
    shift       => sub { shift @trail; scalar @trail },
    unshift     => sub { unshift @trail, 'x'; scalar @trail },
    splice      => sub { splice @trail, 0, 1; scalar @trail },
    elem_a      => sub { $trail[0] = 'x'; $trail[0] },
    elem_h      => sub { $seen{new} = 1; scalar keys %seen },
    delete_h    => sub { delete $seen{top}; scalar keys %seen },
    assign_a    => sub { @trail = (1, 2, 3); scalar @trail },
    assign_h    => sub { %seen = (a => 1, b => 2); scalar keys %seen },
    in_block    => sub { if (1) { push @trail, 'x' } scalar @trail },
    slice_h     => sub { @seen{qw(p q)} = (1, 2); scalar keys %seen },
);
for my $name (sort keys %forms) {
    my $code = $forms{$name};
    my $inside = $code->();
    is_deeply([\@trail, \%seen], [['top'], { top => 1 }], "S3 $name: undone when the sub returns (inside it read $inside)");
    ok(kind($code), "S3 $name: the sub has a scope");
}
my $reader = sub { my $x = $trail[0] . $seen{top}; scalar @trail };
$reader->();
is(kind($reader), 0, 'S3: a sub that only reads has no scope');

# S4: nested levels follow the context.
%seen = (a => { b => 0 }, list => [1]);
@trail = ({ k => 'v' });
my @inside;
sub callee { push @inside, $seen{a}{b}, scalar @{ $seen{list} }, $trail[0]{k} }
sub nested_writes {
    $seen{a}{b} = 1;
    push @{ $seen{list} }, 2;
    $trail[0]{k} = 'changed';
    callee();
}
nested_writes();
is_deeply(\@inside, [1, 2, 'changed'], 'S4: a callee reads the nested writes while the sub runs');
is($seen{a}{b}, 0, 'S4: $seen{a}{b} = 1 is undone when the sub returns');
is(scalar @{ $seen{list} }, 1, 'S4: push @{ $seen{list} } is undone');
is($trail[0]{k}, 'v', 'S4: $trail[0]{k} = ... is undone');
ok(kind(\&nested_writes), 'S4: the sub has a scope');

# A dereference written as a block, alone in a sub: nothing else there gives
# the sub a scope, so the block form itself has to be followed to its root.
%seen = (user => { roles => ['reader'] }, l => [1]);
sub push_two_down   { push @{ $seen{user}{roles} }, 'admin'; scalar @{ $seen{user}{roles} } }
sub push_one_down   { push @{ $seen{l} }, 2; scalar @{ $seen{l} } }
sub assign_block    { %{ $seen{user} } = (name => 'x'); scalar keys %{ $seen{user} } }
sub arrow_block     { push @{$seen{user}->{roles}}, 'admin'; 1 }
sub elem_in_block   { ${ $seen{user} }{name} = 'y'; 1 }
for my $c ([push_two_down => \&push_two_down, 2], [push_one_down => \&push_one_down, 2],
           [assign_block => \&assign_block, 1], [arrow_block => \&arrow_block, 1], [elem_in_block => \&elem_in_block, 1]) {
    my ($name, $code, $want) = @$c;
    ok(kind($code), "block dereference, $name: the sub has a scope");
    is($code->(), $want, "block dereference, $name: inside, the change is read");
    is_deeply(\%seen, { user => { roles => ['reader'] }, l => [1] }, "block dereference, $name: undone when the sub returns");
}

# S5: the same through a scalar.
my @s5;
sub through_scalar { $variable->{top}{k} = 2; push @s5, $variable->{top}{k} }
through_scalar();
is($s5[0], 2, 'S5: inside, the nested write through the scalar is read');
is($variable->{top}{k}, 1, 'S5: and it is undone when the sub returns');
ok(kind(\&through_scalar), 'S5: the sub has a scope');
sub replace_scalar { $variable = { other => 1 }; 1 }
replace_scalar();
is($variable->{top}{k}, 1, 'S5: replacing the reference is undone too');

is(Context::Vars::_depth(), 0, 'no scope left open');
done_testing;
