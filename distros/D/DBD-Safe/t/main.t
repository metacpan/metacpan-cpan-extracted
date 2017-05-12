#!/usr/bin/perl

package Test::DBD::Safe;

use strict;
use warnings;

use lib qw(lib);

use DBI;

use Test::Class;
use Test::Exception;
use Test::More;

use base qw(Test::Class);

$DBD::Safe::VERSION = 0.02;

sub _connect : Test(3) {
    use_ok('DBD::Safe');
    my $dbh = get_dbh();
    ok($dbh);
    my $rdbh1 = $dbh->func('x_safe_get_dbh');
    my $rdbh2 = $dbh->func('x_safe_get_dbh');
    is("$rdbh2", "$rdbh1", "don't reconnect in good cases");
}

sub _x_safe_get_dbh : Test(4) {
    my $dbh = get_dbh();
    my $rdbh = $dbh->func('x_safe_get_dbh');

    my $test = sub {
        isnt("$rdbh", "$dbh", "dbh and real_dbh is different");
        is($rdbh->{Driver}->{Name}, "ExampleP", "real_dbh is really real");
    };
    $test->();

    if ($DBI::VERSION <= 1.53) {
        return ("\$DBI::VERSION <= 1.53, don't test implicit call of x_safe_get_dbh");
    }

    $rdbh = $dbh->x_safe_get_dbh;
    $test->();
}

sub reconnect_ping : Test(1) {
    my $dbh = get_dbh();
    my $rdbh1 = $dbh->func('x_safe_get_dbh');

    no strict 'refs';
    no warnings;
    local *{'DBD::ExampleP::db::ping'} = sub { 0 };
    my $rdbh2 = $dbh->func('x_safe_get_dbh');
    isnt("$rdbh2", "$rdbh1", "reconnect if ping is negative");
}

sub reconnect_fork : Test(2) {
    my $dbh = get_dbh();

    my $parent_real_dbh = $dbh->func('x_safe_get_dbh');

    my $pid = open(CHILD_WRITE, "-|");

    if ($pid) {
        my $child_real_dbh;
        while (my $l = <CHILD_WRITE>) {
            $child_real_dbh .= $l;
        }
        chomp($child_real_dbh);
        close(CHILD_WRITE);
        isnt("$child_real_dbh", "$parent_real_dbh", "reconnect in child after fork()");
    } else {
        my $child_real_dbh = $dbh->func('x_safe_get_dbh');
        print "$child_real_dbh\n";
        exit();
    }

    my $parent_real_dbh2 = $dbh->func('x_safe_get_dbh');
    is("$parent_real_dbh", "$parent_real_dbh2", "parent dbh not changed since fork()");
}

sub reconnect_threads : Test(1) {
    no strict 'refs';
    local $INC{'threads.pm'} = 1;
    local *{'threads::tid'} = sub { 42 };

    my $dbh = get_dbh();
    my $real_dbh1 = $dbh->func('x_safe_get_dbh');
    my $state = $dbh->FETCH('x_safe_state');
    $state->{tid} = 43;

    my $real_dbh2 = $dbh->func('x_safe_get_dbh');
    isnt("$real_dbh2", "$real_dbh1", "reconnect if threads()");
}

sub retry_cb : Test(1) {
    my $cb = sub {
        my $try = shift;
        return 0
    };
    dies_ok(sub { get_dbh({retry_cb => $cb}) }, "always negative retry_cb");
}

sub reconnect_cb : Test(2) {
    my $last_connected;
    my $cb = sub {
        use Time::HiRes qw(time);
        my $dbh = shift;
        my $t = time();
        if (!defined($last_connected) ||
            ($t - $last_connected >= 1))
        {
            $last_connected = $t;
            return 1;
        } else {
            return 0;
        }
    };
    my $dbh = get_dbh({reconnect_cb => $cb});
    my $rdbh1 = $dbh->func('x_safe_get_dbh');
    my $rdbh2 = $dbh->func('x_safe_get_dbh');
    sleep(1);
    my $rdbh3 = $dbh->func('x_safe_get_dbh');

    is("$rdbh2", "$rdbh1", "don't use reconnect_cb when it is not needed");
    isnt("$rdbh3", "$rdbh2", "reconnected using reconnect_cb");
}

sub transaction_autocommit_on : Test(12) {
    for my $method (qw/commit rollback/) {
        my $dbh = get_dbh();
        dies_ok { $dbh->$method } "$method doesn't work without begin_work";
    }
    {
        my $dbh = get_dbh();
        ok($dbh->{AutoCommit}, 'AutoCommit is true');
        eval { $dbh->begin_work };
        ok(!$@, 'can start begin_work in normal situation');
        ok(!$dbh->{AutoCommit}, 'AutoCommit is false during transaction');
        eval { $dbh->commit };
        ok(!$@, 'can commit in normal situation');
        ok($dbh->{AutoCommit}, 'AutoCommit backed to true');
    }
    {
        my $dbh = get_dbh();
        eval {
            $dbh->begin_work;
            $dbh->rollback;
        };
        ok(!$@, 'can rollback in normal situation');
    }
    {
        my $dbh = get_dbh();
        eval {
            $dbh->begin_work;
            $dbh->{x_safe_state}->{dbh}->STORE('Active', 0);
            $dbh->func('x_safe_get_dbh');
        };
        ok($@, "can't reconnect during transaction");
    }
    {
        my $dbh = get_dbh();
        eval {
            $dbh->begin_work;
            $dbh->{x_safe_state}->{dbh}->STORE('Active', 0);
        };
        ok(!$@, "it's all ok before commit");
        eval { $dbh->commit };
        ok($@, "but can't commit with broken connection");
        eval { $dbh->rollback };
        ok($@, "and can't rollback with broken connection");
    }
}

sub transaction_autocommit_off : Test(6) {
    my $g = sub { get_dbh({AutoCommit => 0 }) };
    {
        my $dbh = $g->();
        ok(!$dbh->{AutoCommit}, 'AutoCommit is false');
    }
    {
        my $dbh = $g->();
        dies_ok { $dbh->begin_work; } "begin_work doesn't works with AutoCommit=false";
    }
    {
        my $dbh = $g->();
        eval {
            $dbh->func('x_safe_get_dbh');
            $dbh->commit;
        };
        ok(!$@, 'no errors in good situation');
    }
    {
        my $dbh = $g->();
        eval {
            $dbh->func('x_safe_get_dbh');
            $dbh->rollback;
        };

        ok(!$@, 'can rollback in good situation');
    }
    {
        my $dbh = $g->();
        eval {
            $dbh->{x_safe_state}->{dbh}->STORE('Active', 0);
            $dbh->commit;
        };
        ok($@, "can't commit with broken connection");

        eval {
            $dbh->rollback;
        };
        ok($@, "can't rollback with broken connection");
    }
}

sub raise_error : Test(2) {
    return ("not implemented yet");
    my $f = sub {
        my $raise_error = shift;
        my $dies = shift || 0;

        my $dbh = get_dbh({RaiseError => $raise_error, AutoCommit => 0});
        $dbh->func('x_safe_get_dbh');
        break_dbh($dbh);
        eval { $dbh->begin_work };
        my $error = $@;
        unless ($dies) {
            $error = !$@;
        }
        ok($error, "RaiseError: $raise_error, dies: $dies");
    };

    $f->(1, 1);
    $f->(0, 0);
}

sub get_dbh {
    my $attr = shift || {};
    my $dbh = DBI->connect('DBI:Safe:', undef, undef,
        {
         dbi_connect_args => ['dbi:ExampleP:dummy', '', ''],
         PrintError => 1, RaiseError => 1, AutoCommit => 1,
         %{$attr},
        }
    );
    return $dbh;
}

sub break_dbh {
    my $dbh = shift;
    $dbh->{x_safe_state}->{dbh}->STORE('Active', 0);
}

# parameters validation
# PrintError/RaiseError/etc

Test::Class->runtests(
    __PACKAGE__->new
);

1;

