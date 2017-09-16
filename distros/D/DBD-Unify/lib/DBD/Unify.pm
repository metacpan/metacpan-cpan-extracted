#   Copyright (c) 1999-2017 H.Merijn Brand
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.

use 5.8.4;

use strict;
use warnings;

package DBD::Unify;

our $VERSION = "0.89";

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

our $err    = 0;	# holds error code   for DBI::err
our $errstr = "";	# holds error string for DBI::errstr
our $state  = "";	# holds SQL state    for DBI::state
our $drh    = undef;	# holds driver handle once initialized

sub driver {
    return $drh if $drh;
    my $class = shift; # second argument ($attr) not used: ignored

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

sub connect {
    my ($dr_h, $dbname, $user, $auth) = @_;

    unless ($ENV{UNIFY} && -d $ENV{UNIFY} && -x _) {
	$dr_h->{Warn} and
	    Carp::croak "\$UNIFY not set or invalid. UNIFY may fail\n";
	}
    # More checks here if wanted ...

    defined $user or $user = "";
    defined $auth or $auth = "";

    # create a 'blank' dbh
    my $dbh = DBI::_new_dbh ($dr_h, {
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

sub data_sources {
    my ($dr_h) = @_;
    $dr_h->{Warn} and
	Carp::carp "\$dr_h->data_sources () not defined for Unify\n";
    "";
    } # data_sources

1;

####### Database ##############################################################

package DBD::Unify::db;

$DBD::Unify::db::imp_data_size = 0;

sub parse_trace_flag {
    my ($dbh, $name) = @_;
  # print STDERR "# Flags: $name\n";
    return 0x7FFFFF00 if $name eq "DBD";	# $h->trace ("DBD"); -- ALL
  # return 0x01000000 if $name eq "select";	# $h->trace ("SQL|select");
  # return 0x02000000 if $name eq "update";	# $h->trace ("1|update");
  # return 0x04000000 if $name eq "delete";
  # return 0x08000000 if $name eq "insert";
    return $dbh->SUPER::parse_trace_flag ($name);
    } # parse_trace_flag

sub type_info_all {
    #my ($dbh) = @_;
    require DBD::Unify::TypeInfo;
    return [ @$DBD::Unify::TypeInfo::type_info_all ];
    } # type_info_all

sub get_info {
    my ($dbh, $info_type) = @_;
    require  DBD::Unify::GetInfo;
    my $v = $DBD::Unify::GetInfo::info{int $info_type};
    ref $v eq "CODE" and $v = $v->($dbh);
    return $v;
    } # get_info

sub private_attribute_info {
    return {
	dbd_verbose	=> undef,

	uni_verbose	=> undef,
	uni_unicode	=> undef,
	};
    } # private_attribute_info

sub ping {
    my $dbh = shift;
    $dbh->prepare ("select USER_NAME from SYS.DATABASE_USERS") or return 0;
    return 1;
    } # ping

sub prepare {
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

sub _is_or_like {
    my ($fld, $val) = @_;
    $val =~ m/[_%]/ ? "$fld like '$val'" : "$fld = '$val'";
    } # _is_or_like

sub table_info {
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
    my $sql = join " " =>
	q{select '', OWNR, TABLE_NAME, TABLE_TYPE, RDWRITE},
	q{from   SYS.ACCESSIBLE_TABLES},
	(@where ? " where @where" : "");
    my $sth = $dbh->prepare ($sql);
    $sth or return;
    $sth->{ChopBlanks} = 1;
    $sth->execute;
    $sth;
    } # table_info

{   my (%cache, @links, $pki);

    sub _sys_clear_cache {
	%cache = ();
	@links = ();
	$pki   = undef;
	} # _sys_clear_cache
    *DBI::db::uni_clear_cache = \&_sys_clear_cache;

    sub _set_info_cache {
	my $dbh = shift;

	keys %cache and return;

	if (my $dd = $dbh->func ("db_dict")) {
	    require DBD::Unify::TypeInfo;
	    foreach my $c (grep { defined } @{$dd->{COLUMN}}) {
		my $t = $dd->{TABLE}[$c->{TID}];
		my $s = $t->{ANAME} || "";
		my @c = (@{$c}{qw(
		    NAME TYPE LENGTH SCALE DSP_LEN DSP_SCL
		    NULLABLE RDONLY PKEY UNIQUE )}, 1, 0,);
		$c[$_] = $c[$_] ? "Y" : "N" for -6, -5, -4, -3, -2, -1;
		$c[1] = DBD::Unify::TypeInfo::hli_type ($c[1]);
		$cache{$s}{$t->{NAME}}{$c->{NAME}} = [ $s, $t->{NAME}, @c ];
		}
	    return;
	    }

	my $sth = $dbh->prepare (join " " =>
	    "select OWNR, TABLE_NAME, COLUMN_NAME, DATA_TYPE, DATA_LENGTH,",
		   "DATA_SCALE, DISPLAY_LENGTH, DISPLAY_SCALE, NULLABLE,",
		   "RDNLY, PRIMRY, UNIQ, LOGGED, ORDERED",
	    "from   SYS.ACCESSIBLE_COLUMNS") or return;
	$sth->{ChopBlanks} = 1;
	$sth->execute or return;
	my %sac;
	my @fld = @{$sth->{NAME_lc}};
	$sth->bind_columns (\@sac{@fld});
	while ($sth->fetch) {
	    $cache{$sac{ownr} || ""}
		  {$sac{table_name}}
		  {$sac{column_name}} = [ @sac{@fld} ];
	    }
	} # _set_info_cache

    sub _set_link_cache {
	my $dbh = shift;

	@links and return;

	if (my $dd = $dbh->func ("db_dict")) {
	    foreach my $c (grep { defined && $_->{LINK} >= 0 } @{$dd->{COLUMN}}) {
		my $t = $dd->{TABLE}[$c->{TID}];
		my $s = $t->{ANAME} || "";
		my $p = $dd->{COLUMN}[$c->{LINK}];
		my $T = $dd->{TABLE}[$p->{TID}];
		my $S = $T->{ANAME} || "";
		push @links, {
		    index_name			=> "",		# ?
		    referenced_owner		=> $S,
		    referenced_table		=> $T->{NAME},
		    referenced_column		=> $p->{NAME},
		    referencing_owner		=> $s,
		    referencing_table		=> $t->{NAME},
		    referencing_column		=> $c->{NAME},
		    referencing_column_ord	=> 0,		# ?
		    };
		}
	    return;
	    }

	my $sth = $dbh->prepare (join " " =>
	    "select INDEX_NAME,",
		   "REFERENCED_OWNER,  REFERENCED_TABLE,  REFERENCED_COLUMN,",
		   "REFERENCING_OWNER, REFERENCING_TABLE, REFERENCING_COLUMN,",
		   "REFERENCING_COLUMN_ORD",
	    "from   SYS.LINK_INDEXES");
	$sth or return;
	$sth->{ChopBlanks} = 1;
	$sth->execute or return;
	my %sli;
	my @fld = @{$sth->{NAME_lc}};
	$sth->bind_columns (\@sli{@fld});
	while ($sth->fetch) {
	    push @links, { %sli };
	    }
	} # _set_link_cache

    sub _sys_column_info {
	my ($dbh, $sch, $tbl, $col) = @_;

	_set_info_cache ($dbh);

	my @ci;
	foreach my $s (sort keys %cache) {
	    $sch and lc $sch ne lc $s and next;
	    foreach my $t (sort keys %{$cache{$s}}) {
		$tbl and lc $tbl ne lc $t and next;
		foreach my $c (sort keys %{$cache{$s}{$t}}) {
		    $col and lc $col ne lc $c and next;
		    push @ci, $cache{$s}{$t}{$c};
		    }
		}
	    }
	@ci;
	}

    sub _sys_link_info {
	my $dbh = shift;
	my ($Pcatalog, $Pschema, $Ptable,
	    $Fcatalog, $Fschema, $Ftable, $attr) = (@_, {});

	$Pcatalog and warn "Catalogs are not supported in Unify\n";
	$Fcatalog and warn "Catalogs are not supported in Unify\n";

	$attr && ref $attr && keys %$attr and warn "Attributes are ignored in link_info\n";

	_set_link_cache ($dbh);

	my @fki;
	for (@links) {
	    $Pschema and lc $_->{referenced_owner}  ne lc $Pschema and next;
	    $Ptable  and lc $_->{referenced_table}  ne lc $Ptable  and next;
	    $Fschema and lc $_->{referencing_owner} ne lc $Fschema and next;
	    $Ftable  and lc $_->{referencing_table} ne lc $Ftable  and next;

	    push @fki, [
		undef, @{$_}{qw( referenced_owner  referenced_table  referenced_column  )},
		undef, @{$_}{qw( referencing_owner referencing_table referencing_column )},
		$_->{referencing_column_ord} + 1,
		undef, undef,
		$_->{index_name}, undef,
		undef, undef,
		];
	    }
	@fki;
	} # _sys_link_info

    sub _sys_primary_keys {
	my $dbh = shift;
	unless ($pki) {
	    _set_info_cache ($dbh);

	    # Note that PRIMRY is *only* set for tables with *ONE* key field
	    # for composite keys this doesn't work :(
	    foreach my $s (sort keys %cache) {
		foreach my $t (sort keys %{$cache{$s}}) {
		    foreach my $c (sort keys %{$cache{$s}{$t}}) {
			$cache{$s}{$t}{$c}[-4] eq "Y" or next;
			push @{$pki->{key}{$s}{$t}}, $c;
			}
		    }
		}

	    # For tables with a combined key, we need to analyse the automatic
	    # added HASH_INDEX for those tables
	    if (my $hth = $dbh->prepare (join " " =>
		    "select   OWNR, TABLE_NAME, COLUMN_NAME, COLUMN_ORD",
		    "from     SYS.HASH_INDEXES_G",
		    "where    UNIQUE_SPEC = 'Y'",
		    "order by OWNR, TABLE_NAME, COLUMN_ORD")) {
		$hth->{ChopBlanks} = 1;
		$hth->execute or return;
		$hth->bind_columns (\my ($sch, $tbl, $fld, $ord));
		while ($hth->fetch) {
		    #warn "$ord $sch.$tbl.$fld\n";
		    push @{$pki->{key}{$sch}{$tbl}}, $fld;
		    }
		}
	    }
	$pki;
	} # _sys_primary_keys
    }

sub column_info {
    my $dbh = shift;
    my ($catalog, $schema, $table, $column);
    ref $_[0] or ($catalog, $schema, $table, $column) = splice @_, 0, 4;
    if ($catalog) {
	$dbh->{Warn} and
	    Carp::carp "Unify does not support catalogs in column_info\n";
	return;
	}
    my @ci = _sys_column_info ($dbh, $schema, $table, $column) or return;
    my @fki;
    require DBD::Unify::TypeInfo;
    for (@ci) {
	my @sli = @$_;
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
	RaiseError       => $dbh->{RaiseError},
	PrintError       => $dbh->{PrintError},
	ChopBlanks       => 1,
	FetchHashKeyName => $dbh->{FetchHashKeyName} || "NAME",
	})->prepare ("select column_info", {
	    rows => \@fki,
	    NAME => \@col_name,
	    });
    } # column_info

sub primary_key {
    my $dbh = shift;
    my ($catalog, $schema, $table) = @_;
    if ($catalog) {
	$dbh->{Warn} and
	    Carp::carp "Unify does not support catalogs in table_info\n";
	return;
	}

    if (my $dd = $dbh->func ("db_dict")) {
	my @key;
	foreach my $c (grep { defined && $_->{PKEY} } @{$dd->{COLUMN}}) {
	    my $t   = $dd->{TABLE}[$c->{TID}];
	    my $sch = $t->{ANAME} || "";
	    my $tbl = $t->{NAME};
	    defined $schema && lc $sch ne lc $schema and next;
	    defined $table  && lc $tbl ne lc $table  and next;
	    push @key, $c->{NAME};
	    }
	return @key;
	}

    # Fetching table information from SYS is *extremely* slow
    # Feel free to add your home-grown caching or prepared knowledge here
    my @key = eval {
	require PROCURA::U2000;
	PROCURA::U2000::get_key ($schema, $table);
	};
    @key and return @key;

    my $pki_cache = _sys_primary_keys ($dbh);
    $pki_cache && $pki_cache->{key} or return;

    foreach my $sch (sort keys %{$pki_cache->{key}}) {
	defined $schema && lc $sch ne lc $schema and next;
	foreach my $tbl (sort keys %{$pki_cache->{key}{$sch}}) {
	    defined $table && lc $tbl ne lc $table and next;
	    push @key, @{$pki_cache->{key}{$sch}{$tbl}};
	    }
	}
    return @key;
    } # primary_key

sub quote_identifier {
    my ($dbh, @arg) = map { defined $_ && $_ ne "" ? $_ : undef } @_;
    return $dbh->SUPER::quote_identifier (@arg);
    } # quote_identifier

# $sth = $dbh->foreign_key_info (
#            $pk_catalog, $pk_schema, $pk_table,
#            $fk_catalog, $fk_schema, $fk_table,
#            \%attr);
sub foreign_key_info {
    my $dbh = shift;
    my ($Pcatalog, $Pschema, $Ptable,
	$Fcatalog, $Fschema, $Ftable, $attr) = (@_, {});

    my @fki = _sys_link_info ($dbh,
	    $Pcatalog, $Pschema, $Ptable,
	    $Fcatalog, $Fschema, $Ftable, $attr);

    my @col_name = qw(
	UK_TABLE_CAT UK_TABLE_SCHEM UK_TABLE_NAME UK_COLUMN_NAME
	FK_TABLE_CAT FK_TABLE_SCHEM FK_TABLE_NAME FK_COLUMN_NAME
	ORDINAL_POSITION

	UPDATE_RULE DELETE_RULE
	FK_NAME UK_NAME
	DEFERABILITY UNIQUE_OR_PRIMARY );
    DBI->connect ("dbi:Sponge:", "", "", {
	RaiseError       => $dbh->{RaiseError},
	PrintError       => $dbh->{PrintError},
	ChopBlanks       => 1,
	FetchHashKeyName => $dbh->{FetchHashKeyName} || "NAME",
	})->prepare ("select link_info", {
	    rows => \@fki,
	    NAME => \@col_name,
	    });
    } # foreign_key_info

# type = "R" ? references me : references
# This is to be converted to foreign_key_info
sub link_info {
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

sub private_attribute_info {
    return {
	uni_type	=> undef,
	};
    } # private_attribute_info

1;

####### End ###################################################################
__END__

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
There is no central files (like F</etc/oratab> for Oracle) that lists all
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

=item uni_clear_cache ()

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

Currently the driver tries to cache information about the schema as it
is required. When there are fields added, removed, or altered, references
are added or removed or primary keys or unique hashes are added or removed
it is wise to call C<< $dbh->uni_clear_cache >> to ensure that the info
on next inquiries will be up to date.

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

=item int  dbd_bind_ph (SV *sth, imp_sth_t *imp_sth, SV *param, SV *value, IV sql_type, SV *attribs, int is_inout, IV maxlen)

=item SV  *dbd_db_FETCH_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv)

=item int  dbd_db_STORE_attrib (SV *dbh, imp_dbh_t *imp_dbh, SV *keysv, SV *valuesv)

=item int  dbd_db_commit (SV *dbh, imp_dbh_t *imp_dbh)

=item void dbd_db_destroy (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_db_disconnect (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_db_do (SV *dbh, char *statement)

=item int  dbd_db_login (SV *dbh, imp_dbh_t *imp_dbh, char *dbname, char *user, char *pwd)

=item int  dbd_db_rollback (SV *dbh, imp_dbh_t *imp_dbh)

=item int  dbd_discon_all (SV *drh, imp_drh_t *imp_drh)

=item int  dbd_fld_describe (SV *dbh, imp_sth_t *imp_sth, int num_fields)

=item void dbd_init (dbistate_t *dbistate)

=item int  dbd_prm_describe (SV *dbh, imp_sth_t *imp_sth, int num_params)

=item SV  *dbd_st_FETCH_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv)

=item int  dbd_st_STORE_attrib (SV *sth, imp_sth_t *imp_sth, SV *keysv, SV *valuesv)

=item int  dbd_st_blob_read (SV *sth, imp_sth_t *imp_sth, int field, long offset, long len, SV *destrv, long destoffset)

=item void dbd_st_destroy (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_execute (SV *sth, imp_sth_t *imp_sth)

=item AV  *dbd_st_fetch (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_finish (SV *sth, imp_sth_t *imp_sth)

=item int  dbd_st_prepare (SV *sth, imp_sth_t *imp_sth, char *statement, SV *attribs)

=item int  dbd_st_rows (SV *sth, imp_sth_t *imp_sth)

=back

=head2 DBD specific functions

=head3 db_dict

Query the data dictionary through HLI calls:

 my $dd = $dbh->func (   "db_dict");
 my $dd = $dbh->func (0, "db_dict"); # same
 my $dd = $dbh->func (1, "db_dict"); # force reload

This function returns the data dictionary of the database in a hashref. The
dictionary contains all information accessible to the current user and will
likely contain all accessible schema's, tables, columns, and simple links
(referential integrity).

The force_reload argument is useful if the data dictionary might have changed:
adding/removing tables/links/primary keys, altering tables etc.

The dictionary will have 4 entries

=over 2

=item TYPE
X<TYPE>

 my $types = $dd->{TYPE};

This holds a list with the native type descriptions of the C<TYPE> entries
in the C<COLUMN> hashes.

 say $dd->{TYPE}[3]; # DATE

=item AUTH
X<AUTH>

 my $schemas = $dd->{AUTH};

This will return a reference to a list of accessible schema's. The schema's
that are not accessible or do not exist (anymore) have an C<undef> entry.

Each auth entry is C<undef> or a hashref with these entries:

=over 2

=item AID
X<AID>

Holds the AUTH ID of the schema (INTEGER). In the current implementation,
the C<AID> entry is identical to the index in the list

 say $schemas->[3]{AID};
 # 3

=item NAME
X<NAME>

Holds the name of the schema (STRING)

 say $schemas->[3]{NAME};
 # DBUTIL

=item TABLES
X<TABLES>

Holds the list of accessible table ID's in this schema (ARRAY of INTEGER's)

 say join ", " => $schemas->[3]{TABLES};
 # 43, 45, 47, 48, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 61

=back

=item TABLE
X<TABLE>

 my $tables = $dd->{TABLE};

This will return a reference to a list of accessible tables. The tables
that are not accessible or do not exist (anymore) have an C<undef> entry.

Each table entry is C<undef> or a hashref with these entries:

=over 2

=item AID
X<AID>

Holds the AUTH ID (INTEGER) of the schema this table belongs to.

 say $tables->[43]{AID};
 # 3

=item ANAME
X<ANAME>

Holds the name of the schema this table belongs too.

 say $tables->[43]{NAME};
 # UTLATH

=item TID
X<TID>

Holds the TABLE ID of the table (INTEGER). In the current implementation,
the C<TID> entry is identical to the index in the list

 say $tables->[43]{TID};
 # 43

=item NAME
X<NAME>

Holds the name of the table

 say $tables->[43]{NAME};
 # UTLATH

=item KEY
X<KEY>

Holds a list of column indices (C<CID>'s) of the columns that are the
primary key of this table. The list can be empty if the table has no
primary key.

 say for @{$tables->[43]{KEY}};
 # 186

=item CGRP
X<CGRP>

Holds a list of column groups for this table (if any).

 my $cgrp = $dd->{TABLE}[59];

Each entry in the list holds a has with the following entries

=over 2

=item CID
X<CID>

Holds the column ID of this column group

 say $cgrp->[0]{CID}
 # 260

=item TYPE
X<TYPE>

Holds the type of this group. This will always be C<100>.

 say $cgrp->[0]{TYPE}
 # 100

=item COLUMNS
X<COLUMNS>

Holds the list of C<CID>s this group consists of

 say for @{$cgrp->[0]{COLUMNS}}
 # 255
 # 256

=back

=item DIRECTKEY
X<DIRECTKEY>

Holds a true/false indication of the table being C<DIRECT-KEYED>.

 say $tables->[43]{DIRECTKEY}
 # 1

=item FIXEDSIZE
X<FIXEDSIZE>

Holds a true/false indication of the table being of fixed size.
See also L<EXPNUM>

=item EXPNUM
X<EXPNUM>

If L<FIXEDNUM> is true, this entry holds the number of records of the table

=item OPTIONS
X<OPTIONS>

=item PKEYED
X<PKEYED>

Holds a true/false indication of the table being primary keyed

=item SCATTERED
X<SCATTERED>

Holds a true/false indication if the table has data scattered across volumes

=item COLUMNS
X<COLUMNS>

Holds a list of column indices (C<CID>'s) of the columns of this table.

 say for @{$tables->[43]{COLUMNS}};
 # 186
 # 187
 # 188

=back

=item COLUMN
X<COLUMN>

 my $columns = $dd->{COLUMN};

This will return a reference to a list of accessible columns. The columns
that are not accessible or do not exist (anymore) have an C<undef> entry.

Each columns entry is C<undef> or a hashref with these entries:

=over 2

=item CID
X<CID>

Holds the COLUMN ID of the column (INTEGER). In the current implementation,
the C<CID> entry is identical to the index in the list

 say $columns->[186]{CID};
 # 186

=item NAME
X<NAME>

Holds the name of the column

 say $columns->[186]{NAME};
 # ATHID

=item TID
X<TID>

Holds the TABLE ID (INTEGER) of the table this column belongs to.

 say $columns->[186]{TID};
 # 43

=item TNAME
X<TNAME>

Holds the name of the table this column belongs to.

 say $columns->[186]{TNAME};
 # DBUTIL

=item TYPE
X<TYPE>

Holds the type (INTEGER) of the column

 say $columns->[186]{TYPE};
 # 2

The description of the type can be found in the C<TYPE> entry in C<$dd->{TYPE}>.

=item LENGTH
X<LENGTH>

Holds the length of the column or C<0> if not appropriate.

 say $columns->[186]{LENGTH};
 # 9

=item SCALE
X<SCALE>

Holds the scale of the column or C<0> if not appropriate.

 say $columns->[186]{SCALE};
 # 0

=item NULLABLE
X<NULLABLE>

Holds the true/false indication of this column allowing C<NULL> as value

 say $columns->[186]{NULLABLE};
 # 0

Primary keys implicitly do not allow C<NULL> values

=item DSP_LEN
X<DSP_LEN>

Holds, if appropriate, the display length of the column

 say $columns->[186]{DSP_LEN};
 # 10

=item DSP_SCL
X<DSP_SCL>

Holds, if appropriate, the display scale of the column

 say $columns->[186]{DSP_SCL};
 # 0

=item DSP_PICT
X<DSP_PICT>

Holds, if appropriate, the display format of the column

 say $columns->[186]{DSP_PICT};
 #

=item OPTIONS
X<OPTIONS>

Holds the internal (bitmap) representation of the options for this column.
Most, if not all, of these options have been translated to the other entries
in this hash.

 say $columns->[186]{OPTIONS};
 # 16412

=item PKEY
X<PKEY>

Holds a true/false indication of the column is a (single) primary key.

 say $columns->[186]{PKEY};
 # 1

=item RDONLY
X<RDONLY>

Holds a true/false indication of the column is read-only.

 say $columns->[186]{RDONLY};
 # 0

=item UNIQUE
X<UNIQUE>

Holds a true/false indication of the column is unique.

 say $columns->[186]{UNIQUE};
 # 1

=item LINK
X<LINK>

Holds the C<CID> of the column this column links to through referential
integrity. This value is C<-1> if there is no link.

 say $columns->[186]{LINK};
 # -1

=item REFS
X<REFS>

Holds a list of column indices (C<CID>'s) of the columns referencing
this column in a link.

 say for @{$columns->[186]{REFS}};
 # 191
 # 202

=item NBTREE
X<NBTREE>

Holds the number of B-tree indices the column participates in

 say $columns->[186]{NBTREE};
 # 0

=item NHASH
X<NHASH>

Holds the number of hash-tables the column belongs to

 say $columns->[186]{NHASH};
 # 0

=item NPLINK
X<NPLINK>

Holds the number of links the column is parent of

 say $columns->[186]{NPLINK};
 # 2

=item NCLINK
X<NCLINK>

Holds the number of links the column is child of (<C0> or C<1>)

 say $columns->[186]{NCLINK};
 # 0

If this entry holds C<1>, the C<LINK> entry holds the C<CID> of the
parent column.

=back

=back

Combining all of these into describing a table, might look like done in
F<examples/describe.pl>

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

=head1 AUTHOR

DBI/DBD was developed by Tim Bunce, who also developed the DBD::Oracle.

H.Merijn Brand developed the DBD::Unify extension.

Todd Zervas has given a lot of feedback and patches.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 1999-2017 H.Merijn Brand

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
