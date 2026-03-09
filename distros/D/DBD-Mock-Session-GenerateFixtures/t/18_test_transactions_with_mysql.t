use strict;
use warnings;

use Test2::V0;
use Try::Tiny;
use File::Which qw(which);

BEGIN {
    my $mysqld_check = which('mysqld') || which('mariadb');

    if ( !$mysqld_check ) {
        plan skip_all => "MariaDB is not installed or not in PATH. Please run 'sudo apt-get install -y mariadb-server mariadb-client libmariadb-dev'";
    }
}

use lib qw(lib t);

use DBI;
use Data::Dumper;
use DBD::Mock::Session::GenerateFixtures;
use Sub::Override;
use File::Path qw(rmtree);
use Test::mysqld;

use MyDatabase qw(build_mysql_db populate_test_db);

my $mysqld = Test::mysqld->new(
    my_cnf => {
        'skip-networking' => '',    # no TCP socket
    }
) or die "Failed to start Test::mysqld";

my $dbh = DBI->connect(
    $mysqld->dsn( dbname => 'test' ),
    {
        RaiseError => 0,            # ← THIS is where it goes
        PrintError => 0,
        AutoCommit => 1,
    }
);

build_mysql_db($dbh);
populate_test_db($dbh);
my $obj = DBD::Mock::Session::GenerateFixtures->new( { dbh => $dbh } );

my $sql_user_login_history = <<"SQL";
-- comment
/* foo 
bar */
INSERT INTO user_login_history (user_id) VALUES (?)
SQL

my $failed_sql_user_login_history = <<"SQL";
INSERT INTO user_login_history (id) VALUES (?)
SQL

subtest 'upsert generate mock data' => sub {

    $obj->get_dbh()->begin_work();
    my ( $r, $r_2 );
    my $success = 1;
    my $not_ok;
    try {
        my $sth = $obj->get_dbh()->prepare($sql_user_login_history);
        $r   = $sth->execute(1) or die $obj->get_dbh()->err();
        $r_2 = $sth->execute(2) or die $obj->get_dbh()->err();
    }
    catch {
        $not_ok = $obj->get_dbh()->err();
    };

    $obj->get_dbh()->commit() if $success;

    is( $r,   1, 'one row inserted is ok' );
    is( $r_2, 1, 'one second inserted is ok' );

    $obj->get_dbh()->begin_work();
    my $r_3;
    my $ok    = 1;
    my $error = undef;
    try {
        my $sth_2 = $obj->get_dbh()->prepare('INSERT INTO user_login_history (id) VALUES (?)');
        $r_3 = $sth_2->execute('aa') or die $obj->get_dbh()->err();
    }
    catch {
        $ok    = 0;
        $error = $obj->get_dbh()->err();
        $obj->get_dbh()->rollback();
    };

    $dbh->commit() if $ok;
    ok( $error, 'rollback is ok' );
};

subtest 'upsert generate mock data for nested transactions both are ok' => sub {
    my $dbh = $obj->get_dbh();
    try {
        $dbh->begin_work();
        my $sth = $dbh->prepare($sql_user_login_history);
        my $r   = $sth->execute(3) or die $obj->get_dbh()->err();
        try {
            my $sth_2 = $dbh->prepare($sql_user_login_history);
            my $r_2   = $sth_2->execute(4) or die $dbh->err();
            is( $r_2, 1, 'one second inserted is ok' );
        }
        catch {
            $dbh->rollback();
        };
        $dbh->commit();
        is( $r, 1, 'one row inserted is ok' );
    }
    catch {
        $obj->get_dbh()->rollback();
    };

};

subtest 'upsert generate mock data for nested transactions - big trans is not ok' => sub {
    my $error_big   = undef;
    my $error_small = undef;

    my $dbh = $obj->get_dbh();
    my $ok  = 1;
    try {
        $dbh->begin_work();
        my $sth = $dbh->prepare($failed_sql_user_login_history);
        my $r   = $sth->execute(3) or die $dbh->get_dbh()->err();
        try {
            my $sth_2 = $dbh->prepare($sql_user_login_history);
            my $r_2   = $sth_2->execute(4) or die $dbh->err();
        }
        catch {
            $ok          = 0;
            $error_small = $dbh->err();
            $dbh->rollback();
        };
    }
    catch {
        $ok        = 0;
        $error_big = $dbh->err();
        $dbh->rollback();
    };

    $dbh->commit() if $ok;

    ok( $error_big, 'error in the big try/catch is ok' );
};

subtest 'upsert generate mock data for nested transactions - small trans is not ok' => sub {
    my $error_big   = undef;
    my $error_small = undef;

    my $dbh = $obj->get_dbh();
    my $ok  = 1;
    try {
        $dbh->begin_work();
        my $sth = $dbh->prepare($sql_user_login_history);
        my $r   = $sth->execute(3) or die $dbh->err();
        try {
            my $sth_2 = $dbh->prepare($failed_sql_user_login_history);
            my $r_2   = $sth_2->execute(4) or die $dbh->err();
        }
        catch {
            $error_small = $dbh->err();
            $ok          = 0;
            $dbh->rollback();
        };
    }
    catch {
        $error_big = $dbh->err();
        $dbh->rollback();
    };

    $dbh->commit() if $ok;
    ok( $error_small, 'error in the small try/catch is ok' );
};

subtest 'test mysql proc call' => sub {
    my $proc_call = <<"SQL";
        CALL pr_user_login_history(?)
SQL
    my $sth_proc = $dbh->prepare($proc_call);
    $sth_proc->execute(1);
    my $proc_result = $sth_proc->fetchrow_hashref();
    my $expected = {
          'user_id' => 1,
          'id' => 1,
          'login_at' => '2026-03-08 19:08:04'
        };
    is($proc_result->{user_id}, 1);
};

done_testing();
