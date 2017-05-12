# NAME

DBIx::Delta - a module for applying outstanding database deltas
(migrations) to a database instance

# SYNOPSIS

    # Must be used via a subclass providing a db connection e.g.
    package Foo::Delta;
    use base qw(DBIx::Delta);
    use DBI;
    sub connect { 
        DBI->connect('dbi:SQLite:dbname=foo.db');
    }
    1;

    # Then:
    perl -MFoo::Delta -le 'Foo::Delta->run'
    # Or create a delta run script (e.g. delta.pl):
    use Foo::Delta;
    Foo::Delta->run;

    # Then to check for deltas that have not been applied
    ./delta.pl 
    # And to apply those deltas and update the database
    ./delta.pl -u

# DESCRIPTION

DBIx::Delta is a module used to apply database deltas (migrations) to a 
database instance.

It is intended for use in maintaining multiple database schemas in sync
e.g. you create deltas on your development database instance, and
subsequently apply those deltas to your test instance, and then finally
to production.

It is simple and only requires DBI/DBD for your database connectivity.

## DELTAS

Deltas are just '\*.sql' files containing arbitrary sql statements, in
your current directory. Any deltas that haven't been seen before are
executed against your database, and if successful, the filename is
recorded in an 'applied' subdirectory, and those deltas are thereafter
ignored. 

This means that you can't change or add to a delta after it has been
applied to the database. Changes to existing database objects must be 
done via new deltas using appropriate 'ALTER' commands.

## USAGE

    # Must be used via a subclass providing a db connection e.g.
    package Foo::Delta;
    use base qw(DBIx::Delta);
    use DBI;
    sub connect { 
        DBI->connect('dbi:SQLite:dbname=foo.db','','');
    }
    1;

    # And then ...
    perl -MFoo::Delta -le 'Foo::Delta->run'

## STATEMENT FILTERING

As of version 0.5 DBIx::Delta supports statement filtering, allowing 
subclasses to do arbitrary munging of statements before they're applied.
This is done by overriding the filter\_statement method in your subclass:

    sub filter_statement {
      my ($self, $statement) = @_;

      # Munge $statement

      return $statement;
    }

This can be useful, for instance, if you're doing IP-based grants in your
deltas, and need to use different addresses for your different environments.
For instance, you could use the following grant in your delta (mysql syntax):

    grant all on db.table to user@localhost;

and then modify it in your production DBIx::Delta subclass by doing:

    $statement =~ s/^(grant.*)localhost/${1}192.168.0.10/;

# AUTHOR

Gavin Carr <gavin@openfusion.com.au>

# LICENCE

Copyright 2005-2014, Gavin Carr.

This program is free software. You may copy or redistribute it under the 
same terms as perl itself.
