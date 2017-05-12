package DBD::Safe;
BEGIN {
  $DBD::Safe::VERSION = '0.06';
}

use strict;
use warnings;

#ABSTRACT: keep safe connection to DB


use base qw(DBD::File);

use vars qw($err $errstr $sqlstate $drh);

sub DESTROY {
    shift->STORE(Active => 0);
}

$err      = 0;  # DBI::err
$errstr   = ""; # DBI::errstr
$sqlstate = ""; # DBI::state
$drh      = undef;

sub driver {
    my ($class, $attr) = @_;
    return $drh if $drh;

    DBI->setup_driver($class);

    # x_<smth> allowed only from 1.54
    if ($DBI::VERSION > 1.53) {
        DBD::Safe::db->install_method('x_safe_get_dbh');
    }

    my $self = $class->SUPER::driver({
        Name        => 'Safe',
        Version     => $DBD::Safe::VERSION,
        Err         => \$DBD::Safe::err,
        Errstr      => \$DBD::Safe::errstr,
        State       => \$DBD::Safe::sqlstate,
        Attribution => 'DBD::Safe',
    });
    return $self;
}

sub CLONE {
    undef $drh;
}

#######################################################################
package DBD::Safe::dr;
BEGIN {
  $DBD::Safe::dr::VERSION = '0.06';
}

use strict;
use warnings;

$DBD::Safe::dr::imp_data_size = 0;
use DBD::File;
use DBI qw();
use base qw(DBD::File::dr);

sub connect {
    my($drh, $dbname, $user, $auth, $attr) = @_;

    my $connect_cb;
    if ($attr->{connect_cb}) {
        $connect_cb = $attr->{connect_cb};
    } elsif ($attr->{dbi_connect_args}) {
        $connect_cb = sub { DBI->connect(@{$attr->{dbi_connect_args}}) };
    } else {
        die "No connect way defined\n";
        #return $drh->set_err($DBI::stderr, "No connect way defined");
    }

    my $retry_cb = sub {
        my $try = shift;
        if ($try == 1) {
            return 1;
        } else {
            return 0;
        }
    };
    $retry_cb = $attr->{retry_cb} if ($attr->{retry_cb});

    my $reconnect_cb = sub { 0 };
    $reconnect_cb = $attr->{reconnect_cb} if ($attr->{reconnect_cb});


    my $reconnect_period = $attr->{reconnect_period};

    my $dbh = DBI::_new_dbh(
      $drh => {
               Name         => 'safedb',
               USER         => $user,
               CURRENT_USER => $user,
              },
    );
    $dbh->STORE(Active => 1);

    $dbh->STORE('x_safe_connect_cb'       => $connect_cb);
    $dbh->STORE('x_safe_state'            => {});
    $dbh->STORE('x_safe_retry_cb'         => $retry_cb);
    $dbh->STORE('x_safe_reconnect_cb'     => $reconnect_cb);

    return $dbh;
}

#######################################################################
package DBD::Safe::db;
BEGIN {
  $DBD::Safe::db::VERSION = '0.06';
}

use strict;
use warnings;

use Time::HiRes qw(time);

$DBD::Safe::db::imp_data_size = 0;

my $LOCAL_ATTRIBUTES = {
    PrintError => 1,
    RaiseError => 1,
    Active     => 1,
    AutoCommit => 1,
};

use vars qw($AUTOLOAD);

sub prepare;
sub column_info;
sub last_insert_id;

sub begin_work {
    my $dbh = shift;

    if (!$dbh->FETCH('AutoCommit')) {
        die "Already in a transaction\n";
    }
    $dbh->STORE('AutoCommit', 0);

    my $in_transaction = $dbh->FETCH('x_safe_in_transaction');
    $in_transaction++;
    $dbh->STORE('x_safe_in_transaction', $in_transaction);
    $dbh->STORE('x_safe_transaction_start', time());

    return _proxy_method('begin_work', $dbh, @_);
}

sub _do_commit_or_rollback {
    my ($dbh, $f, @args) = @_;

    if ($dbh->FETCH('AutoCommit')) {
        die "$f() without begin_work()\n";
    }

    my $in_transaction = $dbh->FETCH('x_safe_in_transaction');
    return _proxy_method($f, $dbh, @args) unless ($in_transaction);

    $in_transaction--;
    my $error = 0;
    if ($in_transaction < 0) {
        $in_transaction = 0;
        $error = 1;
    }
    $dbh->STORE('x_safe_in_transaction', $in_transaction);

    if ($error) {
        die "$f() without begin_work()\n";
        #$dbh->set_err(0, "commit() without begin_work()");
    }

    if ($f eq 'rollback') {
        my $tr_start = $dbh->FETCH('x_safe_transaction_start') || 0;
        my $last_reconnect = $dbh->FETCH('x_safe_state')->{last_reconnect} || 0;
        if ($last_reconnect > $tr_start) {
            die "Disconnect occured during transaction, can't call rollback()\n";
        }
    }

    my $res = _proxy_method($f, $dbh, @args);
    if ($in_transaction == 0) {
        $dbh->STORE('AutoCommit', 1);
    }
    return $res;
}

sub commit {
    my $dbh = shift;

    return _do_commit_or_rollback($dbh, 'commit', @_);
}

sub rollback {
    my $dbh = shift;

    return _do_commit_or_rollback($dbh, 'rollback', @_);
}

sub _proxy_method {
    my ($method, $dbh, @args) = @_;
    my $state = $dbh->FETCH('x_safe_state');
    my $real_dbh = stay_connected($dbh);
    return $real_dbh->$method(@args);
}

# TODO: take a more accurate logic from DBD::Proxy
sub AUTOLOAD {
    my $method = $AUTOLOAD;
    $method =~ s/(.*::(.*)):://;
    my $class = $1;
    my $type = $2;

    my $s = sub {
        return _proxy_method($method, @_)
    };

    no strict 'refs';
    *{$AUTOLOAD} = $s;
    goto &$s;
}

sub x_safe_get_dbh {
    # $dont_check is a special flag for FETCH and STORE methods
    my ($dbh, $dont_check) = @_;

    # doesn't call here FETCH avoiding recursion
    my $state = $dbh->{x_safe_state};
    if (!$state || !$state->{dbh} || !$dont_check) {
        stay_connected($dbh);
        $state = $dbh->{x_safe_state};
    }

    return $state->{dbh};
}

sub disconnect {
    my ($dbh) = @_;

    $dbh->STORE(Active => 0);

    1;
}

sub _attr_is_local {
    my $attr = shift;
    return 0 unless defined($attr);
    return 1 if ($attr =~ /^(x_safe_|private_)/);
    return 1 if ($LOCAL_ATTRIBUTES->{$attr});
    return 0;
}

sub STORE {
    my ($dbh, $attr, $val) = @_;

    if (_attr_is_local($attr)) {
        $dbh->{$attr} = $val;

        # because of some old DBI bug
        if ($attr eq 'Active') {
            my $v = $dbh->FETCH($attr);
        }

#        if ($LOCAL_ATTRIBUTES->{$attr}) {
#            my $caller = caller(1);
#            my $real_dbh = stay_connected($dbh);
#            $real_dbh->{$attr} => $val if ($real_dbh);
#        }
    } else {
        my $real_dbh = x_safe_get_dbh($dbh, 'dont_check');
        $real_dbh->STORE($attr => $val);
    }
}

sub FETCH {
    my ($dbh, $attr) = @_;

    if (_attr_is_local($attr)) {
        return $dbh->{$attr};
    } else {
        my $real_dbh = x_safe_get_dbh($dbh, 'dont_check');
        return $real_dbh->FETCH($attr);
    }
}

sub DESTROY {
    my $dbh = shift;
    $dbh->disconnect;
}

sub stay_connected {
    my $dbh = shift;
    my ($caller, $f) = (caller(1))[0,3];

    my $state = $dbh->FETCH('x_safe_state');
    my $reconnect_cb = $dbh->FETCH('x_safe_reconnect_cb');

    my $reconnect = 0;
    if ($state->{dbh}) {
        if (
            $reconnect_cb->($dbh) ||
            (defined($state->{tid}) && $state->{tid} != threads->tid) ||
            ($state->{pid} != $$) ||
            (!is_connected($dbh))
           )
        {
            $reconnect = 1;

            if ($state->{pid} != $$) {
                $state->{dbh}->{InactiveDestroy} = 1;
            }
        }
    } else {
        $reconnect = 1;
    }

    if ($reconnect) {
        $state->{last_reconnect} = time();
        if ($state->{dbh} && !$dbh->FETCH('AutoCommit')) {
            die "Reconnect needed when db in transaction\n";
            #return $dbh->set_err($DBI::stderr, "Reconnect needed when db in transaction");
        }

        my $try = 0;
        my $retry_cb = $dbh->FETCH('x_safe_retry_cb');
        while (1) {
            $try++;
            my $can_connect = $retry_cb->($try);
            if ($can_connect) {
                my $dbh = eval { real_connect($dbh) };
                if (!$dbh) {
                    next;
                } else {
                    $state->{dbh} = $dbh;
                    last;
                }
            } else {
                my $error = $state->{last_error} || '';
                chomp($error);

                die "All tries to connect is ended, can't connect: [$error]\n";
                #return $dbh->set_err(
                #    $DBI::stderr,
                #    "All tries to connect is ended, can't connect: [$error]"
                #);
            }
        }
    }

    return $state->{dbh};
}

sub is_connected {
    my $dbh = shift;

    my $state = $dbh->FETCH('x_safe_state');

    my $active = $state->{dbh}->{Active} || '';
    my $ping = $state->{dbh}->ping || '';

    return $active && $ping;
}

sub real_connect {
    my $dbh = shift;

    my $connect_cb = $dbh->FETCH('x_safe_connect_cb');
    my $state = $dbh->FETCH('x_safe_state');

    my $real_dbh;
    eval {
        $real_dbh = $connect_cb->();
#        for (keys %{$LOCAL_ATTRIBUTES}) {
#            $real_dbh->{$_} = $dbh->FETCH($_);
#        }
    };
    if ($@) {
        $state->{last_error} = $@;
    } else {
        $state->{last_connected} = time();
    }

    $state->{pid} = $$;
    $state->{tid} = threads->tid if $INC{'threads.pm'};

    return $real_dbh;
}

1;

package DBD::Safe::st;
BEGIN {
  $DBD::Safe::st::VERSION = '0.06';
}

$DBD::Safe::st::imp_data_size = 0;

1;

__END__
=pod

=head1 NAME

DBD::Safe - keep safe connection to DB

=head1 VERSION

version 0.06

=head1 SYNOPSIS

  use DBI;
  my $dbh = DBI->connect(
      'DBI:Safe:', undef, undef,
      { dbi_connect_args => [$dsn, $user, $password, $args] }
  );

=head1 DESCRIPTION

DBD::Safe is an abstract DBI driver that helps you to keep a safe connection to
your database. Its purpose is to reconnect to the database when connection becomes corrupted.
DBD::Safe makes reconnection in the following cases:

  - connection was dropped (usually occurs in long-running processes)
  - process was forked or threaded

DBD::Safe throws an exception if reconnection is needed during the transaction.

=head1 WHY YET ANOTHER SOLUTION?

CPAN contains modules with similar functionality. On the first place it is a
L<DBIx::Connector>, also see L<DBIx::HA> and L<DBIx::DWIW>.
But DBIx::Connector and DBIx::DWIW assume their own interface for interacting with
database. If you are going to use DBIx::Connector you must explicitly call
C<< $conn->dbh >> to get a real dbh connection. And if you want to add some fault tolerance
in a tons of existed code, you must refactor all this code where you use database
connections.

DBD::Safe has a transparent interface. You just need to replace C<connect()> options
and after this you can use it as usual database handler.

=head1 METHODS

=over

=item C<connect>

For using DBD::Safe use DBI in a such manner:

  my $dbh = DBI->connect('DBI:Safe:', undef, undef, $dbd_safe_args);

All arguments for DBD::Safe are passed in the C<$dbd_safe_args> hashref.
This hashref can have following keys:

=over

=item I<dbi_connect_args>

It is an arrayref with arguments for C<< DBI->connect() >> which you pass when you
use DBI without DBD::Safe. These arguments will be used for (re)connection to
your database.

=item I<connect_cb>

Instead of passing C<dbi_connect_args> you can pass coderef that will be called
during (re)connection. This coderef must return database handler. Using
C<connect_cb> you can switch to another replica in case of disconnection or
implement another logic.

You must pass one of C<dbi_connect_args> or C<connect_cb>.

=item I<retry_cb>

This callback is used every time when DBD::Safe decides that reconnection needed.
By default DBD::Safe make only one try to reconnect and dies if it was
unsuccessful. You can override this using C<retry_cb>.
This callback takes one argument - number of reconnection trials - and returns
true or false (to make another reconnection attempt or not).
For example, you can place some C<sleep()> in this callback depending on number of trials.

=item I<reconnect_cb>

Callback that additionally checks if reconnection is necessary. Input argument is a C<$dbh>
handler, output - true or false.
For example, you can use this callback to reconnect every N seconds.

=back

=item C<x_safe_get_dbh>

If you have DBI with version >= 1.54, then you can explicitly call

  my $real_dbh = $safe_dbh->x_safe_get_dbh;

This method will return real database handler that uses in the current time.

If you have DBI with version < 1.54, you can call

  my $real_dbh = $safe_dbh->func('x_safe_get_dbh');

=back

=head1 BUGS AND CAVEATS

Connection is checked on each query. This can double your request execution time if all your requests are fast and network latency of your database is big enough.

Statement objects are not safe. Once you've prepared the statement, it won't reconnect to the database transparently.

There are no retries. If the request fails, it fails. This module just check that DB is alive *before* it tries to execute the statement. (Custom, per-query policies support is planned for the future releases).

=head1 SEE ALSO

L<http://github.com/tadam/DBD-Safe>,
L<DBIx::Connector>, L<DBIx::HA>, L<DBIx::DWIW>.

=head1 AUTHOR

Yury Zavarin <yury.zavarin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Yury Zavarin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

