# NAME

Amon2::DBI - Simple DBI wrapper

# SYNOPSIS

    use Amon2::DBI;

    my $dbh = Amon2::DBI->connect(...);

# DESCRIPTION

Amon2::DBI is a simple DBI wrapper. It provides better usability for you.

# FEATURES

- Set AutoInactiveDestroy to true.

    If your DBI version is higher than 1.614, Amon2::DBI set AutoInactiveDestroy as true.

- Set sqlite\_unicode and mysql\_enable\_utf8 and pg\_enable\_utf8 automatically

    Amon2::DBI set sqlite\_unicode and mysql\_enable\_utf8 automatically.
    If using DBD::Pg version less than 2.99, pg\_enable\_utf8 too.

- Nested transaction management.

    Amon2::DBI supports nested transaction management based on RAII like DBIx::Class or DBIx::Skinny. It uses [DBIx::TransactionManager](https://metacpan.org/pod/DBIx::TransactionManager) internally.

- Raising error when you occurred.

    Amon2::DBI raises exception if your $dbh occurred exception.

# ADDITIONAL METHODS

Amon2::DBI is-a DBI. And Amon2::DBI provides some additional methods.

- `$dbh->do_i(@args);`

    Amon2::DBI uses [SQL::Interp](https://metacpan.org/pod/SQL::Interp) as a SQL generator. Amon2::DBI generate SQL using @args and do it.

- `$dbh->insert($table, \%row);`

    It's equivalent to following statement:

        $dbh->do_i(qq{INSERT INTO $table }, \%row);

# AUTHOR

Tokuhiro Matsuno &lt;tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
