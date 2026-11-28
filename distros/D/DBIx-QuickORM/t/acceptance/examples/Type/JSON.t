# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Type/JSON.pm. Whenever an example
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

    # json and jsonb fields are typed
    my $orm = DBIx::QuickORM->new(credentials => \%credentials);

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            prefs => {
                theme => 'dark',
                tags  => ['a', 'b'],
            },
        },
    );

    my $theme = $ann->field('prefs')->{theme};
    my $text  = $ann->raw_field('prefs');        # the JSON text

    # a plain string is JSON text
    $orm->insert(
        users => {
            name  => 'Bo',
            prefs => '{"theme":"light"}',
        },
    );

    # Keep a JSON field as text:
    my $plain = DBIx::QuickORM->new(
        credentials => \%credentials,
        types       => {users => {prefs => undef}},
    );

    my $json = $plain->find(users => $ann->field('id'))->field('prefs');

    is($theme,                                                             'dark',                              "a reference is stored as JSON and inflates back");
    is($text,                                                              '{"tags":["a","b"],"theme":"dark"}', "as canonical JSON text");
    is($orm->handle('users')->where({name => 'Bo'})->only->field('prefs'), {theme => 'light'},                  "a plain string is stored as given");
    is($json,                                                              $text,                               "types undef leaves the field as text");
};

done_testing;
