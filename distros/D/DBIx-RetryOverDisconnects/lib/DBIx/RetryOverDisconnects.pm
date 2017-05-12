package DBIx::RetryOverDisconnects;
use base 'DBI';
use strict;
use 5.006;

our $VERSION = '0.12';
our ($errstr, $err);
use Exception::Class qw(DBIx::RetryOverDisconnects::Exception);
DBIx::RetryOverDisconnects::Exception->Trace(1);
use constant PRIV => 'private_DBIx-RetryOverDisconnects_data';

=head1 NAME

DBIx::RetryOverDisconnects - DBI wrapper that helps to deal with databases connection problems

=head1 SYNOPSIS

    use DBIx::RetryOverDisconnects;
    my $dbh = DBIx::RetryOverDisconnects->connect($dsn, $user, $pass, {
        ReconnectRetries  => 5,
        ReconnectInterval => 1,
        ReconnectTimeout  => 3,
        TxnRetries        => 3,
    });

    #All of this 3 methods will be successfuly completed despite of
    #possible connection losses except for sql errors.
    $dbh->do("...");
    my $sth = $dbh->prepare("...");
    $sth->execute(...);

    #other functionality that DBI supports

    $dbh->begin_work;
    my $ok = eval {
        $dbh->do("...");
        #...code
        $dbh->do("...");
        $dbh->commit;
        1;
    };

    unless ($ok) {
        if ($dbh->is_trans_disconnect) {
            #connection to database has been lost during transaction
            #$dbh has been already reconnected to database as we felt here.
            #It is now safe to retry the transaction from the beginning.
        }
        elsif($dbh->is_fatal_disconnect) {
            #database is down and reconnect retries limit is reached
        }
        elsif($dbh->is_sql_error) {
            #all other DBI's errors that are not related to connection problems
            $dbh->rollback;
            #deal with sql error;
        }
    }

    #or simply run the perl code in transaction mode.
    $dbh->txn_do(sub {
        $dbh->do("...");
        #...code
        $dbh->do("...");
    });
    #successful completion is guaranteed except for sql or perl errors.

=head1 DESCRIPTION

This wrapper intercepts all requests. If some request fails this module
detects the reason of fail. If the reason was database connection problem
then wrapper would automatically reconnect and restart the query. Otherwise
it would rethrow the exception.

If you are not in transaction then you can just do

    $dbh->do('...');
    $sth->execute(...);

This might have 2 fatal cases:

=over

=item *

SQL error (a good reason to die).

=item *

Reconnect retries limit reached (database is completely down or network failure).

=back

For example, if the connection to database were lost during 'execute' call, the module
would reconnect to database with a timeout 'ReconnectTimeout'. If reconnect failed it
would reconnect again 'ReconnectRetries' times with 'ReconnectInterval' interval
(in seconds). If reconnect retries limit was reached it would raise an error and
$dbh->is_fatal_disconnect would be true.

If you are in transaction then even DB disconnect will raise an error.
But you can check $dbh->is_trans_disconnect and restart the transaction if it is 'true'.
Other possible errors are the same: sql error and reconnect limit.

The recommended way of using transactions is

    $dbh->txn_do($code_ref);

because 'txn_do' would automatically restart the transaction if it was failed because
of database disconnect. The transaction can be restarted at most 'TxnRetries' times.
If 'TxnRetries' limit was reached then error would be raised and
$dbh->is_fatal_trans_disconnect set to true.
Other error cases are the same as above.

'txn_do' would try do to rollback if there was a perl or sql error (no rollback needed
when you loose connection to database: DB server already has done it).
Rollback is successul when $@ =~ /Rollback OK/;

Note: For the perfomance reasons, DBI attribute 'RaiseError' is always set to 'true'.

=head1 METHODS

=head1 Class methods

=head2 connect

    DBIx::RetryOverDisconnects->connect($dsn, $user, $pass, $attrs);

All parameters are passed directly to DBI.
Additional $attrs are

=over

=item *

ReconnectRetries - How many times DBIx::RetryOverDisconnects will try to reconnect
to database. Default to 5.

=item *

ReconnectInterval - Interval (in seconds) between reconnect attemps.
Default to 2.

=item *

ReconnectTimeout - Timeout (in seconds) for waiting the database to accept
connection (because sometimes DBI->connect can block your application).
Default to 5.

=item *

TxnRetries - How many times the wrapper would try to restart transaction if it was
failed because of database connection problems. Default to 4.

=back

=cut

sub connect {
    my ($this, $dsn, $user, $pass, $attrs) = @_;

    my $self_attrs = $this->get_self_attrs($attrs);
    $attrs->{RaiseError} = 1;
    my $self = $this->SUPER::connect($dsn, $user, $pass, $attrs);
    my $driver = $self->{Driver}{Name};
    DBIx::RetryOverDisconnects::Exception->new("Sorry, driver '$driver' is not yet supported\n")->throw
        unless DBIx::RetryOverDisconnects::db->can('is_disconnect_'.lc($driver));
    $self_attrs->{AutoCommit} = $self->{AutoCommit};
    $self->{PRIV()} = $self_attrs;

    return $self;
}

sub get_self_attrs {
    my ($this, $attrs) = @_;
    return {
        retries     => exists $attrs->{ReconnectRetries} ? (delete $attrs->{ReconnectRetries}) : 5,
        interval    => (delete $attrs->{ReconnectInterval}) || 1,
        timeout     => (delete $attrs->{ReconnectTimeout}) || 5,
        txn_retries => (delete $attrs->{TxnRetries}) || 4,
    };
}


package DBIx::RetryOverDisconnects::db;
use base 'DBI::db';
use strict;

use constant PRIV => DBIx::RetryOverDisconnects::PRIV();

sub clone {
    my $self = shift;
    local $^W = 0;
    my $data =  $self->{PRIV()};
    $data->{is_cloning} = 1;
    my $new_self = $self->SUPER::clone(@_) or return;
    delete $data->{is_cloning};
    $new_self->{PRIV()} = {%$data};
    return $new_self;
}

=head1 Database handle object methods

=head2 set_callback

    $dbh->set_callback(afterReconnect => $code_ref);

Set callbacks for some events. Currently only afterReconnect is supported.
It is called after every successful reconnect to database.

=cut

sub set_callback {
    my ($self, %callbacks) = @_;
    my $old = $self->{PRIV()}->{callback} || {};
    $self->{PRIV()}->{callback} = {%$old, %callbacks};
    return;
}

sub exc_conn_trans {
    my $self = shift;
    my $msg = 'Connection to database lost while in transaction';
    $DBIx::RetryOverDisconnects::errstr = $msg;
    $DBIx::RetryOverDisconnects::err    = 3;
    DBIx::RetryOverDisconnects::Exception->new($msg);
}

sub exc_conn_trans_fatal {
    my $self = shift;
    my $msg = 'Connection to database lost while in transaction (retries exceeded)';
    $DBIx::RetryOverDisconnects::errstr = $msg;
    $DBIx::RetryOverDisconnects::err    = 4;
    DBIx::RetryOverDisconnects::Exception->new($msg);
}

=head2 is_fatal_trans_disconnect

Returns 'true' if last failed operation was txn_do and TxnRetries limit
was reached.

=cut

sub is_fatal_trans_disconnect {$DBIx::RetryOverDisconnects::err == 4}

=head2 is_trans_disconnect

Return 'true' if last failed operation was a transaction and it could be restarted.
The database handle was successfuly reconnected again.

=cut

sub is_trans_disconnect       {$DBIx::RetryOverDisconnects::err == 3}

=head2 is_fatal_disconnect

Return 'true' if reconnect retries limit has been reached. In this case the
database handle is not connected.

=cut

sub is_fatal_disconnect       {$DBIx::RetryOverDisconnects::err == 2}

=head2 is_sql_error

Return 'true' if query failed because of some other reason, not related to
database connection problems. See $DBI::errstr for details.

=cut

sub is_sql_error              {$DBIx::RetryOverDisconnects::err == 1}

sub exc_conn_fatal {
    my $self = shift;
    my $msg = 'Connection to database lost (retries exceeded)';
    $DBIx::RetryOverDisconnects::errstr = $msg;
    $DBIx::RetryOverDisconnects::err    = 2;
    DBIx::RetryOverDisconnects::Exception->new($msg);
}

sub exc_flush {
    my $self = shift;
    $DBIx::RetryOverDisconnects::errstr = undef;
    $DBIx::RetryOverDisconnects::err    = undef;
}

sub exc_std {
    my ($self, $e) = @_;
    $DBIx::RetryOverDisconnects::errstr = 'standard DBI error';
    $DBIx::RetryOverDisconnects::err    = 1;
    $e;
}

foreach my $func (qw/
    prepare do statistics_info begin_work commit rollback
    selectrow_array selectrow_arrayref selectall_arrayref
    selectall_hashref
/)
{
    no strict 'refs';
    *$func = sub {
        my $self = shift;
        my $super_method = "SUPER::$func";
        my $data = $self->{PRIV()};
        return $self->$super_method(@_) if $data->{Intercept}; #Already protected

        my ($retval, @retval);
        my $wa = wantarray;
        my $autocommit = $self->{AutoCommit};

        while(1) {

            $data->{Intercept} = 1;
            local $@;
            my $ok = eval {
                defined $wa ? $wa ? (@retval = $self->$super_method(@_)) :
                                    ($retval = $self->$super_method(@_)) :
                                    $self->$super_method(@_);
                1;
            };
            $data->{Intercept} = 0;

            last if $ok;

            my $e = DBIx::RetryOverDisconnects::Exception->new( $DBI::errstr or $@ );
            return unless $self->take_measures($e, undef, $autocommit);
        }

        return $wa ? @retval : $retval;
    };
}

=head2 ping

Always returns 'true' or dies ($dbh->is_fatal_disconnect = true). Does original DBI::db's
ping and if it is false then it reconnects.

=cut

sub ping {
    my $self = shift;
    return 1 if $self->SUPER::ping;
    return if $self->{PRIV()}{is_cloning};
    my $in_trans = !$self->{AutoCommit};
    $self->reconnect;
    $self->exc_conn_trans->throw if $in_trans;
    return 1;
}

sub take_measures {
    my ($self, $e, $sth, $autocommit) = @_;
    $self->exc_flush;
    local $@;
    $self->exc_std($e)->rethrow if eval { $self->SUPER::ping };

    my $is_disconnect_method = 'is_disconnect_'.lc($self->{Driver}->{Name});
    if ($self->$is_disconnect_method($e)) {
        warn "Disconnected!\n" if $self->{PrintError};
        return unless $self->reconnect($sth);
        $self->exc_conn_trans->throw unless $autocommit;
        return 1;
    }

    $self->exc_std($e)->rethrow;
}

sub is_disconnect_mysql {
    my $self = shift;
    local $_ = shift;
    return 1 if /lost\s+connection/i or /can't\s+connect/i or
                /server\s+shutdown/i or /MySQL\s+server\s+has\s+gone\s+away/i;
    return;
}

sub is_disconnect_pg {
    my $self = shift;
    local $_ = shift;
    return 1 if /server\s+closed\s+the\s+connection\s+unexpectedly/i or
                /terminating connection/ or
                /no\s+more\s+connections\s+allowed/ or # pgbouncer
                /no\s+working\s+server\s+connection/ or # pgbouncer 1.4.2
                /_timeout/ or # pgbouncer
                /pgbouncer\s+cannot\s+connect\s+to\s+server/; # pgbouncer 1.5+
    return;
}
*is_disconnect_pgpp = *is_disconnect_pg;

sub is_disconnect_sqlite {} #SQLite has no connection problems. Isn't that right?
*is_disconnect_sqlite2 = *is_disconnect_sqlite;

sub is_disconnect_oracle {
    my $self = shift;
    local $_ = shift;
    return 1 if /ORA-03135/ or # "connection lost contact"
                /ORA-03113/;   # "end-of-file on communication channel"
    return;
}

sub is_disconnect_sybase {
    #?
}

sub is_disconnect_db2 {
    #?
}

sub reconnect {
    my ($self, $sth) = @_;
    my $data = $self->{PRIV()};
    my $new_dbh;

    for (my $i = 1; (!$data->{retries} || $i <= $data->{retries}); $i++) {
        warn "Reconnect try #$i\n" if $self->{PrintError};
        my $alarm;
        local $SIG{ALRM} = sub {
            alarm(0);
            die($alarm = 1);
        };
        local $@;
        eval {
            alarm($data->{timeout});
            eval {
                local $^W = 0;
                $new_dbh = $self->clone;
            };
            alarm(0);
        };
        if ($new_dbh) {
            warn "Reconnected!\n" if $self->{PrintError};
            last;
        }
        sleep $data->{interval};
    }

    ($self->disconnect, $self->exc_conn_fatal->throw) unless $new_dbh;

    $self->swap_inner_handle($new_dbh);
    $self->{PRIV()}    = $data;
    $new_dbh->{PRIV()} = undef;
    $new_dbh->STORE('Active', 0);

    $self->STORE('CachedKids', {});
    if ($sth) {
        my $new_sth = $self->prepare_cached($sth->{Statement});
        $sth->swap_inner_handle($new_sth, 1);
        $sth->restore_params($new_sth);
        $new_sth->finish;
    }
    $self->STORE('CachedKids', {});

    #Now autocommit is broken (has been copied from disconnected handle)
    $self->{AutoCommit} = $data->{AutoCommit}; #Set initial value
    $new_dbh->disconnect;

    #Call callback. Currently only one supported.
    if($self->{PRIV()}{callback} && (my $code = $self->{PRIV()}{callback}{afterReconnect})) {
        $code->($self, $sth) if ref $code eq 'CODE';
    }

    return 1;
}

=head2 txn_do

    $dbh->txn_do($code_ref);

Executes $code_ref in a transaction environment. Automatically reconnects and
restarts the transaction in any case of connection problems.
'txn_do' is able to die with one of the is_fatal_disconnect, is_sql_error,
is_fatal_trans_disconnect set to true.

In most cases you don't need to wrap it into 'eval' because all of this exceptions
are subject to die (database completely down, network down, bussiness logic error, etc).

=cut

sub txn_do {
    my ($self, $coderef) = (shift, shift);

    DBIx::RetryOverDisconnects::Exception->new('$coderef must be a CODE reference')->throw
        unless ref $coderef eq 'CODE';

    return $coderef->(@_) unless $self->{AutoCommit};

    my $wa = wantarray;
    my (@result, $result);
    my $i = 0;
    while ('preved') {
        local $@;
        my $ok = eval {
            $self->begin_work;
            defined $wa ? $wa ? (@result = $coderef->(@_)) :
                                ($result = $coderef->(@_)) :
                                $coderef->(@_);
            $self->commit;
            1;
        };
        last if $ok;

        $self->exc_conn_trans_fatal->throw if $self->{PRIV()}{txn_retries} <= $i++;
        next if $self->is_trans_disconnect;
        $@->rethrow if $self->is_fatal_disconnect;
        my $txn_err = $@;
        my $rollback_ok = eval {$self->rollback; 1};
        $txn_err .= $rollback_ok ? ' (Rollback OK)' : "(Rollback failed: $@)";
        DBIx::RetryOverDisconnects::Exception->new($txn_err)->throw;
    }

    return $wa ? @result : $result;
}


package DBIx::RetryOverDisconnects::st;
use base 'DBI::st';
use strict;

use constant PRIV => DBIx::RetryOverDisconnects::PRIV();

foreach my $func (qw/execute execute_array execute_for_fetch/) {
    no strict 'refs';
    *$func = sub {
        my $self = shift;
        my $super_method = "SUPER::$func";
        my $dbh = $self->{Database};
        my $data = $dbh->{PRIV()};
        return $self->$super_method(@_) if $data->{Intercept}; #Already protected

        my ($retval, @retval);
        my $wa = wantarray;
        my $autocommit = $dbh->{AutoCommit};

        while(1) {

            $data->{Intercept} = 1;
            local $@;
            my $ok = eval {
                defined $wa ? $wa ? (@retval = $self->$super_method(@_)) :
                                    ($retval = $self->$super_method(@_)) :
                                    $self->$super_method(@_);
                1;
            };
            $data->{Intercept} = 0;

            last if $ok;

            my $e = DBIx::RetryOverDisconnects::Exception->new( $DBI::errstr or $@ );
            return unless $dbh->take_measures($e, $self, $autocommit);
        }
        return $wa ? @retval : $retval;
    };
}

sub restore_params {
    my $self = shift;
    my $from = shift;
    
    my $types = $from->{ParamTypes} || {};
    #Restore possible ParamArrays
    my $param_arrays = $from->{ParamArrays} || {};
    while (my($bind, $array) = each %$param_arrays) {
        $self->bind_param_array($bind, $array, $types->{$bind} ? $types->{$bind} : ());
    }

    #Restore normal ph's values
    my $param_values = $from->{ParamValues} || {};
    my $i = 1;
    foreach my $bind_name (sort {($a =~ /(\d+)/)[0] <=> ($b =~ /(\d+)/)[0]} keys %$param_values) {
        $self->bind_param($i++, $param_values->{$bind_name}, $types->{$bind_name} ? $types->{$bind_name} : ());
    }
}

=head1 OVERLOADED METHODS

=head2 Database handle object methods

prepare, do, statistics_info, begin_work, commit, rollback, selectrow_array,
selectrow_arrayref, selectall_arrayref, selectall_hashref

=head2 Database statement object methods

execute, execute_array, execute_for_fetch

=head1 DATABASE SUPPORT

Currently PostgreSQL, MySQL, Oracle and SQLite are supported.

=head1 SEE ALSO

L<DBI>, L<DBIx::Class>.

=head1 AUTHOR

Pronin Oleg <syber@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
