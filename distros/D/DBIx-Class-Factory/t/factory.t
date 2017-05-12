use strict;
use warnings;

use Test::More tests => 15;
use Test::Deep;

{
    package DBIx::Class::Factory::Test::Schema::User;
    use base qw(DBIx::Class);

    __PACKAGE__->load_components('Core');
    __PACKAGE__->table('user');
    __PACKAGE__->add_columns(
        id => {
            data_type => 'integer',
            is_auto_increment => 1,
        },
        name => {
            data_type => 'varchar',
            size      => '100',
        },
        comment => {
            data_type     => 'varchar',
            size          => '100',
            default_value => 'DEFAULT COMMENT',
            is_nullable   => 1,
        },
        superuser => {
            data_type => 'bool',
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->has_many(
        accounts => 'DBIx::Class::Factory::Test::Schema::Account',
        'user_id'
    );
}

{
    package DBIx::Class::Factory::Test::Schema::Account;
    use base qw(DBIx::Class);

    __PACKAGE__->load_components('Core');
    __PACKAGE__->table('account');
    __PACKAGE__->add_columns(
        id => {
            data_type => 'integer',
            is_auto_increment => 1,
        },
        sum => {
            data_type => 'integer',
        },
        user_id => {
            data_type => 'integer',
        },
    );
    __PACKAGE__->set_primary_key('id');
    __PACKAGE__->belongs_to(
        user => 'DBIx::Class::Factory::Test::Schema::User',
        'user_id'
    );
}

{
    package DBIx::Class::Factory::Test::Schema;
    use base qw(DBIx::Class::Schema);

    __PACKAGE__->load_classes('User', 'Account');
}

my $schema = DBIx::Class::Factory::Test::Schema->connect(
    'dbi:SQLite:dbname=dbix-class-factory-test.sqlite', '', ''
);
my $result;
my $user_iter = 42;

{
    package DBIx::Class::Factory::Test::UserFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset($schema->resultset('User'));
    __PACKAGE__->fields({
        name => __PACKAGE__->seq(sub {'User #' . shift}, $user_iter),
        superuser => 0,
    });
}

{
    package DBIx::Class::Factory::Test::AfterUserFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset($schema->resultset('User'));

    sub after_get_fields {
        my ($class, $fields) = @_;

        $fields->{name} = 'after';

        return {%{$fields}, name => 'after'};
    }

    sub after_build {
        my ($class, $row) = @_;

        $row->superuser(1);

        return $row;
    }

    sub after_create {
        my ($class, $row) = @_;

        $row->add_to_accounts({sum => 123});

        return $row;
    }
}

{
    package DBIx::Class::Factory::Test::ParamedUserFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset($schema->resultset('User'));
    __PACKAGE__->exclude('all');
    __PACKAGE__->fields({
        name => __PACKAGE__->callback(sub { shift->get('all') }),
        comment => __PACKAGE__->callback(sub { shift->get('all') }),
        superuser => 0,
    });
}

{
    package DBIx::Class::Factory::Test::AccountFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->resultset($schema->resultset('Account'));
    __PACKAGE__->fields({
        user => __PACKAGE__->related_factory('DBIx::Class::Factory::Test::UserFactory'),
        sum => 0,
    });
}

{
    package DBIx::Class::Factory::Test::UserWithTwoAccountsFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->base_factory('DBIx::Class::Factory::Test::UserFactory');
    __PACKAGE__->fields({
        accounts => __PACKAGE__->related_factory_batch(
            2, 'DBIx::Class::Factory::Test::AccountFactory',
            {user => {}}, # negate parent 'user => ...'
        ),
    });
}

{
    package DBIx::Class::Factory::Test::CommentedUserFactory;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->base_factory('DBIx::Class::Factory::Test::UserFactory');
    __PACKAGE__->fields({
        comment => sub {shift->get('name')},
    });
}

{
    package DBIx::Class::Factory::Test::CommentedUserFactoryBot;

    use base qw(DBIx::Class::Factory);

    __PACKAGE__->fields({
        name    => 'NAME',
        comment => 'COMMENT',
    });

    # at the bottom
    __PACKAGE__->base_factory('DBIx::Class::Factory::Test::CommentedUserFactory'); 
}

$schema->deploy();

$result = DBIx::Class::Factory::Test::UserFactory->get_fields();
cmp_deeply(
    $result,
    {name => 'User #' . $user_iter++, superuser => 0},
    'get_fields'
);

$result = DBIx::Class::Factory::Test::UserFactory->build({superuser => 1});
cmp_deeply(
    $result,
    methods(name => 'User #' . $user_iter++, superuser => 1),
    'build'
);

$result = DBIx::Class::Factory::Test::UserFactory->create();
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(name => 'User #' . $user_iter++),
    'create'
);
is($result->comment, 'DEFAULT COMMENT', 'discard_changes is on by default');

$result = DBIx::Class::Factory::Test::UserFactory->get_fields_batch(2, {superuser => 1});
cmp_deeply(
    $result,
    [
        {name => 'User #' . $user_iter++, superuser => 1},
        {name => 'User #' . $user_iter++, superuser => 1},
    ],
    'get_fields_batch'
);

$result = DBIx::Class::Factory::Test::UserFactory->build_batch(2);
cmp_deeply(
    $result,
    [
        methods(name => 'User #' . $user_iter++, superuser => 0),
        methods(name => 'User #' . $user_iter++, superuser => 0),
    ],
    'build_batch'
);

$result = DBIx::Class::Factory::Test::UserFactory->create_batch(2, {superuser => 1});
cmp_deeply(
    [
        $schema->resultset('User')->search({
            id => [map {$_->id} @{$result}]
        })->all()
    ],
    bag(
        methods(name => 'User #' . $user_iter++, superuser => 1),
        methods(name => 'User #' . $user_iter++, superuser => 1),
    ),
    'create_batch'
);

$result = DBIx::Class::Factory::Test::CommentedUserFactory->create();
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(comment => 'User #' . $user_iter++),
    'create (with base factory)'
);

$result = DBIx::Class::Factory::Test::CommentedUserFactoryBot->create({name => 'FOO'});
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(comment => 'COMMENT', name => 'FOO'),
    'create (with base factory, base_factory at the bottom)'
);

$result = DBIx::Class::Factory::Test::AccountFactory->create();
cmp_deeply(
    $schema->resultset('User')->find($result->user_id),
    methods(name => 'User #' . $user_iter++),
    'related_factory helper'
);

$result = DBIx::Class::Factory::Test::UserWithTwoAccountsFactory->create();
cmp_deeply(
    $result->accounts->count,
    2,
    'related_factory_batch helper'
);

$result = DBIx::Class::Factory::Test::ParamedUserFactory->create({all => 'TEST'});
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(name => 'TEST', comment => 'TEST'),
    'create with excluded param'
);

$result = DBIx::Class::Factory::Test::AfterUserFactory->create();
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(name => 'after'),
    'after_get_fields'
);
cmp_deeply(
    $schema->resultset('User')->find($result->id),
    methods(superuser => 1),
    'after_build'
);
cmp_deeply(
    [$schema->resultset('User')->find($result->id)->accounts],
    [methods(sum => 123)],
    'after_create'
);

END {
    unlink('dbix-class-factory-test.sqlite');
}
