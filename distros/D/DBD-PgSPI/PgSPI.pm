#
#  Copyright (c) 2000,2001 Alex Pilosov
#  Copyright (c) 1997,1998,1999 Edmund Mergl
#  Copyright (c) 1994,1995,1996,1997 Tim Bunce
#
#  You may distribute under the terms of either the GNU General Public
#  License or the Artistic License, as specified in the Perl README file.

require 5.003;

$DBD::PgSPI::VERSION = '0.02';

{
    package DBD::PgSPI;

    use DBI ();
    use DynaLoader ();
    use Exporter ();
    use DBD::Pg ();  # we punt certain functions there
    @ISA = qw(DynaLoader Exporter);
    @EXPORT = qw($pg_dbh); # since we can only have one connection, 
                          # might as well export it

    require_version DBI 1.00;

    bootstrap DBD::PgSPI $VERSION;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $drh = undef;	# holds driver handle once initialized

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'internal',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::PgSPI::err,
	    'Errstr' => \$DBD::PgSPI::errstr,
	    'Attribution' => 'PostgreSQL SPI DBD by Alex Pilosov',
	});

	$drh;
    }

    $pg_dbh = DBI->connect("dbi:PgSPI:internal");
    1;
}

{   package DBD::PgSPI::dr; # ====== DRIVER ======
    use strict;

    sub data_sources {
        my @sources=("dbi:PgSPI:internal");
        return @sources;
    }


    sub connect {
        my($drh, $dbname, $user, $auth)= @_;

        # create a 'blank' dbh

        my($dbh) = DBI::_new_dbh($drh, {
            'Name' => 'internal',
        });

        # Connect to the database using SPI
        DBD::PgSPI::db::_login($dbh) or return undef;

        $dbh;
    }

}


{   package DBD::PgSPI::db; # ====== DATABASE ======
    use strict;

    sub prepare {
        my($dbh, $statement, @attribs)= @_;

        # create a 'blank' sth

        my $sth = DBI::_new_sth($dbh, {
            'Statement' => $statement,
        });

        DBD::PgSPI::st::_prepare($sth, $statement, @attribs) or return undef;

        $sth;
    }


    sub ping {
        my($dbh) = @_;

        return 1;
    }

# punt these functions to Pg
    sub table_info {         # DBI spec: TABLE_CAT, TABLE_SCHEM, TABLE_NAME, TABLE_TYPE, REMARKS
        my(@args) = @_;
	return DBD::Pg::db::table_info(@args);
    }


    sub tables {
        my(@args) = @_;
	return DBD::Pg::db::tables(@args);
    }


    sub table_attributes {
        my(@args) = @_;
	return DBD::Pg::db::table_attributes(@args);
    }


    sub type_info_all {
        my(@args) = @_;
	return DBD::Pg::db::type_info_all(@args);
    }


    sub quote {
        my ($dbh, $str, $data_type) = @_;

        return "NULL" unless defined $str;

        unless ($data_type) {
            $str =~ s/'/''/g;           # ISO SQL2
            # In addition to the DBI method it doubles also the
            # backslash, because PostgreSQL treats a backslash as an
            # escape character.
            $str =~ s/\\/\\\\/g;
            return "'$str'";
        }

        # Optimise for standard numerics which need no quotes
        return $str if $data_type == DBI::SQL_INTEGER
                    || $data_type == DBI::SQL_SMALLINT
                    || $data_type == DBI::SQL_DECIMAL
                    || $data_type == DBI::SQL_FLOAT
                    || $data_type == DBI::SQL_REAL
                    || $data_type == DBI::SQL_DOUBLE
                    || $data_type == DBI::SQL_NUMERIC;
        my $ti = $dbh->type_info($data_type);
        # XXX needs checking
        my $lp = $ti ? $ti->{LITERAL_PREFIX} || "" : "'";
        my $ls = $ti ? $ti->{LITERAL_SUFFIX} || "" : "'";
        # XXX don't know what the standard says about escaping
        # in the 'general case' (where $lp != "'").
        # So we just do this and hope:
        $str =~ s/$lp/$lp$lp/g
                if $lp && $lp eq $ls && ($lp eq "'" || $lp eq '"');
        return "$lp$str$ls";
    }
}


{   package DBD::PgSPI::st; # ====== STATEMENT ======

    # all done in XS

}

1;

__END__


=head1 NAME

DBD::PgSPI - PostgreSQL database driver for the DBI module


=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect("dbi:PgSPI:internal", "", "");

=head1 DESCRIPTION

IF YOU ARE LOOKING FOR A WAY TO ACCESS POSTGRESQL DATABASE FROM A PERL
SCRIPT RUNNING OUTSIDE OF YOUR DATABASE, LOOK AT DBD::Pg, YOU CANNOT 
USE THIS MODULE. THIS MODULE IS ONLY INTENDED FOR USE BY STORED PROCEDURES
WRITTEN IN 'plperl' PROGRAMMING LANGUAGE RUNNING INSIDE POSTGRESQL.

DBD::PgSPI is a Perl module which works with the DBI module to provide
access to PostgreSQL database from within pl/perl functions inside the
database.

=head1 MODULE DOCUMENTATION

This documentation describes driver specific behavior and restrictions. 
It is not supposed to be used as the only reference for the user. In any 
case consult the DBI documentation first !


=head1 THE DBI CLASS

=head2 DBI Class Methods

=over 4

=item B<connect>

To connect to a database, use the following syntax: 

   $dbh = DBI->connect("dbi:PgSPI:", "", "");

This is necessary to initialize SPI interface. You cannot specify 
any other parameters to connect(), and if you do, they'll be ignored..

=item B<data_sources>

  @data_sources = DBI->data_sources('PgSPI');

The driver supports this method, only returning 'dbi:PgSPI:internal',
since there is only data source, the current database.

=back


=head2 DBI Dynamic Attributes

See Common Methods. 


=head1 METHODS COMMON TO ALL HANDLES

=over 4

=item B<err>

  $rv = $h->err;

Supported by the driver as proposed by DBI. For the connect 
method it returns PQstatus. In all other cases it returns 
PQresultStatus of the current handle. 

=item B<errstr>

  $str = $h->errstr;

Supported by the driver as proposed by DBI. It returns the 
PQerrorMessage related to the current handle. 

=item B<state>

  $str = $h->state;

This driver does not (yet) support the state method. 

=item B<func>

This driver supports a variety of driver specific functions 
accessible via the func interface:

  $attrs = $dbh->func($table, 'table_attributes');

(See DBD::Pg for further documentation on this)

=back


=head1 ATTRIBUTES COMMON TO ALL HANDLES

=over 4

=item B<Warn> (boolean, inherited)

Implemented by DBI, no driver-specific impact.

=item B<Active> (boolean, read-only)

Supported by the driver as proposed by DBI. A database 
handle is active while it is connected and  statement 
handle is active until it is finished. 

=item B<Kids> (integer, read-only)

Implemented by DBI, no driver-specific impact.

=item B<ActiveKids> (integer, read-only)

Implemented by DBI, no driver-specific impact.

=item B<CachedKids> (hash ref)

Implemented by DBI, no driver-specific impact.

=item B<CompatMode> (boolean, inherited)

Not used by this driver. 

=item B<InactiveDestroy> (boolean)

Implemented by DBI, no driver-specific impact.

=item B<PrintError> (boolean, inherited)

Implemented by DBI, no driver-specific impact.

=item B<RaiseError> (boolean, inherited)

Implemented by DBI, no driver-specific impact.

=item B<ChopBlanks> (boolean, inherited)

Supported by the driver as proposed by DBI. This 
method is similar to the SQL-function RTRIM. 

=item B<LongReadLen> (integer, inherited)

Implemented by DBI, not used by the driver.

=item B<LongTruncOk> (boolean, inherited)

Implemented by DBI, not used by the driver.

=item B<Taint> (boolean, inherited)

Implemented by DBI, no driver-specific impact.

=item B<private_*>

Implemented by DBI, no driver-specific impact.

=back


=head1 DBI DATABASE HANDLE OBJECTS

=head2 Database Handle Methods

=over 4

=item B<selectrow_array>

  @row_ary = $dbh->selectrow_array($statement, \%attr, @bind_values);

Implemented by DBI, no driver-specific impact.

=item B<selectall_arrayref>

  $ary_ref = $dbh->selectall_arrayref($statement, \%attr, @bind_values);

Implemented by DBI, no driver-specific impact.

=item B<selectcol_arrayref>

  $ary_ref = $dbh->selectcol_arrayref($statement, \%attr, @bind_values);

Implemented by DBI, no driver-specific impact.

=item B<prepare>

  $sth = $dbh->prepare($statement, \%attr);

PostgreSQL does not have the concept of preparing 
a statement. Hence the prepare method just stores 
the statement after checking for place-holders. 
No information about the statement is available 
after preparing it. 

=item B<prepare_cached>

  $sth = $dbh->prepare_cached($statement, \%attr);

Implemented by DBI, no driver-specific impact. 
This method is not useful for this driver, because 
preparing a statement has no database interaction. 

=item B<do>

  $rv  = $dbh->do($statement, \%attr, @bind_values);

Implemented by DBI, no driver-specific impact. See the 
notes for the execute method elsewhere in this document. 

=item B<commit>

  $rc  = $dbh->commit;

Supported by the driver as proposed by DBI. See also the 
notes about B<Transactions> elsewhere in this document. 

=item B<rollback>

  $rc  = $dbh->rollback;

Supported by the driver as proposed by DBI. See also the 
notes about B<Transactions> elsewhere in this document. 

=item B<disconnect>

  $rc  = $dbh->disconnect;

Supported by the driver as proposed by DBI. 

=item B<ping>

  $rc = $dbh->ping;

Since the database is always 'up', this method always returns 1.

=item B<table_info>
=item B<tables>
=item B<type_info_all>
=item B<type_info>
 See DBD::Pg documentation for details.

=item B<quote>

  $sql = $dbh->quote($value, $data_type);

This module implements it's own quote method. In addition to the 
DBI method it doubles also the backslash, because PostgreSQL treats 
a backslash as an escape character. 

=back

=head2 Database Handle Attributes

=over 4

=item B<AutoCommit>  (boolean)

Currently, since there are no nested transactions supported
by PostgreSQL, you cannot turn off AutoCommit, and the database
should be considered as 'transaction-unsupported'.

=item B<Name>  (string, read-only)

Always returns 'internal'.

=item B<RowCacheSize>  (integer)

Implemented by DBI, not used by the driver.

=item B<pg_auto_escape> (boolean)

PostgreSQL specific attribute. If true, then quotes and backslashes in all 
parameters will be escaped in the following way: 

  escape quote with a quote (SQL)
  escape backslash with a backslash except for octal presentation

The default is on. Note, that PostgreSQL also accepts quotes, which 
are escaped by a backslash. Any other ASCII character can be used 
directly in a string constant. 

=item B<pg_INV_READ> (integer, read-only)

Constant to be used for the mode in lo_creat and lo_open.

=item B<pg_INV_WRITE> (integer, read-only)

Constant to be used for the mode in lo_creat and lo_open.

=back


=head1 DBI STATEMENT HANDLE OBJECTS

=head2 Statement Handle Methods

=over 4

=item B<bind_param>

  $rv = $sth->bind_param($param_num, $bind_value, \%attr);

Supported by the driver as proposed by DBI. 

=item B<bind_param_inout>

Not supported by this driver. 

=item B<execute>

  $rv = $sth->execute(@bind_values);

Supported by the driver as proposed by DBI. 
In addition to 'UPDATE', 'DELETE', 'INSERT' statements, for 
which it returns always the number of affected rows, the execute 
method can also be used for 'SELECT ... INTO table' statements. 

=item B<fetchrow_arrayref>

  $ary_ref = $sth->fetchrow_arrayref;

Supported by the driver as proposed by DBI. 

=item B<fetchrow_array>

  @ary = $sth->fetchrow_array;

Supported by the driver as proposed by DBI. 

=item B<fetchrow_hashref>

  $hash_ref = $sth->fetchrow_hashref;

Supported by the driver as proposed by DBI. 

=item B<fetchall_arrayref>

  $tbl_ary_ref = $sth->fetchall_arrayref;

Implemented by DBI, no driver-specific impact. 

=item B<finish>

  $rc = $sth->finish;

Supported by the driver as proposed by DBI. 

=item B<rows>

  $rv = $sth->rows;

Supported by the driver as proposed by DBI. 
In contrast to many other drivers the number of rows is 
available immediately after executing the statement. 

=item B<bind_col>

  $rc = $sth->bind_col($column_number, \$var_to_bind, \%attr);

Supported by the driver as proposed by DBI. 

=item B<bind_columns>

  $rc = $sth->bind_columns(\%attr, @list_of_refs_to_vars_to_bind);

Supported by the driver as proposed by DBI. 

=back


=head2 Statement Handle Attributes

=over 4

=item B<NUM_OF_FIELDS>  (integer, read-only)

Implemented by DBI, no driver-specific impact. 

=item B<NUM_OF_PARAMS>  (integer, read-only)

Implemented by DBI, no driver-specific impact. 

=item B<NAME>  (array-ref, read-only)

Supported by the driver as proposed by DBI. 

=item B<NAME_lc>  (array-ref, read-only)

Implemented by DBI, no driver-specific impact. 

=item B<NAME_uc>  (array-ref, read-only)

Implemented by DBI, no driver-specific impact. 

=item B<TYPE>  (array-ref, read-only)

Supported by the driver as proposed by DBI, with 
the restriction, that the types are PostgreSQL 
specific data-types which do not correspond to 
international standards.

=item B<PRECISION>  (array-ref, read-only)

Not supported by the driver. 

=item B<SCALE>  (array-ref, read-only)

Not supported by the driver. 

=item B<NULLABLE>  (array-ref, read-only)

Not supported by the driver. 

=item B<CursorName>  (string, read-only)

Not supported by the driver. See the note about 
B<Cursors> elsewhere in this document. 

=item B<Statement>  (string, read-only)

Supported by the driver as proposed by DBI. 

=item B<RowCache>  (integer, read-only)

Not supported by the driver. 

=item B<pg_size>  (array-ref, read-only)

PostgreSQL specific attribute. It returns a reference to an 
array of integer values for each column. The integer shows 
the size of the column in bytes. Variable length columns 
are indicated by -1. 

=item B<pg_type>  (hash-ref, read-only)

PostgreSQL specific attribute. It returns a reference to an 
array of strings for each column. The string shows the name 
of the data_type. 

=item B<pg_oid_status> (integer, read-only)

PostgreSQL specific attribute. It returns the OID of the last 
INSERT command. 

=item B<pg_cmd_status> (integer, read-only)

PostgreSQL specific attribute. It returns the type of the last 
command. Possible types are: INSERT, DELETE, UPDATE, SELECT. 

=back


=head1 FURTHER INFORMATION

=head2 Cursors

Cursors (portals in SPI parlance) are not currently being used 
in this implementation. 


=head2 Data-Type bool

The current implementation of PostgreSQL returns 't' for true and 'f' for 
false. From the perl point of view a rather unfortunate choice. The DBD-PgSPI 
module translates the result for the data-type bool in a perl-ish like manner: 
'f' -> '0' and 't' -> '1'. This way the application does not have to check 
the database-specific returned values for the data-type bool, because perl 
treats '0' as false and '1' as true. 


=head1 SEE ALSO

L<DBI>


=head1 AUTHORS

=item *
DBI and DBD-Oracle by Tim Bunce (Tim.Bunce@ig.co.uk)

=item *
DBD-Pg by Edmund Mergl (E.Mergl@bawue.de)

=item *
DBD-PgSPI by Alex Pilosov (alex@pilosoft.com)

 Major parts of this package have been copied from DBI, DBD::Oracle, DBD::Pg.

=head1 COPYRIGHT

The DBD::PgSPI module is free software. 
You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file,
with the exception that it cannot be placed on a CD-ROM or similar media
for commercial distribution without the prior approval of the author.


=head1 ACKNOWLEDGMENTS

See also B<DBI/ACKNOWLEDGMENTS>.

=cut
