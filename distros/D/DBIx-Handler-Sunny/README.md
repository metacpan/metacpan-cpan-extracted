[![Build Status](https://travis-ci.org/tarao/perl5-DBIx-Handler-Sunny.svg?branch=master)](https://travis-ci.org/tarao/perl5-DBIx-Handler-Sunny)
# NAME

DBIx::Handler::Sunny - DBIx::Handler meets Sunny

# SYNOPSIS

    use DBIx::Handler::Sunny;
    my $handler = DBIx::Handler::Sunny->new($dsn, $user, $pass, $opts);
    my $col = $handler->select_one('SELECT ...');
    my $row = $handler->select_row('SELECT ...');
    my $rows = $handler->select_all('SELECT ...');

# DESCRIPTION

`DBIx::Handler::Sunny` is a DBI handler with some useful interface.
It ads [DBIx::Handler](https://metacpan.org/pod/DBIx::Handler) to methods for selecting a column or row(s).

The methods are taken from [DBIx::Sunny](https://metacpan.org/pod/DBIx::Sunny).

# METHODS

- select\_one

        $col = $handler->select_one($query, @bind);

    Shortcut for `prepare`, `execute` and `fetchrow_arrayref->[0]`.

- select\_row

        $row = $handler->select_row($query, @bind);

    Shortcut for `prepare`, `execute` and `fetchrow_hashref`.

- select\_all

        $rows = $handler->select_all($query, @bind);

    Shortcut for `prepare`, `execute` and `selectall_arrayref(..., { Slice => {} }, ...)`.

- last\_insert\_id

        $id = $handler->last_insert_id

    Retrieve the last insert ID by suitable way for the DB driver.
    Supported drivers are SQLite and MySQL.

# SEE ALSO

[DBIx::Handler](https://metacpan.org/pod/DBIx::Handler)

[DBIx::Sunny](https://metacpan.org/pod/DBIx::Sunny)

# LICENSE

Copyright (C) INA Lintaro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

INA Lintaro <tarao.gnn@gmail.com>
