#   @(#)$Id: Informix.pm,v 2018.1 2018/05/11 08:18:30 jleffler Exp $
#
#   @(#)Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28)
#
#   Copyright 1994-95 Tim Bunce
#   Copyright 1996-99 Jonathan Leffler
#   Copyright 2000    Informix Software Inc
#   Copyright 2001-03 IBM
#   Copyright 2004-18 Jonathan Leffler
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#-------------------------------------------------------------------------
# Code and explanations follow for IBM Informix Database Driver for Perl
# (also known as DBD::Informix).
#-------------------------------------------------------------------------

{
    package DBD::Informix;

    use strict;
    use warnings;
    use vars qw($VERSION $drh @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);

    use DBI;
    use DynaLoader;
    use Exporter;
    use POSIX qw(strftime);
    @ISA = qw(DynaLoader Exporter);

    # Make the ix_types values available on request
    # use DBD::Informix qw(:ix_types);
    # Note this is about the only time someone should use
    # an explicit 'use DBD::Informix' statement.
    @EXPORT    = ();        # we export nothing by default
    @EXPORT_OK = ();        # populated by export_ok_tags:
    %EXPORT_TAGS = (
       ix_types => [ qw(
                IX_SMALLINT IX_INTEGER IX_SERIAL IX_INT8 IX_SERIAL8
                IX_BIGINT IX_BIGSERIAL
                IX_DECIMAL IX_MONEY IX_FLOAT IX_SMALLFLOAT
                IX_CHAR IX_VARCHAR IX_NCHAR IX_NVARCHAR IX_LVARCHAR
                IX_BOOLEAN
                IX_DATE IX_DATETIME IX_INTERVAL
                IX_BYTE IX_TEXT IX_CLOB IX_BLOB
                IX_FIXUDT IX_VARUDT
                IX_SET IX_MULTISET IX_LIST IX_ROW IX_COLLECTION
                ) ] );
    Exporter::export_ok_tags('ix_types');

    $VERSION          = "2018.1029";

    my $ATTRIBUTION      = 'Jonathan Leffler <jonathan.leffler@hcl.com>';
    my $Revision         = '$Id: Informix.pm,v 2018.1 2018/05/11 08:18:30 jleffler Exp $';

    # This is for development only - the code must be recompiled each day!
    $VERSION = strftime("%Y.%m%d", localtime time) if ($VERSION =~ m%[:]VERSION[:]%);

    bootstrap DBD::Informix $VERSION;

    $drh = undef;   # holds driver handle once initialized

    sub driver
    {
        return $drh if (defined $drh);

        my($class, $attr) = @_;

        unless ($ENV{INFORMIXDIR})
        {
            require DBD::Informix::Defaults;
            foreach (&DBD::Informix::Defaults::default_INFORMIXDIR(), qw(/usr/informix /opt/informix))
            {
                # If Informix-Connect or Informix-ESQL/C is installed,
                # $INFORMIXDIR must have lib and msg sub-directories.
                if (-d "$_/lib" && -d "$_/msg")
                {
                    $ENV{INFORMIXDIR} = $_;
                    # warn "DBD::Informix - (warning) INFORMIXDIR defaulted to $ENV{INFORMIXDIR}\n";
                    last;
                }
            }
            warn "DBD::Informix - (warning) INFORMIXDIR not set!\n" unless $ENV{INFORMIXDIR};
        }
        unless ($ENV{INFORMIXSERVER})
        {
            require DBD::Informix::Defaults;
            $ENV{INFORMIXSERVER} = &DBD::Informix::Defaults::default_INFORMIXSERVER();
            # Warning suppressed - OnLine (ESQL/C) 5.x does not need $INFORMIXSERVER.
            # But we do not know what we're working with yet!
            # warn "DBD::Informix - (warning) INFORMIXSERVER defaulted to $ENV{INFORMIXSERVER}\n";
        }

        $class .= "::dr";

        # Create new driver handle.
        # The ix_ProductName, ix_ProductVersion, ix_MultipleConnections
        # ix_CurrentConnection and ix_ActiveConnections attributes are
        # handled by the driver's FETCH_attrib function.
        $drh = DBI::_new_drh($class, {
                'Name'                   => 'Informix',
                'Version'                => $VERSION,
                'Attribution'            => "$ATTRIBUTION",
                %{$attr}
            })
            or return undef;

        # Initialize driver data
        DBD::Informix::dr::driver_init($drh);

        $drh;
    }

    sub CLONE
    {
        undef $drh;
    }

    1;
}

{
    package DBD::Informix::dr; # ====== DRIVER ======
    use strict;

    sub connect
    {
        my ($drh, $dbname, $dbuser, $dbpass, $dbattr) = @_;

        $dbname = "" unless(defined $dbname);
        $dbuser = "" unless(defined $dbuser);
        $dbpass = "" unless(defined $dbpass);
        $dbattr = undef unless(defined $dbattr && ref $dbattr eq "HASH");

        if ($ENV{DBD_INFORMIX_DEBUG_CONNATTR} && defined $dbattr)
        {
            print STDERR "# DBD::Informix::dr::connect\n";
            print STDERR "# debugging connection attributes (\$DBD_INFORMIX_DEBUG_CONNATTR set)\n";
            foreach my $attr (keys %$dbattr)
            {
                print STDERR "# attribute: $attr => ${$dbattr}{$attr}\n";
            }
            print STDERR "# end of connection attributes\n";
        }

        # Create new database connection handle for driver
        my $dbh = DBI::_new_dbh($drh, {
                'Name'        => $dbname,
                'ix_Username' => $dbuser,
                'ix_Password' => $dbpass,
            })
            or return undef;

        # Initialize database connection
        DBD::Informix::db::_login($dbh, $dbname, $dbuser, $dbpass, $dbattr)
            or return undef;

        $dbh;
    }

    1;
}

{
    package DBD::Informix::db; # ====== DATABASE ======
    use strict;

    # Required by DBI and used by Apache::DBI
    sub ping
    {
        my ($dbh) = @_;
        my $ret = 0;
        eval {
            local $SIG{__DIE__}  = sub { return (0); };
            local $SIG{__WARN__} = sub { return (0); };
            $ret = $dbh->do('SELECT 1 FROM "informix".systables WHERE TabID = 1');
        };
        return ($@) ? 0 : $ret;
    }

    sub get_info
    {
        my ($dbh, $info_type) = @_;
        require DBD::Informix::GetInfo;
        my $v = $DBD::Informix::GetInfo::info{int($info_type)};
        $v = $v->($dbh) if ref $v eq 'CODE';
        return $v;
    }

    sub prepare
    {
        my($dbh, $statement, $attr) = @_;

        my $sth = DBI::_new_sth($dbh, {
            'Statement' => $statement,
            })
            or return undef;

        DBD::Informix::st::_prepare($sth, $statement, $attr)
            or return undef;

        $sth;
    }

    # This type_info_all function was automatically generated by
    # DBI::DBD::TypeInfo::write_typeinfo v1.00.
    sub type_info_all
    {
        my($dbh, $info_type) = @_;
        require DBD::Informix::TypeInfo;
        return $DBD::Informix::TypeInfo::type_info_all;
    }

    # ----------------------------------------------------------------
    # Use default implementation of do (which is DBD::_::db::do).
    # Although EXECUTE IMMEDIATE was introduced in Informix ESQL/C
    # Version 5.00, when it is used, DBD::Informix loses track
    # of key operations such as BEGIN WORK (as pointed out by
    # Jason Bodnar <jcbodnar@mail.utexas.edu>).
    # So, DBD::Informix needs to use the full prepare, execute, and
    # finish functions under all circumstances.  Because the default
    # routine does that, use the default routine.
    # ----------------------------------------------------------------

    # ---------------------------------------------------------------------
    # Override DBD::_::db::tables because it does not quote table owner
    # names.  Mostly, this does not matter unless you work with a MODE ANSI
    # database where owner.table and "owner".table are two different tables
    # (but informix.systables and "informix".systables are still the same
    # table by some internal chicanery).  Note: Using double quotes around
    # the name is correct even if DELIMIDENT is set.  Note that it is
    # necessary to escape double quotes within both the owner name and
    # table name strings.  Note that table names are only escaped if they
    # do not match a C identifier (alphabetic or underscore for first
    # character; alphanumeric or underscore thereafter).

    sub tables
    {
        my ($dbh, @args) = @_;
        my $sth = $dbh->table_info(@args);
        return () unless $sth;
        require DBD::Informix::Metadata;
        my ($owner, $table, @tables, $unwanted1, $unwanted2, $unwanted3);
        $sth->bind_columns(\$unwanted1, \$owner, \$table, \$unwanted2, \$unwanted3);
        while($sth->fetchrow_arrayref)
        {
            my $result = &DBD::Informix::Metadata::ix_map_tablename($owner, $table);
            push @tables, $result;
        }
        return @tables;
    }

    # ----------------------------------------------------------------

    # ----------------------------------------------------------------
    # Utility functions: _tables and _columns
    # ----------------------------------------------------------------
    # SQL fragments to list tables, views, and synonyms

    sub _tables
    {
        my ($dbh, @info) = @_;
        require DBD::Informix::Metadata;
        return &DBD::Informix::Metadata::ix_tables($dbh, @info);
    }

    sub _columns
    {
        my ($dbh, @tables) = @_;
        require DBD::Informix::Metadata;
        return &DBD::Informix::Metadata::ix_columns($dbh, @tables);
    }

    #-----------------------------------------------------------------
    # table_info function
    # - originally by David Bitseff <dbitsef@uswest.com>

    sub table_info
    {
        my($dbh) = @_;
        require DBD::Informix::Metadata;
        return &DBD::Informix::Metadata::ix_table_info($dbh);
    }

    1;
}

{
    package DBD::Informix::st; # ====== STATEMENT ======

    # No non-standard methods needed by DBD::Informix

    1;
}

1;

# Note: You should use "fill -sl70" to format the paragraphs in the
# following documentation.  That means lines are wrapped at 70
# columns, and each sentence starts on a new line.  The 'perldoc'
# program reformats the text to wrap sentences.

__END__

=head1 NAME

DBD::Informix - Informix Database Driver for Perl DBI

=head1 SYNOPSIS

  use DBI;

=head1 DESCRIPTION

This document describes Informix Database Driver for Perl DBI Version 2018.1029 (2018-10-28).

You should also read the documentation for DBI C<perldoc DBI> as this
document qualifies what is stated there.
Note that this document was last fully updated for the DBI Version
0.85 specification, but the code requires features from DBI Version
1.14.
Consequently, both this document and DBD::Informix are probably
considerably out of line with some of the new features and minor
details of the DBI specification.

The definitive statement of what should be in the driver is in the
Cheetah book, as amended by any later versions of DBI.
If you don't have a copy of it, go and get it and read it.

    Programming the Perl DBI
    Alligator Descartes and Tim Bunce
    O'Reilly (http://www.oreilly.com), February 2000, ISBN 1-56592-699-4

The primary URL for information about Perl and DBI is:

    http://dbi.perl.org/

This document still has a biassed view of how to use DBI and
DBD::Informix and covers parts of DBI and most of DBD::Informix.
In late 1996, the DBI documentation was in a very confused state.
The DBI documentation has improved with each release of DBI, and the
comments in the DBI document about DBI and its drivers are a better
indication of what should happen.
However, this document might still be a better reflection of the
actual behavior of DBD::Informix.

Be aware that on occasion, the description in this document gets
complex because of differences between different versions of Informix
software and different types of Informix databases.
The key factor is the version of ESQL/C used when building
DBD::Informix.
Basically, there are two groups of versions to worry about, the 5.x
family of versions (5.00.UC1 through 5.20.UCx at the moment), and the 6.x
and later family of versions (6.00 through 9.53, and then 2.90 through 3.70
at the moment; yes, some clown in marketing decreased the version number).
All version families acquire extra versions on occasion.

Note that DBD::Informix does not work with Informix ESQL/C Version
4.1x or earlier versions because it uses both SQL descriptors and
strings for cursor names and statement names, and these features were
not available before Version 5.00.

For information about Informix software, you should also read the
Notes/FAQ file that is distributed with Informix Database Driver for Perl DBI.

=head2 TECHNICAL SUPPORT

For information on technical support for Informix Database Driver for Perl DBI, please run:

        perldoc DBD::Informix::TechSupport

For information on reporting bugs in Informix Database Driver for Perl DBI, please review the
Notes/bug.reports file as well.

=head2 JAPANESE DOCUMENTATION

For a Japanese translation of a version of this documentation
(maintained by Kawai Takanori <kawai@nippon-rad.co.jp>), see the
following Web site:

    http://member.nifty.ne.jp/hippo2000/perltips/DBD/informix.htm

=head1 USE OF DBD::Informix

=head2 LOADING DBD::Informix

To use the DBD::Informix software, you need to load the DBI software.

    use DBI;

Under normal circumstances, you should then connect to your database
using the notation in the section "CONNECTING TO A DATABASE," which
calls DBI->connect().
Note that some of the DBD::Informix test code does not operate under
normal circumstances and therefore uses the nonpreferred techniques
in the section "Driver Attributes and Methods."

Note that you do not write:

    use DBD::Informix;      # !!BUGGY CODE!!

However, starting with version 1.03.PC1, you might write either or both
of the following:

    use DBI qw(:sql_types);
    use DBD::Informix qw(:ix_types);

This loads up some special type names (actually parameterless subs)
that you can use with $sth->bind_param() and $sth->bind_param_inout().
Using this allows you to update blobs (BYTE and TEXT), which was
previously not an option.

The Informix type names are:
    IX_SMALLINT, IX_INTEGER, IX_SERIAL, IX_INT8, IX_SERIAL8,
    IX_BIGINT, IX_BIGSERIAL,
    IX_DECIMAL, IX_MONEY, IX_FLOAT, IX_SMALLFLOAT,
    IX_CHAR, IX_VARCHAR, IX_NCHAR, IX_NVARCHAR, IX_LVARCHAR,
    IX_BOOLEAN,
    IX_DATE, IX_DATETIME, IX_INTERVAL,
    IX_BYTE, IX_TEXT, IX_CLOB, IX_BLOB,
    IX_FIXUDT, IX_VARUDT,
    IX_SET, IX_MULTISET, IX_LIST, IX_COLLECTION

The (un)documented SQL type names from 'use DBI qw(:sql_types)' are
listed below.
All the type names in the first group are treated as equivalent to
strings (Informix CHAR) by DBD::Informix, relying on the database
server to convert the string to the correct underlying type.

    SQL_NUMERIC, SQL_DECIMAL, SQL_INTEGER, SQL_BIGINT,
    SQL_TINYINT, SQL_SMALLINT, SQL_FLOAT, SQL_REAL, SQL_DOUBLE,
    SQL_VARCHAR, SQL_CHAR,
    SQL_DATE, SQL_TIME, SQL_TIMESTAMP

All the types in this second group are treated as equivalent to
BYTE blobs.

    SQL_BINARY, SQL_VARBINARY, SQL_LONGVARBINARY

And the only type in this third group is treated as equivalent to
a TEXT blob.

    SQL_LONGVARCHAR

=head2 DRIVER ATTRIBUTES AND METHODS

Most people should skip this section.
If you have a burning desire to explicitly install the
Informix driver independently of connecting to any database, use:

    $drh = DBI->install_driver('Informix');

This statement gives you a reference to the driver, also known as
the driver handle.
If the load fails, your program stops immediately (unless, perhaps,
you eval the statement).

Once you have the driver handle, you can interrogate the driver for
some basic information:

    print "Driver Information\n";
    # Type is always 'dr'.
    print "    Type:                  $drh->{Type}\n";
    # Name is always 'Informix'.
    print "    Name:                  $drh->{Name}\n";
    # Version is the version of DBD::Informix (such as 0.51).
    print "    Version:               $drh->{Version}\n";
    # The Attribution identifies the culprits who provided you
    # with this software.
    print "    Attribution:           $drh->{Attribution}\n";
    # ProductName is the version of ESQL/C; it corresponds to
    # the first line of the output from "esql -V".
    print "    Product:               $drh->{ix_ProductName}\n";
    # ProductVersion is an integer version number such as 721
    # for ESQL/C Version 7.21.UC1.
    print "    Product Version:       $drh->{ix_ProductVersion}\n";
    # MultipleConnections indicates whether the driver
    # supports multiple connections (1) or not (0).
    print "    Multiple Connections:  $drh->{ix_MultipleConnections}\n";
    # ActiveConnections identifies the number of open connections.
    print "    Active Connections:      $drh->{ix_ActiveConnections}\n";
    # CurrentConnection identifies the current connection.
    print "    Current Connections:     $drh->{ix_CurrentConnection}\n";

Once you have loaded the driver, you can connect to a database, or you
can sever all connections to databases with disconnect_all.

    $drh->disconnect_all;

=head1 AVAILABLE DATA SOURCES

To find out which databases are available, you can use the function:

    @dbnames = DBI->data_sources('Informix');

Note that you might also be able to connect to other databases not
listed by DBI->data_sources using other notations to identify the
database.
For example, you can connect to "dbase@server" if "server" appears in
the sqlhosts file and the database "dbase" exists on the server and
the server is up and you have permission to use both the server and
the database on the server and so on.
Also, you might not be able to connect to every one of the databases
listed if you have not been given at least connect permission on the
database.
However, the databases listed by the DBI->data_sources method
certainly exist, and it is legitimate to try connecting to those
sources.

=over 4

Issue: DBI (up to and including version 1.33) does not provide a
mechanism to connect to the server with a username and password, so
DBI->data_sources('Informix') will fail if you need to specify the
username and password and you have not yet connected to some Informix
database server.

=back

You can test whether this worked with:

    if (defined @dbnames) { ...process array... }
    else                  { ...process error... }

See also the test file "t/t07dblist.t".

=head1 CONNECTING TO A DATABASE

To connect to a database, you use the connect function, which
yields a valid database handle if it is successful.
If the driver itself cannot be loaded (by the DBI->install_driver()
method mentioned above), DBI aborts the script (and DBD::Informix can
do nothing about it because it was not loaded successfully).

In Version 1.00 or later, the default value for INFORMIXDIR is recorded
when DBD::Informix is built and INFORMIXDIR is set at run time if no
value is inherited from the environment.
This is of most value to web-based applications.
Similarly, INFORMIXSERVER is recorded when DBD::Informix is built and
set at run time if no value is inherited from the environment.
By default, DBD::Informix Version 1.00 and later is built with absolute
path names for the Informix shared libraries and the setting of
LD_LIBRARY_PATH is not critical unless you overrode the default build
with the DBD_INFORMIX_RELOCATABLE_INFORMIXDIR environment variable.
If you did override the default build, you need to set LD_LIBRARY_PATH
or the local equivalent (such as SHLIB_PATH) before trying to load the
DBD::Informix driver.

    $dbh = DBI->connect("dbi:Informix:$database");
    $dbh = DBI->connect("dbi:Informix:$database", $user, $pass);
    $dbh = DBI->connect("dbi:Informix:$database", $user, $pass, %attr);

The DBI connect method strips the 'dbi:' prefix from the first
argument and loads the DBD module identified by the next string (Informix
in this case).
The string following the second colon is all that is passed to the
DBD::Informix code.
With this format, you do not have to specify the username or password.
Note that if you specify the username but not the password,
DBD::Informix will silently ignore the username.
You can also specify certain attributes in the connect call.
These attributes include:

    AutoCommit
    PrintError
    RaiseError
    ChopBlanks
    ix_WithoutReplication

The DBI specification states that AutoCommit is on (1) by default, but
PrintError, RaiseError, ChopBlanks default to off (0).

The ix_WithoutReplication flags also defaults to off (0).
It is used to control whether explicit transactions are started by BEGIN
WORK or BEGIN WORK WITHOUT REPLICATION.
If it is true, all transactions are started without replication, using
the statement "BEGIN WORK WITHOUT REPLICATION".
You cannot suppress replication by using the following statement.

    $dbh->do("BEGIN WORK WITHOUT REPLICATION");

The value of ix_WithoutReplication can always be changed.
When the value is changed, the last transaction is committed and a new
one is started (with the correct statement).

    $dbh->{ix_WithoutReplication} = 0; # commit then begin occurs internally

Note that if you set ix_WithoutReplication to true and the database does
not support the statement "BEGIN WORK WITHOUT REPLICATION", you get
undefined behavior (probably a syntax error).

# Future direction: add ix_NativeTransactions to override AutoCommit.

You could therefore specify that the database is not to operate in
AutoCommit mode, but errors should be reported automatically by
specifying:

    $dbh = DBI->connect("dbi:Informix:$database", '', '',
                        { AutoCommit => 0, PrintError => 1 });

Note that the AutoCommit behavior is not affected by the type of
Informix database to which you are connecting, except that you will be
unable to connect to an unlogged database with AutoCommit set to off.
See also the extensive notes in the TRANSACTION MANAGEMENT section later
in this document.

=head2 INFORMIX CONNECTION SEMANTICS

If you are using ESQL/C Versions 5.x, DBD::Informix ignores
the username and password data, and the statement is equivalent to
"EXEC SQL DATABASE :database;".
If you are using ESQL/C Versions 6.0x or later, DBD::Informix
uses the username and password only if both are supplied, but it
is then equivalent to:

    EXEC SQL CONNECT TO :database AS :connection
        USER :username USING :password
        WITH CONCURRENT TRANSACTIONS

DBD::Informix gives each connection a name automatically, and that name
can be retrieved via $dbh->{ix_ConnectionName}.

For DBD::Informix, the database name is any valid format for the DATABASE
or CONNECT statements.

Valid database names include the following examples:

    dbase               # 'Local' database
    //machine1/dbase    # Database on remote machine
    dbase@server1       # Database on (remote) server (as defined in sqlhosts)
    @server1            # Connection to (remote) server but no database
    /some/where/dbase   # Connect to local SE database

No database name is supplied implicitly by DBD::Informix.

Note that the test code in DBD::Informix::TestHarness does supply the
names of test databases implicitly, but this is strictly only the test
harness.
Environment variables such as DBD_INFORMIX_DATABASE are only relevant to
the testing, not to production use of DBD::Informix.

Read the DBI documentation to see what, if any, defaults will be
supplied (for example, check for the DBI_DRIVER and DBI_DSN environment
variables).
If DBD::Informix sees an empty string, it makes no connection to any
database with ESQL/C 5.0x, and it makes a default connection to the
database server (using '@server') with ESQL/C 6.00 and later.
An additional string, ".DEFAULT.", can be specified explicitly as the
database name and will be interpreted as a request for a default
connection.
Note that the ".DEFAULT." string is not a valid Informix database name,
so there can be no confusion.

If you have ESQL/C 6.00 or later and you need to do CREATE DATABASE,
DATABASE EXCLUSIVE, DROP DATABASE, START DATABASE, ROLLFORWARD DATABASE,
or do any other operation which lists DATABASE explicitly in the SQL
statement, then you must use either the explicit ".DEFAULT." connection
or the "@server1" notation to connect to the database server where the
database resides (or will reside).

=head2 DATABASE HANDLE ATTRIBUTES

Once you have a database handle, you can interrogate it for some basic
information about the database.
The ix_ServerVersion, ix_BlobSupport, and ix_StoredProcedures attributes
are read-only attributes.
They provide
support for the XPS servers, older versions of which do not necessarily
have blob and stored procedure support, unlike other versions of
IBM Informix OnLine (though ix_BlobSupport is set false for SE too).
Note that to determine these values, DBD::Informix interrogates the
system catalog, which represents a small performance hit.
The server version number is retrieved from the entry in
"informix".systables with the table name 'bVERSION' (where the b
represents a blank).
It is not always precisely the version that is reported by the oninit
program, for example, but the difference is usually small and not
critical.
DBD::Informix cannot use the Informix utilities to determine the
database version more accurately because there is no guarantee that the
database server is on the same machine as the DBD::Informix code.
It also does not use the DBINFO('version','full') statement because not
all available servers support it (and the behaviour is sometimes
reprehensible when the server does not).

     print "Database Information\n";
     # Type is always 'db'.
     print "    Type:                    $dbh->{Type}\n";
     # ix_ServerVersion is a number, just like ix_ProductVersion is a number.
     # Although Version 5.10.UC7 SE servers correctly report a
     # version number, some earlier versions might report 0.
     print "    Server Version:          $dbh->{ix_ServerVersion}\n";
     # Name is the name of the database specified at connect.
     print "    Original Database Name:  $dbh->{Name}\n";
     # ix_DatabaseName is the name of the current database.
     print "    Current Database Name:   $dbh->{ix_DatabaseName}\n";
     # AutoCommit is 1 (true) if DBD::Informix ensures that each
     # statement is committed, 0 (false) if statements are combined into
     # a transaction.  See also the section on TRANSACTION MANAGEMENT.
     print "    AutoCommit:              $dbh->{AutoCommit}\n";

     # ix_InformixOnLine is 1 (true) if the handle is connected to an
     # Informix-OnLine server.
     print "    Informix-OnLine:         $dbh->{ix_InformixOnLine}\n";
     # ix_LoggedDatabase is 1 (true) if the database has
     # transactions.
     print "    Logged Database:         $dbh->{ix_LoggedDatabase}\n";
     # ix_ModeAnsiDatabase is 1 (true) if the database is MODE ANSI.
     print "    Mode ANSI Database:      $dbh->{ix_ModeAnsiDatabase}\n";
     # PrintError is 1 (true) if errors are reported when detected.
     print "    Print Errors:            $dbh->{PrintError}\n";
     # ix_InTransaction is 1 (true) if the database is in a transaction.
     print "    Transaction Active:      $dbh->{ix_InTransaction}\n";
     # ix_BlobSupport is 1 (true) if the database supports blobs.
     print "    Blob Support:            $dbh->{ix_BlobSupport}\n";
     # ix_StoredProcedures is 1 (true) if the database has stored procedures.
     print "    Stored Procedures:       $dbh->{ix_StoredProcedures}\n";
     # ix_ConnectionName is the name of the ESQL/C connection.
     # Mainly applicable with Informix ESQL/C 6.00 and later.
     print "    Connection Name:         $dbh->{ix_ConnectionName}\n";

If $dbh->{PrintError} is true, then DBI will report each error
automatically on STDERR when it is detected.
The error is also available via the package variables $DBI::errstr and
$DBI::err.
Note that $DBI::errstr includes the SQL error number and the ISAM error
number if there is one.
The message might extend over several lines and is generally formatted
so that it can be displayed neatly within 80 columns.

If $dbh->{PrintError} is false, then DBI does not report any errors when
it detects them; the user must note that errors have occurred and decide
whether to report them.

If you connect using the DBI->connect() method, or if you have forgotten
the driver, you can discover it again using:

    $drh = $dbh->{Driver};

This statement allows you to access the driver methods and attributes
described previously.

The name of the current database for a given database handle is tracked
accurately even when the DATABASE, CLOSE DATABASE, CREATE DATABASE,
ROLLFORWARD DATABASE, and START DATABASE statements are used.
Note that you cannot prepare CONNECT statements, so they do not have to
be tracked.
Except when using ESQL/C 5.x, you cannot use the database statements
listed above if you connect directly to a database, so the statements do
not have to be tracked very often - you must have connected to the
server alone.

Note that DBD::Informix allows you to obtain any of the driver
attributes from a database handle too.

=head2 METADATA

You can call two methods using the DBI func() to get
at some basic Informix metadata relatively conveniently.

    @list = $dbh->func('_tables');
    @list = $dbh->func('user', '_tables');
    @list = $dbh->func('base', '_tables');
    @list = $dbh->func('user', 'base', '_tables');
    @list = $dbh->func('system', '_tables');
    @list = $dbh->func('view', '_tables');
    @list = $dbh->func('synonym', '_tables');

The lists of tables are all qualified as "owner".tablename, and you
can use them in SQL statements without fear that the table is not
present in the database (unless someone deletes it behind your back).
The leading arguments qualify the list of names returned.
Private synonyms are reported for just the current user.

    @list = $dbh->func('_columns');
    @list = $dbh->func(@tables, '_columns');

The lists are each references to an array of values corresponding to
the owner name, table name, column number, column name, basic
data type (C<ix_ColType> value--see below), and data length
(C<ix_ColLength> value--see below).
If no tables are listed, all columns in the database are listed.
This can be quite slow because handling synonyms properly requires a
UNION operation.
Further, although the '_tables' method reports the names of remote
synonyms, the '_columns' method does not expand them (mainly because
it is very hard to do properly).
See the examples in t/t55mdata.t for how to use these methods.
Exercise for the reader: Extend '_columns' to get reports on the
columns in remote synonyms, including relocated remote synonyms where
the original referenced site now forwards the name to a third site!

See also C<DBD::Informix::Metadata(3)>.

=head2 DISCONNECTING FROM A DATABASE

You can also disconnect from the database:

    $dbh->disconnect;

The previous example will roll back any uncommitted work.
Note that this example does not destroy the database handle.
You need to do an explicit 'undef $dbh' to destroy the handle.
Any statements you prepare with this handle are finished (see below)
and cannot be used again.
All space associated with the statements is released.

If you are using an Informix driver for which $drh->{ProductVersion}
>= 600, you can have multiple concurrent connections (subject to the
normal Informix constraint that a single process can have at most one
shared memory connection open at any time).
This means that multiple calls to $drh->connect will give you
independent connections to one or more databases.

If you are using an Informix driver for which $drh->{ProductVersion} <
600, you cannot have multiple concurrent connections.
If you make multiple calls to $drh->connect, you will achieve the same
effect as if you execute several database statements in a row.
Multiple calls to $drh->connect will generally switch databases
successfully but will invalidate any statements you previously
prepared.
Multiple calls to $drh->connect might fail in instances when the
current database is not local or when there is an active transaction.

=head2 SIMPLE STATEMENTS

Given a database connection, you can execute a variety of simple
statements with a variety of different calls:

    $dbh->commit;
    $dbh->rollback;

These two operations commit or roll back the current transaction.
If the database is unlogged, the two operations do nothing.
If AutoCommit is set to 1, the two operations do nothing useful.
If AutoCommit is set to 0, a new transaction is started
(implicitly for a database that is MODE ANSI, explicitly for a
database that is not MODE ANSI).

To execute most preparable parameterless statements you can use:

    $dbh->do($stmt);

The statement must be neither a SELECT statement other than
SELECT...INTO TEMP nor an EXECUTE PROCEDURE statement where the
procedure returns data.

You can execute an arbitrary statement with parameters using:

    $dbh->do($stmt, undef, @parameters);
    $dbh->do($stmt, undef, $param1, $param2);

The 'undef' represents an undefined reference to a hash of attributes
(\%attr) as documented in the DBI specification.
Again, the statement must not be a SELECT or EXECUTE PROCEDURE that
returns data.
The values in @parameters (or the separate values) are bound to the
question marks in the statement string.

    $sth = $dbh->prepare($stmt);
    $sth->execute(@parameters);

This function is implemented by the DBI package and therefore does not
use EXECUTE IMMEDIATE.

The only reliable way to embed an arbitrary string inside a statement
is to use the quote method:

    $dbh->quote($string);

This method is provided by the DBI package implementation and is
inherited by the DBD::Informix package.
The string is enclosed in single quotes, and any embedded single
quotes are doubled up, which conforms to the SQL-92 standard.
You might typically use this method in a context such as:

    $value = q{Doesn't work unless quotes ("'" and '"') are handled};

    $stmt = "INSERT INTO SomeTable(SomeColumn) " .
            "VALUES(" . $dbh->quote($value) . ")";

Doing this ensures that the data in $values will be interpreted
correctly, regardless of what quotes appear in $value (unless it
contains newline characters).
Note that the alternative assignment below does not work!

    # !!BUGGY CODE!!
    $stmt = "INSERT INTO SomeTable(SomeColumn) VALUES($dbh->quote($value))";

However, before using $dbh->quote, consider whether to use a
placeholder, '?', in instead.
You should probably use a placeholder if the string represents a value
in the WHERE clause of a SELECT, UPDATE or DELETE statement, or a
value in the VALUES list of an INSERT statement, or a value in the SET
clause of an UPDATE statement, or a parameter to a function or stored
procedure.
Note that you must use a placeholder if the string could be longer
than 255 characters, or if the underlying column is a blob (BYTE,
TEXT, BLOB or CLOB) type.
Otherwise, the string probably represents a table name or a column
name and you must use $dbh->quote.

=head2 CREATING STATEMENTS

You can also prepare a statement for multiple uses, and you can do
this for SELECT and EXECUTE PROCEDURE statements that return data
(cursory statements) as well as noncursory statements that return no data.
You create a statement handle (another reference) using:

    $sth = $dbh->prepare($stmt);

If the statement is a SELECT that returns data (not SELECT...INTO TEMP) or
an EXECUTE PROCEDURE for a procedure that returns values, a cursor is
declared for the prepared statement.

The prepare call accepts an optional attributes parameter that is a
reference to a hash.
Starting with version 1.03.PC1, the following attributes are recognized:

    {ix_InsertCursor => 1, ix_ScrollCursor => 1, ix_CursorWithHold => 1}

The ix_ScrollCursor is a placeholder that may become unnecessary with a
future revision of DBI.

The ix_CursorWithHold attribute is only of relevance if AutoCommit is
disabled.
When AutoCommit is enabled, all cursors have to be WITH HOLD (just one
more reason to hate AutoCommit).

    $sth = $dbh->prepare("SELECT id, name FROM tablename", {'ix_CursorWithHold' => 1});

After the cursor is opened ($sth->execute), it is not closed by
$dbh->commit().
Either fetch all the rows or use $sth->finish() to close it.

The ix_InsertCursor attribute can be applied to an INSERT statement (but
generates an error -481 for other types of statement).
Subsequent uses of $sth->execute() will use the ESQL/C PUT statement to
insert the data, and $sth->finish() will close the INSERT cursor.
There is at present no mechanism to invoke the FLUSH statement.

It would be reasonable to add {ix_BlobLocation => 'InFile'} to support
per-statement blob location.

You need to check for errors unless you are using {RaiseError => 1}.

    # Emphasizing the error handling.
    die "Failed to prepare '$stmt'\n"
        unless ($sth = $dbh->prepare($stmt));

    # Emphasizing the SQL action.
    $sth = $dbh->prepare($stmt) or die "Failed to prepare '$stmt'\n"

You can tell whether the statement is just executable or whether it is
a cursory (fetchable) statement by testing the
Informix-specific attribute ix_Fetchable.
The approved, canonical DBI method of doing this check is
"$sth->{NUM_OF_FIELDS} > 0".

Once the statement is prepared, you can execute it:

    $sth->execute;

For a noncursory statement, this simply executes the statement.
If the statement is executed successfully, the number of rows
affected will be returned.
If an error occurs, the returned value will be undef.
If the statement does not affect any rows, the string returned is
"0E0", which evaluates to true but also to zero.

For a cursory statement, $sth->execute opens the cursor.
If the cursor is opened successfully, it returns the value "0E0",
which evaluates to true but also to zero.
If an error occurs, the returned value will be undef.

You can also specify the input parameters for a statement that contains
question-marks as place-holders using:

    $sth->execute(@parameters);

The first parameter will be supplied as the value for the first
place-holder question mark in the statement, the second parameter for
the second place-holder, and so on.

You can also bind specific values for parameters with $sth->bind_param
method.

=over 4

Issue: At the moment, there is no checking by DBD::Informix on how many
input parameters are supplied and how many are needed.
Note that the Informix servers give no support for determining the
number of input parameters except in the VALUES clause of an INSERT
statement.
This needs to be resolved.

=back

The Informix servers give no support for determining the types of
input parameters of any SQL statement except in the VALUES clause of
an INSERT statement.
(Some versions have partial support for describing the input
parameters to an UPDATE statement, but PTS Bug 111987 asserts that
this is not actually usable, not least because the server has to be
specially configured to make it available at all.)
This means that DBD::Informix cannot handle blobs automatically in the
SET clause of an UPDATE statement.

However, starting with version 1.03.PC1, you can provide the necessary
information to DBD::Informix manually.
The $sth->bind_param() method can be used with a type attribute:

    $upd = 'UPDATE SomeTable SET TextCol = ? WHERE Pkey = ?';
    $sth = $dbh->prepare($upd);
    $sth->bind_param(1, $blob_val, { ix_type => IX_TEXT });
    $sth->bind_param(2, $pkey);
    $sth->execute;
    $sth->bind_param(1, $new_blob_val, { TYPE => SQL_LONGVARCHAR });
    $sth->bind_param(2, $new_pkey, { TYPE => SQL_INTEGER });

The attribute tells DBD::Informix to treat the parameter specially.
The official, DBI sanctioned 'TYPE=>SQL_xyz' names are listed earlier
in this document.

Note that you cannot use $sth->execute($blob_val, $pkey) because there
is no way to convey the type information to the code.
Also note that Informix servers do provide information about blob
values in both the select-list of a SELECT statement and the VALUES
clause of the INSERT statement.
The INSERT statement is a special case, and it provides support for
code that implements the non-SQL statement 'LOAD FROM "file" INSERT
INTO SomeTable'.

For cursory statements, you can discover the returned column
names, types, nullability, and so on.
You do this with:

    @name = @{$sth->{NAME}};        # Column names
    @null = @{$sth->{NULLABLE}};    # True => accepts nulls
    @type = @{$sth->{TYPE}};        # ODBC Data Type numbers
    @prec = @{$sth->{PRECISION}};   # ODBC PRECISION numbers (or undef)
    @scal = @{$sth->{SCALE}};       # ODBC SCALE numbers (or undef)

    # Native (Informix) type equivalents
    @tnam = @{$sth->{ix_NativeTypeName}};   # Type name
    @tnum = @{$sth->{ix_ColType}};          # Type number from SysColumns.ColType
    @tlen = @{$sth->{ix_ColLength}};        # Type length from SysColumns.ColLength
    @tlen = @{$sth->{ix_ExtendedType}};     # Extended type number from SysColumns.Extended_ID
    @tlen = @{$sth->{ix_ExtendedTypeName}}; # Extended type name from SysColumns.Extended_ID

=over 4

Note: Informix uses '(expression)' in the array $sth->{NAME} for any
nonaliased computed value in a SELECT list, and to describe the return
values from stored procedures, and so on.
This could be usefully improved.
There is also no guarantee that the names returned are unique.
For example, in "SELECT A.Column, B.Column FROM Table1 A, Table1 B
WHERE ...", both the return columns are described as 'column'.

=back

If the statement is a cursory statement, you can retrieve the
values in any of a number of ways, as described in the DBI
specification.

    $ref = $sth->fetchrow_arrayref;
    $ref = $sth->fetch;                 # Alternative spelling...
    @row = @{$ref};

    @row = @{$sth->fetchrow_arrayref};  # Shorthand for above...

    @row = $sth->fetchrow_array;

    $ref = $sth->fetchall_arrayref;

As usual, you have to worry about whether this worked or not.
You would normally, therefore, use:

    while ($ref = $sth->fetch)
    {
        # We know we got some data here.
        ...
    }
    # Investigate whether an error occurred or the SELECT
    # simply had nothing more to return.
    if ($sth->{sqlcode} < 0)
    {
        # Process error...
    }

The returned data includes blobs mapped into strings.
Note that byte blobs might contain ASCII NUL '\0' characters.
Perl knows how long the strings are and does preserve NUL in the
middle of a byte blob.
However, you might need to be careful when you decide how to
handle this string.

The returned data includes blobs mapped into strings.
Note that byte blobs might contain ASCII NUL '\0' characters.
Perl knows how long the strings are and does preserve NUL in the
middle of a byte blob.
However, you might need to be careful when you decide how to
handle this string.

There is provision to specify how you want blobs handled.
You can set the attribute:

    $sth->{ix_BlobLocation} = 'InMemory';      # Default
    $sth->{ix_BlobLocation} = 'InFile';        # In a named file
    $sth->{ix_BlobLocation} = 'DummyValue';    # Return dummy values
    $sth->{ix_BlobLocation} = 'NullValue';     # Return undefined

InFile mode returns the name of a file in the fetched array, and
that file can be accessed by Perl using normal file access methods.
DummyValue mode returns "<<TEXT VALUE>>" for text blobs or "<<BYTE
VALUE>>" for byte (binary) blobs.
NullValue mode returns undefined (meaning that the Perl "defined"
operator would return false) values.
Note that these two options do not necessarily prevent the Server from
returning the data to the application, but the user does not get to
see the data--this depends on the internal implementation of the
ESQL/C FETCH operation in conjunction with SQL descriptors.

You can also set the ix_BlobLocation attribute on the database,
overriding it at the statement level.

=over 4

BUG: ix_BlobLocation is not handled properly.

=back

When you have fetched as many rows as required, you close the cursor using:

    $sth->finish;

You do not have to finish a cursor explicitly if you executed a fetch
that failed to retrieve any data.

Using $sth->finish simply closes the cursor but does not free the cursor
or the statement.
That is done when you destroy (undef) the statement handle:

    undef $sth;

You can also implicitly rebind a statement handle to a new statement
by simply using the same variable again.
This does not cause any memory leaks.

You can use the (DBI standard) Statement attribute to discover (or
rediscover) the text of a statement:

    $txt = $sth->{Statement};

=head2 CURSORS FOR UPDATE

You can use the (DBI standard) attribute $sth->{CursorName} to retrieve the name of a
cursor.
If the statement for $sth is actually a SELECT and the cursor is in a
MODE ANSI database or is declared with the 'FOR UPDATE [OF col,...'
tag, you can use the cursor name in a 'DELETE...WHERE CURRENT OF'
or 'UPDATE...WHERE CURRENT OF' statement.

    $st1 = $dbh->prepare("SELECT * FROM SomeTable FOR UPDATE");
    $wc = "WHERE CURRENT OF $st1->{CursorName}";
    $st2 = $dbh->prepare("UPDATE SomeTable SET SomeColumn = ? $wc");
    $st3 = $dbh->prepare("DELETE FROM SomeTable $wc");
    $st1->execute;
    $row = $st1->fetch;
    $st2->execute("New Value");
    $row = $st1->fetch;
    $st3->execute();

=head2 ACCESSING THE SQLCA RECORD

You can access the SQLCA record via either a database handle or a
statement handle.

    $sqlcode = $sth->{ix_sqlcode};
    $sqlerrm = $sth->{ix_sqlerrm};
    $sqlerrp = $sth->{ix_sqlerrp};
    @sqlerrd = @{$sth->{ix_sqlerrd}};
    @sqlwarn = @{$sth->{ix_sqlwarn}};

Note that the warning information is treated as an array (as in Informix
4GL) rather than as a bunch of separate fields (as in Informix ESQL/C).
However, the array is indexed from zero (as in ESQL/C, C, Perl, and so
on), rather than from one (as in Informix 4GL).
Also note that both $sth->{ix_sqlerrd} and $sth->{ix_sqlwarn} return a
reference to an array.
Inspect the code in the print_sqlca() function in
DBD::Informix::TestHarness for more ideas on the use of these
statements.
You cannot set the sqlca record.

The sqlerrd array has the following useful columns:

        $sth->{ix_sqlerrd}[1] - serial value after insert or ISAM error code
        $sth->{ix_sqlerrd}[3] - estimated cost
        $sth->{ix_sqlerrd}[4] - offset of the error into the SQL statement
        $sth->{ix_sqlerrd}[5] - rowid of the last row processed

=head2 OBTAINING THE VALUE INSERTED FOR A SERIAL COLUMN

The following example is a very useful and important technique with Informix.
However, it is also not portable to other databases because they do not have
the SERIAL data type.

        # insert a row into a table with a primary key that is a SERIAL
        $stmt = $dbh->do("insert into table (serial_id, number) values(0, 10)");
        print "the new row has a serial_id of $sth->{ix_sqlerrd}[1]\n";

For more information, you can read the "Informix ESQL/C Programmer's
Manual" or "Informix Guide to SQL: Reference Manual."
The exact chapter and verse depends on which version you use.

As an extension, you can also access $sth->{ix_serial} as a synonym for
$sth->{ix_sqlerrd}[1] and $sth->{ix_serial8} to obtain the last SERIAL8
value that was generated, and if you have CSDK 3.50 (and IDS 11.50) with
support for BIGINT and BIGSERIAL, $sth->{ix_bigserial} too.

=head1 TRANSACTION MANAGEMENT

Transaction management in DBI, and therefore in DBD::Informix, is both
complex and counter-intuitive to the experienced user of IBM Informix
database servers.
You should read this section carefully.

If you find a deviation between what is documented and what actually
occurs, be sure to report it.
The problem might be in the documentation, in the code, or in both.

The logging mode of your Informix database (whether it is MODE ANSI,
logged, unlogged) does not affect the external (visible to the user)
behaviour of transactions.
The AutoCommit attribute controls the semantics of transactions
exclusively.
Internally, the driver has to do considerable work to handle
transactions and AutoCommit correctly.

=head2 THE INTERACTIONS OF AUTOCOMMIT WITH INFORMIX DATABASES

Three types of Informix database need to be considered:
MODE ANSI, Logged, and UnLogged.
Although MODE ANSI databases also have a transaction log, the category
of Logged databases specifically excludes MODE ANSI databases.
In OnLine, this refers to databases created WITH LOG or WITH BUFFERED
LOG; in SE, to databases created WITH LOG IN "/some/file/name".

Two AutoCommit modes exist: On, Off.

Two transaction states are possible: In-TX (In transaction), No-TX
(Outside transaction).

At least 13 types of statements (in 4 groups and 9 subgroups) need to
be considered:

=over 2

    $drh->connect('xyz');                   # Group 1A
    $dbh->do('DATABASE xyz');               # Group 1B
    $dbh->do('CREATE DATABASE xyz');        # Group 1B
    $dbh->do('ROLLFORWARD DATABASE xyz');   # Group 1B
    $dbh->do('START DATABASE xyz');         # Group 1B
    $dbh->disconnect();                     # Group 2A
    $dbh->do('CLOSE DATABASE');             # Group 2B
    $dbh->commit();                         # Group 3A
    $dbh->rollback();                       # Group 3A
    $dbh->do('BEGIN WORK');                 # Group 3B
    $dbh->do('ROLLBACK WORK');              # Group 3C
    $dbh->do('COMMIT WORK');                # Group 3C
    $dbh->prepare('SELECT ...');            # Group 4A
    $dbh->prepare('UPDATE ...');            # Group 4B

=back

Group 1 statements establish connections to databases.
The type of database to which you are connected has no effect on the
AutoCommit mode.
Group 1A is the primary means of connecting to a database; Group
1B statements can change the current database.
Group 1B statements, however, cannot be executed except on the ".DEFAULT."
connection when you use ESQL/C 6.00 or later.

For all types of databases, the default AutoCommit mode is On.
With a MODE ANSI or a Logged database, the value of AutoCommit can be
set to Off, which automatically starts a transaction (explicitly if
the database is Logged, implicitly if the database is MODE ANSI).
For an UnLogged database, the AutoCommit mode cannot be changed.
Any attempt to change AutoCommit mode to Off with an UnLogged database
generates a nonfatal warning.

Group 2 statements sever the connection to a database.
The Group 2A statement renders the database handle unusable; no
further operations are possible except 'undef' or reassigning with a
new connection.
The Group 2B statement means that no operations other than those in
Group 1B or 'DROP DATABASE' are permitted on the handle.
As with the Group 1B statements, the Group 2B statement can only be
used on a ".DEFAULT." connection.
The value of AutoCommit is irrelevant after the database is closed
but is not altered by DBD::Informix.

Group 3 and 4 statements interact in many complicated ways, but the
new style of operation considerably simplifies the interactions.
One side effect of the changes is that BEGIN WORK is completely
marginalized and will generally cause an error.
Although UPDATE is cited in Group 4B, it represents any statement
that is not a SELECT statement.
Note that 'SELECT...INTO TEMP' is a Group 4B statement because it
returns no data to the program.
An 'EXECUTE PROCEDURE' statement is in Group 4A if it returns data
and in Group 4B if it does not, and you cannot tell which of the two
groups applies until after the statement is prepared.

=head2 MODE ANSI DATABASES

Previously, MODE ANSI databases were regarded as being in a
transaction at all times, but this is not the only way to view the way
these databases work.
However, it is more satisfactory to regard the state immediately after
a database is opened, or immediately after a COMMIT WORK or ROLLBACK
WORK operation as being in the No-TX state.
Any statement other than a disconnection statement (Group 2) or a
commit or rollback (Group 3A or 3C) takes the databases into the
In-TX state.

In a MODE ANSI database, you can execute BEGIN WORK successfully.
However, if AutoCommit is On, the transaction is immediately
committed, so it does you no good.

If the user elects to switch to AutoCommit On, things get trickier.
All cursors need to be declared WITH HOLD so that Group 4B statements
being committed do not close the active cursors.
Whenever a Group 4B statement is executed, the statement needs to be
committed.
With OnLine (and theoretically with SE), if the statement fails there
is no need to do a rollback -- the statement failing did the rollback
anyway.
As before, the code does ROLLBACK WORK before disconnecting, though it
should not actually be necessary.

=head2 LOGGED DATABASES

Previously, there were some big distinctions between Logged and MODE
ANSI databases.
One major advantage of the changes is that now there is essentially no
distinction between the two.

Note that executing BEGIN WORK does not buy you anything; you have to
switch AutoCommit mode explicitly to get any useful results.

=head2 UNLOGGED DATABASES

The transaction state is No-TX and AutoCommit is On, and this cannot
be changed.
Any attempt to set AutoCommit to Off generates a nonfatal warning but
the program will continue; setting AutoCommit to On generates neither a
warning nor an error.
Both $dbh->commit and $dbh->rollback succeed but do nothing.
Executing any Group 3B or 3C statement will generate an error.

Ideally, if you attempt to connect to an UnLogged database with
AutoCommit Off, you would get a connect failure.
There are problems implementing this because of the way DBI 0.85
behaves when failures occur, so this is not actually implemented.

=head1 ATTRIBUTE NAME CHANGES

Early releases of DBD::Informix, some of the Informix-specific
attributes had names that did not start 'ix_', but these old-style
attribute names are no longer recognized and an error message is
generated (by DBI).

Sometimes, an attribute name is changed for other reasons.
If there is an old spelling, then the old name is eliminated over three
releases spanning a period of not less than 6 months.
In the first release, the old name is recognized and a warning is
emitted but the change takes effect as it always used to.
In the second release, the old name is recognized and a warning is
emitted but no change occurs.
In the third release, the old name is no longer recognized (which yields
an error message from DBI).
You are strongly counselled to eliminate the warnings ASAP (and to keep
more or less current with releases of DBD::Informix).

=head1 MAPPING BETWEEN ESQL/C AND DBD::INFORMIX

A crude form of the mapping between DBD::Informix functions and ESQL/C
equivalents follows--there are a number of ways in which it is not
quite precise (for example, the influence of AutoCommit), but the
mapping is accurate enough for most purposes.

    DBI->connect            => DATABASE in 5.0x
    $dbh->disconnect        => CLOSE DATABASE in 5.0x

    DBI->connect            => CONNECT in 6.0x and later
    $dbh->disconnect        => DISCONNECT in 6.0x and later

    $dbh->commit            => COMMIT WORK (+BEGIN WORK)
    $dbh->rollback          => ROLLBACK WORK (+BEGIN WORK)

    $dbh->do                => EXECUTE IMMEDIATE
    $dbh->prepare           => PREPARE, DESCRIBE (DECLARE)
    $sth->execute           => EXECUTE or OPEN
    $sth->fetch             => FETCH
    $sth->fetchrow          => FETCH
    $sth->finish            => CLOSE

    undef $sth              => FREE cursor, FREE statement, etc

=head1 KNOWN RESTRICTIONS

=over 2

=item *

Blobs (meaning BYTE and TEXT blobs) can only be located in memory.
The provision for locating them in files is not functional.

=item *

BLOB and CLOB smart blobs are not handled directly by DBD::Informix.
The workaround is to use LOTOFILE to extract blobs from the database to
a file, and to use FILETOBLOB or FILETOCLOB to insert blobs from file
into the database.

=item *

Support for the less common types, such as row types, is either less
than perfect or even non-existent.
Sometimes, it will work sufficiently well; you won't, however, get a
Perl structured value out of the system - at most you would get a string
representation of the value.
If you really need to use some feature and DBD::Informix screws it up
impossibly badly, then either (a) submit a patch that fixes it or (b)
contact the maintenance team with a request for help.
This situation has been ongoing for more than a decade, and few people
have reported problems, which is a main reason that it hasn't been
fixed.

=item *

[I<This was an issue in the 1990s; I've not seen the problem for a long time.>]

If you use Informix ESQL/C Version 6.00 or later
and do not set both the environment variables CLIENT_LOCALE
and DB_LOCALE, ESQL/C might set one or both of them during the
connect operation.
When ESQL/C does so, it makes Perl emit a "Bad free()" error if you
subsequently modify the %ENV hash in the Perl script.
This is nasty, but there is no easy solution.
To establish what values you should set, arrange for the
compilation to define DBD_IX_DEBUG_ENVIRONMENT:

    make UFLAGS=-DDBD_IX_DEBUG_ENVIRONMENT

The code in dbdimp.ec will then call the function dbd_ix_printenv() in
dbd_ix_db_login(), which will help you identify what has been changed.

=back

=head1 AUTHOR

At various times:

=over 2

=item *

Tim Bunce (Tim.Bunce@ig.co.uk) # Obsolete email address

=item *

Tim Bunce (Tim.Bunce@pobox.com)

=item *

Alligator Descartes (descarte@hermetica.com) # Obsolete email address

=item *

Alligator Descartes (descarte@arcana.co.uk) # Obsolete email address

=item *

Alligator Descartes (descarte@symbolstone.org)

=item *

Jonathan Leffler (johnl@informix.com) # Obsolete email address

=item *

Jonathan Leffler (jleffler@visa.com) # Obsolete email address

=item *

Jonathan Leffler (j.leffler@acm.org)

=item *

Jonathan Leffler (jleffler@informix.com) # Obsolete email address

=item *

Jonathan Leffler (jleffler@google.com)  # Obsolete email address

=item *

Jonathan Leffler (jleffler@us.ibm.com)  # Obsolete email address

=item *

Jonathan Leffler (jonathan.leffler@hcl.com)

=back

With contributions from many other people who should all be mentioned in the
ChangeLog file.

=head1 SEE ALSO

perl(1)

Using 'perldoc', read the pages on:

=over 2

=item *
DBI - main documentation on Perl DBI

=item *
DBI::FAQ - Separately installable module of Frequently Asked Questions

=item *
DBD::Informix::TechSupport - How to report problems with DBD::Informix

=item *
DBD::Informix::TestHarness - Test harness used when testing DBD::Informix

=item *
DBD::Informix::Summary - Standardized summary of DBD::Informix properties

=item *
DBD::Informix::Configure - Tools used in configuring DBD::Informix

=item *
DBD::Informix::Metadata - Functions used by DBD::Informix for metadata queries

=item *
DBI::DBD - How to write a driver for Perl DBI

=back

=cut
