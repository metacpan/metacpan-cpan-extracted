#
#   Copyright (c) 1996-2000  Henrik Tougaard
#   Copytight (c) 2012, 2013 Tomasz Konojacki
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

require 5.008_004;

=head1 NAME

DBD::IngresII - DBI driver for Actian Ingres and Actian Vectorwise RDBMS

=head1 SYNOPSIS

    $dbh = DBI->connect("DBI:IngresII:$dbname", $user, $options, {AutoCommit=>0})
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

# Note that Perl Critic will complain about this '{' but IMHO it improves
# readability
{
    package DBD::IngresII;

    use strict;

    use DBI 1.00;
    use DynaLoader ();

    our @ISA = qw(DynaLoader);

    our $VERSION = '0.96';

    bootstrap DBD::IngresII $VERSION;

    our $err = 0;        # holds error code   for DBI::err
    our $errstr = "";    # holds error string for DBI::errstr
    our $drh = undef;    # holds driver handle once initialised

    sub driver{
        return $drh if $drh;
        my($class, $attr) = @_;

        $class .= "::dr";

        # not a 'my' since we use it above to prevent multiple drivers
        $drh = DBI::_new_drh($class, {
            'Name' => 'IngresII',
            'Version' => $VERSION,
            'Err'    => \$DBD::IngresII::err,
            'Errstr' => \$DBD::IngresII::errstr,
            'Attribution' => 'IngresII DBD by Henrik Tougaard',
            });

        DBD::IngresII::db->install_method('ing_utf8_quote');
        DBD::IngresII::db->install_method('ing_bool_to_str');
        DBD::IngresII::db->install_method('ing_norm_bool');
        DBD::IngresII::db->install_method('ing_is_vectorwise');

        return $drh;
    }
    1;
}


{   package DBD::IngresII::dr; # ====== DRIVER ======
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
        DBD::IngresII::db::_login($this, $dbname, $user, $auth)
            or return;

        return $this;
    }

    sub data_sources {
        my ($drh) = @_;
        warn("\$drh->data_sources() not defined for Ingres\n")
            if $drh->{"warn"};
        "";
    }

}


{   package DBD::IngresII::db; # ====== DATABASE ======
    use strict;

    use Carp;
    use utf8;

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
        Carp::carp "DBD::IngresII::\$dbh->do() attribs unused\n" if $attribs;
        if (
            (lc($statement) =~ /^insert/) or
            (lc($statement) =~ /^update/) or
            (lc($statement) =~ /^delete/)
        ) {
            my $sth = $dbh->prepare($statement) or return;
            my $cnt = 0;
            foreach (@params) {
                ++$cnt;
                if (defined) { $sth->bind_param($cnt, $_); }
                else {
                    $sth->bind_param($cnt, $_, { TYPE => DBI::SQL_VARCHAR }); #dummy type, not used
                }
            }
            my $numrows = $sth->execute() or return;
            $sth->finish;
            return $numrows; #return $sth->rows; should bring the same result, but doesnt
        }
        else {
            delete $dbh->{Statement};
            my $numrows = DBD::IngresII::db::_do($dbh, $statement);
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

        DBD::IngresII::st::_prepare($sth, $statement, $attribs)
            or return;

        return $sth;
    }

    sub table_info {
        my ($dbh, $catalog, $schema, $table, $type) = @_;

        $schema = $schema ? $schema : q/%/;
        $table = $table ? $table : q/%/;
        $type = $type ? $type : 'table';

        my $schemaPred = ($schema =~ /%|_/) ? ' like ' : ' = ';
        my $tablePred = ($table =~ /%|_/) ? ' like ' : ' = ';

        my @types = split(/,/, $type);
        my $include_synonyms = 0;

        my @tTypes;
        for my $tType ( @types ) {
            $tType =~ s/'|"//g;
            $tType =~ s/\s//g;
            $include_synonyms++ if $tType =~ /synonym/i;

            if ($tType =~ /^table/i) {
                $tType = 'T';
            }
            elsif ($tType =~ /^view/i) {
                $tType = 'V';
            }
            elsif ($tType =~ /^index/i) {
                $tType = 'I';
            }
            elsif ($tType =~ /^synonym/i) {
                $tType = 'S';
            }
            else {
                $tType = 'T';
            }

            push( @tTypes, $dbh->quote($tType) );
        }

        my $types = '(' . join(',', @tTypes) . ')';

        my $sth;

        if ( $include_synonyms ) {
            $sth = $dbh->prepare( qq{
                select varchar(null) as table_cat,
                table_owner as table_schem,
                table_name,
                case table_type
                    when 'T' then 'TABLE'
                    when 'V' then 'VIEW'
                    when 'I' then 'INDEX'
                    else table_type
                end as table_type,
                varchar(null) as remarks,
                system_use,
                num_rows,
                storage_structure,
                row_width,
                modify_date,
                location_name,
                table_pagesize
                from iitables
                where table_type in $types
                and table_owner $schemaPred '$schema'
                and table_name $tablePred '$table'
                and system_use = 'U'

                union

                select varchar(null) as table_cat,
                synonym_owner as table_schem,
                synonym_name as table_name,
                table_type = 'SYNONYM',
                varchar(null) as remarks,
                varchar(null) as system_use,
                varchar(null) as num_rows,
                varchar(null) as storage_structure,
                varchar(null) as row_width,
                varchar(null) as modify_date,
                varchar(table_name) as location_name,
                varchar(null) as table_pagesize
                from iisynonyms
                where synonym_owner $schemaPred '$schema'
            });
        }
        else {
            $sth = $dbh->prepare(qq{
                select varchar(null) as table_cat,
                table_owner as table_schem,
                table_name,
                case table_type
                    when 'T' then 'TABLE'
                    when 'V' then 'VIEW'
                    when 'I' then 'INDEX'
                    else table_type
                end as table_type,
                varchar(null) as remarks,
                num_rows,
                storage_structure,
                row_width,
                modify_date,
                location_name,
                table_pagesize
                from iitables
                where table_type in $types
                and VARCHAR(table_owner) $schemaPred '$schema'
                and VARCHAR(table_name) $tablePred '$table'
                and varchar(system_use) = 'U'
            });
        }

        return unless $sth;
        $sth->execute;
        return $sth;
    }

    sub column_info {
        my ($dbh, $catalog, $schema, $table, $column) = @_;

        $schema = $schema ? $schema : q/%/;
        $table = $table ? $table : q/%/;
        $column = $column ? $column : q/%/;

        my $schemaPred = ($schema =~ /%|_/) ? ' like ' : ' = ';
        my $tablePred = ($table =~ /%|_/) ? ' like ' : ' = ';
        my $colPred = ($column =~ /%|_/) ? ' like ' : ' = ';

        my $sth = $dbh->prepare(qq{
            select
            varchar(null) as table_cat,
            varchar(col.table_owner) as stable_schem,
            varchar(col.table_name) as table_name,
            varchar(column_name) as column_name,
            column_ingdatatype as date_type,
            column_datatype as type_name,
            column_length as column_size,
            int(0) as buffer_length,
            column_scale as decimal_digits,
            int(0) as num_prec_radix,
            column_nulls as nullable,
            varchar('') as remarks,
            column_default_val as column_def,
            column_datatype as sql_data_type,
            varchar(null) as sql_datetime_sub,
            int(0) as char_octet_length,
            column_sequence as ordinal_position,
            column_nulls as is_nullable,
            syn.synonym_name
            from iicolumns col
            left join iisynonyms syn on
            syn.table_name = col.table_name
            where col.table_owner $schemaPred '$schema'
            and (col.table_name $tablePred '$table' or syn.synonym_name $tablePred '$table')
            and column_name $colPred '$column'
            order by col.table_owner, col.table_name, column_sequence
        });

        return unless $sth;
        $sth->execute;
        return $sth;
    }

    sub get_info {
        my ($dbh, $ident) = @_;

        return unless $ident;

        if ($ident == 17) { # SQL_DBMS_NAME
            my $sth = $dbh->prepare("SELECT dbmsinfo('_version')");

            return unless $sth;

            $sth->execute;

            my $info = $sth->fetchrow;
            $sth->finish;

            if ($info =~ /^(\w{2})/) {
                if ($1 eq 'II') {
                    return 'Ingres';
                }
                elsif ($1 eq 'VW') {
                    return 'Vectorwise';
                }
                else {
                    return 'unknown';
                }
            }

            return 'unknown';
        }
        elsif ($ident == 18) { # SQL_DBMS_VER
            my $sth = $dbh->prepare("SELECT dbmsinfo('_version')");

            return unless $sth;

            $sth->execute;

            my $info = $sth->fetchrow;
            $sth->finish;

            if ($info =~ /^(II|VW) (\d+\.\d+\.\d+)/) {
                return $2;
            }

            return 'unknown';
        }
        elsif ($ident == 29 ) { return q{'}        } # SQL_IDENTIFIER_QUOTE_CHAR
        elsif ($ident == 30 ) { return 256         } # SQL_MAXIMUM_COLUMN_NAME_LENGTH
        elsif ($ident == 31 ) { return 64          } # SQL_MAXIMUM_CURSOR_NAME_LENGTH
        elsif ($ident == 32 ) { return 32          } # SQL_MAXIMUM_SCHEMA_NAME_LENGTH
        elsif ($ident == 35 ) { return 256         } # SQL_MAXIMUM_TABLE_NAME_LENGTH
        elsif ($ident == 107) { return 32          } # SQL_MAXIMUM_USER_NAME_LENGTH
        elsif ($ident == 21 ) { return 'Y'         } # SQL_PROCEDURES
        elsif ($ident == 40 ) { return 'PROCEDURE' } # SQL_PROCEDURE_TERM
        elsif ($ident == 41 ) { return '.'         } # SQL_QUALIFIER_NAME_SEPARATOR
        elsif ($ident == 39 ) { return 'USER'      } # SQL_SCHEMA_TERM
        elsif ($ident == 45 ) { return 'TABLE'     } # SQL_TABLE_TERM
        else  { return } # Unknown

    }


    sub ping {
        my($dbh) = @_;
        # we know that DBD::IngresII prepare does a describe so this will
        # actually talk to the server and is this a valid and cheap test.
        return 1 if $dbh->prepare('select * from iitables');
        return 0;
    }

    sub type_info_all {
        my ($dbh) = @_;
        my $ti = [
            {
                TYPE_NAME          => 0,
                DATA_TYPE          => 1,
                COLUMN_SIZE        => 2,
                LITERAL_PREFIX     => 3,
                LITERAL_SUFFIX     => 4,
                CREATE_PARAMS      => 5,
                NULLABLE           => 6,
                CASE_SENSITIVE     => 7,
                SEARCHABLE         => 8,
                UNSIGNED_ATTRIBUTE => 9,
                FIXED_PREC_SCALE   => 10,
                AUTO_UNIQUE_VALUE  => 11,
                LOCAL_TYPE_NAME    => 12,
                MINIMUM_SCALE      => 13,
                MAXIMUM_SCALE      => 14,
                SQL_DATA_TYPE      => 15,
                SQL_DATETIME_SUB   => 16,
                NUM_PREC_RADIX     => 17,
                INTERVAL_PRECISIO  => 18,
            },
            [ 'SMALLINT',     DBI::SQL_SMALLINT,
                undef, "","",  undef, 1, 0, 2, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'INTEGER',      DBI::SQL_INTEGER,
                undef, "","", "size=1,2,4", 1, 0, 2, 0, 0 ,0 ,undef ,0 ,0, undef, undef, undef, undef ],
            [ 'MONEY',        DBI::SQL_DECIMAL,
                undef, "","",  undef, 1, 0, 2, 0, 1, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'FLOAT',        DBI::SQL_DOUBLE,
                undef, "","", "size=4,8", 1, 0, 2, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'ANSIDATE',     DBI::SQL_DATE,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'DECIMAL',      DBI::SQL_DECIMAL,
                undef, "","", "precision,scale", 1, 0, 2, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'VARCHAR',      DBI::SQL_VARCHAR,
                undef, "'","'", "max length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'BOOLEAN',      DBI::SQL_INTEGER,
                undef, "","", undef, 1, 0, 2, 0, 0 ,0 ,undef ,0 ,0, undef, undef, undef, undef ],
            [ 'BYTE VARYING', DBI::SQL_VARBINARY,
                undef, "'","'", "max length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'C',         DBI::SQL_CHAR,
                undef, "'","'", "length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'CHAR',         DBI::SQL_CHAR,
                undef, "'","'", "length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'NCHAR',         DBI::SQL_BINARY,
                undef, "'","'", "length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'NVARCHAR',      DBI::SQL_VARBINARY,
                undef, "'","'", "length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'BYTE',         DBI::SQL_BINARY,
                undef, "'","'", "length", 1, 1, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'LONG VARCHAR', DBI::SQL_LONGVARCHAR,
                undef, undef, undef, undef, 1, 1, 0, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'LONG BYTE',    DBI::SQL_LONGVARBINARY,
                undef, undef, undef, undef, 1, 1, 0, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'TIMESTAMP',    DBI::SQL_DATETIME,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'TIMESTAMP WITH TIME ZONE',    DBI::SQL_DATETIME,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'TIMESTAMP WITH LOCAL TIME ZONE',    DBI::SQL_DATETIME,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'TIME',    DBI::SQL_TIME,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'TIME WITH TIME ZONE',    DBI::SQL_TIME,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'TIME WITH LOCAL TIME ZONE',    DBI::SQL_TIME,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'INTERVAL YEAR TO MONTH',    DBI::SQL_INTERVAL_YEAR_TO_MONTH,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
            [ 'INTERVAL DAY TO SECOND',    DBI::SQL_INTERVAL_DAY_TO_SECOND,
                undef, "'","'", undef, 1, 0, 3, 0, 0, 0, undef, 0, 0, undef, undef, undef, undef ],
        ];
        return $ti;
    }

    sub ing_utf8_quote {
        my ($dbh, $str) = @_;
        my ($new_str, @chars, $is_ascii);

        $str = '' unless defined $str;
        $new_str = '';

        $is_ascii = $str =~ /^[[:ascii:]]*$/;

        unless ($is_ascii || utf8::is_utf8($str)) {
            Carp::carp 'Non-utf8 string passed to ->utf8_quote';
        }

        $str = 'U&' . $dbh->quote($str);

        # Backslashes need to be escaped
        $str =~ s{\\}{\\\\}g;

        return $str if $is_ascii;

        @chars = split //, $str;

        for (@chars) {
            if ($_ !~ /^[[:ascii:]]$/) {
                $new_str .= sprintf '\\+%06x', ord $_;
            }
            else {
                $new_str .= $_;
            }
        }

        return $new_str;
    }

    sub ing_bool_to_str {
        my ($dbh, $bool) = @_;

        unless (defined $bool) {
            return 'NULL';
        }
        elsif ($bool == 0) {
            return 'FALSE';
        }
        elsif ($bool == 1) {
            return 'TRUE';
        }
        else {
            Carp::carp 'Non-boolean passed to ->ing_bool_to_str';
            return;
        }
    }

    sub ing_norm_bool {
        my ($dbh, $bool) = @_;

        return unless defined $bool;
        return $bool ? 1 : 0;
    }

    sub ing_is_vectorwise {
        my $dbh = shift;

        return ($dbh->get_info(17) eq 'Vectorwise');
    }
}


{   package DBD::IngresII::st; # ====== STATEMENT ======
    use strict;

}

1;

__END__

=encoding utf8

=head1 DESCRIPTION

DBD::IngresII is a database driver for the perl DBI system that allows
access to Ingres and Vectorwise databases. It is built on top of the standard
DBI extension and implements the methods that DBI requires.

This document describes the differences between the "generic" DBD and
DBD::IngresII.

=head1 EXTENSIONS/CHANGES

=head2 Connect

  DBI->connect("DBI:IngresII:dbname[;options]");
  DBI->connect("DBI:IngresII:dbname[;options]", user [, password]);
  DBI->connect("DBI:IngresII:dbname[;options]", user [, password], \%attr);

To use DBD::IngresII call C<connect> specifying a I<datasource> option beginning
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

  DBI->connect("DBI:IngresII:mydb", "me", "mypassword")

=item *

with options and no password

  DBI->connect("DBI:IngresII:mydb;-Rmyrole/myrolepassword", "me")

=item *

dynamic vnode

  DBI->connect("DBI:IngresII:@localhost,tcp_ip,II;[login,password]::dbname")

=item *

Ingres/Net database

  DBI->connect("DBI:IngresII:thatnode::thisdb;-xw -l", "him", "hispassword")

=back

and so on.

=head2 AutoCommit Defaults to ON

B<Important>: The DBI spec defines that AutoCommit is B<ON> after connect.
This is the opposite of the normal Ingres default (autocommit B<OFF>).

To reflect this behavior in your code, it is recommended that the
C<connect> call ends with the attributes C<{ AutoCommit =E<gt> 0 }>.

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

DBD::IngresII supports the LONG VARCHAR and LONG BYTE data types
as detailed in L<DBI/"Handling BLOB / LONG / Memo Fields">.

The default value for LongReadLen in DBD::IngresII is 2GB, the maximum
size of a long data type field.  DBD::IngresII dynamically allocates
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

Normally cursors are declared C<READONLY> to increase speed. READONLY
cursors don't create exclusive locks for all the rows selected; this is
the default.

If you need to update a row then you will need to ensure that either

=over 4

=item *

the C<select> statement contains an C<for update of> clause, or

=item *

the C<$dbh-E<gt>prepare> calls includes the attribute
C<{ing_readonly =E<gt> 0}>.

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

B<NOTE> DBD::IngresII version later than 0.19_1 have opened all cursors for
update. This change breaks that behaviour. Sorry if this breaks your code.

=head2 ing_rollback

The DBI docs state that 'Changing C<AutoCommit> from off to on will
trigger a C<commit>'.

Setting ing_rollback to B<on> will change that to 'Changing C<AutoCommit>
from off to on will trigger a C<rollback>'.

Default value is B<off>.

B<NOTE> Since DBD::IngresII version 0.53 ing_rollback has also an impact
on the behavior on C<disconnect> . Earlier versions always did a
C<rollback>, when disconnecting while a transaction was active. Now
despite the state of C<AutoCommit> the action (rollback/commit) is
determined on the state of C<ing_rollback>. If it's on, a rollback is
done, otherwise a commit takes place. So if C<AutoCommit> is off, and
you disconnect without commiting, all your work would be treated like
one big transaction.

Please take that in mind: This is just due to compatibility to other
databases. Correct would be a C<commit> at the end of the transaction,
before disconnecting...

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

=item 'n': UTF-16 string

UTF-16 types - nchar or nvarchar.

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

boolean -> DBI::SQL_BOOLEAN

=item *

c -> DBI::SQL_CHAR

=item *

char -> DBI::SQL_CHAR

=item *

nchar -> DBI::SQL_BINARY

=item *

nvarchar -> DBI::SQL_VARBINARY

=item *

text -> DBI::SQL_CHAR

=item *

byte -> DBI::SQL_BINARY

=item *

varchar -> DBI::SQL_VARCHAR

=item *

byte varying -> DBI::SQL_VARBINARY

=item *

ansidate -> DBI::SQL_DATE

=item *

timestamp -> DBI::SQL_DATETIME

=item *

timestamp with time zone -> DBI::SQL_DATETIME

=item *

timestamp with local time zone -> DBI::SQL_DATETIME

=item *

time -> DBI::SQL_TIME

=item *

time with time zone -> DBI::SQL_TIME

=item *

time with local time zone -> DBI::SQL_TIME

=item *

money -> DBI::SQL_DECIMAL

=item *

decimal -> DBI::SQL_DECIMAL

=item *

long varchar -> DBI::SQL_LONGVARCHAR

=item *

long byte -> DBI::SQL_LONGVARBINARY

=item *

interval year to month -> DBI::SQL_INTERVAL_YEAR_TO_MONTH

=item *

interval day to second -> DBI::SQL_INTERVAL_DAY_TO_SECOND

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

See also the C<$sth-E<gt>{TYPE}> field in the DBI docs.

=head2 ing_ph_ingtypes

    $sth->{ing_ph_ingtypes}           (\@)

Returns an array containing the Ingres types of the columns the
placeholders represent. This is a guess from the context of the
placeholder in the prepared statement. Be aware, that the guess
isn't always correct and sometypes a zero (illegal) type is returned.
Plus negative values indicate nullability of the parameter.
A C<$sth-E<gt>{ing_ph_nullable}> field is to be implemented yet.

=head2 ing_ph_inglengths

    $sth->{ing_ph_inglengths}         (\@)

Returns an array containing the lengths of the placeholders analog to
the $sth->{ing_lengths} field.

=head2 ing_utf8_quote

    # Returns q{U&'Chrz\+000105szcz'}
    $dbh->ing_utf8_quote('Chrząszcz');

Returns quoted string (which prevents SQL injection) with escaped UTF-8
literals.

=head2 ing_bool_to_str

    # Returns 'TRUE':
    $dbh->ing_bool_to_str($hashref->{some_kind_of_true_bool);

Converts boolean returned from Ingres into string. For undef it returns 'NULL',
for 0 - 'FALSE' and for 1 'TRUE'.

=head2 ing_norm_bool

    # Returns 1:
    $dbh->ing_norm_bool(34);

If supplied scalar is true, it returns 1, otherwise it returns 0.
There's one special case - when supplied scalar is undef, C<ing_norm_bool>
returns undef which is translated by DBI to NULL.

=head2 ing_enable_utf8

    $dbh->{ing_enable_utf8} = 1;

By default, this flag is set to 0. When it is enabled, all strings (C<CHAR>,
C<VARCHAR>, C<C>, etc., but not C<NCHAR>/C<NVARCHAR>) retrieved from database
which can be interpreted as valid UTF-8 (but not as valid ASCII), will have
scalar's ("scalar" means "variable" in Perl world) UTF-8 flag set on.

Note that you should use this attribute only if C<II_CHARSET> is set to C<UTF8>.

=head2 ing_is_vectorwise

    # Returns 1 if $dbh is connected to Vectorwise, 0 if it is connected to
    # Ingres

    $dbh->ing_is_vectorwise

This method checks whether database handle is connected to Actian Vectorwise
database.

=head2 ing_empty_isnull

    $dbh->{ing_empty_isnull} = 1;
    # or:
    $sth->{ing_empty_isnull} = 1;

When this attribute is set to 1, then all empty strings passed to C<execute> or
C<bind_param> will be interpreted as NULLs by Ingres.

If you are using this attribute only for statement handle, then you need to set it
before binding params, so it will be honoured.

After creation of statement handle, setting C<ing_empty_isnull> attribute in
database_handle will have no effect on statement handle.

By default it is set to 0.

=head1 FEATURES NOT IMPLEMENTED

=head2 state

  $h->state                (undef)

SQLSTATE is not implemented.

=head2 disconnect_all

Not implemented

=head2 commit and rollback invalidate open cursors

DBD::IngresII should warn when a commit or rollback is isssued on a $dbh
with open cursors.

Possibly a commit/rollback should also undef the $sth's. (This should
probably be done in the DBI-layer as other drivers will have the same
problems).

After a commit or rollback the cursors are all ->finish'ed, i.e., they
are closed and the DBI/DBD will warn if an attempt is made to fetch
from them.

A future version of DBD::IngresII wil possibly re-prepare the statement.

This is needed for

=head2 Cached statements

A new feature in DBI that is not implemented in DBD::IngresII.

=head2 bind_param_inout (Procedure calls)

It is possible to call database procedures from DBD::IngresII. It is B<NOT>
possible to get return values from the procedure.

A solution is underway for support for procedure calls from the DBI.
Until that is defined procedure calls can be implemented as a
DB::Ingres-specific function (like L<get_event>) if the need arises and
someone is willing to do it.

=head1 UNICODE FAQ

In this section I will answer some questions about Unicode and Ingres.

    Q: What is Unicode, and what is UTF-8, are these different words for same
       thing?

    A: Please read perlunitut, especially the "Definitions" section. To read it
       run "perldoc perlunitut" command or type "perlunitut" in your web search
       engine of choice.

    Q: Is it possible to change II_CHARSET after installation of Ingres?

    A: No, it would corrupt database. You need to reinstall Ingres, this time
       with other II_CHARSET.

    Q: I tried your examples and all I get is some garbage.

    A: There are few possibilites what went wrong:

         - You have created database with "createdb -n dbname", not
           "createdb -i dbname".

         - You are printing string to console without encoding it to console
           charset. For example, for polish Windows you need to encode it to
           cp852 encoding.

=head1 UNICODE EXAMPLES

You want to store or retrieve unicode string from Ingres database? Like
with everything in Perl, there's more than one way to do it (TMTOWTDI).
Here are some examples:

    # Example number one, it uses NVARCHAR, and assumes that II_CHARSET is set
    # to UTF8

    # Database must be created with "createdb -i dbname"

    use utf8;

    use Encode;

    my $dbh = DBI->connect("DBI:IngresII:dbname");
    my $sth = $dbh->prepare("CREATE TABLE foobar (str nvarchar(10))");
    $sth->execute;
    $sth = $dbh->prepare("INSERT INTO foobar values (?)");
    $sth->execute(encode('utf-8', 'ąść')); # Instead of utf-8 use charset
                                           # that is specified in II_CHARSET

    $sth = $dbh->prepare("SELECT * FROM foobar");
    $sth->execute;
    my $hashref = $sth->fetchrow_hashref;

    my $variable = decode('utf-16le', $hashref->{str});

Second one:

    # Example number two, it uses VARCHAR, it will work only with II_CHARSET
    # set to UTF8.

    # Database must be created with "createdb -i dbname"

    use utf8;

    use Encode;

    my $dbh = DBI->connect("DBI:IngresII:dbname");
    my $sth = $dbh->prepare("CREATE TABLE foobar (str varchar(10))");
    $sth->execute;
    $sth = $dbh->prepare("INSERT INTO foobar values (?)");
    $sth->execute('ąść');

    $sth = $dbh->prepare("SELECT * FROM foobar");
    $sth->execute;
    my $hashref = $sth->fetchrow_hashref;

    my $variable = decode('utf-8', $hashref->{str});

Third:

    # Example number three, it uses VARCHAR, it will work only with II_CHARSET
    # set to UTF8.
    # Now we will use automatic UTF-8 handling.

    # Database must be created with "createdb -i dbname"

    use utf8;

    use Encode;

    my $dbh = DBI->connect("DBI:IngresII:dbname");
    $dbh->{ing_enable_utf8} = 1; # Enable UTF-8 support
    my $sth = $dbh->prepare("CREATE TABLE foobar (str varchar(10))");
    $sth->execute;
    $sth = $dbh->prepare("INSERT INTO foobar values (?)");
    $sth->execute('ąść');

    $sth = $dbh->prepare("SELECT * FROM foobar");
    $sth->execute;
    my $hashref = $sth->fetchrow_hashref;

    my $variable = $hashref->{str}; # No need to decode.

Fourth:

    # Example number three, it uses VARCHAR, it will work only with II_CHARSET
    # set to UTF8.
    # Now we will use automatic UTF-8 handling.

    # Database must be created with "createdb -i dbname"

    use utf8;

    use Encode;

    my $dbh = DBI->connect("DBI:IngresII:dbname");
    $dbh->{ing_enable_utf8} = 1; # Enable UTF-8 support
    my $sth = $dbh->prepare("CREATE TABLE foobar (str varchar(10))");
    $sth->execute;
    my $input = $dbh->ing_utf8_quote('ąść');
    $sth = $dbh->prepare("INSERT INTO foobar values ($input)");
    $sth->execute;

    $sth = $dbh->prepare("SELECT * FROM foobar");
    $sth->execute;
    my $hashref = $sth->fetchrow_hashref;

    my $variable = $hashref->{str}; # No need to decode.

=head1 INSTALLATION

You can install C<DBD::IngresII> manually, or use CPAN.


=over 4

=item *

Manual installation with basic tests (if you are using Windows, use C<set>
instead of C<export> and C<dmake> or C<nmake> instead of C<make>:

    perl Makefile.PL
    export DBI_DSN=<my-favourite-test-database-dsn>
    make
    make test
    make install

Instead of C<DBI_DSN>, you can use C<DBI_DBNAME> which should contain name of
desired test database.

=item *

Manual installation with full tests (requires database created with C<-i> flag
and C<II_CHARSET> must be set to C<UTF8>).

    perl Makefile.PL
    export DBI_TEST_NCHAR=1
    export DBI_TEST_UTF8=1
    export DBI_DSN=<my-favourite-test-database-dsn>
    make
    make test
    make install

=item *

Automatic installation with CPAN.

    export DBI_DSN=<my-favourite-test-database-dsn>
    cpan install DBD::IngresII

=back

=head1 SUCCESSFULLY TESTED PLATFORMS

=over 4

=item *

Ingres 10S Enterprise Build 126 + Solaris 10 + gcc on x86

=item *

Vectorwise 2.5.1 Enterprise Build 162 + Windows + Visual C++ on x64

=item *

Ingres 10.1 Community Build 125 + Windows + Visual C++ on x64

=item *

Ingres 10.1 Community Build 125 + Windows + MinGW on x64

=item *

Ingres 10.1 Community Build 125 + Linux + gcc on x64

=item *

Ingres 10S Enterprise Build 126 + Windows + Visual C++ on x86

=item *

Ingres 10.1 Community Build 121 + Windows + Visual C++ on x86

=item *

Ingres 10.1 Community Build 121 + Windows + MinGW on x86

=item *

Ingres 10.1 Community Build 121 + Windows + Visual C++ on x64

=item *

Ingres 10.1 Community Build 121 + Windows + MinGW on x64

=item *

Ingres 10.1 Community Build 120 + Linux + gcc on x86

=item *

Ingres 10.1 Community Build 120 + Linux + gcc on x64

=item *

Ingres 9.2.3 Enterprise Build 101 + Windows + Visual C++ on x86

=back

=head1 NOTES

=head2 $dbh->table_info, $dbh->column_info, $dbh->get_info

The table_info and column_info functions are just working against tables.
Views and synonyms still have to be implemented. The get_info function
returns just the newer version strings correctly, since I'm still looking
for documentation for the older ones.

I wonder if I have forgotten something?

=head1 IF YOU HAVE PROBLEMS

There are few places where you can seek help:

=over 4

=item *

Actian community forums - C<http://community.actian.com/forum/>

=item *

Ingres usenet group - C<comp.databases.ingres>

=item *

Myself - C<me@xenu.tk>

=back

=head1 FOSSIL REPOSITORY

DBD::IngresII Fossil repository is hosted at xenu.tk:

    http://code.xenu.tk/repos.cgi/dbd-ingresii

=head1 REPORTING BUGS

Please report bugs at CPAN RT:

    https://rt.cpan.org/Public/Dist/Display.html?Name=DBD-IngresII

Please include full details of which version of Ingres/esql, operating system
and Perl you're using. If you are on Windows, include name of Perl distribution
that you are using (i.e. "ActivePerl" or "Strawberry Perl").

=head1 KNOWN PROBLEMS

TODO

=head1 AUTHORS

DBI/DBD was developed by Tim Bunce, <Tim.Bunce@ig.co.uk>, who also
developed the DBD::Oracle that is the closest we have to a generic DBD
implementation.

Henrik Tougaard, <htoug@cpan.org> developed the DBD::Ingres extension.

Stefan Reddig, <sreagle@cpan.org> is currently (2008) adopting it to
include some more features.

Tomasz Konojacki <me@xenu.tk> has forked DBD::Ingres to DBD::IngresII.

=head1 CONTRIBUTORS

Sorted from latest contribution to first one. If I forgot about someone, mail me
at me@xenu.tk.

=over 4

=item *

Dennis Roesler

=item *

Geraint Jones

=item *

Remy Chibois

=item *

Mike Battersby

=item *

Tim Bunce

=item *

Dirk Kraemer

=item *

Sebastian Bazley

=item *

Bernard Royet

=item *

Bruce W. Hoylman

=item *

Alan Murray

=item *

Dirk Koopman

=item *

Ulrich Pfeifer

=item *

Jochen Wiedmann

=item *

Gil Hirsch

=item *

Paul Lindner

=back

=cut

=head1 SEE ALSO

The DBI documentation in L<DBI> and L<DBI::DBD>.