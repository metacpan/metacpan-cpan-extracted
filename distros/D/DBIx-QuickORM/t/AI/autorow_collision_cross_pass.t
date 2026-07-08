use Test2::V0 '!meta', '!pass';

# define_autorow runs twice against the same generated row class: once for the
# introspected schema and once for the merged schema. A relationship that only
# appears on the second pass must still be caught when its accessor name
# collides with a column accessor installed on the first pass, rather than being
# silently dropped.

use DBIx::QuickORM::Schema::Autofill;
use DBIx::QuickORM::Schema::Table;
use DBIx::QuickORM::Schema::Table::Column;
use DBIx::QuickORM::Link;

sub col {
    my ($name) = @_;
    return DBIx::QuickORM::Schema::Table::Column->new(name => $name, order => 1, type => \'integer');
}

sub link_to {
    my ($other, @aliases) = @_;
    return DBIx::QuickORM::Link->new(
        local_table   => 'source',
        local_columns => ['other_id'],
        other_table   => $other,
        other_columns => ['id'],
        unique        => 0,
        aliases       => [@aliases],
    );
}

my $autofill = DBIx::QuickORM::Schema::Autofill->new(types => {}, affinities => {}, hooks => {}, skip => {});

subtest collision_across_passes => sub {
    my $row_class = 'My::AutorowB6::Collide';

    # Pass 1 (introspected): a column named 'foo' -> installs a 'foo' accessor.
    my $pass1 = DBIx::QuickORM::Schema::Table->new(
        name    => 'source',
        columns => {foo => col('foo'), id => col('id')},
    );

    # Pass 2 (merged): a declared relationship aliased 'foo'.
    my $pass2 = DBIx::QuickORM::Schema::Table->new(
        name    => 'source',
        columns => {id => col('id')},
        links   => [link_to('others', 'foo')],
    );

    ok(lives { $autofill->define_autorow($row_class, $pass1) }, "first pass installs the column accessor") or note $@;
    ok($row_class->can('foo'), "the 'foo' column accessor exists after pass 1");

    my $err = dies { $autofill->define_autorow($row_class, $pass2) };
    ok($err, "the second pass croaks on the relationship colliding with the column accessor");
    like($err, qr/Cannot generate the 'foo' accessor/, "diagnostic names the colliding accessor");
    like($err, qr/column accessor/, "diagnostic mentions the column side of the collision");
    like($err, qr/relationship to 'others'/, "diagnostic mentions the relationship side of the collision");
};

subtest no_false_collision => sub {
    my $row_class = 'My::AutorowB6::Clean';

    my $pass1 = DBIx::QuickORM::Schema::Table->new(
        name    => 'source',
        columns => {id => col('id')},
    );

    my $pass2 = DBIx::QuickORM::Schema::Table->new(
        name    => 'source',
        columns => {id => col('id')},
        links   => [link_to('others', 'others_rel')],
    );

    ok(lives { $autofill->define_autorow($row_class, $pass1) }, "pass 1 is clean") or note $@;
    ok(lives { $autofill->define_autorow($row_class, $pass2) }, "a non-colliding relationship on pass 2 does not croak") or note $@;
    ok($row_class->can('others_rel'), "the relationship accessor is installed");
};

subtest no_leak_across_independent_builds => sub {
    # The claim registry must be scoped to one build (one Autofill instance), not
    # a package global: two independent builds that reuse the same explicit
    # autorow row class must not see each other's column claims. Otherwise a
    # relationship aliased in build 2 falsely collides with a column that only
    # existed in build 1's schema.
    my $row_class = 'My::AutorowB6::CrossBuild';

    my $build1 = DBIx::QuickORM::Schema::Autofill->new(types => {}, affinities => {}, hooks => {}, skip => {});
    my $b1_table = DBIx::QuickORM::Schema::Table->new(
        name    => 'source',
        columns => {owner => col('owner'), id => col('id')},
    );
    ok(lives { $build1->define_autorow($row_class, $b1_table) }, "build 1 installs the 'owner' column accessor") or note $@;

    my $build2 = DBIx::QuickORM::Schema::Autofill->new(types => {}, affinities => {}, hooks => {}, skip => {});
    my $b2_table = DBIx::QuickORM::Schema::Table->new(
        name    => 'source',
        columns => {id => col('id')},                     # no 'owner' column here
        links   => [link_to('others', 'owner')],          # but a relationship aliased 'owner'
    );
    ok(
        lives { $build2->define_autorow($row_class, $b2_table) },
        "a second independent build does not falsely collide on build 1's stale column claim",
    ) or note $@;
};

done_testing;
