[![Build Status](https://travis-ci.org/soh335/DBIx-Class-Storage-TxnEndHook.svg?branch=master)](https://travis-ci.org/soh335/DBIx-Class-Storage-TxnEndHook)
# NAME

DBIx::Class::Storage::TxnEndHook - transaction hook provider for DBIx::Class

# SYNOPSIS

    package MyApp::Schema;
    use parent 'DBIx::Schema';
    __PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::TxnEndHook');
    __PACKAGE__->ensure_class_loaded('DBIx::Class::Storage::DBI');
    __PACKAGE__->inject_base('DBIx::Class::Storage::DBI', 'DBIx::Class::Storage::TxnEndHook');

    package main

    my $schema = MyApp::Schema->connect(...)
    $schema->storage->txn_begin;
    $schema->storage->add_txn_end_hook(sub { ... });
    $schema->storage->txn_commit;

# DESCRIPTION

DBIx::Class::Storage::TxnEndHook is transaction hook provider for DBIx::Class.
This module is porting from [DBIx::TransactionManager::EndHook](https://metacpan.org/pod/DBIx::TransactionManager::EndHook).

# METHODS

- $schema->storage->add\_txn\_end\_hook(sub{ ... })

    Add transaction hook. You can add multiple subroutine and transaction is not started, cant call
    this method. These subroutines are executed after all transactions are commited. If any
    transaction is failed, these subroutines are cleard.

    If died in subroutine, _warn_ deid message and clear remain all subroutines. It is different from
    [DBIx::Class::Storage::TxnEndHook](https://metacpan.org/pod/DBIx::Class::Storage::TxnEndHook). In [DBIx::TransactionManager::EndHook](https://metacpan.org/pod/DBIx::TransactionManager::EndHook), when died in
    subroutine, other subroutines are canceld and _died_.

    Why ? It's caused by [DBIx::Class::Storage::TxnScopeGuard](https://metacpan.org/pod/DBIx::Class::Storage::TxnScopeGuard). Guard object marked inactivated
    after `$self->{storage}->txn_commit` in `DBIx::Class::Storage::TxnScopeGuard::commit`.
    So if died in here, can't mark guard as inactivated.

# SEE ALSO

[DBIx::Class](https://metacpan.org/pod/DBIx::Class)

[DBIx::Class::Storage](https://metacpan.org/pod/DBIx::Class::Storage)

[DBIx::TransactionManager::EndHook](https://metacpan.org/pod/DBIx::TransactionManager::EndHook)

# LICENSE

Copyright (C) soh335.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

soh335 <sugarbabe335@gmail.com>
