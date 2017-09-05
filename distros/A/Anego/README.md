[![Build Status](https://travis-ci.org/papix/Anego.svg?branch=master)](https://travis-ci.org/papix/Anego)
# NAME

Anego - The database migration utility as our elder sister.

# SYNOPSIS

    # show status
    $ anego status

    RDBMS:        MySQL
    Database:     myapp
    Schema class: MyApp::DB::Schema (lib/MyApp/DB/Schema.pm)

    Hash     Commit message
    --------------------------------------------------
    e299e9f  commit
    1fdc91a  initial commit

    # migrate to latest schema
    $ anego migrate

    # migrate to schema of specified revision
    $ anego migrate revision 1fdc91a

    # show difference between current database schema and latest schema
    $ anego diff

    # show difference between current database schema and schema of specified revision
    $ anego diff revision 1fdc91a

# DESCRIPTION

Anego is database migration utility.

# CONFIGURATION

Anego requires configuration file.
In default, Anego uses `.anego.pl` as configuration file.

    # .anego.pl
    +{
        connect_info => ['dbi:mysql:database=myapp;host=localhost', 'root'],
        schema_class => 'MyApp::DB::Schema',
    }

If you want to use other files for configuration, you can use `-c` option: `anego status -c ./config.pl`

# SCHEMA CLASS

To define database schema, Anego uses [DBIx::Schema::DSL](https://metacpan.org/pod/DBIx::Schema::DSL):

    package MyApp::DB::Schema;
    use strict;
    use warnings;
    use DBIx::Schema::DSL;

    create_table 'author' => columns {
        integer 'id', primary_key, auto_increment;
        varchar 'name', unique;
    };

    create_table 'module' => columns {
        integer 'id', primary_key, auto_increment;
        varchar 'name';
        text    'description';
        integer 'author_id';

        add_index 'author_id_idx' => ['author_id'];

        belongs_to 'author';
    };

    1;

# LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

papix <mail@papix.net>
