# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Role/Row.pm. Whenever an example
# there changes, change its copy here to match: t/acceptance/Examples.t fails while any example has
# no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my %credentials = (dsn => $db->connect_string, user => $db->username, pass => $db->password);

    package My::Row;
    use Object::HashBase qw{<orm <table row_data};
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Row';

    # Raw values by default, but inflated_field and inflated_fields still inflate.
    sub field  { my $self = shift; $self->raw_field(@_) }
    sub fields { my $self = shift; $self->raw_fields(@_) }

    package main;

    my $orm = DBIx::QuickORM->new(
        credentials => \%credentials,
        row_class   => 'My::Row',
    );

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            prefs => {theme => 'dark'},
        },
    );

    my $raw = $ann->field('prefs');             # the JSON text
    my $all = $ann->inflated_field('prefs');    # {theme => 'dark'}

    isa_ok($ann, ['My::Row'], "rows use the class");
    is($raw,                            '{"theme":"dark"}',          "field gives the raw form");
    is($all,                            {theme => 'dark'},           "inflated_field the inflated one");
    is([$ann->fields('name', 'prefs')], ['Ann', '{"theme":"dark"}'], "fields gives the raw form too");

    {
        my $alice = $ann;

        my $post  = $alice->insert_fk('posts', {title => 'One'});
        my $posts = $alice->insert_many_fk('posts', link => {id => 'user_id'}, {title => 'A'}, {title => 'B'});

        is($post->field('user_id'),              $alice->field('id'), "insert_fk links the new row");
        is([map { $_->field('title') } @$posts], ['A', 'B'],          "insert_many_fk with a link");
    }
};

done_testing;
