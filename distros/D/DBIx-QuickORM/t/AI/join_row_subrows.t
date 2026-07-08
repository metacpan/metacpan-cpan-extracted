use Test2::V0;

# Regression tests for DBIx::QuickORM::Join::Row sub-row fan-out:
#  - field accessors must return undef (not crash) for a known alias whose
#    sub-row was dropped by a LEFT-JOIN miss, and croak cleanly for an unknown
#    alias or bare proto.
#  - is_valid must use all-semantics so a join row containing an invalidated
#    sub-row is not simultaneously is_valid and is_invalid.

require DBIx::QuickORM::Join::Row;

{
    package t::FakeJoin;
    sub new        { bless {}, shift }
    sub components { {a => 1, b => 1, c => 1} }    # 'c' is a valid component that missed the LEFT JOIN
}
{
    package t::FakeSubRow;
    sub new        { my ($c, %a) = @_; bless {%a}, $c }
    sub is_valid   { $_[0]->{valid} ? 1 : 0 }
    sub is_invalid { $_[0]->{valid} ? 0 : 1 }
    sub field      { "$_[0]->{tag}:$_[1]" }
}

# Build a Join::Row directly (its real init needs a live connection/manager);
# 'c' is intentionally absent from by_alias to model a LEFT-JOIN miss. Note
# Join::Row stores source/connection as closures (source() calls the slot).
sub join_row {
    my $join = t::FakeJoin->new;
    bless {
        source   => sub { $join },
        by_alias => {
            a => t::FakeSubRow->new(valid => 1, tag => 'A'),
            b => t::FakeSubRow->new(valid => 1, tag => 'B'),
        },
    }, 'DBIx::QuickORM::Join::Row';
}

subtest field_accessor_guards => sub {
    my $jr = join_row();

    is($jr->field('a.name'), 'A:name', "field() dispatches to a present sub-row");
    is($jr->field('c.name'), undef,    "field() on a known-but-absent (LEFT-JOIN-missed) sub-row returns undef");

    like(dies { $jr->field('zzz.x') }, qr/No subrow with alias 'zzz'/, "field() on an unknown alias croaks cleanly");
    like(dies { $jr->field('name') },  qr/No subrow with alias 'name'/, "a bare proto (no alias) croaks cleanly");

    is($jr->field_is_desynced('c.name'), undef, "other accessors also guard the absent sub-row");
};

subtest is_valid_is_all_semantics => sub {
    my $jr = join_row();

    ok($jr->is_valid,   "a join row with all sub-rows valid is valid");
    ok(!$jr->is_invalid, "and is not invalid");

    $jr->{by_alias}{b}{valid} = 0;    # invalidate one sub-row

    ok(!$jr->is_valid, "a join row with an invalidated sub-row is not valid");
    ok($jr->is_invalid, "and it reports invalid (never both true)");
};

done_testing;
