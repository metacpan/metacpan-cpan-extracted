#   @(#)$Id: Metadata.pm,v 2014.1 2014/04/21 06:38:37 jleffler Exp $
#
#   @(#)DBD::Informix Metadata Methods
#
#   Copyright 2002-03 IBM
#   Copyright 2013-14 Jonathan Leffler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#-------------------------------------------------------------------------
# Code and explanations follow for DBD::Informix
# (Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31))
#-------------------------------------------------------------------------

{
    package DBD::Informix::Metadata;
    use strict;
    use warnings;
    use DBI;
    use vars qw( @ISA @EXPORT );

    require Exporter;
    require DynaLoader;
    @ISA = qw(Exporter DynaLoader);
    @EXPORT = qw(
            ix_tables
            ix_columns
            ix_table_info
            ix_delimit_identifier
            ix_cond_delimit_identifier
            ix_undelimit_identifier
            ix_map_tablename
        );

    my
    $VERSION         = "2018.1031";
    my $ATTRIBUTION = 'Jonathan Leffler <jleffler@google.com>';
    my $Revision    = '$Id: Metadata.pm,v 2014.1 2014/04/21 06:38:37 jleffler Exp $';

    $VERSION = "1.01.009" if ($VERSION =~ m%[:]VERSION[:]%);

    sub ix_delimit_identifier
    {
        my($id) = @_;
        $id =~ s/"/""/go;
        return qq{"$id"};
    }

    sub ix_undelimit_identifier
    {
        my($id) = @_;
        if ($id =~ m/^"([^"]|"")*"$/o)
        {
            $id =~ s/^"//o;
            $id =~ s/"$//o;
            $id =~ s/""//go;
        }
        return $id;
    }

    sub ix_cond_delimit_identifier
    {
        my($id) = @_;
        $id = ix_delimit_identifier($id) if ($id !~ m/^[A-Za-z_]\w*$/);
        return $id;
    }

    sub ix_map_tablename
    {
        my($owner, $table, $column) = @_;
        $table = ix_cond_delimit_identifier($table);
        if ($owner)
        {
            $owner = ix_delimit_identifier($owner);
            $table = qq{$owner.$table};
        }
        if ($column)
        {
            # Column name too;
            $column = ix_cond_delimit_identifier($column);
            $table = qq{$table.$column};
        }
        return $table;
    }

    # ----------------------------------------------------------------
    # Utility functions: _tables and _columns
    # ----------------------------------------------------------------
    # SQL fragments to list tables, views, and synonyms

    my %tables;
    $tables{'tables'}  =
        q{ SELECT T.Owner, T.TabName FROM 'informix'.SysTables T
            WHERE T.TabName NOT LIKE " %" };
    $tables{'user'}    = q{ AND T.Tabid >= 100 };
    $tables{'system'}  = q{ AND T.Tabid <  100 };
    $tables{'base'}    = q{ AND T.TabType = 'T' };
    $tables{'view'}    = q{ AND T.TabType = 'V' };
    $tables{'synonym'} =
        q{ AND (T.TabType = 'S' OR (T.TabType = 'P' AND T.Owner = USER)) };
    $tables{'order'}   = q{ ORDER BY T.Owner, T.TabName };

    sub ix_tables
    {
        my ($dbh, @info) = @_;
        my @result = ();
        my $i;
        # Build query string
        my $stmt = $tables{'tables'};
        for ($i = 0; $i <= $#info; $i++)
        {
            $i =~ tr/A-Z/a-z/;
            $stmt .= $tables{$info[$i]} unless $info[$i] eq 'tables';
        }
        $stmt .= $tables{'order'};
        # Tidy up the statement only if you are going to print it!
        # $stmt =~ s/^ //;
        # $stmt =~ s/ $//;
        # $stmt =~ s/  +/ /g;
        # print "$stmt\n";
        my $sth = $dbh->prepare($stmt);
        if (defined $sth)
        {
            return @result unless $sth->execute;
            my ($owner, $table);
            $sth->bind_columns(\$owner, \$table);
            $i = 0;
            while ($sth->fetchrow_arrayref)
            {
                $result[$i++] = ix_map_tablename($owner, $table);
            }
            $sth->finish;
        }
        @result;
    }

    # ----------------------------------------------------------------
    #
    # Generating complete lists of columns for local tables, views,
    # and synonyms is hard!  For example, you need to do this:
    #
    #-- Base Table Information
    # SELECT T.Owner, T.TabName, C.ColNo, C.ColName, C.ColType,
    #    C.ColLength
    #     FROM 'informix'.SysTables T, 'informix'.SysColumns C
    #     WHERE T.Tabid = C.Tabid
    #       AND T.TabType IN ('T', 'V')
    #       AND (T.TabName IN ('privsyn', 'pubsyn', 'tabcol') OR
    #            ((T.TabName = 'syscolumns' AND
    #            T.Owner = 'informix')))
    # UNION
    # -- Local Synonyms (PUBLIC and PRIVATE)
    # SELECT T.Owner, T.TabName, C.ColNo, C.ColName, C.ColType,
    #    C.ColLength
    #     FROM 'informix'.SysTables T, 'informix'.SysColumns C,
    #          'informix'.SysSynTable S
    #     WHERE T.Tabid = S.Tabid
    #       AND S.BTabid = C.Tabid
    #       AND ((T.TabType = 'P' AND T.Owner = USER)
    #   OR T.TabType =  'S')
    #       AND (T.TabName IN ('privsyn', 'pubsyn', 'tabcol') OR
    #            ((T.TabName = 'syscolumns'
    #   AND T.Owner = 'informix')))
    # -- Remote Synonyms are not handled!
    # ORDER BY 1, 2, 3;
    #
    # Mercifully, you cannot build local synonyms on top of other local
    # synonyms.  You need not even consider whether to add support for
    # remote synonyms because they can be chained through an arbitrary
    # number of remote sites.
    #
    # -----------------------------------------------------------------
    # SQL fragments to list columns
    # Note the re-use of $tables{'synonym'} from above!

    my %columns;
    $columns{'columns'}  =
        q{
    SELECT T.Owner, T.TabName, C.ColNo, C.ColName, C.ColType, C.ColLength
        FROM 'informix'.SysTables T, 'informix'.SysColumns C
        };
    $columns{'direct'}  =
        q{ WHERE T.Tabid = C.Tabid AND T.TabType IN ('T', 'V') };
    $columns{'synonym'} = qq{ , 'informix'.SysSynTable S
    WHERE T.Tabid = S.Tabid AND S.BTabid = C.Tabid
    $tables{'synonym'}
        };
    $columns{'order'}   = q{ ORDER BY 1, 2, 3 };

    sub ix_columns
    {
        my ($dbh, @tables) = @_;
        my @result = ();
        my $i;
        # Build query string
        my $s_list = "";
        my $s_pad = "";
        my $d_list = "";
        my $d_pad = "";
        for ($i = 0; $i <= $#tables; $i++)
        {
            my $tab = $tables[$i];
            if ($tab =~ /["'](.+)["']\.(.*)/)
            {
                $d_list .= "$d_pad (T.TabName = '$2' AND T.Owner = '$1') ";
                $d_pad = "OR";
            }
            else
            {
                $s_list .= "$s_pad '$tab'";
                $s_pad = ", ";
            }
        }
        $s_list = "T.TabName IN ($s_list)" if $s_list;
        my $cond = "";
        if ($d_list && $s_list)
        {
            $cond = " AND (($s_list) OR ($d_list))"
        }
        elsif ($s_list)
        {
            $cond = " AND ($s_list)" if $s_list;
        }
        elsif ($d_list)
        {
            $cond = " AND ($d_list)" if $d_list;
        }
        my $stmt  = "$columns{'columns'} $columns{'direct'} $cond";
        $stmt .= "UNION $columns{'columns'} $columns{'synonym'} $cond";
        $stmt .= " $columns{'order'}";
        # Tidy up the statement only if you are going to
        # print it!
        #$stmt =~ s/^ //;
        #$stmt =~ s/ $//;
        #$stmt =~ s/  +/ /g;
        #print "$stmt\n";
        my $sth = $dbh->prepare($stmt);
        if (defined $sth)
        {
            return @result unless $sth->execute;
            my ($ref) = $sth->fetchall_arrayref;
            @result = @{$ref};
            $sth->finish;
        }
        @result;
    }

    #-----------------------------------------------------------------
    # table_info function - originally by David Bitseff <dbitsef@uswest.com>
    # Note: DBI spec says it needs:
    #   TABLE_QUALIFIER, TABLE_OWNER, TABLE_NAME,
    #   TABLE_TYPE, and TABLE_REMARKS in that order,
    # possibly with extra data.
    # There is no explanation of what a TABLE_QUALIFIER is, so null (undef)
    # should be returned.  The table type is supposed to be one of:
    # "TABLE", "VIEW", "SYSTEM TABLE", "GLOBAL TEMPORARY", "LOCAL
    # TEMPORARY", "ALIAS", "SYNONYM", or a data-source-specific type.
    # Informix cannot identify temporary tables;  there are no
    # ALIAS tables; there are private and public synonyms, so we will
    # return the data-source specific 'PRIVATE SYNONYM' for them.
    # Note that the temp table cannot be dropped until the statement handle
    # is destroyed. Because we do not know when the handle is destroyed, we
    # either have to drop it and recreate it each time, or check whether
    # it has already been created and create it only if not yet created.

    sub ix_table_info
    {
        my($dbh) = @_;
        my($tab) = "dbd_ix_tabinfo_typ";
        my($msg);
        my($handler) = $SIG{__WARN__};
        $SIG{__WARN__} = sub { $msg = $_[0]; };
        my ($ok) = $dbh->do("CREATE TEMP TABLE $tab (tabtype CHAR(1) NOT NULL UNIQUE, typename CHAR(20) NOT NULL);");
        $SIG{__WARN__} = $handler;
        if ($ok)
        {
            $dbh->do("INSERT INTO $tab VALUES('T', 'TABLE');
                      INSERT INTO $tab VALUES('C', 'SYSTEM TABLE');
                      INSERT INTO $tab VALUES('V', 'VIEW');
                      INSERT INTO $tab VALUES('A', 'ALIAS');
                      INSERT INTO $tab VALUES('S', 'SYNONYM');
                      INSERT INTO $tab VALUES('P', 'PRIVATE SYNONYM');
                      INSERT INTO $tab VALUES('G', 'GLOBAL TEMPORARY');
                      INSERT INTO $tab VALUES('L', 'LOCAL TEMPORARY');
                     ") or return undef;
        }
        my $sth = $dbh->prepare(qq{
            SELECT
                '' AS TABLE_QUALIFIER,
                T.Owner AS TABLE_OWNER,
                T.TabName AS TABLE_NAME,
                I.TypeName AS TABLE_TYPE,
                'TabID: ' || T.TabID || ' Created: ' || EXTEND(T.Created, YEAR TO DAY) AS TABLE_REMARKS
            FROM "informix".systables T, $tab I
            WHERE (T.TabID >= 100 AND I.TabType = T.TabType)
               OR (T.TabID < 100 AND T.TabType = 'T' AND I.TabType = 'C')
            ORDER BY TABLE_OWNER, TABLE_NAME
            }) or return undef;
        $sth->execute or return undef;
        $sth;
    }

    # -----------------------------------------------------------------

    1;
}

1;

# Note: You should use "fill -sl70" to format the paragraphs in the
# following documentation.  That means lines are wrapped at 70
# columns, and each sentence starts on a new line.  The 'perldoc'
# program reformats the text to wrap sentences.

__END__

=head1 NAME

DBD::Informix::Metadata - Metadata Methods for DBD::Informix

=head1 SYNOPSIS

  use DBI; # This is the usual method.

  # If you need direct access to the functions.
  use DBD::Informix::Metadata;

=head1 DESCRIPTION

This document describes the metadata methods for DBD::Informix
(Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31)).

Note that you would seldom actually use this package directly (despite
the synopsis above); the methods you would use are defined in the
DBD::Informix::db package (in the Informix.pm file).

=head2 The ix_tables function

You can call two methods using the DBI func() to get
at some basic Informix metadata relatively conveniently.

    @list = $dbh->func('_tables');
    @list = $dbh->func('user', '_tables');
    @list = $dbh->func('base', '_tables');
    @list = $dbh->func('user', 'base', '_tables');
    @list = $dbh->func('system', '_tables');
    @list = $dbh->func('view', '_tables');
    @list = $dbh->func('synonym', '_tables');

Alternatively, the direct calling mechanism is:

    @list = DBD::Informix::Metadata::ix_tables($dbh, @attrs);

The lists of tables are all qualified as "owner".tablename (with
metacharacter mapping done by ix_map_tablename described below), and you
can use them in SQL statements without fear that the table is not
present in the database (unless someone deletes it behind your back).
The leading arguments qualify the list of names returned.
Private synonyms are reported for just the current user.

Note that the names are returned in the format suitable for use in SQL statements;
this is distinct from the format the values are stored in the database.

=head2 The ix_columns function

The normal mechanism for calling this function is:

    @list = $dbh->func('_columns');
    @list = $dbh->func(@tables, '_columns');

Alternatively, the direct calling mechanism is:

    @list = DBD::Informix::Metadata::ix_columns($dbh, @tables);

The lists are each references to an array of values corresponding to the
owner name, table name, column number, column name, basic data type
(ix_ColType value--see below), and data length (ix_ColLength--see
below).
If no tables are listed, all columns in the database are listed.
This can be quite slow because handling synonyms properly requires a
UNION operation.

Further, although the '_tables' method reports the names of remote
synonyms, the '_columns' method does not expand them (mainly because it
is very hard to do properly).
See the examples in t/t55mdata.t for how to use these methods.
Exercise for the reader: Extend '_columns' to get reports on the columns
in remote synonyms, including relocated remote synonyms where the
original referenced site now forwards the name to a third site!

Note that the return values from this are in the same format as found in
the system catalogues and are not necessary suitable for directly
embedding in an SQL statement.

=head2 The ix_map_tablename method

This method is used internally to map the owner, table (and optionally
column) names from the format found in the system catalog to a format
that can be used in an SQL statement.
The difference is important - and can be substantial.

    $sql = ix_map_tablename($owner, $table [, $column]);

The owner name will be enclosed in double quotes; if it contains double
quotes, those will be doubled up as required by SQL.
The table name will only be enclosed in double quotes if it is not a
valid C identifier (meaning, it starts with an alphabetic character or
underscore, and continues with alphanumeric characters or underscores).
If it is enclosed in double quotes, any embedded double quotes are
doubled up.
If provided, the column name is given the same treatment as the table
name.

=head2 The ix_table_info method

    $sth = ix_table_info($dbh);

The ix_table_info method returns a statement handle for the given
database handle that will return a description of all the tables in the
database.
The description of the data complies with a very old version the
requirements of the DBI table_info method.

Expect this function to change!

=head2 The ix_delimit_identifier method

    $id = ix_delimit_identifier($id);

The ix_delimit_identifier encloses the given argument in double quotes,
and doubles up any embedded double quotes, and returns the delimited
identifier.
This converts a value from the system catalog into a form that can be
used in an SQL statement provided $ENV{DELIMIDENT} is set.

=head2 The ix_cond_delimit_identifier method

    $id = ix_cond_delimit_identifier($id);

The ix_cond_delimit_identifier calls ix_delimit_identifier on the
argument if the argument is not a valid C identifier.
This converts a value from the system catalog into a form that can be
used in an SQL statement if $ENV{DELIMIDENT} is set, but avoids
converting values that do not have to be delimited to maximize the
chance of it working when $ENV{DELIMIDENT{ is not set.

=head2 The ix_undelimit_identifier method

    $id = ix_undelimit_identifier($id);

The ix_undelimit_identifier converts a delimited identifier into the
form that would be found in the system catalog, and returns other
identifiers unchanged.
A delimited identifier consists of a double quote, a sequence of either
not duoble quotes or pairs of double quotes and a trailing double quote.
Note that neither "owner"."table" nor "owner".table qualifies as a
delimited identifier.

The resulting value is suitable for use with a placeholder in a query on
the system catalog.
If the value is to be embedded in a string literal as part of a query,
then it needs to be escaped with single quotes using the DBI-standard
$h->quote method so that any embedded single quotes are doubled up
correctly.

=head1 AUTHOR

Jonathan Leffler (jleffler@google.com)

=head1 SEE ALSO

perl(1)

Using 'perldoc', read the pages on:

=over 2

=item *
DBI - main documentation on Perl DBI

=item *
DBI::FAQ - Separately installable module of Frequently Asked Questions

=item *
DBD::Informix - The Perl DBI Driver for Informix

=back

=cut
