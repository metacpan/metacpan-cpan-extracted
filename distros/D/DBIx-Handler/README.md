# NAME

DBIx::Handler - fork-safe and easy transaction handling DBI handler

# SYNOPSIS

    use DBIx::Handler;
    my $handler = DBIx::Handler->new($dsn, $user, $pass, $dbi_opts, $opts);
    my $dbh = $handler->dbh;
    $dbh->do(...);

# DESCRIPTION

DBIx::Handler is fork-safe and easy transaction handling DBI handler.

DBIx::Handler provide scope base transaction, fork safe dbh handling, simple.

# METHODS

- my $handler = DBIx::Handler->new($dsn, $user, $pass, $dbi\_opts, $opts);

    get database handling instance.

    Options:

    - on\_connect\_do : CodeRef|ArrayRef\[Str\]|Str
    - on\_disconnect\_do : CodeRef|ArrayRef\[Str\]|Str

        Execute SQL or CodeRef when connected/disconnected.

    - result\_class : ClassName

        This is a `query` method's result class.
        If this value is defined, `$result_class-`new($handler, $sth)> is called in `query()` and `query()` returns the instance.

    - trace\_query : Bool

        Enables to inject a caller information as SQL comment.

    - trace\_ignore\_if : CodeRef

        Ignore to inject the SQL comment when trace\_ignore\_if's return value is true.

    - no\_ping : Bool

        By default, ping before each executing query.
        If it affect performance then you can set to true for ping stopping.

    - dbi\_class : ClassName

        By default, this module uses generally [DBI](https://metacpan.org/pod/DBI) class.
        For example, if you want to use another custom class compatibility with DBI, you can use it with this option.

    - prepare\_method : Str

        By default, this module uses generally [prepare](https://metacpan.org/pod/prepare) method.
        For example, if you want to use `prepare_cached` method or other custom method compatibility with `prepare` method, you can use it with this option.

- my $handler = DBIx::Handler->connect($dsn, $user, $pass, $opts);

    connect method is alias for new method.

- my $dbh = $handler->dbh;

    get fork safe DBI handle.

- $handler->disconnect;

    disconnect current database handle.

- my $txn\_guard = $handler->txn\_scope

    Creates a new transaction scope guard object.

        do {
            my $txn_guard = $handler->txn_scope;
                # some process
            $txn_guard->commit;
        }

    If an exception occurs, or the guard object otherwise leaves the scope
    before `$txn->commit` is called, the transaction will be rolled
    back by an explicit ["txn\_rollback"](#txn_rollback) call. In essence this is akin to
    using a ["txn\_begin"](#txn_begin)/["txn\_commit"](#txn_commit) pair, without having to worry
    about calling ["txn\_rollback"](#txn_rollback) at the right places. Note that since there
    is no defined code closure, there will be no retries and other magic upon
    database disconnection.

- $txn\_manager = $handler->txn\_manager

    Get the [DBIx::TransactionManager](https://metacpan.org/pod/DBIx::TransactionManager) instance.

- $handler->txn\_begin

    start new transaction.

- $handler->txn\_commit

    commit transaction.

- $handler->txn\_rollback

    rollback transaction.

- $handler->in\_txn

    are you in transaction?

- my @result = $handler->txn($coderef);

    execute $coderef in auto transaction scope.

    begin transaction before $coderef execute, do $coderef with database handle, after commit or rollback transaction.

        $handler->txn(sub {
            my $dbh = shift;
            $dbh->do(...);
        });

    equals to:

        $handler->txn_begin;
            my $dbh = $handler->dbh;
            $dbh->do(...);
        $handler->txn_rollback;

- my @result = $handler->run($coderef);

    execute $coderef.

        my $rs = $handler->run(sub {
            my $dbh = shift;
            $dbh->selectall_arrayref(...);
        });

    or

        my @result = $handler->run(sub {
            my $dbh = shift;
            $dbh->selectrow_array('...');
        });

- my $sth = $handler->query($sql, \[\\@bind | \\%bind\]);

    execute query. return database statement handler.

- my $sql = $handler->trace\_query\_set\_comment($sql);

    inject a caller information as a SQL comment to `$sql` when trace\_query is true.

## ACCESSORS

The setters and the getters for options.

- result\_class
- trace\_query
- trace\_ignore\_if
- no\_ping
- on\_connect\_do
- on\_disconnect\_do

# AUTHOR

Atsushi Kobayashi &lt;nekokak \_at\_ gmail \_dot\_ com>

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
