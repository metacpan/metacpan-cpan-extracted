#   Copyright (c) 1999-2015 H.Merijn Brand
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

require 5.006;

use strict;
use warnings;

package DBD::Unify;

our $VERSION = "0.87";

=head1 NAME

DBD::Unify - DBI driver for Unify database systems

=head1 SYNOPSIS

 # Examples marked NYT are Not Yet Tested, they might work
 #  all others have been tested.
 # man DBI for explanation of each method (there's more than listed here)

 $dbh = DBI->connect ("DBI:Unify:[\$dbname]", "", $schema, {
                         AutoCommit    => 0,
                         ChopBlanks    => 1,
                         uni_unicode   => 0,
                         uni_verbose   => 0,
                         uni_scanlevel => 2,
                         });
 $dbh = DBI->connect_cached (...);                   # NYT
 $dbh->do ($statement);
 $dbh->do ($statement, \%attr);
 $dbh->do ($statement, \%attr, @bind);
 $dbh->commit;
 $dbh->rollback;
 $dbh->disconnect;

 $all = $dbh->selectall_arrayref ($statement);
 @row = $dbh->selectrow_array ($statement);
 $col = $dbh->selectcol_arrayref ($statement);

 $sth = $dbh->prepare ($statement);
 $sth = $dbh->prepare ($statement, \%attr);
 $sth = $dbh->prepare_cached ($statement);           # NYT
 $sth->execute;
 @row = $sth->fetchrow_array;
 $row = $sth->fetchrow_arrayref;
 $row = $sth->fetchrow_hashref;
 $all = $sth->fetchall_arrayref;
 $sth->finish;

 # Statement has placeholders like where field = ?
 $sth = $dbh->prepare ($statement);
 $sth->bind_param ($p_num, $bind_value);             # NYT
 $sth->bind_param ($p_num, $bind_value, $bind_type); # NYT
 $sth->bind_param ($p_num, $bind_value, \%attr);     # NYT
 $sth->bind_col ($col_num, \$col_variable);          # NYT
 $sth->bind_columns (@list_of_refs_to_vars_to_bind);
 $sth->execute (@bind_values);

 $cnt = $sth->rows;

 $sql = $dbh->quote ($string);

 $err = $dbh->err;
 $err = $sth->err;
 $str = $dbh->errstr;
 $str = $sth->errstr;
 $stt = $dbh->state;
 $stt = $sth->state;

 For large DB fetches the combination $sth->bind_columns ()
 with $sth->fetchrow_arrayref is the fastest (DBI
 documentation).

=cut

# The POD text continues at the end of the file.

###############################################################################

use Carp;
use DBI 1.42;

use DynaLoader ();
use vars qw(@ISA);
@ISA = qw(DynaLoader);
bootstrap DBD::Unify $VERSION;

use vars qw($err $errstr $state $drh);
$err    = 0;		# holds error code   for DBI::err
$errstr = "";		# holds error string for DBI::errstr
$state  = "";		# holds SQL state    for DBI::state
$drh    = undef;	# holds driver handle once initialized

sub driver
{
    return $drh if $drh;
    my ($class, $attr) = @_;

    $class .= "::dr";

    # not a 'my' since we use it above to prevent multiple drivers
    $drh = DBI::_new_drh ($class, {
	Name         => "Unify",
	Version      => $VERSION,
	Err          => \$DBD::Unify::err,
	Errstr       => \$DBD::Unify::errstr,
	State        => \$DBD::Unify::state,
	Attribution  => "DBD::Unify by H.Merijn Brand",
	});

    $drh;
    } # driver

1;

####### Driver ################################################################

package DBD::Unify::dr;

$DBD::Unify::dr::imp_data_size = 0;

sub connect
{
    my ($drh, $dbname, $user, $auth) = @_;

    unless ($ENV{UNIFY} && -d $ENV{UNIFY} && -x _) {
	$drh->{Warn} and
	    Carp::croak "\$UNIFY not set or invalid. UNIFY may fail\n";
	}
    # More checks here if wanted ...

    $user = "" unless defined $user;
    $auth = "" unless defined $auth;

    # create a 'blank' dbh
    my $dbh = DBI::_new_dbh ($drh, {
	Name          => $dbname,
	USER          => $user,
	CURRENT_USER  => $user,
	});

    # Connect to the database..
    DBD::Unify::db::_login ($dbh, $dbname, $user, $auth) or return;

#   if ($attr) {
#	if ($attr->{dbd_verbose}) {
#	    $dbh->trace ("DBD");
#	    }
#	}

    $dbh;
    } # connect

sub data_sources
{
    my ($drh) = @_;
    $drh->{Warn} and
	Carp::carp "\$drh->data_sources () not defined for Unify\n";
    "";
    } # data_sources

1;

####### Database ##############################################################

package DBD::Unify::db;

$DBD::Unify::db::imp_data_size = 0;

sub parse_trace_flag
{
    my ($dbh, $name) = @_;
  # print STDERR "# Flags: $name\n";
    return 0x7FFFFF00 if $name eq "DBD";	# $h->trace ("DBD"); -- ALL
  # return 0x01000000 if $name eq "select";	# $h->trace ("SQL|select");
  # return 0x02000000 if $name eq "update";	# $h->trace ("1|update");
  # return 0x04000000 if $name eq "delete";
  # return 0x08000000 if $name eq "insert";
    return $dbh->SUPER::parse_trace_flag ($name);
    } # parse_trace_flag

sub type_info_all
{
    my ($dbh) = @_;
    require DBD::Unify::TypeInfo;
    return [ @$DBD::Unify::TypeInfo::type_info_all ];
    } # type_info_all

sub get_info
{
    my ($dbh, $info_type) = @_;
    require  DBD::Unify::GetInfo;
    my $v = $DBD::Unify::GetInfo::info{int $info_type};
    ref $v eq "CODE" and $v = $v->($dbh);
    return $v;
    } # get_info

sub private_attribute_info
{
    return { 
	dbd_verbose	=> undef,

	uni_verbose	=> undef,
	uni_unicode	=> undef,
	};
    } # private_attribute_info

sub ping
{
    my $dbh = shift;
    $dbh->prepare ("select USER_NAME from SYS.DATABASE_USERS") or return 0;
    return 1;
    } # ping

sub prepare
{
    my ($dbh, $statement, @attribs) = @_;

    # Strip comments
    $statement = join "" => map {
	my $s = $_;
	$s =~ m/^'.*'$/ or $s =~ s/(--.*)$//m;
	$s;
	} split m/('[^']*')/ => $statement;
    # create a 'blank' sth
    my $sth = DBI::_new_sth ($dbh, {
	Statement => $statement,
	});

    # Setup module specific data
#   $sth->STORE ("driver_params" => []);
#   $sth->STORE ("NUM_OF_PARAMS" => ($statement =~ tr/?//));

    DBD::Unify::st::_prepare ($sth, $statement, @attribs) or return;

    $sth;
    } # prepare

sub _is_or_like
{
    my ($fld, $val) = @_;
    $val =~ m/[_%]/ ? "$fld like '$val'" : "$fld = '$val'";
    } # _is_or_like

sub table_info
{
    my $dbh = shift;
    my ($catalog, $schema, $table, $type, $attr);
    ref $_[0] or ($catalog, $schema, $table, $type) = splice @_, 0, 4;
    if ($attr = shift) {
	ref ($attr) eq "HASH" or
	    Carp::croak qq{usage: table_info ({ TABLE_NAME => "foo", ... })};
	exists $attr->{TABLE_SCHEM} and $schema = $attr->{TABLE_SCHEM};
	exists $attr->{TABLE_NAME}  and $table  = $attr->{TABLE_NAME};
	exists $attr->{TABLE_TYPE}  and $type   = $attr->{TABLE_TYPE};
	}
    if ($catalog) {
	$dbh->{Warn} and
	    Carp::carp "Unify does not support catalogs in table_info\n";
	return;
	}

    my @where;
    $schema and push @where, _is_or_like ("OWNR",       $schema);
    $table  and push @where, _is_or_like ("TABLE_NAME", $table);
    $type   and $type = uc substr $type, 0, 1;
    $type   and push @where, _is_or_like ("TABLE_TYPE", $type);
    local $" = " and ";
    my $where = @where ? " where @where" : "";
    my $sth = $dbh->prepare (
	"select '', OWNR, TABLE_NAME, TABLE_TYPE, RDWRITE ".
	"from   SYS.ACCESSIBLE_TABLES ".
	$where);
    $sth or return;
    $sth->{ChopBlanks} = 1;
    $sth->execute;
    $sth;
    } # table_info

sub column_info
{
    my $dbh = shift;
    my ($catalog, $schema, $table, $column);
    ref $_[0] or ($catalog, $schema, $table, $column) = splice @_, 0, 4;
    if ($catalog) {
	$dbh->{Warn} and
	    Carp::carp "Unify does not support catalogs in column_info\n";
	return;
	}
    my @where;
    $schema and push @where, "OWNR        like '$schema'";
    $table  and push @where, "TABLE_NAME  like '$table'";
    $column and push @where, "COLUMN_NAME like '$column'";
    local $" = " and ";
    my $where = @where ? " where @where" : "";
    my $sth = $dbh->prepare (
	"select OWNR, TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_LENGTH, DATA_SCALE, DISPLAY_LENGTH, DISPLAY_SCALE, NULLABLE, RDNLY, PRIMRY, UNIQ, LOGGED, ORDERED ".
	"from   SYS.ACCESSIBLE_COLUMNS ".
	$where);
    $sth or return;
    $sth->execute;
    my @fki;
    require DBD::Unify::TypeInfo;
    while (my @sli = $sth->fetchrow_array) {
	my $uni_type_name = $sli[3];
	   $uni_type_name =~ s/^CHARACTER$/CHAR/;
	   $uni_type_name =~ s/^DOUBLE$/DOUBLE PRECISION/;
	my $uni_type = DBD::Unify::TypeInfo::uni_type ($uni_type_name);
	my $odbc_type = (
	    $uni_type_name eq "NUMERIC" && $sli[4] <= 4 ? 5 : # SMALLINT
	    DBD::Unify::_uni2sql_type ($uni_type) ) || 0;
	push @fki, [
	    # TABLE_CAT, TABLE_SCHEM, TABLE_NAME, COLUMN_NAME,
	    undef, @sli[0..2],
	    # DATA_TYPE, TYPE_NAME,
	    $odbc_type, DBD::Unify::TypeInfo::odbc_type ($odbc_type),
	    # COLUMN_SIZE, BUFFER_LENGTH, DECIMAL_DIGITS, NUM_PREC_RADIX,
	    $sli[4], undef, $sli[5], undef,
	    # NULLABLE,
	    $sli[8] eq "N" ? 0 : $sli[8] eq "Y" ? 1 : 2,
	    # REMARKS, COLUMN_DEF, SQL_DATA_TYPE, SQL_DATETIME_SUB,
	    undef, undef, undef, undef,
	    # CHAR_OCTET_LENGTH, ORDINAL_POSITION, IS_NULLABLE
	    undef, undef, undef,

	    # CHAR_SET_CAT, CHAR_SET_SCHEM, CHAR_SET_NAME, COLLATION_CAT,
	    # COLLATION_SCHEM, COLLATION_NAME, UDT_CAT, UDT_SCHEM, UDT_NAME,
	    # DOMAIN_CAT, DOMAIN_SCHEM, DOMAIN_NAME, SCOPE_CAT, SCOPE_SCHEM,
	    # SCOPE_NAME, MAX_CARDINALITY, DTD_IDENTIFIER, IS_SELF_REF,
	    undef, undef, undef, undef, undef, undef, undef, undef, undef,
	    undef, undef, undef, undef, undef, undef, undef, undef, undef,

	    # uni_type, uni_type_name
	    $uni_type, $uni_type_name,

	    # uni_display_length, uni_display_scale, uni_rdonly, uni_primry,
	    # uni_uniq, uni_logged, uni_ordered
	    @sli[6,7,9..13],
	    ];
	}
    $sth->finish;
    $sth = undef;

    my @col_name = qw(
	TABLE_CAT TABLE_SCHEM TABLE_NAME
	COLUMN_NAME DATA_TYPE TYPE_NAME COLUMN_SIZE BUFFER_LENGTH
	DECIMAL_DIGITS NUM_PREC_RADIX NULLABLE

	REMARKS COLUMN_DEF SQL_DATA_TYPE SQL_DATETIME_SUB CHAR_OCTET_LENGTH
	ORDINAL_POSITION IS_NULLABLE

	CHAR_SET_CAT CHAR_SET_SCHEM CHAR_SET_NAME COLLATION_CAT COLLATION_SCHEM
        COLLATION_NAME UDT_CAT UDT_SCHEM UDT_NAME DOMAIN_CAT DOMAIN_SCHEM
        DOMAIN_NAME SCOPE_CAT SCOPE_SCHEM SCOPE_NAME MAX_CARDINALITY
        DTD_IDENTIFIER IS_SELF_REF

	uni_type uni_type_name

	uni_display_length uni_display_scale uni_rdonly uni_primry
	uni_uniq uni_logged uni_ordered
	);
    DBI->connect ("dbi:Sponge:", "", "", {
	RaiseError       => $sth->{RaiseError},
	PrintError       => $sth->{PrintError},
	ChopBlanks       => 1,
	FetchHashKeyName => $sth->{FetchHashKeyName} || "NAME",
	})->prepare ("select column_info $where", {
	    rows => \@fki,
	    NAME => \@col_name,
	    });
    } # column_info

my $info_cache;

sub primary_key
{
    my $dbh = shift;
    my ($catalog, $schema, $table) = @_;
    if ($catalog) {
	$dbh->{Warn} and
	    Carp::carp "Unify does not support catalogs in table_info\n";
	return;
	}

    # Fetching table information from SYS is *extremely* slow
    # Feel free to add your home-grown caching or prepared knowledge here
    my @key = eval {
	require PROCURA::U2000;
	PROCURA::U2000::get_key ($schema, $table);
	};
    @key and return @key;

    unless ($info_cache) {
	# Note that PRIMRY is *only* set for tables with *ONE* key field
	# for composite keys this doesn't work :(
	my $sth = $dbh->prepare (
	    "select COLUMN_NAME, OWNR, TABLE_NAME ".
	    "from   SYS.ACCESSIBLE_COLUMNS ".
	    "where  PRIMRY = 'Y'") or return;
	$sth->{ChopBlanks} = 1;
	$sth->execute or return;

	$sth->bind_columns (\my ($fld, $sch, $tbl));
	while ($sth->fetch) {
	    #warn "* $sch.$tbl.$fld\n";
	    push @{$info_cache->{key}{$sch}{$tbl}}, $fld;
	    }

	# For tables with a combined key, we need to analyse the automatic
	# added HASH_INDEX for those tables
	if (my $hth = $dbh->prepare (
		"select   OWNR, TABLE_NAME, COLUMN_NAME, COLUMN_ORD ".
		"from     SYS.HASH_INDEXES_G ".
		"where    UNIQUE_SPEC = 'Y' ".
		"order by OWNR, TABLE_NAME, COLUMN_ORD")) {
	    $hth->{ChopBlanks} = 1;
	    $hth->execute or return;
	    $hth->bind_columns (\my ($sch, $tbl, $fld, $ord));
	    while ($hth->fetch) {
		#warn "$ord $sch.$tbl.$fld\n";
		push @{$info_cache->{key}{$sch}{$tbl}}, $fld;
		}
	    }
	}
    $info_cache && $info_cache->{key} or return;

    foreach my $sch (sort keys %{$info_cache->{key}}) {
	defined $schema && lc $sch ne lc $schema and next;
	foreach my $tbl (sort keys %{$info_cache->{key}{$sch}}) {
	    defined $table && lc $tbl ne lc $table and next;
	    push @key, @{$info_cache->{key}{$sch}{$tbl}};
	    }
	}
    return @key;
    } # primary_key

sub quote_identifier
{
    my ($dbh, @arg) = map { defined $_ && $_ ne "" ? $_ : undef } @_;
    return $dbh->SUPER::quote_identifier (@arg);
    } # quote_identifier

# $sth = $dbh->foreign_key_info (
#            $pk_catalog, $pk_schema, $pk_table,
#            $fk_catalog, $fk_schema, $fk_table,
#            \%attr);
sub foreign_key_info
{
    my $dbh = shift;
    my ($Pcatalog, $Pschema, $Ptable,
	$Fcatalog, $Fschema, $Ftable, $attr) = (@_, {});

    my @where;
    $Pschema and push @where, "REFERENCED_OWNER  = '$Pschema'";
    $Ptable  and push @where, "REFERENCED_TABLE  = '$Ptable'";
    $Fschema and push @where, "REFERENCING_OWNER = '$Fschema'";
    $Ftable  and push @where, "REFERENCING_TABLE = '$Ftable'";

    my $where = @where ? "where " . join " and " => @where : "";
    my $sth = $dbh->prepare (join "\n",
	"select INDEX_NAME, ",
	"       REFERENCED_OWNER,  REFERENCED_TABLE,  REFERENCED_COLUMN,",
	"       REFERENCING_OWNER, REFERENCING_TABLE, REFERENCING_COLUMN,",
	"       REFERENCING_COLUMN_ORD",
	"from   SYS.LINK_INDEXES",
	$where);
    $sth or return;
    $sth->{ChopBlanks} = 1;
    $sth->execute or return;
    my @fki;
    while (my @sli = $sth->fetchrow_array) {
	push @fki, [
	    undef, @sli[1..3],
	    undef, @sli[4..6], $sli[7] + 1,
	    undef, undef,
	    $sli[0], undef,
	    undef, undef
	    ];
	}
    $sth->finish;
    undef $sth;

    my @col_name = qw(
	UK_TABLE_CAT UK_TABLE_SCHEM UK_TABLE_NAME UK_COLUMN_NAME
	FK_TABLE_CAT FK_TABLE_SCHEM FK_TABLE_NAME FK_COLUMN_NAME
	ORDINAL_POSITION

	UPDATE_RULE DELETE_RULE
	FK_NAME UK_NAME
	DEFERABILITY UNIQUE_OR_PRIMARY );
    DBI->connect ("dbi:Sponge:", "", "", {
	RaiseError       => $sth->{RaiseError},
	PrintError       => $sth->{PrintError},
	ChopBlanks       => 1,
	FetchHashKeyName => $sth->{FetchHashKeyName} || "NAME",
	})->prepare ("select link_info $where", {
	    rows => \@fki,
	    NAME => \@col_name,
	    });
    } # foreign_key_info

# type = "R" ? references me : references
# This is to be converted to foreign_key_info
sub link_info
{
    my $dbh = shift;
    my ($catalog, $schema, $table, $type, $attr);
    ref $_[0] or ($catalog, $schema, $table, $type) = splice @_, 0, 4;
    if ($attr = shift) {
	ref ($attr) eq "HASH" or
	    Carp::croak qq{usage: link_info ({ TABLE_NAME => "foo", ... })};
	exists $attr->{TABLE_SCHEM} and $schema = $attr->{TABLE_SCHEM};
	exists $attr->{TABLE_NAME}  and $table  = $attr->{TABLE_NAME};
	exists $attr->{TABLE_TYPE}  and $type   = $attr->{TABLE_TYPE};
	}
    my @where;
    unless ($type and $type =~ m/^[Rr]/) {
	$schema and push @where, "REFERENCING_OWNER = '$schema'";
	$table  and push @where, "REFERENCING_TABLE = '$table'";
	}
    else {
	$schema and push @where, "REFERENCED_OWNER  = '$schema'";
	$table  and push @where, "REFERENCED_TABLE  = '$table'";
	}
    local $" = " and ";
    my $where = @where ? " where @where" : "";
    my $sth = $dbh->prepare (join "\n",
	"select '', REFERENCED_OWNER, INDEX_NAME, REFERENCED_TABLE,",
	"       REFERENCED_COLUMN, REFERENCED_COLUMN_ORD,",
	"       REFERENCING_OWNER, REFERENCING_TABLE, REFERENCING_COLUMN,",
	"       REFERENCING_COLUMN_ORD ",
	"from   SYS.LINK_INDEXES",
	$where);
    $sth or return;
    $sth->{ChopBlanks} = 1;
    $sth->execute;
    $sth;
    } # link_info

*DBI::db::link_info = \&link_info;

1;

####### Statement #############################################################

package DBD::Unify::st;

sub private_attribute_info
{
    return { 
	uni_type	=> undef,
	};
    } # private_attribute_info

1;

####### End ###################################################################

=head1 DESCRIPTION

DBD::Unify is an extension to Perl which allows access to Unify
databases. It is built on top of the standard DBI extension and
implements the methods that DBI requires.

This document describes the differences between the "generic" DBD
and DBD::Unify.

=head2 Extensions/Changes

=over 2

=item returned types

The DBI docs state that:

   Most data is returned to the perl script as strings (null values
   are returned as undef).  This allows arbitrary precision numeric
   data to be handled without loss of accuracy.  Be aware that perl
   may  not preserve the same accuracy when the string is used as a
   number.

Integers are returned as integer values (perl's IV's).

(Huge) amounts, floats, reals and doubles are returned as strings for which
numeric context (perl's NV's) has been invoked already, so adding zero to
force convert to numeric context is not needed.

Chars are returned as strings (perl's PV's).

Chars, Dates, Huge Dates and Times are returned as strings (perl's PV's).
Unify represents midnight with 00:00, not 24:00.

=item connect

    connect ("DBI:Unify:dbname[;options]" [, user [, auth [, attr]]]);

Options to the connection are passed in the data-source
argument. This argument should contain the database
name possibly followed by a semicolon and the database options
which are ignored.

Since Unify database authorization is done using grant's using the
user name, the I<user> argument may be empty or undef. The I<auth>
field will be used as a default schema. If the I<auth> field is empty
or undefined connect will check for the environment variable $USCHEMA
to use as a default schema. If neither exists, you will end up in your
default schema, or if none is assigned, in the schema PUBLIC.

At the moment none of the attributes documented in DBI's "ATTRIBUTES
COMMON TO ALL HANDLES" are implemented specifically for the Unify
DBD driver, but they might have been inherited from DBI. The I<ChopBlanks>
attribute is implemented, but defaults to 1 for DBD::Unify.
The Unify driver supports "uni_scanlevel" to set the transaction scan
level to a value between 1 and 16 and "uni_verbose" to set DBD specific
debugging, allowing to show only massages from DBD-Unify without using
the default DBI->trace () call.

The connect call will result in statements like:

    CONNECT;
    SET CURRENT SCHEMA TO PUBLIC;  -- if auth = "PUBLIC"
    SET TRANSACTION SCAN LEVEL 7;  -- if attr has { uni_scanlevel => 7 }

local database

    connect ("/data/db/unify/v63AB", "", "SYS")

=item AutoCommit

It is recommended that the C<connect> call ends with the attributes
S<{ AutoCommit => 0 }>, although it is not implemented (yet).

If you don't want to check for errors after B<every> call use
S<{ AutoCommit => 0, RaiseError => 1 }> instead. This will C<die> with
an error message if any DBI call fails.

=item Unicode

By default, this driver is completely Unicode unaware: what you put into
the database will be returned to you without the encoding applied.

To enable automatic decoding of UTF-8 when fetching from the database,
set the C<uni_unicode> attribute to a true value for the database handle
(statement handles will inherit) or to the statement handle.

  $dbh->{uni_unicode} = 1;

When CHAR or TEXT fields are retrieved and the content fetched is valid
UTF-8, the value will be marked as such.

=item re-connect

Though both the syntax and the module support connecting to different
databases, even at the same time, the Unify libraries seem to quit
connecting to a new database, even if the old one is closed following
every rule of precaution.

To be safe in closing a handle of all sorts, undef it after it is done with,
it will than be destroyed. (As of 0.12 this is tried internally for handles
that proved to be finished)

explicit:

 my $dbh = DBI->connect (...);
 my $sth = $dbh->prepare (...);
 :
 $sth->finish;     undef $sth;
 $dbh->disconnect; undef $dbh;

or implicit:

 {   my $dbh = DBI->connect (...);
     {   my $sth = $dbh->prepare (...);
         while (my @data = $sth->fetchrow_array) {
             :
             }
         }  # $sth implicitly destroyed by end-of-scope
     $dbh->disconnect;
     }  # $dbh implicitly destroyed by end-of-scope

=item do

 $dbh->do ($statement)

This is implemented as a call to 'EXECUTE IMMEDIATE' with all the
limitations that this implies.

=item commit and rollback invalidates open cursors

DBD::Unify does warn when a commit or rollback is issued on a $dbh
with open cursors.

Possibly a commit/rollback/disconnect should also undef the $sth's.
(This should probably be done in the DBI-layer as other drivers will
have the same problems).

After a commit or rollback the cursors are all ->finish'ed, i.e. they
are closed and the DBI/DBD will warn if an attempt is made to fetch
from them.

A future version of DBD::Unify might re-prepare the statement.

=back

=head2 Stuff implemented in perl

=over 2

=item driver

Just here for DBI. No use in telling the end-user what to do with it :)

=item connect

=item data_sources

There is no way for Unify to tell what data sources might be available.
There is no central files (like /etc/oratab for Oracle) that lists all
available sources, so this method will always return an empty list.

=item quote_identifier

As DBI's C<quote_identifier ()> gladly accepts the empty string as a
valid identifier, I have to override this method to translate empty
strings to undef, so the method behaves properly. Unify does not allow
to select C<NULL> as a constant as in:

    select NULL, foo from bar;

=item prepare ($statement [, \%attr])

The only attribute currently supported is the C<dbd_verbose> (or its
alias C<uni_verbose>) level. See "trace" below.

=item table_info ($;$$$$)

=item columne_info ($$$$)

=item foreign_key_info ($$$$$$;$)

=item link_info ($;$$$$)

=item primary_key ($$$)

Note that these five get their info by accessing the C<SYS> schema which
is relatively extremely slow. e.g. Getting all the primary keys might well
run into seconds, rather than milliseconds.

This is work-in-progress, and we hope to find faster ways to get to this
information. Also note that in order to keep it fast across multiple calls,
some information is cached, so when you alter the data dictionary after a
call to one of these, that cached information is not updated.

For C<column_info ()>, the returned C<DATA_TYPE> is deduced from the
C<TYPE_NAME> returned from C<SYS.ACCESSIBLE_COLUMNS>. The type is in
the ODBC range and the original Unify type and type_name are returned
in the additional fields C<uni_type> and C<uni_type_name>. Somehow
selecting from that table does not return valid statement handles for
types C<currency> and C<huge integer>.

  Create as           sth attributes       uni_type/uni_type_name
  ------------------- -------------------  -------------------------
  amount              FLOAT             6   -4 AMOUNT (9, 2)
  amount (5, 2)       FLOAT             6   -4 AMOUNT (5, 2)
  huge amount         REAL              7   -6 HUGE AMOUNT (15, 2)
  huge amount (5, 2)  REAL              7   -6 HUGE AMOUNT (5, 2)
  huge amount (15, 2) REAL              7   -6 HUGE AMOUNT (15, 2)
  byte                BINARY           -2  -12 BYTE (1)
  byte (512)          BINARY           -2  -12 BYTE (512)
  char                CHAR              1    1 CHAR (1)
  char (12)           CHAR              1    1 CHAR (12)
  currency            DECIMAL           3    - ?
  currency (9)        DECIMAL           3    - ?
  currency (7,2)      DECIMAL           3    - ?
  date                DATE              9   -3 DATE
  huge date           TIMESTAMP        11  -11 HUGE DATE
  decimal             NUMERIC           2    2 NUMERIC (9)
  decimal (2)         NUMERIC           2    2 NUMERIC (2)
  decimal (8)         NUMERIC           2    2 NUMERIC (8)
  double precision    DOUBLE PRECISION  8    8 DOUBLE PRECISION (64)
  float               DOUBLE PRECISION  8    6 FLOAT (64)
  huge integer        HUGE INTEGER     -5    - ?
  integer             NUMERIC           2    2 NUMERIC (9)
  numeric             NUMERIC           2    2 NUMERIC (9)
  numeric (2)         SMALLINT          5    2 NUMERIC (2)
  numeric (6)         NUMERIC           2    2 NUMERIC (6)
  real                REAL              7    7 REAL (32)
  smallint            SMALLINT          5    2 NUMERIC (4)
  text                TEXT             -1   -9 TEXT
  time                TIME             10   -7 TIME

=item ping

=back

=head2 Stuff implemented in C (XS)

=over 2

=item trace

The C<DBI-E<gt>trace (level)> call will promote the level to DBD::Unify,
showing both the DBI layer debugging messages as well as the DBD::Unify
specific driver-side debug messages.

It is however also possible to trace B<only> the DBD-Unify without the
C<DBI-E<gt>trace ()> call by using the C<uni_verbose> attribute on C<connect ()>
or by setting it later to the database handle, the default level is set from
the environment variable C<$DBD_TRACE> if defined:

  $dbh = DBI->connect ("DBI::Unify", "", "", { uni_verbose => 3 });
  $dbh->{uni_verbose} = 3;

As DBD::Oracle also supports this scheme since version 1.22, C<dbd_verbose>
is a portable alias for C<uni_verbose>, which is also supported in DBD::Oracle.

DBD::Unify now also allows an even finer grained debugging, by allowing
C<dbd_verbose> on statement handles too. The default C<dbd_verbose> for
statement handles is the global C<dbd_verbose> at creation time of the
statement handle.

The environment variable C<DBD_VERBOSE> is used if defined and overrules
C<$DBD_TRACE>.

  $dbh->{dbd_verbose} = 4;
  $sth = $dbh->prepare ("select * from foo");  # sth's dbd_verbose = 4
  $dbh->{dbd_verbose} = 3;                     # sth's dbd_verbose = 4
  $sth->{dbd_verbose} = 5;                     # now 5

Currently, the following levels are defined:

=over 2

=item 1 & 2

No DBD messages implemented at level 1 and 2, as they are reserved for DBI

=item Z<>3

  DBD::Unify::dbd_db_STORE (ScanLevel = 7)
  DBD::Unify::st_prepare u_sql_00_000000 ("select * from foo")
  DBD::Unify::st_prepare u_sql_00_000000 (<= 4, => 0)
  DBD::Unify::st_execute u_sql_00_000000
  DBD::Unify::st_destroy 'select * from parm'
  DBD::Unify::st_free u_sql_00_000000
  DBD::Unify::st 0x7F7F25CC 0x0000 0x0000 0x00000000 0x00000000 0x00000000
  DBD::Unify::st destroyed
  DBD::Unify::db_disconnect
  DBD::Unify::db_destroy

=item Z<>4

Level 3 plus errors and additional return codes and field types and values:

  DBD::Unify::st_prepare u_sql_00_000000 ("select c_bar from foo where c_foo = 1")
      After allocate, sqlcode = 0
      After prepare,  sqlcode = 0
      After allocate, sqlcode = 0
      After describe, sqlcode = 0
      After count,    sqlcode = 0, count = 1
  DBD::Unify::fld_describe o_sql_00_000000 (1 fields)
      After get,      sqlcode = 0
  DBD::Unify::st_prepare u_sql_00_000000 (<= 1, => 0)
  DBD::Unify::st_execute u_sql_00_000000
      After open,     sqlcode = 0 (=> 0)
  DBD::Unify::st_fetch u_sql_00_000000
      Fetched         sqlcode = 0, fields = 1
      After get,      sqlcode = 0
       Field   1: c_bar: NUMERIC  4: (6030) 6030 ==
       Fetch done
  DBD::Unify::st_finish u_sql_00_000000
      After close,    sqlcode = 0
  DBD::Unify::st_destroy 'select c_bar from foo where c_foo = 1'
  DBD::Unify::st_free u_sql_00_000000
      After deallocO, sqlcode = 0
      After deallocU, sqlcode = 0

=item Z<>5

Level 4 plus some content info:

  DBD::Unify::st_fetch u_sql_00_000000
      Fetched         sqlcode = 0, fields = 1
      After get,      sqlcode = 0
       Field   1: [05 00 04 00 00] c_bar: NUMERIC  4: (6030) 6030 ==
       Fetch done

=item Z<>6

Level 5 plus internal coding for exchanges and low(er) level return codes:

  DBD::Unify::fld_describe o_sql_00_000000 (1 fields)
      After get,      sqlcode = 0
       Field   1: [05 00 04 00 FFFFFFFF] c_bar
  DBD::Unify::st_prepare u_sql_00_000000 (<= 1, => 0)

=item Z<>7

Level 6 plus destroy/cleanup states:

  DBD::Unify::st_free u_sql_00_000000
   destroy allocc destroy alloco    After deallocO, sqlcode = 0
   destroy alloci destroy allocp    After deallocU, sqlcode = 0
   destroy stat destroy growup destroy impset

=item Z<>8

No messages (yet) set to level 8 and up.

=back

=item int  dbd_bind_ph (SV *sth, imp_sth_t *imp_sth, SV *param, SV *value,

=item SV  *dbd_db_FETCH_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv)

=item int  dbd_db_STORE_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)

=item int  dbd_db_commit (SV *dbh, imp_dbh_t *imp_dbh)

=item void dbd_db_destroy (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_db_disconnect (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_db_do (SV *dbh, char *statement)

=item int  dbd_db_login (SV *dbh, imp_dbh_t *imp_dbh,

=item int  dbd_db_rollback (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_discon_all (SV *drh, imp_drh_t *imp_drh)

=item int  dbd_fld_describe (SV *dbh, imp_sth_t *imp_sth, int num_fields)

=item void dbd_init (dbistate_t *dbistate)

=item int  dbd_prm_describe (SV *dbh, imp_sth_t *imp_sth, int num_params)

=item SV  *dbd_st_FETCH_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv)

=item int  dbd_st_STORE_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv)

=item int  dbd_st_blob_read (SV *sth, imp_sth_t *imp_sth, int field,

=item void dbd_st_destroy (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_execute (SV *sth, imp_sth_t *imp_sth)

=item AV  *dbd_st_fetch (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_finish (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_prepare (SV *sth, imp_sth_t *imp_sth, char *statement, SV *attribs)

=item int  dbd_st_rows (SV *sth, imp_sth_t *imp_sth)

=back

=head1 TODO

As this module is probably far from complete, so will the TODO list most
likely will be far from complete. More generic (test) items are mentioned
in the README in the module distribution.

=over 4

=item Handle attributes

Check if all documented handle (database- and statement-) attributes are
supported and work as expected.

  local $dbh->{RaiseError}       = 0;
  local $sth->{FetchHashKeyName} = "NAME";

=item Statement attributes

Allow setting and getting statement attributes. A specific example might be

  $sth->{PrintError}       = 0;
  $sth->{FetchHashKeyName} = "NAME_uc";

=item 3-argument bind_param ()

Investigate and implement 3-argument versions of $sth->bind_param ()

=item looks_as_number ()

Investigate if looks_as_number () should be used in st_bind ().
Comments are in where it should.

=item Multiple open databases

Try finding a way to open several different Unify databases at the
same time for parallel (or at least sequential) processing.

=back

=head1 SEE ALSO

The DBI documentation in L<DBI>, a lot of web pages, some very good, the
Perl 5 DBI Home page (http://dbi.perl.org/), other DBD modules'
documentation (DBD-Oracle is probably the most complete), the
comp.lang.perl.modules newsgroup and the dbi-users mailing list
(mailto:dbi-users-help@perl.org)

=head1 AUTHORS

DBI/DBD was developed by Tim Bunce, who also developed the DBD::Oracle.

H.Merijn Brand developed the DBD::Unify extension.

Todd Zervas has given a lot of feedback and patches.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1999-2015 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
