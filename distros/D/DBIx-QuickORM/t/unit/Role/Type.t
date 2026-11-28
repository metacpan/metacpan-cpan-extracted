# Test origin: AI
use Test2::V0;

use Role::Tiny();
use DBIx::QuickORM::Role::Type;

package My::Type {
    use Role::Tiny::With qw/with/;
    sub inflate { "in:$_[1]" }
    sub deflate { "out:$_[1]" }
    with 'DBIx::QuickORM::Role::Type';
}

ok(My::Type->DOES('DBIx::QuickORM::Role::Type'), "A class with inflate and deflate consumes the role");
is(My::Type->is_inflated('x'), undef, "is_inflated cannot tell by default");
ok(!My::Type->can($_), "The role provides no '$_'") for qw/base_types matches/;

subtest cache_facts => sub {
    is(My::Type->inflated_is_immutable_for_cache, 0, "Inflated values are not immutable by default");
    is(My::Type->inflate_is_identity({}),         0, "and inflate is not taken to be the identity");

    my $data = {a => [1, {b => 2}]};
    my $copy = My::Type->clone_inflated($data);
    is($copy, $data, "clone_inflated copies the value");
    ok($copy != $data && $copy->{a} != $data->{a} && $copy->{a}->[1] != $data->{a}->[1], "deeply, sharing no reference");
    is(My::Type->clone_inflated('x'),   'x',   "A plain value is returned as it is");
    is(My::Type->clone_inflated(undef), undef, "so is undef");
    like(
        dies {
            My::Type->clone_inflated({code => sub { 1 }})
        },
        qr/^My::Type cannot copy an inflated value with Storable::dclone, so it needs its own clone_inflated\(\) or a true inflated_is_immutable_for_cache\(\)/,
        "A value dclone cannot copy croaks",
    );
};

subtest _for_field => sub {
    is(My::Type->_for_field({table => 'users', name => 'id'}), ' for users.id', "Table and name give table.field");
    is(My::Type->_for_field({name  => 'id'}),                  ' for id',       "A name alone gives the field");
    is(My::Type->_for_field({table => 'users'}),               '',              "Nothing without a name");
    is(My::Type->_for_field(undef), '', "Nothing without a record");
};

like(
    dies { Role::Tiny->apply_roles_to_package('My::Half', 'DBIx::QuickORM::Role::Type') },
    qr/missing inflate, deflate/,
    "inflate and deflate are required",
);

done_testing;
