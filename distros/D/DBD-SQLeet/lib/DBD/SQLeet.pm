package DBD::SQLeet;

use 5.006;
use strict;
use DBI   1.57 ();
use DynaLoader ();

our $VERSION = '1.58';
our @ISA     = 'DynaLoader';

# sqlite_version cache (set in the XS bootstrap)
our ($sqlite_version, $sqlite_version_number);

# not sure if we still need these...
our ($err, $errstr);

__PACKAGE__->bootstrap($VERSION);

# New or old API?
use constant NEWAPI => ($DBI::VERSION >= 1.608);

# global registry of collation functions, initialized with 2 builtins
our %COLLATION;
tie %COLLATION, 'DBD::SQLeet::_WriteOnceHash';
$COLLATION{perl}       = sub { $_[0] cmp $_[1] };
$COLLATION{perllocale} = sub { use locale; $_[0] cmp $_[1] };

our $drh;
my $methods_are_installed = 0;

sub driver {
    return $drh if $drh;

    if (!$methods_are_installed && DBD::SQLeet::NEWAPI ) {
        DBI->setup_driver('DBD::SQLeet');

        DBD::SQLeet::db->install_method('sqlite_last_insert_rowid');
        DBD::SQLeet::db->install_method('sqlite_busy_timeout');
        DBD::SQLeet::db->install_method('sqlite_create_function');
        DBD::SQLeet::db->install_method('sqlite_create_aggregate');
        DBD::SQLeet::db->install_method('sqlite_create_collation');
        DBD::SQLeet::db->install_method('sqlite_collation_needed');
        DBD::SQLeet::db->install_method('sqlite_progress_handler');
        DBD::SQLeet::db->install_method('sqlite_commit_hook');
        DBD::SQLeet::db->install_method('sqlite_rollback_hook');
        DBD::SQLeet::db->install_method('sqlite_update_hook');
        DBD::SQLeet::db->install_method('sqlite_set_authorizer');
        DBD::SQLeet::db->install_method('sqlite_backup_from_file');
        DBD::SQLeet::db->install_method('sqlite_backup_to_file');
        DBD::SQLeet::db->install_method('sqlite_enable_load_extension');
        DBD::SQLeet::db->install_method('sqlite_load_extension');
        DBD::SQLeet::db->install_method('sqlite_register_fts3_perl_tokenizer');
        DBD::SQLeet::db->install_method('sqlite_trace', { O => 0x0004 });
        DBD::SQLeet::db->install_method('sqlite_profile', { O => 0x0004 });
        DBD::SQLeet::db->install_method('sqlite_table_column_metadata', { O => 0x0004 });
        DBD::SQLeet::db->install_method('sqlite_db_filename', { O => 0x0004 });
        DBD::SQLeet::db->install_method('sqlite_db_status', { O => 0x0004 });
        DBD::SQLeet::st->install_method('sqlite_st_status', { O => 0x0004 });
        DBD::SQLeet::db->install_method('sqlite_create_module');

        $methods_are_installed++;
    }

    $drh = DBI::_new_drh( "$_[0]::dr", {
        Name        => 'SQLite',
        Version     => $VERSION,
        Attribution => 'DBD::SQLeet by Matt Sergeant et al',
    } );

    return $drh;
}

sub CLONE {
    undef $drh;
}


package # hide from PAUSE
    DBD::SQLeet::dr;

sub connect {
    my ($drh, $dbname, $user, $auth, $attr) = @_;

    # Default PrintWarn to the value of $^W
    # unless ( defined $attr->{PrintWarn} ) {
    #    $attr->{PrintWarn} = $^W ? 1 : 0;
    # }

    my $dbh = DBI::_new_dbh( $drh, {
        Name => $dbname,
    } );

    my $real = $dbname;
    if ( $dbname =~ /=/ ) {
        foreach my $attrib ( split(/;/, $dbname) ) {
            my ($key, $value) = split(/=/, $attrib, 2);
            if ( $key =~ /^(?:db(?:name)?|database)$/ ) {
                $real = $value;
            } elsif ( $key eq 'uri' ) {
                $real = $value;
                $attr->{sqlite_open_flags} |= DBD::SQLeet::OPEN_URI();
            } else {
                $attr->{$key} = $value;
            }
        }
    }

    if (my $flags = $attr->{sqlite_open_flags}) {
        unless ($flags & (DBD::SQLeet::OPEN_READONLY() | DBD::SQLeet::OPEN_READWRITE())) {
            $attr->{sqlite_open_flags} |= DBD::SQLeet::OPEN_READWRITE() | DBD::SQLeet::OPEN_CREATE();
        }
    }

    # To avoid unicode and long file name problems on Windows,
    # convert to the shortname if the file (or parent directory) exists.
    if ( $^O =~ /MSWin32/ and $real ne ':memory:' and $real ne '' and $real !~ /^file:/ and !-f $real ) {
        require File::Basename;
        my ($file, $dir, $suffix) = File::Basename::fileparse($real);
        # We are creating a new file.
        # Does the directory it's in at least exist?
        if ( -d $dir ) {
            require Win32;
            $real = join '', grep { defined } Win32::GetShortPathName($dir), $file, $suffix;
        } else {
            # SQLite can't do mkpath anyway.
            # So let it go through as it and fail.
        }
    }

    # Hand off to the actual login function
    DBD::SQLeet::db::_login($dbh, $real, $user, $auth, $attr) or return undef;

    # Register the on-demand collation installer, REGEXP function and
    # perl tokenizer
    if ( DBD::SQLeet::NEWAPI ) {
        $dbh->sqlite_collation_needed( \&install_collation );
        $dbh->sqlite_create_function( "REGEXP", 2, \&regexp );
        $dbh->sqlite_register_fts3_perl_tokenizer();
    } else {
        $dbh->func( \&install_collation, "collation_needed"  );
        $dbh->func( "REGEXP", 2, \&regexp, "create_function" );
        $dbh->func( "register_fts3_perl_tokenizer" );
    }

    # HACK: Since PrintWarn = 0 doesn't seem to actually prevent warnings
    # in DBD::SQLeet we set Warn to false if PrintWarn is false.

    # NOTE: According to the explanation by timbunce,
    # "Warn is meant to report on bad practices or problems with
    # the DBI itself (hence always on by default), while PrintWarn
    # is meant to report warnings coming from the database."
    # That is, if you want to disable an ineffective rollback warning
    # etc (due to bad practices), you should turn off Warn,
    # and to silence other warnings, turn off PrintWarn.
    # Warn and PrintWarn are independent, and turning off PrintWarn
    # does not silence those warnings that should be controlled by
    # Warn.

    # unless ( $attr->{PrintWarn} ) {
    #     $attr->{Warn} = 0;
    # }

    return $dbh;
}

sub install_collation {
    my $dbh       = shift;
    my $name      = shift;
    my $collation = $DBD::SQLeet::COLLATION{$name};
    unless ($collation) {
        warn "Can't install unknown collation: $name" if $dbh->{PrintWarn};
        return;
    }
    if ( DBD::SQLeet::NEWAPI ) {
        $dbh->sqlite_create_collation( $name => $collation );
    } else {
        $dbh->func( $name => $collation, "create_collation" );
    }
}

# default implementation for sqlite 'REGEXP' infix operator.
# Note : args are reversed, i.e. "a REGEXP b" calls REGEXP(b, a)
# (see http://www.sqlite.org/vtab.html#xfindfunction)
sub regexp {
    use locale;
    return if !defined $_[0] || !defined $_[1];
    return scalar($_[1] =~ $_[0]);
}

package # hide from PAUSE
    DBD::SQLeet::db;

sub prepare {
    my $dbh = shift;
    my $sql = shift;
    $sql = '' unless defined $sql;

    my $sth = DBI::_new_sth( $dbh, {
        Statement => $sql,
    } );

    DBD::SQLeet::st::_prepare($sth, $sql, @_) or return undef;

    return $sth;
}

sub do {
    my ($dbh, $statement, $attr, @bind_values) = @_;

    # shortcut
    my $allow_multiple_statements = $dbh->FETCH('sqlite_allow_multiple_statements');
    if  (defined $statement && !defined $attr && !@bind_values) {
        # _do() (i.e. sqlite3_exec()) runs semicolon-separate SQL
        # statements, which is handy but insecure sometimes.
        # Use this only when it's safe or explicitly allowed.
        if (index($statement, ';') == -1 or $allow_multiple_statements) {
            return DBD::SQLeet::db::_do($dbh, $statement);
        }
    }

    my @copy = @{[@bind_values]};
    my $rows = 0;

    while ($statement) {
        my $sth = $dbh->prepare($statement, $attr) or return undef;
        $sth->execute(splice @copy, 0, $sth->{NUM_OF_PARAMS}) or return undef;
        $rows += $sth->rows;
        # XXX: not sure why but $dbh->{sqlite...} wouldn't work here
        last unless $allow_multiple_statements;
        $statement = $sth->{sqlite_unprepared_statements};
    }

    # always return true if no error
    return ($rows == 0) ? "0E0" : $rows;
}

sub ping {
    my $dbh = shift;

    # $file may be undef (ie. in-memory/temporary database)
    my $file = DBD::SQLeet::NEWAPI ? $dbh->sqlite_db_filename
                                   : $dbh->func("db_filename");

    return 0 if $file && !-f $file;
    return $dbh->FETCH('Active') ? 1 : 0;
}

sub _get_version {
    return ( DBD::SQLeet::db::FETCH($_[0], 'sqlite_version') );
}

my %info = (
    17 => 'SQLite',       # SQL_DBMS_NAME
    18 => \&_get_version, # SQL_DBMS_VER
    29 => '"',            # SQL_IDENTIFIER_QUOTE_CHAR
);

sub get_info {
    my($dbh, $info_type) = @_;
    my $v = $info{int($info_type)};
    $v = $v->($dbh) if ref $v eq 'CODE';
    return $v;
}

sub _attached_database_list {
    my $dbh = shift;
    my @attached;

    my $sth_databases = $dbh->prepare( 'PRAGMA database_list' ) or return;
    $sth_databases->execute or return;
    while ( my $db_info = $sth_databases->fetchrow_hashref ) {
        push @attached, $db_info->{name} if $db_info->{seq} >= 2;
    }
    return @attached;
}

# SQL/CLI (ISO/IEC JTC 1/SC 32 N 0595), 6.63 Tables
# Based on DBD::Oracle's
# See also http://www.ch-werner.de/sqliteodbc/html/sqlite3odbc_8c.html#a213
sub table_info {
    my ($dbh, $cat_val, $sch_val, $tbl_val, $typ_val, $attr) = @_;

    my @where = ();
    my $sql;
    if (  defined($cat_val) && $cat_val eq '%'
       && defined($sch_val) && $sch_val eq ''
       && defined($tbl_val) && $tbl_val eq '')  { # Rule 19a
        $sql = <<'END_SQL';
SELECT NULL TABLE_CAT
     , NULL TABLE_SCHEM
     , NULL TABLE_NAME
     , NULL TABLE_TYPE
     , NULL REMARKS
END_SQL
    }
    elsif (  defined($cat_val) && $cat_val eq ''
          && defined($sch_val) && $sch_val eq '%'
          && defined($tbl_val) && $tbl_val eq '') { # Rule 19b
        $sql = <<'END_SQL';
SELECT NULL      TABLE_CAT
     , t.tn      TABLE_SCHEM
     , NULL      TABLE_NAME
     , NULL      TABLE_TYPE
     , NULL      REMARKS
FROM (
     SELECT 'main' tn
     UNION SELECT 'temp' tn
END_SQL
        for my $db_name (_attached_database_list($dbh)) {
            $sql .= "     UNION SELECT '$db_name' tn\n";
        }
        $sql .= ") t\n";
    }
    elsif (  defined($cat_val) && $cat_val eq ''
          && defined($sch_val) && $sch_val eq ''
          && defined($tbl_val) && $tbl_val eq ''
          && defined($typ_val) && $typ_val eq '%') { # Rule 19c
        $sql = <<'END_SQL';
SELECT NULL TABLE_CAT
     , NULL TABLE_SCHEM
     , NULL TABLE_NAME
     , t.tt TABLE_TYPE
     , NULL REMARKS
FROM (
     SELECT 'TABLE' tt                  UNION
     SELECT 'VIEW' tt                   UNION
     SELECT 'LOCAL TEMPORARY' tt        UNION
     SELECT 'SYSTEM TABLE' tt
) t
ORDER BY TABLE_TYPE
END_SQL
    }
    else {
        $sql = <<'END_SQL';
SELECT *
FROM
(
SELECT NULL         TABLE_CAT
     ,              TABLE_SCHEM
     , tbl_name     TABLE_NAME
     ,              TABLE_TYPE
     , NULL         REMARKS
     , sql          sqlite_sql
FROM (
    SELECT 'main' TABLE_SCHEM, tbl_name, upper(type) TABLE_TYPE, sql
    FROM sqlite_master
UNION ALL
    SELECT 'temp' TABLE_SCHEM, tbl_name, 'LOCAL TEMPORARY' TABLE_TYPE, sql
    FROM sqlite_temp_master
END_SQL

        for my $db_name (_attached_database_list($dbh)) {
            $sql .= <<"END_SQL";
UNION ALL
    SELECT '$db_name' TABLE_SCHEM, tbl_name, upper(type) TABLE_TYPE, sql
    FROM "$db_name".sqlite_master
END_SQL
        }

        $sql .= <<'END_SQL';
UNION ALL
    SELECT 'main' TABLE_SCHEM, 'sqlite_master'      tbl_name, 'SYSTEM TABLE' TABLE_TYPE, NULL sql
UNION ALL
    SELECT 'temp' TABLE_SCHEM, 'sqlite_temp_master' tbl_name, 'SYSTEM TABLE' TABLE_TYPE, NULL sql
)
)
END_SQL
        $attr = {} unless ref $attr eq 'HASH';
        my $escape = defined $attr->{Escape} ? " ESCAPE '$attr->{Escape}'" : '';
        if ( defined $sch_val ) {
            push @where, "TABLE_SCHEM LIKE '$sch_val'$escape";
        }
        if ( defined $tbl_val ) {
            push @where, "TABLE_NAME LIKE '$tbl_val'$escape";
        }
        if ( defined $typ_val ) {
            my $table_type_list;
            $typ_val =~ s/^\s+//;
            $typ_val =~ s/\s+$//;
            my @ttype_list = split (/\s*,\s*/, $typ_val);
            foreach my $table_type (@ttype_list) {
                if ($table_type !~ /^'.*'$/) {
                    $table_type = "'" . $table_type . "'";
                }
            }
            $table_type_list = join(', ', @ttype_list);
            push @where, "TABLE_TYPE IN (\U$table_type_list)" if $table_type_list;
        }
        $sql .= ' WHERE ' . join("\n   AND ", @where ) . "\n" if @where;
        $sql .= " ORDER BY TABLE_TYPE, TABLE_SCHEM, TABLE_NAME\n";
    }
    my $sth = $dbh->prepare($sql) or return undef;
    $sth->execute or return undef;
    $sth;
}

sub primary_key_info {
    my ($dbh, $catalog, $schema, $table, $attr) = @_;

    my $databases = $dbh->selectall_arrayref("PRAGMA database_list", {Slice => {}});

    my @pk_info;
    for my $database (@$databases) {
        my $dbname = $database->{name};
        next if defined $schema && $schema ne '%' && $schema ne $dbname;

        my $quoted_dbname = $dbh->quote_identifier($dbname);

        my $master_table =
            ($dbname eq 'main') ? 'sqlite_master' :
            ($dbname eq 'temp') ? 'sqlite_temp_master' :
            $quoted_dbname.'.sqlite_master';

        my $sth = $dbh->prepare("SELECT name, sql FROM $master_table WHERE type = ?") or return;
        $sth->execute("table") or return;
        while(my $row = $sth->fetchrow_hashref) {
            my $tbname = $row->{name};
            next if defined $table && $table ne '%' && $table ne $tbname;

            my $quoted_tbname = $dbh->quote_identifier($tbname);
            my $t_sth = $dbh->prepare("PRAGMA $quoted_dbname.table_info($quoted_tbname)") or return;
            $t_sth->execute or return;
            my @pk;
            while(my $col = $t_sth->fetchrow_hashref) {
                push @pk, $col->{name} if $col->{pk};
            }

            # If there're multiple primary key columns, we need to
            # find their order from one of the auto-generated unique
            # indices (note that single column integer primary key
            # doesn't create an index).
            if (@pk > 1 and $row->{sql} =~ /\bPRIMARY\s+KEY\s*\(\s*
                (
                    (?:
                        (
                            [a-z_][a-z0-9_]*
                          | (["'`])(?:\3\3|(?!\3).)+?\3(?!\3)
                          | \[[^\]]+\]
                        )
                        \s*,\s*
                    )+
                    (
                        [a-z_][a-z0-9_]*
                      | (["'`])(?:\5\5|(?!\5).)+?\5(?!\5)
                      | \[[^\]]+\]
                    )
                )
                    \s*\)/six) {
                my $pk_sql = $1;
                @pk = ();
                while($pk_sql =~ /
                    (
                        [a-z_][a-z0-9_]*
                      | (["'`])(?:\2\2|(?!\2).)+?\2(?!\2)
                      | \[([^\]]+)\]
                    )
                    (?:\s*,\s*|$)
                        /sixg) {
                    my($col, $quote, $brack) = ($1, $2, $3);
                    if ( defined $quote ) {
                        # Dequote "'`
                        $col = substr $col, 1, -1;
                        $col =~ s/$quote$quote/$quote/g;
                    } elsif ( defined $brack ) {
                        # Dequote []
                        $col = $brack;
                    }
                    push @pk, $col;
                }
            }

            my $key_name = $row->{sql} =~ /\bCONSTRAINT\s+(\S+|"[^"]+")\s+PRIMARY\s+KEY\s*\(/i ? $1 : 'PRIMARY KEY';
            my $key_seq = 0;
            foreach my $pk_field (@pk) {
                push @pk_info, {
                    TABLE_SCHEM => $dbname,
                    TABLE_NAME  => $tbname,
                    COLUMN_NAME => $pk_field,
                    KEY_SEQ     => ++$key_seq,
                    PK_NAME     => $key_name,
                };
            }
        }
    }

    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my @names = qw(TABLE_CAT TABLE_SCHEM TABLE_NAME COLUMN_NAME KEY_SEQ PK_NAME);
    my $sth = $sponge->prepare( "primary_key_info", {
        rows          => [ map { [ @{$_}{@names} ] } @pk_info ],
        NUM_OF_FIELDS => scalar @names,
        NAME          => \@names,
    }) or return $dbh->DBI::set_err(
        $sponge->err,
        $sponge->errstr,
    );
    return $sth;
}


our %DBI_code_for_rule = ( # from DBI doc; curiously, they are not exported
                           # by the DBI module.
  # codes for update/delete constraints
  'CASCADE'             => 0,
  'RESTRICT'            => 1,
  'SET NULL'            => 2,
  'NO ACTION'           => 3,
  'SET DEFAULT'         => 4,

  # codes for deferrability
  'INITIALLY DEFERRED'  => 5,
  'INITIALLY IMMEDIATE' => 6,
  'NOT DEFERRABLE'      => 7,
 );


my @FOREIGN_KEY_INFO_ODBC = (
  'PKTABLE_CAT',       # The primary (unique) key table catalog identifier.
  'PKTABLE_SCHEM',     # The primary (unique) key table schema identifier.
  'PKTABLE_NAME',      # The primary (unique) key table identifier.
  'PKCOLUMN_NAME',     # The primary (unique) key column identifier.
  'FKTABLE_CAT',       # The foreign key table catalog identifier.
  'FKTABLE_SCHEM',     # The foreign key table schema identifier.
  'FKTABLE_NAME',      # The foreign key table identifier.
  'FKCOLUMN_NAME',     # The foreign key column identifier.
  'KEY_SEQ',           # The column sequence number (starting with 1).
  'UPDATE_RULE',       # The referential action for the UPDATE rule.
  'DELETE_RULE',       # The referential action for the DELETE rule.
  'FK_NAME',           # The foreign key name.
  'PK_NAME',           # The primary (unique) key name.
  'DEFERRABILITY',     # The deferrability of the foreign key constraint.
  'UNIQUE_OR_PRIMARY', # qualifies the key referenced by the foreign key
);

# Column names below are not used, but listed just for completeness's sake.
# Maybe we could add an option so that the user can choose which field
# names will be returned; the DBI spec is not very clear about ODBC vs. CLI.
my @FOREIGN_KEY_INFO_SQL_CLI = qw(
  UK_TABLE_CAT
  UK_TABLE_SCHEM
  UK_TABLE_NAME
  UK_COLUMN_NAME
  FK_TABLE_CAT
  FK_TABLE_SCHEM
  FK_TABLE_NAME
  FK_COLUMN_NAME
  ORDINAL_POSITION
  UPDATE_RULE
  DELETE_RULE
  FK_NAME
  UK_NAME
  DEFERABILITY
  UNIQUE_OR_PRIMARY
 );

sub foreign_key_info {
    my ($dbh, $pk_catalog, $pk_schema, $pk_table, $fk_catalog, $fk_schema, $fk_table) = @_;

    my $databases = $dbh->selectall_arrayref("PRAGMA database_list", {Slice => {}}) or return;

    my @fk_info;
    my %table_info;
    for my $database (@$databases) {
        my $dbname = $database->{name};
        next if defined $fk_schema && $fk_schema ne '%' && $fk_schema ne $dbname;

        my $quoted_dbname = $dbh->quote_identifier($dbname);
        my $master_table =
            ($dbname eq 'main') ? 'sqlite_master' :
            ($dbname eq 'temp') ? 'sqlite_temp_master' :
            $quoted_dbname.'.sqlite_master';

        my $tables = $dbh->selectall_arrayref("SELECT name FROM $master_table WHERE type = ?", undef, "table") or return;
        for my $table (@$tables) {
            my $tbname = $table->[0];
            next if defined $fk_table && $fk_table ne '%' && $fk_table ne $tbname;

            my $quoted_tbname = $dbh->quote_identifier($tbname);
            my $sth = $dbh->prepare("PRAGMA $quoted_dbname.foreign_key_list($quoted_tbname)") or return;
            $sth->execute or return;
            while(my $row = $sth->fetchrow_hashref) {
                next if defined $pk_table && $pk_table ne '%' && $pk_table ne $row->{table};

                unless ($table_info{$row->{table}}) {
                    my $quoted_tb = $dbh->quote_identifier($row->{table});
                    for my $db (@$databases) {
                        my $quoted_db = $dbh->quote_identifier($db->{name});
                        my $t_sth = $dbh->prepare("PRAGMA $quoted_db.table_info($quoted_tb)") or return;
                        $t_sth->execute or return;
                        my $cols = {};
                        while(my $r = $t_sth->fetchrow_hashref) {
                            $cols->{$r->{name}} = $r->{pk};
                        }
                        if (keys %$cols) {
                            $table_info{$row->{table}} = {
                                schema  => $db->{name},
                                columns => $cols,
                            };
                            last;
                        }
                    }
                }

                next if defined $pk_schema && $pk_schema ne '%' && $pk_schema ne $table_info{$row->{table}}{schema};

                push @fk_info, {
                    PKTABLE_CAT   => undef,
                    PKTABLE_SCHEM => $table_info{$row->{table}}{schema},
                    PKTABLE_NAME  => $row->{table},
                    PKCOLUMN_NAME => $row->{to},
                    FKTABLE_CAT   => undef,
                    FKTABLE_SCHEM => $dbname,
                    FKTABLE_NAME  => $tbname,
                    FKCOLUMN_NAME => $row->{from},
                    KEY_SEQ       => $row->{seq} + 1,
                    UPDATE_RULE   => $DBI_code_for_rule{$row->{on_update}},
                    DELETE_RULE   => $DBI_code_for_rule{$row->{on_delete}},
                    FK_NAME       => undef,
                    PK_NAME       => undef,
                    DEFERRABILITY => undef,
                    UNIQUE_OR_PRIMARY => $table_info{$row->{table}}{columns}{$row->{to}} ? 'PRIMARY' : 'UNIQUE',
                };
            }
        }
    }

    my $sponge_dbh = DBI->connect("DBI:Sponge:", "", "")
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my $sponge_sth = $sponge_dbh->prepare("foreign_key_info", {
        NAME          => \@FOREIGN_KEY_INFO_ODBC,
        rows          => [ map { [@{$_}{@FOREIGN_KEY_INFO_ODBC} ] } @fk_info ],
        NUM_OF_FIELDS => scalar(@FOREIGN_KEY_INFO_ODBC),
    }) or return $dbh->DBI::set_err(
        $sponge_dbh->err,
        $sponge_dbh->errstr,
    );
    return $sponge_sth;
}

my @STATISTICS_INFO_ODBC = (
  'TABLE_CAT',        # The catalog identifier.
  'TABLE_SCHEM',      # The schema identifier.
  'TABLE_NAME',       # The table identifier.
  'NON_UNIQUE',       # Unique index indicator.
  'INDEX_QUALIFIER',  # Index qualifier identifier.
  'INDEX_NAME',       # The index identifier.
  'TYPE',             # The type of information being returned.
  'ORDINAL_POSITION', # Column sequence number (starting with 1).
  'COLUMN_NAME',      # The column identifier.
  'ASC_OR_DESC',      # Column sort sequence.
  'CARDINALITY',      # Cardinality of the table or index.
  'PAGES',            # Number of storage pages used by this table or index.
  'FILTER_CONDITION', # The index filter condition as a string.
);

sub statistics_info {
    my ($dbh, $catalog, $schema, $table, $unique_only, $quick) = @_;

    my $databases = $dbh->selectall_arrayref("PRAGMA database_list", {Slice => {}}) or return;

    my @statistics_info;
    for my $database (@$databases) {
        my $dbname = $database->{name};
        next if defined $schema && $schema ne '%' && $schema ne $dbname;

        my $quoted_dbname = $dbh->quote_identifier($dbname);
        my $master_table =
            ($dbname eq 'main') ? 'sqlite_master' :
            ($dbname eq 'temp') ? 'sqlite_temp_master' :
            $quoted_dbname.'.sqlite_master';

        my $tables = $dbh->selectall_arrayref("SELECT name FROM $master_table WHERE type = ?", undef, "table") or return;
        for my $table_ref (@$tables) {
            my $tbname = $table_ref->[0];
            next if defined $table && $table ne '%' && uc($table) ne uc($tbname);

            my $quoted_tbname = $dbh->quote_identifier($tbname);
            my $sth = $dbh->prepare("PRAGMA $quoted_dbname.index_list($quoted_tbname)") or return;
            $sth->execute or return;
            while(my $row = $sth->fetchrow_hashref) {

                next if $unique_only && !$row->{unique};
                my $quoted_idx = $dbh->quote_identifier($row->{name});
                for my $db (@$databases) {
                    my $quoted_db = $dbh->quote_identifier($db->{name});
                    my $i_sth = $dbh->prepare("PRAGMA $quoted_db.index_info($quoted_idx)") or return;
                    $i_sth->execute or return;
                    my $cols = {};
                    while(my $info = $i_sth->fetchrow_hashref) {
                        push @statistics_info, {
                            TABLE_CAT   => undef,
                            TABLE_SCHEM => $db->{name},
                            TABLE_NAME  => $tbname,
                            NON_UNIQUE    => $row->{unique} ? 0 : 1,
                            INDEX_QUALIFIER => undef,
                            INDEX_NAME      => $row->{name},
                            TYPE            => 'btree', # see http://www.sqlite.org/version3.html esp. "Traditional B-trees are still used for indices"
                            ORDINAL_POSITION => $info->{seqno} + 1,
                            COLUMN_NAME      => $info->{name},
                            ASC_OR_DESC      => undef,
                            CARDINALITY      => undef,
                            PAGES            => undef,
                            FILTER_CONDITION => undef,
                       };
                    }
                }
            }
        }
    }

    my $sponge_dbh = DBI->connect("DBI:Sponge:", "", "")
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    my $sponge_sth = $sponge_dbh->prepare("statistics_info", {
        NAME          => \@STATISTICS_INFO_ODBC,
        rows          => [ map { [@{$_}{@STATISTICS_INFO_ODBC} ] } @statistics_info ],
        NUM_OF_FIELDS => scalar(@STATISTICS_INFO_ODBC),
    }) or return $dbh->DBI::set_err(
        $sponge_dbh->err,
        $sponge_dbh->errstr,
    );
    return $sponge_sth;
}

sub type_info_all {
    return; # XXX code just copied from DBD::Oracle, not yet thought about
#    return [
#        {
#            TYPE_NAME          =>  0,
#            DATA_TYPE          =>  1,
#            COLUMN_SIZE        =>  2,
#            LITERAL_PREFIX     =>  3,
#            LITERAL_SUFFIX     =>  4,
#            CREATE_PARAMS      =>  5,
#            NULLABLE           =>  6,
#            CASE_SENSITIVE     =>  7,
#            SEARCHABLE         =>  8,
#            UNSIGNED_ATTRIBUTE =>  9,
#            FIXED_PREC_SCALE   => 10,
#            AUTO_UNIQUE_VALUE  => 11,
#            LOCAL_TYPE_NAME    => 12,
#            MINIMUM_SCALE      => 13,
#            MAXIMUM_SCALE      => 14,
#            SQL_DATA_TYPE      => 15,
#            SQL_DATETIME_SUB   => 16,
#            NUM_PREC_RADIX     => 17,
#        },
#        [ 'CHAR', 1, 255, '\'', '\'', 'max length', 1, 1, 3,
#            undef, '0', '0', undef, undef, undef, 1, undef, undef
#        ],
#        [ 'NUMBER', 3, 38, undef, undef, 'precision,scale', 1, '0', 3,
#            '0', '0', '0', undef, '0', 38, 3, undef, 10
#        ],
#        [ 'DOUBLE', 8, 15, undef, undef, undef, 1, '0', 3,
#            '0', '0', '0', undef, undef, undef, 8, undef, 10
#        ],
#        [ 'DATE', 9, 19, '\'', '\'', undef, 1, '0', 3,
#            undef, '0', '0', undef, '0', '0', 11, undef, undef
#        ],
#        [ 'VARCHAR', 12, 1024*1024, '\'', '\'', 'max length', 1, 1, 3,
#            undef, '0', '0', undef, undef, undef, 12, undef, undef
#        ]
#    ];
}

my @COLUMN_INFO = qw(
    TABLE_CAT
    TABLE_SCHEM
    TABLE_NAME
    COLUMN_NAME
    DATA_TYPE
    TYPE_NAME
    COLUMN_SIZE
    BUFFER_LENGTH
    DECIMAL_DIGITS
    NUM_PREC_RADIX
    NULLABLE
    REMARKS
    COLUMN_DEF
    SQL_DATA_TYPE
    SQL_DATETIME_SUB
    CHAR_OCTET_LENGTH
    ORDINAL_POSITION
    IS_NULLABLE
);

sub column_info {
    my ($dbh, $cat_val, $sch_val, $tbl_val, $col_val) = @_;

    if ( defined $col_val and $col_val eq '%' ) {
        $col_val = undef;
    }

    # Get a list of all tables ordered by TABLE_SCHEM, TABLE_NAME
    my $sql = <<'END_SQL';
SELECT TABLE_SCHEM, tbl_name TABLE_NAME
FROM (
    SELECT 'main' TABLE_SCHEM, tbl_name
    FROM sqlite_master
    WHERE type IN ('table','view')
UNION ALL
    SELECT 'temp' TABLE_SCHEM, tbl_name
    FROM sqlite_temp_master
    WHERE type IN ('table','view')
END_SQL

    for my $db_name (_attached_database_list($dbh)) {
        $sql .= <<"END_SQL";
UNION ALL
    SELECT '$db_name' TABLE_SCHEM, tbl_name
    FROM "$db_name".sqlite_master
    WHERE type IN ('table','view')
END_SQL
    }

    $sql .= <<'END_SQL';
UNION ALL
    SELECT 'main' TABLE_SCHEM, 'sqlite_master' tbl_name
UNION ALL
    SELECT 'temp' TABLE_SCHEM, 'sqlite_temp_master' tbl_name
)
END_SQL

    my @where;
    if ( defined $sch_val ) {
        push @where, "TABLE_SCHEM LIKE '$sch_val'";
    }
    if ( defined $tbl_val ) {
        push @where, "TABLE_NAME LIKE '$tbl_val'";
    }
    $sql .= ' WHERE ' . join("\n   AND ", @where ) . "\n" if @where;
    $sql .= " ORDER BY TABLE_SCHEM, TABLE_NAME\n";
    my $sth_tables = $dbh->prepare($sql) or return undef;
    $sth_tables->execute or return undef;

    # Taken from Fey::Loader::SQLite
    my @cols;
    while ( my ($schema, $table) = $sth_tables->fetchrow_array ) {
        my $sth_columns = $dbh->prepare(qq{PRAGMA "$schema".table_info("$table")}) or return;
        $sth_columns->execute or return;

        for ( my $position = 1; my $col_info = $sth_columns->fetchrow_hashref; $position++ ) {
            if ( defined $col_val ) {
                # This must do a LIKE comparison
                my $sth = $dbh->prepare("SELECT '$col_info->{name}' LIKE '$col_val'") or return undef;
                $sth->execute or return undef;
                # Skip columns that don't match $col_val
                next unless ($sth->fetchrow_array)[0];
            }

            my %col = (
                TABLE_SCHEM      => $schema,
                TABLE_NAME       => $table,
                COLUMN_NAME      => $col_info->{name},
                ORDINAL_POSITION => $position,
            );

            my $type = $col_info->{type};
            if ( $type =~ s/(\w+)\s*\(\s*(\d+)(?:\s*,\s*(\d+))?\s*\)/$1/ ) {
                $col{COLUMN_SIZE}    = $2;
                $col{DECIMAL_DIGITS} = $3;
            }

            $col{TYPE_NAME} = $type;

            if ( defined $col_info->{dflt_value} ) {
                $col{COLUMN_DEF} = $col_info->{dflt_value}
            }

            if ( $col_info->{notnull} ) {
                $col{NULLABLE}    = 0;
                $col{IS_NULLABLE} = 'NO';
            } else {
                $col{NULLABLE}    = 1;
                $col{IS_NULLABLE} = 'YES';
            }

            push @cols, \%col;
        }
        $sth_columns->finish;
    }
    $sth_tables->finish;

    my $sponge = DBI->connect("DBI:Sponge:", '','')
        or return $dbh->DBI::set_err($DBI::err, "DBI::Sponge: $DBI::errstr");
    $sponge->prepare( "column_info", {
        rows          => [ map { [ @{$_}{@COLUMN_INFO} ] } @cols ],
        NUM_OF_FIELDS => scalar @COLUMN_INFO,
        NAME          => [ @COLUMN_INFO ],
    } ) or return $dbh->DBI::set_err(
        $sponge->err,
        $sponge->errstr,
    );
}

#======================================================================
# An internal tied hash package used for %DBD::SQLeet::COLLATION, to
# prevent people from unintentionally overriding globally registered collations.

package # hide from PAUSE
    DBD::SQLeet::_WriteOnceHash;

require Tie::Hash;

our @ISA = qw(Tie::StdHash);

sub TIEHASH {
    bless {}, $_[0];
}

sub STORE {
    ! exists $_[0]->{$_[1]} or die "entry $_[1] already registered";
    $_[0]->{$_[1]} = $_[2];
}

sub DELETE {
    die "deletion of entry $_[1] is forbidden";
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

DBD::SQLeet - SQLite3 DBI driver with optional encryption

DBD::SQLeet is a combination of the DBD::SQLite CPAN module:
<https://metacpan.org/pod/DBD::SQLite> and
sqleet - public domain encryption extension for SQLite3:
<https://github.com/resilar/sqleet>

=head1 SYNOPSIS

use DBI;
my $dbh = DBI->connect("dbi:SQLeet:dbname=$dbfile","","");
$dbh->do("PRAGMA key = 'password';");

=head1 DESCRIPTION

DBD::SQLeet is a complete SQLite3 DBI Driver with optional encryption.

SQLite is a public domain file-based relational database engine that you
can find at <http://www.sqlite.org/>.

DBD::SQLeet Perl code and test suite
are entirely based on the DBD::SQLite v.1.58 CPAN module.

The DBD::SQLeet API is a verbatim copy of the DBD::SQLite v.1.58 API.
See <https://metacpan.org/pod/DBD::SQLite> for reference.

=head1 SQLITE VERSION

DBD::SQLeet is compiled with a bundled sqleet library:
sqleet version 0.24.0 as of this release.

DBD::SQLeet follows the sqleet versioning scheme.
<https://github.com/resilar/sqleet#versioning-scheme>

Version 0.24.0 of sqleet is based on SQLite v3.24.0

=head1 DIFFERENCES FROM DBD::SQLite

DBD::SQLeet may not open successfully a database using the following code:

  my $dbh = DBI->connect("dbi:SQLite:file:$dbfile","","");

SQLite3 support for opening an URI filename is otherwise not impaired.
You can use:

  my $dbh = DBI->connect("dbi:SQLite:uri=file:$dbfile","","");

=head1 AUTHORS

Matt Sergeant E<lt>matt@sergeant.orgE<gt>

Francis J. Lacoste E<lt>flacoste@logreport.orgE<gt>

Wolfgang Sourdeau E<lt>wolfgang@logreport.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Max Maischein E<lt>corion@cpan.orgE<gt>

Laurent Dami E<lt>dami@cpan.orgE<gt>

Kenichi Ishigaki E<lt>ishigaki@cpan.orgE<gt>

Dimitar D. Mitov E<lt>ddmitov@yahoo.comE<gt>

=head1 COPYRIGHT

Some parts of the bundled SQLite code in this distribution is Public Domain.
https://www.sqlite.org/copyright.html

sqlite3.c and sqlite3.h in this distribution are part of sqleet:
https://github.com/resilar/sqleet
public domain encryption extension for SQLite3 released under the UNLICENSE license.

DBD::SQLite is copyright 2002 - 2007 Matt Sergeant.

Some parts copyright 2008 Francis J. Lacoste.

Some parts copyright 2008 Wolfgang Sourdeau.

Some parts copyright 2008 - 2013 Adam Kennedy.

Some parts copyright 2009 - 2013 Kenichi Ishigaki.

Some parts derived from L<DBD::SQLite::Amalgamation>
copyright 2008 Audrey Tang.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
