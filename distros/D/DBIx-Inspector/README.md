# NAME

DBIx::Inspector - Get information from $dbh

# SYNOPSIS

    use DBIx::Inspector;

    my $dbh = DBI->connect(...) or die;
    my $inspector = DBIx::Inspector->new(dbh => $dbh);
    my @tables = $inspector->tables;
    for my $table (@tables) {
        print "  pk:\n";
        for my $pk ($table->primary_key) {
            print "    ", $pk->name, "\n";
        }
        print "  columns:\n";
        for my $column ($table->columns) {
            print "    ", $column->name, "\n";
        }
    }

# DESCRIPTION

DBIx::Inspector is a inspector for $dbh.

This is under development. __Any API will change without notice.__

# METHODS

- `my $inspector = DBIx::Inspector->new(dbh => $dbh);`

    Create new instance of DBIx::Inspector.

- `my @tables = $inspector->tables();`

    Retrieve table objects from $dbh. Every elements in @tables is instance of [DBIx::Inspector::Table](http://search.cpan.org/perldoc?DBIx::Inspector::Table).

- `my $table = $inspector->table($table_name);`

    Retrieve table object from $dbh. Return value is instance of [DBIx::Inspector::Table](http://search.cpan.org/perldoc?DBIx::Inspector::Table).

- `my @views = $inspector->views();`

    Retrieve view objects from $dbh. Every elements in @views is instance of [DBIx::Inspector::Table](http://search.cpan.org/perldoc?DBIx::Inspector::Table).

- `my $view = $inspector->view($view_name);`

    Retrieve view object from $dbh. Return value is instance of [DBIx::Inspector::Table](http://search.cpan.org/perldoc?DBIx::Inspector::Table).

# AUTHOR

Tokuhiro Matsuno <tokuhirom AAJKLFJEF@ GMAIL COM>

# SEE ALSO

[DBI](http://search.cpan.org/perldoc?DBI)

# LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
