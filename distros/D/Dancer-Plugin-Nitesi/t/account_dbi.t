#! perl

use Test::More;
use Test::Database;

# statements produced by SQL::Abstract are not understood by DBI::SQL::Nano
use SQL::Statement;

use Dancer::Test;

use Dancer ':tests';
use Dancer::Plugin::Nitesi;

my (@handles, $tests, $ret, %test_exclusion_map);

%test_exclusion_map = (CSV => 1, DBM => 1, SQLite => 1, SQLite2 => 1);

@handles = Test::Database->handles();

$tests = 0;

for my $testdb (@handles) {
    next if $test_exclusion_map{$testdb->dbd()};
    $tests += 7;
}

if ($tests) {
    # determine number of tests
    plan tests => $tests;
}
else {
    plan skip_all => 'No test database handles available';
}

my @tables = qw/users roles user_roles permissions/;

# run tests
for my $testdb (@handles) {
    next if $test_exclusion_map{$testdb->dbd()};

    # for last login tests etc.
    my $start_time = time;

    diag 'Testing with DBI driver ' . $testdb->dbd();

    my $dbh = $testdb->dbh();

    set plugins => {Nitesi =>
                    {Account =>
                     {Provider => 'DBI',
                      Connection => $dbh,
                     }
                    }
                   };

    Dancer::Plugin::Nitesi::_reset_settings_and_vars();

    my $q = query($dbh);

    for my $t (@tables) {
        if (grep {$_ =~ /^(.*?\.)?$t$/} $q->_tables) {
            query($dbh)->_drop_table($t);
        }
    }

    my @user_fields = (q{uid serial primary key},
                       q{username varchar(255) NOT NULL},
                       q{email varchar(255) NOT NULL DEFAULT ''},
                       q{password varchar(255) NOT NULL DEFAULT ''},
                       q{first_name varchar(255) NOT NULL DEFAULT ''},
                       q{last_name varchar(255) NOT NULL DEFAULT ''},
                       q{last_login integer NOT NULL DEFAULT 0},
                       q{created timestamp NOT NULL},
                       q{modified timestamp},
                       q{inactive boolean NOT NULL DEFAULT FALSE},
                       );

    query($dbh)->_create_table('users', \@user_fields);

    my @role_fields = (q{rid serial primary key},
                       q{name varchar(32) NOT NULL},
                       q{label varchar(255) NOT NULL},
                       );

    query($dbh)->_create_table('roles', \@role_fields);

    my @user_role_fields = (q{uid integer DEFAULT 0 NOT NULL},
                            q{rid integer DEFAULT 0 NOT NULL},
                            q{PRIMARY KEY (uid, rid)},
    );

    query($dbh)->_create_table('user_roles', \@user_role_fields);

    my @permission_fields = (q{rid integer not null default 0},
                       q{uid integer not null default 0},
                       q{perm varchar(255) not null default ''},
    );

    query($dbh)->_create_table('permissions', \@permission_fields);


    # create account
    $ret = account->create(email => 'shopper@nitesi.biz',
                           password=> 'nevairbe');

    ok ($ret, "Create account.")
        || diag "Failed to create account.";

    # check account
    $ret = account->exists('shopper@nitesi.biz');

    ok ($ret, "Check account.")
        || diag "Failed to check account.";
    
    # login test with valid password
    $ret = account->login(username => 'shopper@nitesi.biz', password => 'nevairbe');

    ok ($ret, "Login test.")
        || diag "Failed to login.";

    $ret = account->last_login;
    ok ($ret == 0, "Test initial last login value.")
        || diag "Last login is $ret instead of 0.";

    # login test with invalid password
    $ret = account->login(username => 'shopper@nitesi.biz', password => 'secret');

    ok (! $ret, "Login test with invalid password.")
        || diag "Successful login with invalid password.";

    # test again with valid password
    $ret = account->login(username => 'shopper@nitesi.biz', password => 'nevairbe');

    ok ($ret, "Login test (again).")
        || diag "Failed to login.";

    $ret = account->last_login;
    ok ($ret >= $start_time, "Test last login value.")
        || diag "Last login $ret is older than $start_time.";

    # clean up test database
    for my $t (@tables) {
        query($dbh)->_drop_table($t);
    }
}
