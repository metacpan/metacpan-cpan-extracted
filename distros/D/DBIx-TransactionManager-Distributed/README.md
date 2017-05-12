# NAME

DBIx::TransactionManager::Distributed;

# VERSION

    0.01

# DESCRIPTION

Generic database handling utilities.

Currently provides a minimal database handle tracking facility, allowing code
to request a transaction against all active database handles.

# SYNOPSIS

    use DBIx::TransactionManager::Distributed qw(register_dbh release_dbh txn);
    my $dbh1 = DBI->connect('dbi:Pg', '', '', { RaiseError => 1});
    my $dbh2 = DBI->connect('dbi:Pg', '', '', { RaiseError => 1});
    my $dbh3 = DBI->connect('dbi:Pg', '', '', { RaiseError => 1});

    register_dbh(category1 => $dbh1);
    register_dbh(category1 => $dbh2);
    register_dbh(category2 => $dbh2);
    register_dbh(category2 => $dbh3);

    txn { $dbh1->do('update ta set name = "a"'); $dbh2->do('insert into tb values (1)') } 'category1';
    txn { $dbh2->do('update tc set name = "b"'); $dbh3->do('insert into td values (2)') } 'category2';

    release_dbh(category1 => $dbh1);
    release_dbh(category1 => $dbh1);
    release_dbh(category2 => $dbh2);
    release_dbh(category3 => $dbh3);

## register\_dbh

Records the given database handle as being active and available for running transactions against.

Expects a category (string value) and [DBI::db](https://metacpan.org/pod/DBI::db) instance.

Returns the database handle.

Example:

    sub _dbh {
        my $dbh = DBI->connect('dbi:Pg', '', '', { RaiseError => 1});
        return DBIx::TransactionManager::Distributaed::register_dbh(category => $dbh);
    }

## release\_dbh

Marks the given database handle as no longer active - it will not be used for any further transaction requests
via ["txn"](#txn).

Returns the database handle.

Example:

    sub DESTROY {
        my $self = shift;
        return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
        DBIx::TransactionManager::Distributaed::release_dbh($self->dbh)->disconnect;
    }

## \_remove\_dbh\_from\_category

Helper function to reduce common code - removes the given `$dbh` from a single category.

Used internally.

## dbh\_is\_registered

Returns true if the provided database handle has been registered already.

Used when registering a handle acquired via ["connect\_cached" in DBI](https://metacpan.org/pod/DBI#connect_cached).

    register_dbh($category => $dbh) unless dbh_is_registered($category => $dbh);

## register\_cached\_dbh

Records the given database handle created via ["connect\_cached" in DBI](https://metacpan.org/pod/DBI#connect_cached) as being active and available for running transactions against.

Expects a category (string value) and [DBI::db](https://metacpan.org/pod/DBI::db) instance.

Returns the database handle.

Example:

    sub _dbh {
        my $dbh = DBI->connect_cached('dbi:Pg', '', '', { RaiseError => 1});
        return register_cached_dbh('category' => $dbh);
    }

## txn

Runs the given coderef in a transaction.

Expects a coderef and one or more database handle categories.

Will call ["begin\_work" in DBI](https://metacpan.org/pod/DBI#begin_work) for every known database handle in the given category,
run the code, then call ["commit" in DBI](https://metacpan.org/pod/DBI#commit) on success, or ["rollback" in DBI](https://metacpan.org/pod/DBI#rollback) on failure.

Will raise an exception on failure, or return an empty list on success.

Example:

    txn { dbh()->do('NOTIFY something') } 'category';

WARNING: This only applies transactions to known database handles. Anything else -
Redis, cache layers, files on disk - is out of scope. Transactions are a simple
["begin\_work" in DBI](https://metacpan.org/pod/DBI#begin_work) / ["commit" in DBI](https://metacpan.org/pod/DBI#commit) pair, there's no 2-phase commit or other
distributed transaction co-ordination happening here.

## \_check\_fork

Test whether we have forked recently, and invalidate all our caches if we have.

Returns true if there has been a fork since last check, false otherwise.

# SEE ALSO

- [DBIx::TransactionManager](https://metacpan.org/pod/DBIx::TransactionManager)
- [DBIx::ScopedTransaction](https://metacpan.org/pod/DBIx::ScopedTransaction)
- [DBIx::Class::Storage::TxnScopeGuard](https://metacpan.org/pod/DBIx::Class::Storage::TxnScopeGuard)

These modules are also handling scope-based transaction. The main difference is this one operates across database handles with different categories.
