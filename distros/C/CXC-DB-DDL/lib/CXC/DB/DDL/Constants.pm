package CXC::DB::DDL::Constants;

# ABSTRACT: Constants

use v5.26;
use strict;
use warnings;
use experimental 'signatures', 'postderef';

our $VERSION = '0.17';

use DBI ();
use CXC::Exporter::Util ':all';
use SQL::Translator::Schema::Constants ();

use namespace::clean;

use base 'Exporter::Tiny';

BEGIN {
    install_CONSTANTS {

        SCHEMA_CONSTANTS => {
            NOT_NULL    => SQL::Translator::Schema::Constants::NOT_NULL(),
            PRIMARY_KEY => SQL::Translator::Schema::Constants::PRIMARY_KEY(),
            FOREIGN_KEY => SQL::Translator::Schema::Constants::FOREIGN_KEY(),
            UNIQUE      => SQL::Translator::Schema::Constants::UNIQUE(),
            NORMAL      => SQL::Translator::Schema::Constants::NORMAL(),
            CHECK_C     => SQL::Translator::Schema::Constants::CHECK_C(),
        },

        SCHEMA_CONSTRAINT_MATCH_TYPES => {
            FULL    => 'full',
            PARTIAL => 'partial',
            SIMPLE  => 'simple',
        },

        SCHEMA_CONSTRAINT_ON_DELETE => {
            NO_ACTION   => 'NO ACTION',
            RESTRICT    => 'RESTRICT',
            SET_NULL    => 'SET NULL',
            SET_DEFAULT => 'SET DEFAULT',
            CASCADE     => 'CASCADE',
        },

        SCHEMA_CONSTRAINT_ON_UPDATE => {
            NO_ACTION   => 'NO ACTION',
            RESTRICT    => 'RESTRICT',
            SET_NULL    => 'SET NULL',
            SET_DEFAULT => 'SET DEFAULT',
            CASCADE     => 'CASCADE',
        },

        # this acess is documented in DBI, so it's legal
        SQL_TYPE_CONSTANTS => {
            map {
                no strict 'refs';    ## no critic (TestingAndDebugging::ProhibitNoStrict)
                $_ => &{"DBI::$_"};
            } $DBI::EXPORT_TAGS{sql_types}->@*,
        },

        CREATE_CONSTANTS => {
            CREATE_IF_NOT_EXISTS => 0,    # create table only if it doesn't exist
            CREATE_ALWAYS        => 1,    # drop then create table
            CREATE_ONCE          => 2,    # error if table already exists
        },

        # these should be the DBD driver name.
        SUPPORTED_DBDS => {
            DBD_SYBASE     => 'Sybase',
            DBD_POSTGRESQL => 'Pg',
            DBD_SQLITE     => 'SQLite',
        },
    };
}

install_EXPORTS;

1;

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

CXC::DB::DDL::Constants - Constants

=head1 VERSION

version 0.17

=head1 SYNOPSIS

  use CXC::DB::DDL::Constants @tags, @symbols;

=head1 DESCRIPTION

This module provides a number of constants useful to build DDL.  It imports a few from
L<SQL::Translator::Schema::Constants>, as well as all of the SQL types provided by L<< DBI's B<sql_types> tag|DBI >>

=head1 EXPORTS

=head2 Symbols

=head2 Tags

These tags are available via either B<:tag> or B<-tag>.  Their associated symbols are available for export directly, e.g.

  use CXC::DB::DDL::Constants 'NOT_NULL';

=head3 schema_constants

This tag provides these constants imported from L<SQL::Translator::Schema::Constants>:

=head4 NOT_NULL

=head4 PRIMARY_KEY

=head4 FOREIGN_KEY

=head4 UNIQUE

=head4 NORMAL

=head4 CHECK_C

Z<>

=head3 schema_constraint_match_types

Z<>

=head4 FULL    => 'full'

=head4 PARTIAL => 'partial'

=head4 SIMPLE  => 'simple'

Z<>

=head3 schema_constraint_on_delete

Z<>

=head4 NO_ACTION   => 'NO ACTION

=head4 RESTRICT    => 'RESTRICT'

=head4 SET_NULL    => 'SET NULL'

=head4 SET_DEFAULT => 'SET DEFAULT'

=head4 CASCADE     => 'CASCADE'

Z<>

=head3 schema_constraint_on_update

Z<>

=head4 NO_ACTION   => 'NO ACTION'

=head4 RESTRICT    => 'RESTRICT'

=head4 SET_NULL    => 'SET NULL'

=head4 SET_DEFAULT => 'SET DEFAULT'

=head4 CASCADE     => 'CASCADE'

Z<>

=head3 create_constants

Z<>

=head4 CREATE_IF_NOT_EXISTS

=head4 CREATE_ALWAYS

=head4 CREATE_ONCE

Z<>

=head3 supported_dbds

The database drivers known to work with L<CXC::DB::DDL> and which may specialized code for their specific quirks.

=head4 DBD_SYBASE

=head4 DBD_SQLITE

=head4 DBD_POSTGRESQL

Z<>

=head3 sql_type_constants

This provides all of the SQL types provided by L<< DBI's B<sql_types>
tag|DBI >>.  There are far too many to list here;  run this code to enumerate them:

  perl -MCXC::DB::DDL::Constants \
     -E 'say join qq{\n}, sort $CXC::DB::DDL::Constants::EXPORT_TAGS{sql_type_constants}->@*'

=head2 Enumerating Functions

These functions return the values of the constants with the associated lower cased tag. For example,

  SCHEMA_CONSTRAINT_MATCH_TYPES() -> 'full', 'partial', 'simple'

=head4 SCHEMA_CONSTANTS

=head4 SCHEMA_CONSTRAINT_MATCH_TYPES

=head4 SCHEMA_CONSTRAINT_ON_DELETE

=head4 SCHEMA_CONSTRAINT_ON_UPDATE

=head4 CREATE_CONSTANTS

=head4 SUPPORTED_DBDS

=head4 SQL_TYPE_CONSTANTS

All of the SQL types provided by L<< DBI's B<sql_types> tag|DBI >>

These functions return the names of the constants with the associated lower cased tag. For example,

  SCHEMA_CONSTRAINT_MATCH_TYPES_NAMES() -> 'FULL', 'PARTIAL', 'SIMPLE'

=head4 SCHEMA_CONSTANTS_NAMES

=head4 SCHEMA_CONSTRAINT_MATCH_TYPES_NAMES

=head4 SCHEMA_CONSTRAINT_ON_DELETE_NAMES

=head4 SCHEMA_CONSTRAINT_ON_UPDATE_NAMES

=head4 CREATE_CONSTANTS_NAMES

=head4 SUPPORTED_DBDS_NAMES

=head4 SQL_TYPE_CONSTANTS_NAMES

Z<>

=for Pod::Coverage SQL_ALL_TYPES
SQL_ARRAY
SQL_ARRAY_LOCATOR
SQL_BIGINT
SQL_BINARY
SQL_BIT
SQL_BLOB
SQL_BLOB_LOCATOR
SQL_BOOLEAN
SQL_CHAR
SQL_CLOB
SQL_CLOB_LOCATOR
SQL_DATE
SQL_DATETIME
SQL_DECIMAL
SQL_DOUBLE
SQL_FLOAT
SQL_GUID
SQL_INTEGER
SQL_INTERVAL
SQL_INTERVAL_DAY
SQL_INTERVAL_DAY_TO_HOUR
SQL_INTERVAL_DAY_TO_MINUTE
SQL_INTERVAL_DAY_TO_SECOND
SQL_INTERVAL_HOUR
SQL_INTERVAL_HOUR_TO_MINUTE
SQL_INTERVAL_HOUR_TO_SECOND
SQL_INTERVAL_MINUTE
SQL_INTERVAL_MINUTE_TO_SECOND
SQL_INTERVAL_MONTH
SQL_INTERVAL_SECOND
SQL_INTERVAL_YEAR
SQL_INTERVAL_YEAR_TO_MONTH
SQL_LONGVARBINARY
SQL_LONGVARCHAR
SQL_MULTISET
SQL_MULTISET_LOCATOR
SQL_NUMERIC
SQL_REAL
SQL_REF
SQL_ROW
SQL_SMALLINT
SQL_TIME
SQL_TIMESTAMP
SQL_TINYINT
SQL_TYPE_DATE
SQL_TYPE_TIME
SQL_TYPE_TIMESTAMP
SQL_TYPE_TIMESTAMP_WITH_TIMEZONE
SQL_TYPE_TIME_WITH_TIMEZONE
SQL_UDT
SQL_UDT_LOCATOR
SQL_UNKNOWN_TYPE
SQL_VARBINARY
SQL_VARCHAR
SQL_WCHAR
SQL_WLONGVARCHAR
SQL_WVARCHAR

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-cxc-db-ddl@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=CXC-DB-DDL>

=head2 Source

Source is available at

  https://gitlab.com/djerius/cxc-db-ddl

and may be cloned from

  https://gitlab.com/djerius/cxc-db-ddl.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<CXC::DB::DDL|CXC::DB::DDL>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
