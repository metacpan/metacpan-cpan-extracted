[![Build Status](https://travis-ci.org/karupanerura/DBIx-TransactionManager-Extended.svg?branch=master)](https://travis-ci.org/karupanerura/DBIx-TransactionManager-Extended) [![Coverage Status](http://codecov.io/github/karupanerura/DBIx-TransactionManager-Extended/coverage.svg?branch=master)](https://codecov.io/github/karupanerura/DBIx-TransactionManager-Extended?branch=master)
# NAME

DBIx::TransactionManager::Extended - extended DBIx::TransactionManager

# SYNOPSIS

    use DBI;
    use DBIx::TransactionManager::Extended;

    my $dbh = DBI->connect('dbi:SQLite:');
    my $tm = DBIx::TransactionManager::Extended->new($dbh);

    # begin transaction
    $tm->txn_begin;

        # execute query
        $dbh->do("insert into foo (id, var) values (1,'baz')");
        # And you can do multiple database operations here

        for my $data (@data) {
            push @{ $txn->context_data->{data} } => $data;
            $tm->add_hook_after_commit(sub {
                my $context_data = shift; # with the current (global) transaction
                my @data = @{ $context_data->{data} };
                return unless @data;

                ...

                $context_data->{data} = [];
            });
        }

    # and commit it.
    $tm->txn_commit;

# DESCRIPTION

DBIx::TransactionManager::Extended is extended DBIx::TransactionManager.
This module provides some useful methods for application development.

# EXTENDED METHODS

## context\_data

This is a accessor for a context data.
The context data is a associative array about a current transaction's context data.

## add\_hook\_before\_commit

Adds hook that run at before the commit all transactions.

## add\_hook\_after\_commit

Adds hook that run at after the commit all transactions.

## remove\_hook\_before\_commit

Removes hook that run at before the commit all transactions.

## remove\_hook\_after\_commit

Removes hook that run at after the commit all transactions.

# SEE ALSO

[DBIx::TransactionManager](https://metacpan.org/pod/DBIx::TransactionManager)

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
