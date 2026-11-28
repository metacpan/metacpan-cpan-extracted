# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Role/Type.pm. Whenever an example
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

    package My::Type::Email;
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Type';

    # claims fields named email
    sub matches { my ($class, $name, $field, $dialect) = @_; $name eq 'email' }

    sub inflate { my ($class, $raw,   $field, $conn) = @_; $raw }
    sub deflate { my ($class, $value, $field, $conn) = @_; lc $value }

    # needed on a primary key field
    sub canonical_key_value { my ($class, $value, $field, $conn) = @_; lc $value }

    sub is_inflated                     { 1 }    # deflate every plain value sent
    sub inflated_is_immutable_for_cache { 1 }    # plain strings: nothing to copy

    package main;

    my $orm = DBIx::QuickORM->new(
        credentials     => \%credentials,
        append_autotype => ['+My::Type::Email'],
    );

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            email => 'Ann@Example.COM',
        },
    );

    my $email = $ann->field('email');    # ann@example.com

    is($email,                                            'ann@example.com', "the type deflates what is written");
    is($orm->db_map->field(users => 'email')->{orm_type}, 'My::Type::Email', "autotype chose it by name");

    # Field hints
    {
        $db->connect->do("CREATE TABLE tokens (token CHAR(36) PRIMARY KEY, note TEXT)");
        # CREATE TABLE tokens (token CHAR(36) PRIMARY KEY, note TEXT)
        # -- a legacy table: UUIDs in upper case
        my $orm = DBIx::QuickORM->new(
            credentials => \%credentials,
            types       => {
                tokens => {
                    token => {
                        class  => 'UUID',
                        format => sub { uc $_[0] },
                    },
                },
            },
        );

        my $id = '0190a6e8-1d2c-7c3b-9f00-123456789abc';

        # stores 0190A6E8-...
        my $token = $orm->insert(
            tokens => {
                token => $id,
                note  => 'legacy',
            },
        );

        # looks up 0190A6E8-...
        my $same = $orm->find(
            tokens => $id,
            cache  => 0,
        );

        is($token->field('token'), uc($id),  "the upper case form is stored");
        is($same->field('note'),   'legacy', "and a lower case key finds it");

        my %args = (
            type_options => {UUID => {format => sub { uc $_[0] }}},
        );
        my $all = DBIx::QuickORM->new(credentials => \%credentials, %args, types => {tokens => {token => 'UUID'}});
        is($all->find(tokens => $id)->field('note'), 'legacy', "type_options formats every field of the type");
    }
};

done_testing;
