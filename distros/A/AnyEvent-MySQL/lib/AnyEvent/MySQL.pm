package AnyEvent::MySQL;

use 5.006;
use strict;
use warnings;

=head1 NAME

AnyEvent::MySQL - Pure Perl AnyEvent socket implementation of MySQL client

=head1 VERSION

Version 1.1.6

=cut

our $VERSION = '1.001007';

use AnyEvent::MySQL::Imp;


=head1 SYNOPSIS

This package is used in my company since 2012 to today (2014). I think it should be stable.
(though some data type fetching through prepared command are not implemented)

Please read the test.pl file as a usage example. >w<

    #!/usr/bin/perl

    use strict;
    use warnings;

    BEGIN {
        eval {
            require AE;
            require Data::Dumper;
            require Devel::StackTrace;
            require EV;
        };
        if( $@ ) {
            warn "require module fail: $@";
            exit;
        }
    }

    $EV::DIED = sub {
        print "EV::DIED: $@\n";
        print Devel::StackTrace->new->as_string;
    };

    use lib 'lib';
    use AnyEvent::MySQL;

    my $end = AE::cv;

    my $dbh = AnyEvent::MySQL->connect("DBI:mysql:database=test;host=127.0.0.1;port=3306", "ptest", "pass", { PrintError => 1 }, sub {
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
    });

    $dbh->do("select * from t1 where a<=?", {}, 15, sub {
        my $rv = shift;
        if( defined($rv) ) {
            warn "Do success: $rv";
        }
        else {
            warn "Do fail: $AnyEvent::MySQL::errstr ($AnyEvent::MySQL::err)";
        }
        $end->send;
    });

    #$end->recv;
    my $end2 = AE::cv;

    #$dbh->prepare("update t1 set a=1 where b=1", sub {
    #$dbh->prepare("select * from t1", sub {
    my $sth = $dbh->prepare("select b, a aaa from t1 where a>?", sub {
    #$dbh->prepare("select * from type_all", sub {
        warn "prepared!";
        $end2->send;
    });

    #$end2->recv;

    my $end3 = AE::cv;

    $sth->execute(1, sub {
        warn "executed! $_[0]";
        $end3->send($_[0]);
    });

    my $fth = $end3->recv;

    my $end4 = AE::cv;

    $fth->bind_col(2, \my $a, sub {
        warn $_[0];
    });
    my $fetch; $fetch = sub {
        $fth->fetch(sub {
            if( $_[0] ) {
                warn "Get! $a";
                $fetch->();
            }
            else {
                warn "Get End!";
                undef $fetch;
                $end4->send;
            }
        });
    }; $fetch->();

    #$fth->bind_columns(\my($a, $b), sub {
    #    warn $_[0];
    #    warn $AnyEvent::MySQL::errstr;
    #});
    #my $fetch; $fetch = sub {
    #    $fth->fetch(sub {
    #        if( $_[0] ) {
    #            warn "Get! ($a, $b)";
    #            $fetch->();
    #        }
    #        else {
    #            undef $fetch;
    #            $end4->send;
    #        }
    #    });
    #}; $fetch->();

    #my $fetch; $fetch = sub {
    #    $fth->fetchrow_array(sub {
    #        if( @_ ) {
    #            warn "Get! (@_)";
    #            $fetch->();
    #        }
    #        else {
    #            undef $fetch;
    #            $end4->send;
    #        }
    #    });
    #}; $fetch->();

    #my $fetch; $fetch = sub {
    #    $fth->fetchrow_arrayref(sub {
    #        if( $_[0] ) {
    #            warn "Get! (@{$_[0]})";
    #            $fetch->();
    #        }
    #        else {
    #            undef $fetch;
    #            $end4->send;
    #        }
    #    });
    #}; $fetch->();

    #my $fetch; $fetch = sub {
    #    $fth->fetchrow_hashref(sub {
    #        if( $_[0] ) {
    #            warn "Get! (@{[%{$_[0]}]})";
    #            $fetch->();
    #        }
    #        else {
    #            undef $fetch;
    #            $end4->send;
    #        }
    #    });
    #}; $fetch->();

    $end4->recv;

    #tcp_connect 0, 3306, sub {
    #    my $fh = shift;
    #    my $hd = AnyEvent::Handle->new( fh => $fh );
    #    AnyEvent::MySQL::Imp::do_auth($hd, 'tiwi', '', sub {
    #        undef $hd;
    #        warn $_[0];
    #        $end->send;
    #    });
    #};

    my $end5 = AE::cv;

    $dbh->selectall_arrayref("select a*2, b from t1 where a<=?", {}, 15, sub {
        warn "selectall_arrayref";
        warn Dumper($_[0]);
    });

    $dbh->selectall_hashref("select a*2, b from t1", 'b', sub {
        warn "selectall_hashref";
        warn Dumper($_[0]);
    });

    $dbh->selectall_hashref("select a*2, b from t1", ['b', 'a*2'], sub {
        warn "selectall_hashref";
        warn Dumper($_[0]);
    });

    $dbh->selectall_hashref("select a*2, b from t1", sub {
        warn "selectall_hashref";
        warn Dumper($_[0]);
    });

    $dbh->selectcol_arrayref("select a*2, b from t1", { Columns => [1,2,1] }, sub {
        warn "selectcol_arrayref";
        warn Dumper($_[0]);
    });

    $dbh->selectall_arrayref("select * from t3", sub {
        warn "selectall_arrayref t3";
        warn Dumper($_[0]);
    });

    $dbh->selectrow_array("select * from t1 where a>? order by a", {}, 2, sub {
        warn "selectrow_array";
        warn Dumper(\@_);
    });

    $dbh->selectrow_arrayref("select * from t1 where a>? order by a", {}, 2, sub {
        warn "selectrow_arrayref";
        warn Dumper($_[0]);
    });

    $dbh->selectrow_hashref("select * from t1 where a>? order by a", {}, 2, sub {
        warn "selectrow_hashref";
        warn Dumper($_[0]);
    });

    my $st = $dbh->prepare("select * from t1 where a>? order by a");

    $st->execute(2, sub {
        warn "fetchall_arrayref";
        warn Dumper($_[0]->fetchall_arrayref());
    });

    $st->execute(2, sub {
        warn "fetchall_hashref(a)";
        warn Dumper($_[0]->fetchall_hashref('a'));
    });

    $st->execute(2, sub {
        warn "fetchall_hashref";
        warn Dumper($_[0]->fetchall_hashref());
    });

    $st->execute(2, sub {
        warn "fetchcol_arrayref";
        warn Dumper($_[0]->fetchcol_arrayref());
    });

    $dbh->begin_work( sub {
        warn "txn begin.. @_ | $AnyEvent::MySQL::errstr ($AnyEvent::MySQL::err)";
    } );

    $dbh->do("update t1 set a=? b=?", {}, 3, 4, sub {
        warn "error update @_ | $AnyEvent::MySQL::errstr ($AnyEvent::MySQL::err)";
    } );

    $dbh->do("update t1 set b=b+1", {}, sub {
        warn "after error update @_ | $AnyEvent::MySQL::errstr ($AnyEvent::MySQL::err)";
    } );

    $dbh->commit( sub {
        warn "aborted commit @_ | $AnyEvent::MySQL::errstr ($AnyEvent::MySQL::err)";
    } );

    $dbh->do("update t1 set b=b+1", {}, sub {
        warn "after aborted commit @_ | $AnyEvent::MySQL::errstr ($AnyEvent::MySQL::err)";
        $end5->send;
    } );

    #my $txh = $dbh->begin_work(sub {
    #    warn "txn begin.. @_";
    #});
    #
    #$dbh->do("insert into t1 values (50,50)", { Tx => $txh }, sub {
    #    warn "insert in txn @_ insertid=".$dbh->last_insert_id;
    #});
    #
    #$txh->rollback(sub {
    #    warn "rollback txn @_";
    #});
    #
    #$dbh->selectall_arrayref("select * from t1", sub {
    #    warn "check rollback txn: ".Dumper($_[0]);
    #});
    #
    #my $txh2 = $dbh->begin_work(sub {
    #    warn "txn2 begin.. @_";
    #});
    #
    #$dbh->do("insert into t1 values (50,50)", { Tx => $txh2 }, sub {
    #    warn "insert in txn2 @_ insertid=".$dbh->last_insert_id;
    #});
    #
    #$txh2->commit(sub {
    #    warn "commit txn2 @_";
    #});
    #
    #$dbh->selectall_arrayref("select * from t1", sub {
    #    warn "check commit txn: ".Dumper($_[0]);
    #});
    #
    #$dbh->do("delete from t1 where a=50", sub {
    #    warn "remove the effect @_";
    #});
    #
    #my $update_st;
    #
    #my $txh3; $txh3 = $dbh->begin_work(sub {
    #    warn "txn3 begin.. @_";
    #});
    #
    #    $update_st = $dbh->prepare("insert into t1 values (?,?)", sub {
    #        warn "prepare insert @_";
    #    });
    #    $update_st->execute(60, 60, { Tx => $txh3 }, sub {
    #        warn "insert 60 @_";
    #    });
    #
    #    $dbh->selectall_arrayref("select * from t1", { Tx => $txh3 }, sub {
    #        warn "select in txn3: ".Dumper($_[0]);
    #    });
    #
    #    $txh3->rollback(sub {
    #        warn "txh3 rollback @_";
    #    });
    #
    #    $dbh->selectall_arrayref("select * from t1", sub {
    #        warn "select out txn3: ".Dumper($_[0]);
    #    });

    #$st_all = $dbh->prepare("select `date`, `time`, `datetime`, `timestamp` from all_type", sub {
    #    warn "prepare st_all @_";
    #});
    #
    #$st_all->execute

    $end5->recv;

    my $readonly_dbh = AnyEvent::MySQL->connect("DBI:mysql:database=test;host=127.0.0.1;port=3306", "ptest", "pass", { ReadOnly => 1 }, sub {
      # ... we can only use "select" and "show" command on this handle
    });

    $end->recv;

=cut

sub _empty_cb {}

=head2 $dbh = AnyEvent::MySQL->connect($data_source, $username, [$auth, [\%attr,]] $cb->($dbh, 1))

=cut
sub connect {
    shift;
    return AnyEvent::MySQL::db->new(@_);
}

package AnyEvent::MySQL::db;

use strict;
use warnings;

use AE;
use AnyEvent::Socket;
use AnyEvent::Handle;
use Scalar::Util qw(weaken dualvar);
use Guard;

# connection state
use constant {
    BUSY_CONN => 1,
    IDLE_CONN => 2,
    ZOMBIE_CONN => 3,
};

# transaction state
use constant {
    NO_TXN => 1,
    EMPTY_TXN => 2,
    CLEAN_TXN => 3,
    DIRTY_TXN => 4,
    DEAD_TXN => 5,
};

# transaction control token
use constant {
    TXN_TASK => 1,
    TXN_BEGIN => 2,
    TXN_COMMIT => 3,
    TXN_ROLLBACK => 4,
};

use constant {
    AUTHi => 0,
    ATTRi => 1,
    HDi => 2,
    CONNi => 9,
    ON_CONNi => 11,

    CONN_STATEi => 3,
    TXN_STATEi => 4,

    TASKi => 5,
    STi => 6,
    FALLBACKi => 10,

    ERRi => 7,
    ERRSTRi => 8,
};

sub _push_task {
    my($dbh, $task) = @_;
    push @{$dbh->{_}[TASKi]}, $task;
    _process_task($dbh) if( $dbh->{_}[CONN_STATEi]==IDLE_CONN );
}

sub _unshift_task {
    my($dbh, $task) = @_;
    unshift @{$dbh->{_}[TASKi]}, $task;
}

sub _report_error {
    my($dbh, $method, $error_num, $error_str) = @_;

    $dbh->{_}[ERRi] = $AnyEvent::MySQL::err = $error_num;
    $dbh->{_}[ERRSTRi] = $AnyEvent::MySQL::errstr = $error_str;
    warn "$dbh $method failed: $error_str ($error_num)\n" if( $dbh->{_}[ATTRi]{PrintError} );

    $dbh->{_}[TXN_STATEi] = DEAD_TXN if( $dbh->{_}[TXN_STATEi]!=NO_TXN );
}

sub _reconnect {
    my $dbh = shift;
    $dbh->{_}[CONN_STATEi] = BUSY_CONN;
    my $retry; $retry = AE::timer .1, 0, sub {
        undef $retry;
        _connect($dbh);
    };
}

sub _connect {
    my $dbh = shift;
    my $cb = $dbh->{_}[ON_CONNi] || \&AnyEvent::MySQL::_empty_cb;
    $dbh->{_}[CONN_STATEi] = BUSY_CONN;

    my $param = $dbh->{Name};
    my $database;
    if( index($param, '=')>=0 ) {
        $param = {
            map { split /=/, $_, 2 } split /;/, $param
        };
        if( $param->{host} =~ /(.*):(.*)/ ) {
            $param->{host} = $1;
            $param->{port} = $2;
        }
    }
    else {
        $param = { database => $param };
    }

    $param->{port} ||= 3306;

    if( $param->{host} eq '' || $param->{host} eq 'localhost' ) { # unix socket
        my $sock = $param->{mysql_socket} || `mysql_config --socket`;
        if( !$sock ) {
            _report_error($dbh, 'connect', 2002, "Can't connect to local MySQL server through socket ''");
            $cb->();
            return;
        }
        $param->{host} = '/unix';
        $param->{port} = $sock;
    }

    warn "Connecting to $param->{host}:$param->{port} ...";
    weaken( my $wdbh = $dbh );
    $dbh->{_}[CONNi] = tcp_connect($param->{host}, $param->{port}, sub {
        my $fh = shift;
        if( !$fh ) {
            warn "Connect to $param->{host}:$param->{port} fail: $!  retry later.";
            undef $wdbh->{_}[CONNi];

            _reconnect($wdbh);
            return;
        }
        warn "Connected ($param->{host}:$param->{port})";

        $wdbh->{_}[HDi] = AnyEvent::Handle->new(
            fh => $fh,
            on_error => sub {
                return if !$wdbh;

                my $wwdbh = $wdbh;
                if( $_[1] ) {
                    warn "Disconnected from $param->{host}:$param->{port} by $_[2]  reconnect later.";
                    undef $wwdbh->{_}[HDi];
                    undef $wwdbh->{_}[CONNi];
                    $wwdbh->{_}[CONN_STATEi] = IDLE_CONN;
                    _report_error($wwdbh, '', 2013, 'Lost connection to MySQL server during query');
                    if( $wwdbh->{_}[FALLBACKi] ) {
                        $wwdbh->{_}[FALLBACKi]();
                    }
                }
            },
        );

        AnyEvent::MySQL::Imp::do_auth($wdbh->{_}[HDi], $wdbh->{Username}, $wdbh->{_}[AUTHi], $param->{database}, sub {
            my($success, $err_num_and_msg, $thread_id) = @_;
            return if !$wdbh;
            if( $success ) {
                $wdbh->{mysql_thread_id} = $thread_id;
                $cb->($wdbh, guard {
                    _process_task($wdbh) if $wdbh;
                });
            }
            else {
                warn "MySQL auth error: $err_num_and_msg  retry later.";
                undef $wdbh->{_}[HDi];
                undef $wdbh->{_}[CONNi];
                _reconnect($wdbh) if $wdbh;
            }
        });
    });
}

sub _process_task {
    my $dbh = shift;
    $dbh->{_}[CONN_STATEi] = IDLE_CONN;
    $dbh->{_}[ERRi] = $AnyEvent::MySQL::err = undef;
    $dbh->{_}[ERRSTRi] = $AnyEvent::MySQL::errstr = undef;
    $dbh->{_}[FALLBACKi] = undef;
    weaken( my $wdbh = $dbh );

    if( !$dbh->{_}[HDi] ) {
        _reconnect($dbh);
        return;
    }

    my $task = shift @{$dbh->{_}[TASKi]};
    return if( !$task );

    my $next = sub {
        _process_task($wdbh) if $wdbh;
    };

    $dbh->{_}[FALLBACKi] = sub {
        undef $dbh->{_}[FALLBACKi];
        if( $dbh->{_}[TXN_STATEi]==NO_TXN && $task->[3]<5 ) {
            ++$task->[3];
            warn "redo the task later.. ($task->[3])";
            unshift @{$dbh->{_}[TASKi]}, $task;
        }
        else {
            $task->[2]();
        }
        _reconnect($dbh);
    };
    if( $task->[0]==TXN_TASK ) {
        if( $dbh->{_}[TXN_STATEi]==DEAD_TXN ) {
            _report_error($dbh, 'process_task', 1402, 'Transaction branch dead');
            $task->[2]();
            _process_task($dbh);
        }
        else {
            $dbh->{_}[TXN_STATEi] = DIRTY_TXN if( $dbh->{_}[TXN_STATEi]!=NO_TXN );
            $dbh->{_}[CONN_STATEi] = BUSY_CONN;
            $task->[1](sub {
                if( $dbh->{_}[TXN_STATEi]==DEAD_TXN && $dbh->{_}[HDi] ) {
                    _rollback($dbh, $next);
                }
                else {
                    $next->();
                }
            });
        }
    }
    elsif( $task->[0]==TXN_BEGIN ) {
        if( $dbh->{_}[TXN_STATEi]==NO_TXN ) {
            $dbh->{_}[TXN_STATEi] = DEAD_TXN;
            $dbh->{_}[CONN_STATEi] = BUSY_CONN;
            $task->[1]($next);
        }
        elsif( $dbh->{_}[TXN_STATEi]==EMPTY_TXN ) {
            $task->[2]($next);
            _process_task($dbh);
        }
        else {
            warn "It's in a transaction already.. Abort the old one and begin the new one.";
            $dbh->{_}[CONN_STATEi] = BUSY_CONN;
            _rollback($dbh, sub {
                $task->[1]($next);
            });
        }
    }
    elsif( $task->[0]==TXN_COMMIT ) {
        if( $dbh->{_}[TXN_STATEi]==DEAD_TXN ) {
            _report_error($dbh, 'process_task', 1402, 'Transaction branch dead');
            $dbh->{_}[TXN_STATEi] = NO_TXN;
            $task->[2]();
            _process_task($dbh);
        }
        elsif( $dbh->{_}[TXN_STATEi]==NO_TXN ) {
            $task->[2]();
            _process_task($dbh);
        }
        else {
            $dbh->{_}[CONN_STATEi] = BUSY_CONN;
            $task->[1]($next);
        }
    }
    elsif( $task->[0]==TXN_ROLLBACK ) {
        if( $dbh->{_}[TXN_STATEi]==DEAD_TXN ) {
            $dbh->{_}[TXN_STATEi] = NO_TXN;
            $task->[2](1);
            _process_task($dbh);
        }
        elsif( $dbh->{_}[TXN_STATEi]==NO_TXN ) {
            $task->[2]();
            _process_task($dbh);
        }
        else {
            $dbh->{_}[CONN_STATEi] = BUSY_CONN;
            $task->[1]($next);
        }
    }
    else {
        warn "Never be here";
    }
}

sub _text_prepare {
    my $statement = shift;
    $statement =~ s(\?){
        my $value = shift;
        if( defined($value) ) {
            $value =~ s/\\/\\\\/g;
            $value =~ s/'/\\'/g;
            "'$value'";
        }
        else {
            'NULL';
        }
    }ge;
    return $statement;
}

=head2 $dbh = AnyEvent::MySQL::db->new($dsn, $username, [$auth, [\%attr,]] [$cb->($dbh, $next_guard)])

    $cb will be called when each time the db connection is connected, reconnected,
    or tried but failed.

    If failed, the $dbh in the $cb's args will be undef.

    You can do some connection initialization here, such as
     set names utf8;

    But you should NOT rely on this for work flow control,
    cause the reconnection can occur anytime.

=cut
sub new {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($class, $dsn, $username, $auth, $attr) = @_;

    my $dbh = bless { _ => [] }, $class;
    if( $dsn =~ /^DBI:mysql:(.*)$/ ) {
        $dbh->{Name} = $1;
    }
    else {
        die "invalid dsn format";
    }
    $dbh->{Username} = $username;
    $dbh->{_}[AUTHi] = $auth;
    $dbh->{_}[ATTRi] = +{ Verbose => 1, %{ $attr || {} } };
    $dbh->{_}[CONN_STATEi] = BUSY_CONN;
    $dbh->{_}[TXN_STATEi] = NO_TXN;
    $dbh->{_}[TASKi] = [];
    $dbh->{_}[ON_CONNi] = $cb;

    _connect($dbh);

    return $dbh;
}

=head2 $error_num = $dbh->err

=cut
sub err {
    return $_[0]{_}[ERRi];
}

=head2 $error_str = $dbh->errstr

=cut
sub errstr {
    return $_[0]{_}[ERRSTRi];
}

=head2 $rv = $dbh->last_insert_id

    Non-blocking get the value immediately

=cut
sub last_insert_id {
    $_[0]{mysql_insertid};
}

sub _do {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($rev_dir, $dbh, $statement, $attr, @bind_values) = @_;

    if( $dbh->{_}[ATTRi]{ReadOnly} && $statement !~ /^\s*(?:show|select)/i ){
        _report_error($dbh, 'do', 1227, 'unable to perform write queries on a ReadOnly handle');
        $cb->();
        return;
    }

    my @args = ($dbh, [TXN_TASK, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, _text_prepare($statement, @bind_values));
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{mysql_insertid} = $_[2];
                    $cb->($_[1]);
                }
                elsif( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                    _report_error($dbh, 'do', $_[1], $_[3]);
                    $cb->();
                }
                else {
                    $cb->(0+@{$_[2]});
                }
            };
            $next_act->();
        });
    }, $cb, 0]);

    if( $rev_dir ) {
        _unshift_task(@args);
    }
    else {
        _push_task(@args);
    }
}

=head2 $dbh->do($statement, [\%attr, [@bind_values,]] [$cb->($rv)])

=cut
sub do {
    unshift @_, 0;
    &_do;
}

=head2 $dbh->pre_do($statement, [\%attr, [@bind_values,]] [$cb->($rv)])

    This method is like $dbh->do except that $dbh->pre_do will unshift
    job into the queue instead of push.

    This method is for the initializing actions in the AnyEvent::MySQL->connect's callback

=cut
sub pre_do {
    unshift @_, 1;
    &_do;
}

=head2 $dbh->selectall_arrayref($statement, [\%attr, [@bind_values,]] $cb->($ary_ref))

=cut
sub selectall_arrayref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($dbh, $statement, $attr, @bind_values) = @_;

    _push_task($dbh, [TXN_TASK, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, _text_prepare($statement, @bind_values));
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{mysql_insertid} = $_[2];
                    $cb->([]);
                }
                elsif( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                    _report_error($dbh, 'selectall_arrayref', $_[1], $_[3]);
                    $cb->();
                }
                else {
                    $cb->($_[2]);
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}


=head2 $dbh->selectall_hashref($statement, [$key_field|\@key_field], [\%attr, [@bind_values,]] $cb->($hash_ref))

=cut

sub selectall_hashref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($dbh, $statement, $key_field) = splice @_, 0, 3;

    my @key_field;
    if( ref($key_field) eq 'ARRAY' ) {
        @key_field = @$key_field;
    }
    elsif( ref($key_field) eq 'HASH' ) {
        unshift @_, $key_field;
        @key_field = ();
    }
    elsif( defined($key_field) ) {
        @key_field = ($key_field);
    }
    else {
        @key_field = ();
    }

    my($attr, @bind_values) = @_;

    _push_task($dbh, [TXN_TASK, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, _text_prepare($statement, @bind_values));
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{mysql_insertid} = $_[2];
                    if( @key_field ) {
                        $cb->({});
                    }
                    else {
                        $cb->([]);
                    }
                }
                elsif( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                    _report_error($dbh, 'selectall_hashref', $_[1], $_[3]);
                    $cb->();
                }
                else {
                    my $res;
                    if( @key_field ) {
                        $res = {};
                    }
                    else {
                        $res = [];
                    }
                    for(my $i=$#{$_[2]}; $i>=0; --$i) {
                        my %record;
                        for(my $j=$#{$_[2][$i]}; $j>=0; --$j) {
                            $record{$_[1][$j][4]} = $_[2][$i][$j];
                        }
                        if( @key_field ) {
                            my $h = $res;
                            for(@key_field[0..$#key_field-1]) {
                                $h->{$record{$_}} ||= {};
                                $h = $h->{$record{$_}};
                            }
                            $h->{$record{$key_field[-1]}} = \%record;
                        }
                        else {
                            push @$res, \%record;
                        }
                    }
                    $cb->($res);
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}

=head2 $dbh->selectcol_arrayref($statement, [\%attr, [@bind_values,]] $cb->($ary_ref))

=cut
sub selectcol_arrayref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($dbh, $statement, $attr, @bind_values) = @_;
    $attr ||= {};
    my @columns = map { $_-1 } @{ $attr->{Columns} || [1] };

    _push_task($dbh, [TXN_TASK, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, _text_prepare($statement, @bind_values));
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{mysql_insertid} = $_[2];
                    $cb->([]);
                }
                elsif( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                    _report_error($dbh, 'selectcol_arrayref', $_[1], $_[3]);
                    $cb->();
                }
                else {
                    my @res = map {
                        my $r = $_;
                        map { $r->[$_] } @columns
                    } @{$_[2]};
                    $cb->(\@res);
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}

=head2 $dbh->selectrow_array($statement, [\%attr, [@bind_values,]], $cb->(@row_ary))

=cut
sub selectrow_array {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($dbh, $statement, $attr, @bind_values) = @_;

    _push_task($dbh, [TXN_TASK, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, _text_prepare($statement, @bind_values));
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{mysql_insertid} = $_[2];
                    $cb->();
                }
                elsif( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                    _report_error($dbh, 'selectrow_array', $_[1], $_[3]);
                    $cb->();
                }
                else {
                    $cb->($_[2][0] ? @{$_[2][0]} : ());
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}

=head2 $dbh->selectrow_arrayref($statement, [\%attr, [@bind_values,]], $cb->($ary_ref))

=cut
sub selectrow_arrayref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($dbh, $statement, $attr, @bind_values) = @_;

    _push_task($dbh, [TXN_TASK, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, _text_prepare($statement, @bind_values));
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{mysql_insertid} = $_[2];
                    $cb->(undef);
                }
                elsif( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                    _report_error($dbh, 'selectrow_arrayref', $_[1], $_[3]);
                    $cb->(undef);
                }
                else {
                    $cb->($_[2][0]);
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}

=head2 $dbh->selectrow_hashref($statement, [\%attr, [@bind_values,]], $cb->($hash_ref))

=cut
sub selectrow_hashref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($dbh, $statement, $attr, @bind_values) = @_;

    _push_task($dbh, [TXN_TASK, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, _text_prepare($statement, @bind_values));
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{mysql_insertid} = $_[2];
                    $cb->(undef);
                }
                elsif( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                    _report_error($dbh, 'selectrow_hashref', $_[1], $_[3]);
                    $cb->(undef);
                }
                else {
                    if( $_[2][0] ) {
                        my %record;
                        for(my $j=$#{$_[2][0]}; $j>=0; --$j) {
                            $record{$_[1][$j][4]} = $_[2][0][$j];
                        }
                        $cb->(\%record);
                    }
                    else {
                        $cb->(undef);
                    }
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}

=head2 $sth = $dbh->prepare($statement, [$cb->($sth)])

    $cb will be called each time when this statement is prepared
    (or re-prepared when the db connection is reconnected)

    if the preparation is not success,
    the $sth in the $cb's arg will be undef.

    So you should NOT rely on this for work flow controlling.

=cut
sub prepare {
    my $dbh = $_[0];

    my $sth = AnyEvent::MySQL::st->new(@_);
    push @{$dbh->{_}[STi]}, $sth;
    weaken($dbh->{_}[STi][-1]);
    return $sth;
}

=head2 $dbh->begin_work([$cb->($rv)])

=cut
sub begin_work {
    my $dbh = shift;
    my $cb = shift || \&AnyEvent::MySQL::_empty_cb;

    _push_task($dbh, [TXN_BEGIN, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, 'begin');
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{_}[TXN_STATEi] = EMPTY_TXN;
                    $cb->(1);
                }
                else {
                    if( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                        _report_error($dbh, 'begin_work', $_[1], $_[3]);
                    }
                    else {
                        _report_error($dbh, 'begin_work', 2000, "Unexpected result: $_[0]");
                    }
                    $cb->();
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}

=head2 $dbh->commit([$cb->($rv)])

=cut
sub commit {
    my $dbh = shift;
    my $cb = shift || \&AnyEvent::MySQL::_empty_cb;

    _push_task($dbh, [TXN_COMMIT, sub {
        my $next_act = shift;

        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, 'commit');
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                    $dbh->{_}[TXN_STATEi] = NO_TXN;
                    $cb->(1);
                }
                else {
                    if( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                        _report_error($dbh, 'commit', $_[1], $_[3]);
                    }
                    else {
                        _report_error($dbh, 'commit', 2000, "Unexpected result: $_[0]");
                    }
                    $cb->();
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}

=head2 $dbh->rollback([$cb->($rv)])

=cut
sub rollback {
    my $dbh = shift;
    my $cb = shift || \&AnyEvent::MySQL::_empty_cb;

    _push_task($dbh, [TXN_ROLLBACK, sub {
        my $next_act = shift;

        _rollback($dbh, $next_act, sub {
            $dbh->{_}[TXN_STATEi] = NO_TXN if( $_[0] );
            &$cb;
        });
    }, $cb, 0]);
}
sub _rollback {
    my($dbh, $next_act, $cb) = @_;

    AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_QUERY, 'rollback');
    AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
        eval {
            if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                $cb->(1) if $cb;
            }
            else {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                    _report_error($dbh, 'rollback', $_[1], $_[3]);
                }
                else {
                    _report_error($dbh, 'rollback', 2000, "Unexpected result: $_[0]");
                }
                $cb->() if $cb;
            }
        };
        $next_act->();
    });
}

=head2 $dbh->ping(sub {my $alive = shift;});

=cut

sub ping {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my ($dbh) = @_;

    _push_task($dbh, [TXN_TASK, sub {
        my $next_act = shift;
        AnyEvent::MySQL::Imp::send_packet($dbh->{_}[HDi], 0, AnyEvent::MySQL::Imp::COM_PING);
        AnyEvent::MySQL::Imp::recv_response($dbh->{_}[HDi], sub {
            eval {
                if ($_[0]==AnyEvent::MySQL::Imp::RES_OK) {
                    $cb->(1);
                }
                else {
                    $cb->(0);
                }
            };
            $next_act->();
        });
    }, $cb, 0]);
}

package AnyEvent::MySQL::st;

use strict;
use warnings;

use Scalar::Util qw(weaken);

use constant {
    DBHi => 0,
    IDi => 1,
    PARAMi => 2,
    FIELDi => 3,
    STATEMENTi => 4,
};

=head2 $sth = AnyEvent::MySQL::st->new($dbh, $statement, [$cb->($sth)])

=cut
sub new {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my($class, $dbh, $statement) = @_;
    my $sth = bless [], $class;
    $sth->[DBHi] = $dbh;
    $sth->[STATEMENTi] = $statement;

    return $sth;
}

=head2 $sth->execute(@bind_values, [\%attr,] [$cb->($fth/$rv)])

=cut
sub execute {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : \&AnyEvent::MySQL::_empty_cb;
    my $attr = ref($_[-1]) eq 'HASH' ? pop : {};
    my($sth, @bind_values) = @_;
    my $dbh = $sth->[DBHi];


    AnyEvent::MySQL::db::_push_task($dbh, [AnyEvent::MySQL::db::TXN_TASK, sub {
        my $next_act = shift;

        my $execute = sub {
            AnyEvent::MySQL::Imp::do_execute_param($dbh->{_}[AnyEvent::MySQL::db::HDi], $sth->[IDi], \@bind_values, $sth->[PARAMi]);
            AnyEvent::MySQL::Imp::recv_response($dbh->{_}[AnyEvent::MySQL::db::HDi], execute => 1, sub {
                eval {
                    if( $_[0]==AnyEvent::MySQL::Imp::RES_OK ) {
                        $cb->($_[1]);
                    }
                    elsif( $_[0]==AnyEvent::MySQL::Imp::RES_RESULT ) {
                        $cb->(AnyEvent::MySQL::ft->new($sth->[FIELDi], $_[2]));
                    }
                    elsif( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                        AnyEvent::MySQL::db::_report_error($dbh, 'execute', $_[1], $_[3]);
                        $cb->();
                    }
                    else {
                        AnyEvent::MySQL::db::_report_error($dbh, 'execute', 2000, "Unknown response: $_[0]");
                        $cb->();
                    }
                };
                $next_act->();
            });
        };

        if( $sth->[IDi] ) {
            $execute->();
        }
        else {
            AnyEvent::MySQL::Imp::send_packet($dbh->{_}[AnyEvent::MySQL::db::HDi], 0, AnyEvent::MySQL::Imp::COM_STMT_PREPARE, $sth->[STATEMENTi]);
            AnyEvent::MySQL::Imp::recv_response($dbh->{_}[AnyEvent::MySQL::db::HDi], prepare => 1, sub {
                if( $_[0]==AnyEvent::MySQL::Imp::RES_PREPARE ) {
                    $sth->[IDi] = $_[1];
                    $sth->[PARAMi] = $_[2];
                    $sth->[FIELDi] = $_[3];

                    $execute->();
                }
                else {
                    if( $_[0]==AnyEvent::MySQL::Imp::RES_ERROR ) {
                        AnyEvent::MySQL::db::_report_error($dbh, 'execute', $_[1], $_[3]);
                        $cb->();
                    }
                    else {
                        AnyEvent::MySQL::db::_report_error($dbh, 'execute', 2000, "Unexpected response: $_[0]");
                        $cb->();
                    }
                }
            });
        }
    }, $cb, 0]);
}

package AnyEvent::MySQL::ft;

use strict;
use warnings;

use constant {
    DATAi => 0,
    BINDi => 1,
    FIELDi => 2,
};

=head2 $fth = AnyEvent::MySQL::ft->new(\@data_set)

=cut
sub new {
    my($class, $field_set, $data_set) = @_;

    my $fth = bless [], $class;
    $fth->[FIELDi] = $field_set;
    $fth->[DATAi] = $data_set;

    return $fth;
}

=head2 $rc = $fth->bind_columns(@list_of_refs_to_vars_to_bind, [$cb->($rc)])

=cut
sub bind_columns {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my $fth = shift;
    my @list_of_refs_to_vars_to_bind = @_;

    if( !@{$fth->[DATAi]} ) {
        $cb->(1) if $cb;
        return 1;
    }
    elsif( @{$fth->[DATAi][0]} == @list_of_refs_to_vars_to_bind ) {
        $fth->[BINDi] = \@list_of_refs_to_vars_to_bind;
        $cb->(1) if $cb;
        return 1;
    }
    else {
        $cb->() if $cb;
        return;
    }
}

=head2 $rc = $fth->bind_col($col_num, \$col_variable, [$cb->($rc)])

=cut
sub bind_col {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my($fth, $col_num, $col_ref) = @_;

    if( !@{$fth->[DATAi]} ) {
        $cb->(1) if $cb;
        return 1;
    }
    elsif( 0<=$col_num && $col_num<=$#{$fth->[DATAi][0]} ) {
        $fth->[BINDi][$col_num] = $col_ref;
        $cb->(1) if $cb;
        return 1;
    }
    else {
        $cb->() if $cb;
        return;
    }
}

=head2 $rv = $fth->fetch([$cb->($rv)])

=cut
sub fetch {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my $fth = shift;

    if( $fth->[BINDi] && $fth->[DATAi] && @{$fth->[DATAi]} ) {
        my $bind = $fth->[BINDi];
        my $row = shift @{$fth->[DATAi]};
        for(my $i=0; $i<@$row; ++$i) {
            ${$bind->[$i]} = $row->[$i] if $bind->[$i];
        }
        $cb->(1) if $cb;
        return 1;
    }
    else {
        $cb->() if $cb;
        return;
    }
}

=head2 @row_ary = $fth->fetchrow_array([$cb->(@row_ary)])

=cut
sub fetchrow_array {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my $fth = shift;

    if( $fth->[DATAi] && @{$fth->[DATAi]} ) {
        my $row = shift @{$fth->[DATAi]};
        $cb->(@$row) if $cb;
        return @$row if defined wantarray;
    }
    else {
        $cb->() if $cb;
        return ();
    }
}

=head2 $ary_ref = $fth->fetchrow_arrayref([$cb->($ary_ref)])

=cut
sub fetchrow_arrayref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my $fth = shift;

    if( $fth->[DATAi] && @{$fth->[DATAi]} ) {
        my $row = shift @{$fth->[DATAi]};
        $cb->($row) if $cb;
        return $row;
    }
    else {
        $cb->() if $cb;
        return;
    }
}

=head2 $hash_ref = $fth->fetchrow_hashref([$cb->($hash_ref)])

=cut
sub fetchrow_hashref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my $fth = shift;

    if( $fth->[DATAi] && @{$fth->[DATAi]} ) {
        my $field = $fth->[FIELDi];
        my $hash = {};
        my $row = shift @{$fth->[DATAi]};
        for(my $i=0; $i<@$row; ++$i) {
            $hash->{$field->[$i][4]} = $row->[$i];
        }
        $cb->($hash) if $cb;
        return $hash;
    }
    else {
        $cb->() if $cb;
        return;
    }
}

=head2 $ary_ref = $fth->fetchall_arrayref([$cb->($ary_ref)])

=cut
sub fetchall_arrayref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my $fth = shift;

    if( $fth->[DATAi] ) {
        my $all = delete $fth->[DATAi];
        $cb->($all) if $cb;
        return $all;
    }
    else {
        $cb->() if $cb;
        return;
    }
}

=head2 $hash_ref = $fth->fetchall_hashref([($key_field|\@key_field),] [$cb->($hash_ref)])

=cut
sub fetchall_hashref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my($fth, $key_field) = @_;

    my @key_field;
    if( ref($key_field) eq 'ARRAY' ) {
        @key_field = @$key_field;
    }
    elsif( defined($key_field) ) {
        @key_field = ($key_field);
    }
    else {
        @key_field = ();
    }

    if( $fth->[DATAi] ) {
        my $field = $fth->[FIELDi];

        my $res;
        if( @key_field ) {
            $res = {};
        }
        else {
            $res = [];
        }

        while( @{$fth->[DATAi]} ) {
            my $row = shift @{$fth->[DATAi]};
            my %record;
            for(my $i=0; $i<@$row; ++$i) {
                $record{$field->[$i][4]} = $row->[$i];
            }
            if( @key_field ) {
                my $h = $res;
                for(@key_field[0..$#key_field-1]) {
                    $h->{$record{$_}} ||= {};
                    $h = $h->{$record{$_}};
                }
                $h->{$record{$key_field[-1]}} = \%record;
            }
            else {
                push @$res, \%record;
            }
        }
        delete $fth->[DATAi];
        $cb->($res) if $cb;
        return $res;
    }
    else {
        $cb->() if $cb;
        return;
    }
}

=head2 $ary_ref = $fth->fetchcol_arrayref([\%attr], [$cb->($ary_ref)])

=cut
sub fetchcol_arrayref {
    my $cb = ref($_[-1]) eq 'CODE' ? pop : undef;
    my($fth, $attr) = @_;
    $attr ||= {};
    my @columns = map { $_-1 } @{ $attr->{Columns} || [1] };

    if( $fth->[DATAi] ) {
        my @res = map {
            my $r = $_;
            map { $r->[$_] } @columns
        } @{ delete $fth->[DATAi] };
        $cb->(\@res) if $cb;
        return \@res;
    }
    else {
        $cb->() if $cb;
        return;
    }
}

=head1 AUTHOR

Cindy Wang (CindyLinz)

=head1 BUGS

Please report any bugs or feature requests to C<http://github.com/CindyLinz/Perl-AnyEvent-MySQL>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AnyEvent::MySQL


You can also look for information at:

=over 4

=item * github

L<https://github.com/CindyLinz/Perl-AnyEvent-MySQL>

=item * Search CPAN

L<http://search.cpan.org/dist/AnyEvent-MySQL/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2011-2015 Cindy Wang (CindyLinz).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 CONTRIBUTOR

Dmitriy Shamatrin (justnoxx@github)

clking (clking@github)

=cut

1; # End of AnyEvent::MySQL
