# NAME

DBIx::NamedParams - use named parameters instead of '?'

# SYNOPSIS

This module allows you to use named parameters as the placeholders instead of '?'.

    use DBIx::NamedParams;

    # Connect DB
    my $dbh = DBI->connect( ... ) or die($DBI::errstr);

    # Bind scalar
    # :<Name>-<Type>
    my $sql_insert = qq{
        INSERT INTO `Users` ( `Name`, `Status` ) VALUES ( :Name-VARCHAR, :State-INTEGER );
    };
    my $sth_insert = $dbh->prepare_ex( $sql_insert ) or die($DBI::errstr);
    $sth_insert->bind_param_ex( { 'Name' => 'Rio', 'State' => 1, } ) or die($DBI::errstr);
    my $rv = $sth_insert->execute() or die($DBI::errstr);

    # Bind fixed array
    # :<Name>{Number}-<Type>
    my $sql_select1 = qq{
        SELECT `ID`, `Name`, `Status`
        FROM `Users`
        WHERE `Status` in ( :State{4}-INTEGER );
    };
    my $sth_select1 = $dbh->prepare_ex( $sql_select1 ) or die($DBI::errstr);
    $sth_select1->bind_param_ex( { 'State' => [ 1,2,4,8 ], } ) or die($DBI::errstr);
    my $rv = $sth_select1->execute() or die($DBI::errstr);

    # Bind variable array
    # :<Name>+-<Type>
    my $sql_select2 = qq{
        SELECT `ID`, `Name`, `Status`
        FROM `Users`
        WHERE `Status` in ( :State+-INTEGER );
    };
    my $sth_select2 = $dbh->prepare_ex( $sql_select2, { 'State' => [ 1,2,4,8 ], } ) 
        or die($DBI::errstr);
    my $rv = $sth_select2->execute() or die($DBI::errstr);

# DESCRIPTION

DBIx::NamedParams helps binding SQL parameters.

# FLAGS

## $DBIx::NamedParams::KeepBindingIfNoKey

In `bind_param_ex()`, this flag controls the behavior when the hash reference doesn't have the key 
in the SQL statement.

Defaults to false. The placeholders according to the missing keys are set to `undef`. 
All of the placeholders have to be set at once.

Setting this to a true value, the placeholders according to the missing keys are kept. 
You can set some placeholders at first, and set other placeholders later.
If you want to set a placeholder to null, you have to set `undef` explicitly.

# METHODS

## DBIx::NamedParams Class Methods

### all\_sql\_types

Returns the all SQL data types defined in [DBI](https://metacpan.org/pod/DBI) .

    my @types = DBIx::NamedParams::all_sql_types();

### debug\_log

Writes the parsed SQL statement and the values at the parameter positions into the log file.
When omitting the filename, creates the log file in the home directory.

    DBIx::NamedParams::debug_log( '/tmp/testNamedParams.log' );

## Database Handle Methods

### driver\_typename\_map

Returns the hash from the driver type names to the DBI typenames.

    my %map = $dbh->driver_typename_map();

### prepare\_ex

Prepares a statement for later execution by the database engine and returns a reference to a statement handle object.
When the SQL statement has the variable array `:<Name>+-<Type>`, the hash reference as the second argument is mandatory.
When the SQL statement doesn't have the variable array `:<Name>+-<Type>`, the hash reference as the second argument is optional.

    my $sth = $dbh->prepare_ex( $statement, $hashref ) or die($DBI::errstr);

## Database Handle Methods

### bind\_param\_ex

Binds each parameters at once according to the hash reference.
The hash reference should have the keys that are same names to the parameter names in the SQL statement.
When the hash reference doesn't have the key that is same to the parameter name, the parameter is not set. 

    $sth->bind_param_ex( $hashref ) or die($DBI::errstr);

# SEE ALSO

## Similar modules

[Tao::DBI](https://metacpan.org/pod/Tao%3A%3ADBI)

[DBIx::NamedBinding](https://metacpan.org/pod/DBIx%3A%3ANamedBinding)

[SQL::NamedPlaceholder](https://metacpan.org/pod/SQL%3A%3ANamedPlaceholder)

## DBD informations

[SQLite Keywords](https://www.sqlite.org/lang_keywords.html) explains how to quote the identifier.

# LICENSE

Copyright (C) TakeAsh.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

[TakeAsh](https://github.com/TakeAsh/)
