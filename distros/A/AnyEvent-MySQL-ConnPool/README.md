AnyEvent::MySQL::ConnPool
=======================

Connpool designed for precious AnyEvent::MySQL.
Provides additional method connect_pool to AnyEvent::MySQL, which is almost exact AnyEvent::MySQL->connect
method, but 4th param(hashref) is slightly different. See example.

	use AnyEvent;
    use AnyEvent::MySQL;
    use AnyEvent::MySQL::ConnPool;

    my $connpool = AnyEvent::MySQL->connect_pool(
        "DBI:mysql:database=test;host=127.0.0.1;port=3306",
        "ptest",
        "pass", {
            PrintError      =>  1,
            # parameters for pool
            # connections count. 5 connections by default.
            PoolSize        =>  5,
            # ping interval. 10 seconds by default.
            CheckInterval   =>  10,
        }, 
        sub {
            my($dbh) = @_;
            if( $dbh ) {
                warn "Connect success!";
                $dbh->pre_do("set names latin1");
                $dbh->pre_do("set names utf8");
            }
            else {
                warn "Connect fail: $AnyEvent::MySQL::errstr ($AnyEvent::MySQL::err)";
                $end->send;
            }
        }
    );

