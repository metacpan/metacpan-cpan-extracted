# $Id: //depot/tilpasninger/dbd-ingres/Ingres.pm#17 $ $DateTime: 2004/01/12 12:10:18 $ $Revision: #17 $
#
#   Copyright (c) 1996-2000 Henrik Tougaard
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

require 5.004;

=head1 NAME

DBD::Ingres - DBI driver for Ingres database systems

=head1 SYNOPSIS

    $dbh = DBI->connect("DBI:Ingres:$dbname", $user, $options, {AutoCommit=>0})
    $sth = $dbh->prepare($statement)
    $sth = $dbh->prepare($statement, {ing_readonly=>1})
    $sth->execute
    @row = $sth->fetchrow
    $sth->finish
    $dbh->commit
    $dbh->rollback
    $dbh->disconnect
    ...and many more

=cut

# The POD text continues at the end of the file.
{
    package DBD::Ingres;

    use DBI 1.00;
    use DynaLoader ();
    @ISA = qw(DynaLoader);

    $VERSION = '0.52';
    my $Revision = substr(q$Change: 18308 $, 8)/100;

    bootstrap DBD::Ingres $VERSION;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $drh = undef;	# holds driver handle once initialised

    sub driver{
        return $drh if $drh;
        my($class, $attr) = @_;

        $class .= "::dr";

        # not a 'my' since we use it above to prevent multiple drivers
        $drh = DBI::_new_drh($class, {
            'Name' => 'Ingres',
            'Version' => $VERSION,
            'Err'    => \$DBD::Ingres::err,
            'Errstr' => \$DBD::Ingres::errstr,
            'Attribution' => 'Ingres DBD by Henrik Tougaard',
            });

        $drh;
    }
    1;
}


{   package DBD::Ingres::dr; # ====== DRIVER ======
    use strict;

    sub connect {
        my($drh, $dbname, $user, $auth)= @_;

        # create a 'blank' dbh
        my $this = DBI::_new_dbh($drh, {
            'Name' => $dbname,
            'USER' => $user,
            'CURRENT_USER' => $user,
            });

        unless ($ENV{'II_SYSTEM'}) {
            warn("II_SYSTEM not set. Ingres may fail\n")
            	if $drh->{Warn};
        }
        unless (-d "$ENV{'II_SYSTEM'}/ingres") {
            warn("No ingres directory in \$II_SYSTEM. Ingres may fail\n")
            	if $drh->{Warn};
        }

        $user = "" unless defined $user;
        $auth = "" unless defined $auth;

        # Connect to the database..
        DBD::Ingres::db::_login($this, $dbname, $user, $auth)
            or return undef;

        $this;
    }

    sub data_sources {
        my ($drh) = @_;
        warn("\$drh->data_sources() not defined for Ingres\n")
            if $drh->{"warn"};
        "";
    }

}


{   package DBD::Ingres::db; # ====== DATABASE ======
    use strict;

    #EXPERIMENTAL! Do not use it!
    sub datatype_helper {
	my ($dbh, $schema, $tablename, $columnname) = @_;
	my $href = undef;
	my $sth = $dbh->column_info('',$schema, $tablename,$columnname);
	return until $href = $sth->fetchrow_hashref;
	if (${$href}{type_name} =~ /LONG VARCHAR/ ) { return DBI::SQL_LONGVARCHAR; }
	elsif (${$href}{type_name} =~ /LONG BYTE/ ) { return DBI::SQL_LONGVARBINARY; }
	elsif (${$href}{type_name} =~ /DECIMAL/ ) { return DBI::SQL_DECIMAL; }
	elsif (${$href}{type_name} =~ /INT/ ) { return DBI::SQL_INTEGER; }
	else { return DBI::SQL_VARCHAR; }
    }

    sub do {
        my ($dbh, $statement, $attribs, @params) = @_;
        Carp::carp "DBD::Ingres::\$dbh->do() attribs unused\n" if $attribs;
	if (
	    (lc($statement) =~ /^insert/) or
	    (lc($statement) =~ /^update/) or
	    (lc($statement) =~ /^delete/)
	   )
	{
	    my $sth = $dbh->prepare($statement) or return undef;
	    my $cnt = 0;
	    foreach (@params) {
		++$cnt;
		if ( defined) {	$sth->bind_param($cnt, $_); }
		else {	$sth->bind_param($cnt, $_, { TYPE => DBI::SQL_VARCHAR }); } #dummy type, not used
	    }
	    my $numrows = $sth->execute() or return undef;
	    $sth->finish;
	    return $numrows; #return $sth->rows; should bring the same result, but doesnt
	}
	else
	{
	    delete $dbh->{Statement};
    	    my $numrows = DBD::Ingres::db::_do($dbh, $statement);
	    return $numrows ;
	}	
    }

    sub prepare {
        my($dbh, $statement, $attribs)= @_;
	my $ing_readonly = defined($attribs->{ing_readonly}) ?
		$attribs->{ing_readonly} :
		scalar $statement !~ /select.*for\s+(?:deferred\s+|direct\s+)?update/is;

        # create a 'blank' sth
        my $sth = DBI::_new_sth($dbh, {
            Statement => $statement,
            ing_statement => $statement,
	    ing_readonly  => $ing_readonly,
            });

        DBD::Ingres::st::_prepare($sth, $statement, $attribs)
            or return undef;

        $sth;
    }

    sub table_info {
        my ($dbh, $catalog, $schema, $table, $type) = @_;
	$schema = ($schema) ? $schema : q/%/;
	$table = ($table) ? $table : q/%/;
	my $sth = $dbh->prepare("
	  SELECT VARCHAR(null) AS TABLE_CAT, table_owner AS TABLE_SCHEM, table_name, 'TABLE' AS TABLE_TYPE
	  FROM iitables WHERE table_type='T' AND VARCHAR(table_owner) LIKE '$schema' AND VARCHAR(table_name) LIKE '$table'");
#        my $sth = $dbh->prepare("
#	  SELECT VARCHAR(null) AS TABLE_CAT, table_owner AS TABLE_SCHEM,	                 table_name, 'TABLE' AS TABLE_TYPE
#	  FROM IITABLES
#	  WHERE table_type='T'
#          UNION
#          SELECT null, table_owner, table_name, 'VIEW'
#          FROM IITABLES
#          WHERE table_type ='V'");
        return unless $sth;
        $sth->execute;
        $sth;
    }

    sub column_info {
        my ($dbh, $catalog, $schema, $table, $column) = @_;
	$schema = ($schema) ? $schema : q/%/;
	$table = ($table) ? $table : q/%/;
	$column = ($column) ? $column : q/%/;
	my $sth = $dbh->prepare("
	  SELECT VARCHAR(null) AS TABLE_CAT, table_owner AS TABLE_SCHEM, table_name AS TABLE_NAME, column_name AS COLUMN_NAME,
	  column_ingdatatype AS DATA_TYPE, column_datatype AS TYPE_NAME, column_length AS COLUMN_SIZE, INT(0) AS BUFFER_LENGTH,
	  column_scale AS DECIMAL_DIGITS, INT(0) AS NUM_PREC_RADIX, column_nulls AS NULLABLE, VARCHAR('') AS REMARKS,
	  column_default_val AS COLUMN_DEF, column_datatype AS SQL_DATA_TYPE, VARCHAR(null) AS SQL_DATETIME_SUB,
	  INT(0) AS CHAR_OCTET_LENGTH, column_sequence AS ORDINAL_POSITION, column_nulls as IS_NULLABLE
	  FROM iicolumns
	  WHERE VARCHAR(table_owner) LIKE '$schema' AND VARCHAR(table_name) LIKE '$table' AND VARCHAR(column_name) LIKE '$column'
	  ORDER BY table_owner, table_name, column_sequence");
        return unless $sth;
        $sth->execute;
        $sth;
    }

    sub get_info {
        my ($dbh, $ident) = @_;
	my $info = '';
	return unless $ident;
	if ($ident == 17 ) { return "Ingres"; }
	elsif ($ident == 18) { $info = "_version"; }
	elsif ($ident == 29) { return "'"; }
	elsif ($ident == 41) { return "."; }
	else { return; }
	my $sth = $dbh->prepare("SELECT dbmsinfo('$info')");
        return unless $sth;
        $sth->execute;
	my $version = $sth->fetchrow;
	if ($version =~ /II 9\.2\.0/) { return "2006 R3"; }
	elsif ($version =~ /II 9\.1\.0/) { return "2006 R2"; }
	elsif ($version =~ /II 9\.0\.4/) { return "2006"; }
	else { return "unknown (implement more)";}
#	return $version;
    }


    sub ping {
        my($dbh) = @_;
        # we know that DBD::Ingres prepare does a describe so this will
        # actually talk to the server and is this a valid and cheap test.
        return 1 if $dbh->prepare("select * from iitables");
        return 0;
    }

    sub type_info_all {
    	my ($dbh) = @_;
    	my $ti = [
    	    {   TYPE_NAME       => 0,
                DATA_TYPE       => 1,
		COLUMN_SIZE	=> 2,
                LITERAL_PREFIX  => 3,
                LITERAL_SUFFIX  => 4,
                CREATE_PARAMS   => 5,
                NULLABLE        => 6,
                CASE_SENSITIVE  => 7,
                SEARCHABLE      => 8,
                UNSIGNED_ATTRIBUTE=> 9,
		FIXED_PREC_SCALE=> 10,
		AUTO_UNIQUE_VALUE=> 11,
                LOCAL_TYPE_NAME => 12,
                MINIMUM_SCALE   => 13,
                MAXIMUM_SCALE   => 14,
		SQL_DATA_TYPE	=> 15,
		SQL_DATETIME_SUB=> 16,
		NUM_PREC_RADIX	=> 17,
		INTERVAL_PRECISIO=> 18,
    	    },
    	    [ 'SMALLINT',     DBI::SQL_SMALLINT,
	      undef, "","",  undef, 1, 0, 2, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'INTEGER',      DBI::SQL_INTEGER,
	      undef, "","", "size=1,2,4", 1, 0, 2, 0, 0 ,0 ,undef ,0 ,0, undef, undef, undef, undef ],
    	    [ 'MONEY',        DBI::SQL_DECIMAL,
	      undef, "","",  undef, 1, 0, 2, 0, 1, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'FLOAT',        DBI::SQL_DOUBLE,
	      undef, "","", "size=4,8", 1, 0, 2, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'DATE',         DBI::SQL_DATE,   
	      undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'DECIMAL',      DBI::SQL_DECIMAL,
	      undef, "","", "precision,scale", 1, 0, 2, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'VARCHAR',      DBI::SQL_VARCHAR,
	      undef, "'","'", "max length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'BYTE VARYING', DBI::SQL_VARBINARY,
	      undef, "'","'", "max length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'CHAR',         DBI::SQL_CHAR,   
	      undef, "'","'", "length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'BYTE',         DBI::SQL_BINARY, 
	      undef, "'","'", "length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'LONG VARCHAR', DBI::SQL_LONGVARCHAR, 
	      undef, undef, undef, undef, 1, 1, 0, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	    [ 'LONG BYTE', DBI::SQL_LONGVARBINARY, 
	      undef, undef, undef, undef, 1, 1, 0, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
    	];
    	return $ti;
    }
}


{   package DBD::Ingres::st; # ====== STATEMENT ======
    use strict;

}

1;

=head1 DESCRIPTION

DBD::Ingres is a database driver for the perl DBI system that allows
access to Ingres databases. It is built on top of the standard DBI
extension and implements the methods that DBI requires.

This document describes the differences between the "generic" DBD and
DBD::Ingres.

=head1 EXTENSIONS/CHANGES

=head2 Connect

  DBI->connect("DBI:Ingres:dbname[;options]");
  DBI->connect("DBI:Ingres:dbname[;options]", user [, password]);
  DBI->connect("DBI:Ingres:dbname[;options]", user [, password], \%attr);

To use DBD::Ingres call C<connect> specifying a I<datasource> option beginning
with I<"DBI:Ingres:">, followed by the database instance name and
optionally a semi-colon followed by any Ingres connect options.

Options must be given exactly as they would be given in an ESQL-connect
statement, i.e., separated by blanks.

The connect call will result in a connect statement like:

  CONNECT dbname IDENTIFIED BY user PASSWORD password OPTIONS=options

E.g.,

=over 4

=item *

local database

  DBI->connect("DBI:Ingres:mydb", "me", "mypassword")

=item *

with options and no password

  DBI->connect("DBI:Ingres:mydb;-Rmyrole/myrolepassword", "me")

=item *

Ingres/Net database

  DBI->connect("DBI:Ingres:thatnode::thisdb;-xw -l", "him", "hispassword")

=back

and so on.

=head2 AutoCommit Defaults to ON

B<Important>: The DBI spec defines that AutoCommit is B<ON> after connect.
This is the opposite of the normal Ingres default.

It is recommended that the C<connect> call ends with the attributes
C<{ AutoCommit =E<gt> 0 }>.

=head2 Returned Types

The DBI docs state that:

=over 4

=item *

Most data is returned to the perl script as strings (null values are
returned as undef).  This allows arbitrary precision numeric data to be
handled without loss of accuracy.  Be aware that perl may not preserve
the same accuracy when the string is used as a number.

=back

This is B<not> the case for Ingres.

Data is returned as it would be to an embedded C program:

=over 4

=item *

Integers are returned as integer values (IVs in perl-speak).

=item *

Floats and doubles are returned as numeric values (NVs in perl-speak).

=item *

Dates, moneys, chars, varchars and others are returned as strings
(PVs in perl-speak).

=back

This does not cause loss of precision, because the Ingres API uses
these types to return the data anyway.

=head2 get_dbevent

This non-DBI method calls C<GET DBEVENT> and C<INQUIRE_INGRES> to
fetch a pending database event. If called without argument a blocking
C<GET DBEVENT WITH WAIT> is called. A numeric argument results in a
call to C<GET DBEVENT WITH WAIT= :seconds>.

In a second step
C<INQUIRE_INGRES> is called to fetch the related information, wich is
returned as a reference to a hash with keys C<name>, C<database>,
C<text>, C<owner> and C<time>. The values are the C<dbevent>* values
received from Ingres. If no event was fetched, C<undef> is returned.
See F<t/event.t> for an example of usage.

  $event_ref = $dbh->func(10, 'get_dbevent')     # wait 10 secs at most
  $event_ref = $dbh->func('get_dbevent')         # blocks

  for (keys %$event_ref) {
    printf "%-20s = '%s'\n", $_, $event_ref->{$_};
  }

=head2 do

$dbh->do is implemented as a call to 'EXECUTE IMMEDIATE' with all the
limitations that this implies. An exception to that are the DML statements
C<INSERT>, C<DELETE> and C<UPDATE>. For them, a call to C<PREPARE> is
made, possible existing parameters are bound and a subsequent C<EXECUTE>
does the job. C<SELECT> isn't supported since $dbh->do doesn't give back
a statement handler hence no way to retrieve data.

=head2 Binary Data

Fetching binary data from char and varchar fields is not guaranteed
to work, but probably will most of the time.  Use 'BYTE' or
'BYTE VARYING' data types in your database for full binary data support.

=head2 Long Data Types

DBD::Ingres supports the LONG VARCHAR and LONG BYTE data types
as detailed in L<DBI/"Handling BLOB / LONG / Memo Fields">.

The default value for LongReadLen in DBD::Ingres is 2GB, the maximum
size of a long data type field.  DBD::Ingres dynamically allocates
memory for long data types as required, so setting LongReadLen to a
large value does not waste memory.

In summary:

=over 4

=item *

When inserting blobs, use bind variables with types specified.

=item *

When fetching blobs, set LongReadLen and LongTruncOk in the $dbh.

=item *

Blob fields are returned as undef if LongReadLen is 0.

=back

Due to their size (and hence the impracticality of copying them inside
the DBD driver), variables bound as blob types are always evaluated at
execute time rather than bind time. (Similar to bind_param_inout, except
you don't pass them as references.)

=head2 ing_readonly

Normally cursors are declared C<READONLY> 
to increase speed. READONLY cursors don't create
exclusive locks for all the rows selected; this is
the default.

If you need to update a row then you will need to ensure that either

=over 4

=item *

the C<select> statement contains an C<for update of> clause, or

= item *

the C<$dbh-E<gt>prepare> calls includes the attribute C<{ing_readonly =E<gt> 0}>.

=back

E.g.,

  $sth = $dbh->prepare("select ....", {ing_readonly => 0});

will be opened for update, as will

  $sth = $dbh->prepare("select .... for direct update of ..")

while

  $sth = $dbh->prepare("select .... for direct update of ..",
                       { ing_readonly => 1} );

will be opened C<FOR READONLY>.

When you wish to actually do the update, where you would normally put the
cursor name, you put:

  $sth->{CursorName}

instead,  for example:

  $sth = $dbh->prepare("select a,b,c from t for update of b");
  $sth->execute;
  $row = $sth->fetchrow_arrayref;
  $dbh->do("update t set b='1' where current of $sth->{CursorName}");

Later you can reexecute the statement without the update-possibility by doing:

  $sth->{ing_readonly} = 1;
  $sth->execute;

and so on. B<Note> that an C<update> will now cause an SQL error.

In fact the "FOR UPDATE" seems to be optional, i.e., you can update
cursors even if their SELECT statements do not contain a C<for update>
part.

If you wish to update such a cursor you B<must> include the C<ing_readonly>
attribute.

B<NOTE> DBD::Ingres version later than 0.19_1 have opened all cursors for
update. This change breaks that behaviour. Sorry if this breaks your code.

=head2 ing_rollback

The DBI docs state that 'Changing C<AutoCommit> from off to on will
trigger a C<commit>'.

Setting ing_rollback to B<on> will change that to 'Changing C<AutoCommit>
from off to on will trigger a C<rollback>'.

Default value is B<off>.

=head2 ing_statement

This has long been deprecated in favor of C<$sth-E<gt>{Statement}>,
which is a DBI standard.

$sth->{ing_statement} provides access to the SQL statement text.

=head2 ing_types

  $sth->{ing_types}              (\@)

Returns an array of the "perl"-type of the return fields of a select
statement.

The types are represented as:

=over 4

=item 'i': integer

All integer types, i.e., int1, int2 and int4.

These values are returned as integers. This should not cause loss of
precision as the internal Perl integer is at least 32 bit long.

=item 'f': float

The types float, float8 and money.

These values are returned as floating-point numbers. This may cause loss
of precision, but that would occur anyway whenever an application
referred to the data (all Ingres tools fetch these values as
floating-point numbers)

=item 'l': long / blob

Either of the two long datatypes, long varchar or long byte.

=item 's': string

All other supported types, i.e., char, varchar, text, date etc.

=back

=head2 Ingres Types and their DBI Equivalents

  $sth->TYPE                       (\@)

See L<DBI> for a description.  The Ingres translations are:

=over 4

=item *

short -> DBI::SQL_SMALLINT

=item *

int -> DBI::SQL_INTEGER

=item *

float -> DBI::SQL_DOUBLE

=item *

double -> DBI::SQL_DOUBLE

=item *

char -> DBI::SQL_CHAR

=item *

text -> DBI::SQL_CHAR

=item *

byte -> DBI::SQL_BINARY

=item *

varchar -> DBI::SQL_VARCHAR

=item *

byte varying -> DBI::SQL_VARBINARY

=item *

date -> DBI::SQL_DATE

=item *

money -> DBI::SQL_DECIMAL

=item *

decimal -> DBI::SQL_DECIMAL

=item *

long varchar -> DBI::SQL_LONGVARCHAR

=item *

long byte -> DBI::SQL_LONGVARBINARY

=back

Have I forgotten any?

=head2 ing_lengths

  $sth->{ing_lengths}              (\@)

Returns an array containing the lengths of the fields in Ingres, eg. an
int2 will return 2, a varchar(7) 7 and so on.

Note that money and date fields will have length returned as 0.

C<$sth-E<gt>{SqlLen}> is the same as C<$sth-E<gt>{ing_lengths}>,
but the use of it is deprecated.

See also the C<$sth-E<gt>{PRECISION}> field in the DBI docs. This returns
a 'reasonable' value for all types including money and date-fields.

=head2 ing_sqltypes

    $sth->{ing_sqltypes}              (\@)

Returns an array containing the Ingres types of the fields. The types
are given as documented in the Ingres SQL Reference Manual.

All values are positive as the nullability of the field is returned in
C<$sth-E<gt>{NULLABLE}>.

See also the C$sth-E<gt>{TYPE}> field in the DBI docs.

=head2 ing_ph_ingtypes

    $sth->{ing_ph_ingtypes}           (\@)
    
Returns an array containing the Ingres types of the columns the place-
holders represent. This is a guess from the context of the placeholder
in the prepared statement. Be aware, that the guess isn't always correct
and sometypes a zero (illegal) type is returned. Plus negative values
indicate nullability of the parameter. A C<$sth-E<gt>{ing_ph_nullable}>
field is to be implemented yet.

=head2 ing_ph_inglengths

    $sth->{ing_ph_inglengths}         (\@)

Returns an array containing the lengths of the placeholders analog to
the $sth->{ing_lengths} field.

=head1 FEATURES NOT IMPLEMENTED

=head2 state

  $h->state                (undef)

SQLSTATE is not implemented.

=head2 disconnect_all

Not implemented

=head2 commit and rollback invalidate open cursors

DBD::Ingres should warn when a commit or rollback is isssued on a $dbh
with open cursors.

Possibly a commit/rollback should also undef the $sth's. (This should
probably be done in the DBI-layer as other drivers will have the same
problems).

After a commit or rollback the cursors are all ->finish'ed, i.e., they
are closed and the DBI/DBD will warn if an attempt is made to fetch
from them.

A future version of DBD::Ingres wil possibly re-prepare the statement.

This is needed for

=head2 Cached statements

A new feature in DBI that is not implemented in DBD::Ingres.

=head2 bind_param_inout (Procedure calls)

It is possible to call database procedures from DBD::Ingres. It is B<NOT>
possible to get return values from the procedure.

A solution is underway for support for procedure calls from the DBI.
Until that is defined procedure calls can be implemented as a
DB::Ingres-specific function (like L<get_event>) if the need arises and
someone is willing to do it.

=head1 NOTES

=head2 $dbh->(table|column|get)_info

The table_info and column_info functions are just working against tables.
Views and synonyms still have to be implemented. The get_info function
returns just the newer version strings correctly, since I'm still looking
 for documentation for the older ones.

I wonder if I have forgotten something?

=head1 SEE ALSO

The DBI documentation in L<DBI> and L<DBI::DBD>.

=head1 AUTHORS

DBI/DBD was developed by Tim Bunce, <Tim.Bunce@ig.co.uk>, who also
developed the DBD::Oracle that is the closest we have to a generic DBD
implementation.

Henrik Tougaard, <htoug@cpan.org> developed the DBD::Ingres extension.

Stefan Reddig, <sreagle@cpan.org> is currently (2008) adopting it to
include some more features.

=cut
