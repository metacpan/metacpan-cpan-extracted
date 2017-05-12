package test::DBIx::DataFactory;
use strict;
use warnings;

use base qw(Test::Class Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw(mysqld dbh));

use Test::More;
use Test::Exception;
use Test::mysqld;
use DBI;
use DBIx::DataFactory;
use Path::Class;

sub startup : Test(startup) {
    my $self = shift;
    my $mysqld = Test::mysqld->new(
        my_cnf => {
            'skip-networking' => '',    # no TCP socket
        }
    ) or $self->SKIP_ALL($Test::mysqld::errstr);
    my $sql = file(__FILE__)->dir->file('test-database.sql')->slurp;
    my $dbh = DBI->connect(
        $mysqld->dsn() . ';mysql_multi_statements=1',
    );
    $dbh->do($sql);

    $self->mysqld($mysqld);
    $self->dbh($dbh);
}

sub _create_factory_method_die : Test(1) {
    my $factory_maker = DBIx::DataFactory->new;
    dies_ok {
        $factory_maker->create_factory_method(
            method   => 'create_factory_data',
            table    => 'test_factory',
            auto_inserted_columns => {
                int => {
                    type => 'Int',
                    size => 8,
                },
                string => {
                    type => 'Str',
                    size => 10,
                },
            },
        );
    };
}

sub _create_factory_method : Test(14) {
    my $self = shift;
    my $factory_maker = DBIx::DataFactory->new({
        username => 'root',
        password => '',
        dsn      => $self->mysqld->dsn(dbname => 'test_factory'),
    });
    $factory_maker->create_factory_method(
        method   => 'create_factory_data',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            string => {
                type => 'Str',
                size => 10,
            },
        },
    );

    my $dbh = DBI->connect($self->mysqld->dsn(dbname => 'test_factory'), 'root', '');

    # check random value
    my $values = $factory_maker->create_factory_data();
    my $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );

    ok $row;
    is $row->{id}, $values->{id};
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, $values->{string};
    like $row->{string}, qr{[a-zA-Z0-9]{10}};
    ok !$row->{text};
    is $row->{str_default}, 'default test';

    # check specified value
    $values = $factory_maker->create_factory_data(string => 'test1', text => 'texttest', str_default => 'default');
    $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );

    ok $row;
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, 'test1';
    is $row->{text}, 'texttest';
    is $row->{str_default}, 'default';
}

sub _create_factory_method_specify_sub : Test(7) {
    my $self = shift;
    my $factory_maker = DBIx::DataFactory->new({
        username => 'root',
        password => '',
        dsn      => $self->mysqld->dsn(dbname => 'test_factory'),
    });
    $factory_maker->create_factory_method(
        method   => 'create_factory_data_sub',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            string => sub { return String::Random->new->randregex('[a-z]{20}') },
        },
    );

    my $dbh = DBI->connect($self->mysqld->dsn(dbname => 'test_factory'), 'root', '');

    my $values = $factory_maker->create_factory_data_sub();
    my $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );
    ok $row;
    is $row->{id}, $values->{id};
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, $values->{string};
    like $row->{string}, qr{[a-z]{20}};
    ok !$row->{text};
}

sub _create_factory_method_install_package : Test(7) {
    my $self = shift;
    my $factory_maker = DBIx::DataFactory->new({
        username => 'root',
        password => '',
        dsn      => $self->mysqld->dsn(dbname => 'test_factory'),
    });
    $factory_maker->create_factory_method(
        method   => 'create_factory_data_package',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            string => sub { return String::Random->new->randregex('[a-z]{20}') },
        },
        install_package => 'test::DBIx::DataFactory',
    );

    my $dbh = DBI->connect($self->mysqld->dsn(dbname => 'test_factory'), 'root', '');

    my $values = $self->create_factory_data_package();
    my $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );

    ok $row;
    is $row->{id}, $values->{id};
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, $values->{string};
    like $row->{string}, qr{[a-z]{20}};
    ok !$row->{text};
}

sub _create_factory_method_creator : Test(8) {
    my $self = shift;
    my $dsn  = $self->mysqld->dsn(dbname => 'test_factory');
    my $dbh  = DBI->connect($dsn, 'root', '');
    my $factory_maker = DBIx::DataFactory->new({
        username => 'root',
        password => '',
        dsn      => $dsn,
    });
    $factory_maker->create_factory_method(
        method   => 'create_factory_data_creator',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            string => sub { return String::Random->new->randregex('[a-z]{20}') },
        },
        creator => sub {
            my ($values) = @_;
            my $builder = SQL::Maker->new(driver => 'mysql');
            my ($sql, @binds) = $builder->insert('test_factory', $values);
            my $sth = $dbh->prepare($sql);
            $sth->execute(@binds);
            return $values;
        },
    );

    my $values = $factory_maker->create_factory_data_creator();
    my $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );

    ok $row;
    ok $row->{id};
    ok !$values->{id};
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, $values->{string};
    like $row->{string}, qr{[a-z]{20}};
    ok !$row->{text};
}

sub _create_factory_method_dbh : Test(14) {
    my $self = shift;
    my $dsn  = $self->mysqld->dsn(dbname => 'test_factory');
    my $dbh  = DBI->connect($dsn, 'root', '');
    my $factory_maker = DBIx::DataFactory->new({
        dbh => $dbh,
    });
    $factory_maker->create_factory_method(
        method   => 'create_factory_data_dbh',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            string => {
                type => 'Str',
                size => 10,
            },
        },
    );

    # check random value
    my $values = $factory_maker->create_factory_data_dbh();
    my $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );

    ok $row;
    is $row->{id}, $values->{id};
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, $values->{string};
    like $row->{string}, qr{[a-zA-Z0-9]{10}};
    ok !$row->{text};
    is $row->{str_default}, 'default test';

    # check specified value
    $values = $factory_maker->create_factory_data_dbh(string => 'test1', text => 'texttest', str_default => 'default');
    $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );

    ok $row;
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, 'test1';
    is $row->{text}, 'texttest';
    is $row->{str_default}, 'default';
}

sub _create_factory_method_connect_attr : Test(14) {
    my $self = shift;
    my $factory_maker = DBIx::DataFactory->new({
        username => 'root',
        password => '',
        dsn      => $self->mysqld->dsn(dbname => 'test_factory'),
        connect_attr => {
            mysql_enable_utf8 => 1,
            on_connect_do     => [
                "SET NAMES 'utf8'",
                "SET CHARACTER SET 'utf8'"
            ],
        },
    });
    $factory_maker->create_factory_method(
        method   => 'create_factory_data_connect_attr',
        table    => 'test_factory',
        auto_inserted_columns => {
            int => {
                type => 'Int',
                size => 8,
            },
            string => {
                type => 'Str',
                size => 10,
            },
        },
    );

    my $dbh = DBI->connect($self->mysqld->dsn(dbname => 'test_factory'), 'root', '');

    # check random value
    my $values = $factory_maker->create_factory_data_connect_attr();
    my $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );

    ok $row;
    is $row->{id}, $values->{id};
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, $values->{string};
    like $row->{string}, qr{[a-zA-Z0-9]{10}};
    ok !$row->{text};
    is $row->{str_default}, 'default test';

    # check specified value
    $values = $factory_maker->create_factory_data_connect_attr(string => 'test1', text => 'texttest', str_default => 'default');
    $row = $dbh->selectrow_hashref(
        'select * from test_factory where `int` = ?', {}, $values->{int},
    );

    ok $row;
    is $row->{int}, $values->{int};
    ok $row->{int} < 100000000;
    is $row->{string}, 'test1';
    is $row->{text}, 'texttest';
    is $row->{str_default}, 'default';
}

sub _add_type : Test(2) {
    ok (!DBIx::DataFactory->defined_types->{'test'});
    DBIx::DataFactory->add_type('test::DBIx::DataFactory::Type::Test');
    is (DBIx::DataFactory->defined_types->{'test'}, 'test::DBIx::DataFactory::Type::Test');
}

__PACKAGE__->runtests;

1;

package test::DBIx::DataFactory::Type::Test;
use strict;
use warnings;

use base qw(DBIx::DataFactory::Type);

use Smart::Args;

sub type_name {'test'}

sub make_value {
    args my $class => 'ClassName';
    return 'test';
};

1;
