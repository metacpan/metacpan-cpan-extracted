# NAME

DBIx::DBFlow - Database development helpers

# SYNOPSIS

in your cpanfile add the following

    requires 'DBIx::DBFlow::Runtime';

    on develop => sub {
      requires 'DBIx::DBFlow';
    }

# USAGE

## Using the DBFlow on a new project:

Create the database in MySQL (tables, fks, etc)

    dbflow_refresh_model --schema MySchema --dbh "DBD:mysql..."

This will create lib/MySchema.pm. Add this code to it:

    our $VERSION = 1;
    
    sub admin_connection {
      my $schema = __PACKAGE__->connect(
        "DBI:mysql:mysql_read_default_file=pathtoadmincreds.cnf;mysql_read_default_group=schema_group",
        undef,
        undef,
        {
          AutoCommit => 1,
          RaiseError => 1,
          mysql_enable_utf8 => 1,
          quote_char => '`',
          name_sep   => '.',
        },
      );
    }

Now install the DBFlow with

    dbflow_create --schema MySchema

Creates a "database" directory with the deploy info for the database. Creates a handler table in your schema

## Using the DBFlow

Before modifying the database, bump up it's version (you're about to produce what will be the next version 
of the database, so we have to signal that)

Modify the database with your favorite tool (HeidiSQL, mysql CLI, etc). Add columns, indexes, etc.

    dbflow_refresh_model --schema MySchema

This will regenerate lib/MySchema

You can still tweak the database more times (add more columns, change types, etc). You have to execute 
`dbflow_refresh_model` each time, in order to refresh the DBIx::Class model

When you're happy with your changes, and want to produce an upgrade:

    dbflow_make_upgrade_scripts --schema MySchema

This creates a `database/MySQL/upgrade/X-Y/___.sql` file that contains the SQL instructions to migrate
from version X to version Y.

You can create your own (new) SQL files in the same directory that will be executed on upgrade, for operations 
that cannot be automatically derived (suppose you have to UPDATE some values on a table), although it's better
to create Perl files that do the updating with the model (so you don't have to implement complex logic in SQL).

Create a `database/_common/upgrade/X-Y/01-upgrade_step.pl` file (where Y corresponds the version you are producing,
and X to the previous one). Put this code in it:

    sub {
      my $model = shift;
    
      my $things = $model->resultset('Things')->search({ ... });
    }

Do whatever perlish things you want in the update script, and please use the model to do it.

you can test the updating all the times you want with `make obliviatedb` and `dbflow_upgrade_schema --schema MySchema`
until you are sure that the update will work in production.

## Updating the production database

    dbflow_upgrade_schema --schema MySchema

In production all you have to do is execute `dbflow_upgrade_schema`.

# Interesting utilities

## Visualizing your schema

You can visualize your schema with

    dbflow_schema_diagram --schema MySchema

It will generate a PNG image called MySchema\_schema.png

You can control the dimensions of the image with `--height` and `--width` parameters.

You can also specify the name of the file to write to with `--file`.

# FAQ

## MySchema.pm cannot be found

The 'lib' directory in the current directory is automatically included (your schema should be there).
You can use the `-I` option to specify an alternate, or try executing with a PERL5LIB that points to the 
appropiate directory with your schema.

## I have more than one schema to manage in my project

All utils let you specify the schema name you're acting upon with `--schema` and the directory
to create the upgrade/deploy scripts `--dir`

# CONTRIBUTE

The source code and issues are on https://github.com/pplu/dbix-dbflow

# AUTHOR
    Jose Luis Martinez
    CPAN ID: JLMARTIN
    pplusdomain@gmail.com

# COPYRIGHT and LICENSE

Copyright (c) 2016 by Jose Luis Martinez Torres

This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.
