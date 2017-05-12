package Bigtop::ScriptHelp::Style::Pg8Live;

use strict; use warnings;

use base 'Bigtop::ScriptHelp::Style';

use DBI;

my $usage_tail =
        "use: -s PgLive 'dbi:Pg:dbname=name' user password [schema]\n";

sub get_db_layout {
    my $self          = shift;
    my $cmd_line_args = shift;
    my $all_tables    = shift || {};

    die $usage_tail unless $cmd_line_args;

    # handle args
    my ( $dsn, $user, $pass, $db_schema ) = split / /, $cmd_line_args;

    $db_schema ||= 'public';

    # connect to database
    my $dbh;
    eval {
        $dbh = DBI->connect( $dsn, $user, $pass );
    };
    if ( $@ ) {
        $@ =~ s/\s+at.*line.*\n//;
        die "couldn't connect to database:\n$@\n$usage_tail\n";
    }

    # get tables which are not already present, strip public. if present
    my @db_tables  = map { $_ =~ s/^public\.//; $_ }
                         $dbh->tables( undef, $db_schema, '%', '%' );

    my @new_tables = grep { not defined $all_tables->{ $_ } } @db_tables;

    # now walk the tables and pull column data
    my %columns;
    my %foreigners;

    my $oid_sth = $dbh->prepare(
            'SELECT oid FROM pg_class WHERE relname = ?'
    );

    my $column_sth = $dbh->prepare(
            'SELECT attname, typname FROM pg_attribute, pg_type '
            .   'WHERE attrelid = ? AND attnum > 0 AND atttypid = pg_type.oid '
            .   'ORDER BY attnum'
    );

    my $pk_sth = $dbh->prepare(
            q!SELECT conkey FROM pg_constraint !
            .   q!WHERE contype = 'p' and conrelid = ?!
    );

    my $defaults_sth = $dbh->prepare(
            'SELECT adnum, adsrc FROM pg_attrdef WHERE adrelid = ?'
    );

    # we could also get the columns in the other table: confkey
    # but we assume it is the id
    my $foreign_sth = $dbh->prepare(
            'SELECT conkey, relname, confkey FROM pg_constraint '
            .   'JOIN pg_class ON pg_class.oid = confrelid '
            .   q!WHERE conrelid = ? AND contype = 'f'!
    );

    my %type_translation_for = (
        timestamptz => 'datetime'
    );

    foreach my $new_table ( @new_tables ) {
        $all_tables->{ $new_table }++;

        # get postgres internal id for this table (they call it an oid)
        $oid_sth->execute( $new_table );
        my ( $oid ) = $oid_sth->fetchrow_array();
        $oid_sth->finish();

        # pull columns and their types
        $column_sth->execute( $oid );
        while ( my ( $col_name, $base_type ) = $column_sth->fetchrow_array()
        ) {
            $base_type = $type_translation_for{ $base_type }
                    if $type_translation_for{ $base_type };

            push @{ $columns{ $new_table } }, {
                name  => $col_name,
                types => [ $base_type ],
            };
        }
        $column_sth->finish();

        # primary keys
        $pk_sth->execute( $oid );
        my ( $pks ) = $pk_sth->fetchrow_array();
        $pk_sth->finish();

        $pks =~ s/\{|\}//g;

        my @pks = split ',', $pks;

        foreach my $pk ( @pks ) {
            push @{ $columns{ $new_table }[ $pk - 1 ]{ types } },
                 'primary_key';
        }

        # defaults
        $defaults_sth->execute( $oid );
        COL_WITH_DEFAULT:
        while ( my ( $col_num, $default_text ) =
                    $defaults_sth->fetchrow_array()
        ) {
            # is this a serially incremented primary key?
            if ( $default_text =~ /^nextval.*${new_table}_id_seq/ ) {
                push @{ $columns{ $new_table }[ $col_num - 1 ]{ types } },
                     'auto';

                next COL_WITH_DEFAULT;
            }

            $default_text =~ s/::.*//; # strip type
            $default_text =~ s/^'//;
            $default_text =~ s/'$//;

            $columns{ $new_table }[ $col_num - 1 ]{ default } = $default_text;
        }

        $defaults_sth->finish();

        # this must be last since it splices the columns array, thus
        # throwing off the postgres supplied column counts
        # foreign keys
        my @doomed_cols;
        $foreign_sth->execute( $oid );
        while ( my ( $this_col, $foreign_table, $foreign_col ) =
                    $foreign_sth->fetchrow_array()
        ) {
            $this_col    =~ s/\{|\}//g;
            $foreign_col =~ s/\{|\}//g;

            push @doomed_cols, $this_col - 1;

            push @{ $foreigners{ $new_table } },
                 { table => $foreign_table, col => $foreign_col }
        }
        $foreign_sth->finish();

        foreach my $doomed_col ( sort { $b <=> $a } @doomed_cols ) {
            splice @{ $columns{ $new_table } }, $doomed_col, 1;
        }
    }

    return {
        all_tables    => $all_tables,
        new_tables    => \@new_tables,
        foreigners    => \%foreigners,
        columns       => \%columns,
    };
}

1;

=head1 NAME

Bigtop::ScriptHelp::Style::PgLive - gets its descriptions from Postgresql

=head1 SYNOPSIS

For normal use:

    bigtop -n AppName -s Pg8Live \
        'dbi:Pg:dbname=yourdb' user pass [schema]

Do the same for tentmaker.  It also works for -a:

    bigtop -a docs/app.bigtop \
        -s Pg8Live 'dbi:Pg:dbname=yourdb' user pass [schema]

Only tables not in docs/app.bigtop will be affected.

For use in scripts:

    use Bigtop::ScriptHelp::Style;

    my $style = Bigtop::ScriptHelp::Style->get_style( 'PgLive' );

    # then pass $style to methods of Bigtop::ScriptHelp

=head1 DESCRIPTION

See C<Bigtop::ScriptHelp::Style> for a description of what this module
must do in general.

This module pulls the database layout from the supplied database.  It
makes queries on internal postgres tables to retrieve its data.
The queries are probably specific to postgres 8.x.  They may work for
earlier versions, but I wouldn't want to put any money down on that.

This module pulls these things from the database whose dsn you supply:

=over 4

=item *

table names

=item *

column names

=item *

SQL type of each column

=item *

primary keys

=item *

column default values

=item *

foreign keys

=back

=head1 METHODS

=over 4

=item get_db_layout

This method does not use standard in.  Instead, it expects these command
line arguments (in order):

=over 4

=item dsn

Suitable for handing to DBI->connect.  Example:

    dbi:Pg:dbname=yourdb

=item database user

=item password for user

=item (optional) schema

Defaults to 'public.'  Use this if you need to bring in tables from one
schema.  There is no support for handling multiple schemas with a single
invocation, but there is no rule against rerunning with the -a flag to
bring in others.

=back

=back

=head1 AUTHOR

Phil Crow, E<lt>crow.phil@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

