package Anego;
use 5.008001;
use strict;
use warnings;
use utf8;

our $VERSION = "0.02";

1;

__END__

=encoding utf-8

=head1 NAME

Anego - The database migration utility as our elder sister.

=head1 SYNOPSIS

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

=head1 DESCRIPTION

Anego is database migration utility.

=head1 CONFIGURATION

Anego requires configuration file.
In default, Anego uses C<.anego.pl> as configuration file.

    # .anego.pl
    +{
        connect_info => ['dbi:mysql:database=myapp;host=localhost', 'root'],
        schema_class => 'MyApp::DB::Schema',
    }

If you want to use other files for configuration, you can use C<-c> option: C<anego status -c ./config.pl>

=head1 SCHEMA CLASS

To define database schema, Anego uses L<DBIx::Schema::DSL>:

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

=head1 LICENSE

Copyright (C) papix.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

papix E<lt>mail@papix.netE<gt>

=cut

