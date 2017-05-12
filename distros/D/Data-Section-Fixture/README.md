# NAME

Data::Section::Fixture - data section as a fixture

# SYNOPSIS

    use Data::Section::Fixture qw(with_fixture);

    my $dbh = DBI->connect(...);

    with_fixture($dbh, sub {
        # fixture data is only accessible inside this scope.
        my $rows = $dbh->selectall_arrayref('SELECT id FROM t ORDER BY id');
        is_deeply $rows, [[1], [2], [3]];
    });

    __DATA__
    @@ setup
    CREATE TABLE t (
        id int
    );
    INSERT INTO t (id) VALUES (1), (2), (3);

    @@ teardown
    DELETE FROM t;

# DESCRIPTION

Data::Section::Fixture is a module to use `__DATA__` section as a fixture data. 
This module is intended to be used with unit testing.

The mark `@@ setup` in `__DATA__` section stands for setup SQL which is executed just before `with_fixture`.
The SQL below the mark `@@ teardown` is executed at the end of `with_fixture` to tear down fixture data.

# FUNCTION

## with\_fixture($dbh, $code\_ref);

Fixture data is only accessible inside this function.

- $dbh

    database handler

- $code\_ref

    executed code

# LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuuki Furuyama <addsict@gmail.com>
