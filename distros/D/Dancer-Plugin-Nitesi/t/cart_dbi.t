#! perl

use Test::More;
use Test::Database;

# statements produced by SQL::Abstract are not understood by DBI::SQL::Nano
use SQL::Statement;

use Dancer::Test;

use Dancer ':tests';
use Dancer::Plugin::Nitesi;

my (@handles, $tests, %test_exclusion_map);

%test_exclusion_map = (CSV => 1, DBM => 1, SQLite => 1, SQLite2 => 1);

@handles = Test::Database->handles();

$tests = 0;

for my $testdb (@handles) {
    next if $test_exclusion_map{$testdb->dbd()};
    $tests += 11;
}

if ($tests) {
    # determine number of tests
    plan tests => $tests;
}
else {
    plan skip_all => 'No test database handles available';
}

my @tables = qw/carts cart_products users roles user_roles permissions/;

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
                     },
                     Cart =>
                     {Backend => 'DBI',
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

    my @cart_fields = (q{code serial NOT NULL primary key},
                       q{name character varying(255) DEFAULT '' NOT NULL},
                       q{uid integer DEFAULT 0 NOT NULL},
                       q{session_id character varying(255) DEFAULT '' NOT NULL},
                       q{created integer DEFAULT 0 NOT NULL},
                       q{last_modified integer DEFAULT 0 NOT NULL},
                       q{type character varying(32) DEFAULT '' NOT NULL},
                       q{approved boolean},
                       q{status character varying(32) DEFAULT '' NOT NULL},
            );

    query($dbh)->_create_table('carts', \@cart_fields);

    my @cart_products_fields = (q{cart integer NOT NULL},
                                q{sku character varying(32) NOT NULL},
                                q{position integer NOT NULL},
                                q{quantity integer DEFAULT 1 NOT NULL},
                                q{priority integer DEFAULT 0 NOT NULL},
                                );

    query($dbh)->_create_table('cart_products', \@cart_products_fields);

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

    run_tests();

    # clean up test database
    for my $t (@tables) {
#        query($dbh)->_drop_table($t);
    }
}

sub run_tests {
    my $ret;

    # main cart
    $ret = cart->add(sku => 'FOO', name => 'Foo Shoes', price => 5, quantity => 2);

    ok ($ret, "Add Foo Shoes to cart.")
        || diag "Failed to add foo shoes.";

    $ret = cart->count;

    ok($ret == 1, "Checking cart count after adding two FOOs.")
        || diag "Count is $ret instead of 1.";

    # removing items
    $ret = cart->remove('FOO');

    ok($ret)
        || diag "Failed to remove foo shoes: ", cart->error;

    $ret = cart->count;

    ok($ret == 0, "Checking cart count after removing two FOOs.")
        || diag "Count is $ret instead of 0.";

    # wishlist
    $ret = cart('wishlist')->add(sku => 'BAR', name => 'Bar Shoes', price => 5, quantity => 2);

    ok ($ret, "Add Bar Shoes to wishlist.")
        || diag "Failed to add bar shoes.";

    $ret = cart('wishlist')->count;

    ok($ret == 1, "Checking wishlist count after adding two BARs.")
        || diag "Count is $ret instead of 1.";

    # now creating account and login
    my $uid = create_account();

    $ret = cart('wishlist')->count;

    ok($ret == 1, "Checking wishlist count after login.")
        || diag "Count is $ret instead of 1.";

    # create new cart
    $ret = cart('dealer')->add(sku => 'PUMPS', name => 'Pumps', price => 5, quantity => 3);

     ok ($ret, "Add pumps to dealer cart.")
         || diag "Failed to add pumps to dealer cart.";

#    $ret = cart('dealer')->uid;
#    warn "Ret: ", $ret, "\n";
};

sub create_account {
    my $ret;

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

    return account->uid;
}

