package DB::Handy;
######################################################################
#
# DB::Handy - Pure-Perl flat-file relational database with DBI-like interface
#
# https://metacpan.org/dist/DB-Handy
#
# Copyright (c) 2026 INABA Hitoshi <ina.cpan@gmail.com>
######################################################################
#
# Compatible : Perl 5.005_03 and later
# Platform   : Windows and UNIX/Linux
#
# FILE LAYOUT:
#   <base_dir>/<database>/
#     <table>.sch               schema  (text, key=value lines)
#     <table>.dat               records (fixed-length binary; 1st byte is active/deleted flag)
#     <table>.<idxname>.idx     sorted index (binary)
#
# INDEX FILE FORMAT (each entry is fixed-size):
#   Header  : "SDBIDX1\n"   (8 bytes)
#   Entries (sorted ascending by key_bytes):
#     [key_bytes : keysize bytes][rec_no : 4 bytes big-endian uint32]
#
# Key encoding (byte order == value order):
#   INT   : sign-bit-flipped big-endian uint32
#   FLOAT : IEEE 754 order-preserving 8-byte encoding
#   other : NUL-padded fixed-width string
#
# SCHEMA FILE format for indexes:
#   IDX=<idxname>:<colname>:<unique 0|1>
######################################################################

use 5.00503;    # Universal Consensus 1998 for primetools
                # Perl 5.005_03 compatibility for historical toolchains
# use 5.008001; # Lancaster Consensus 2013 for toolchains

use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) { $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use Fcntl qw(:flock);
use File::Path ();
use File::Spec;
use POSIX ();

use vars qw($VERSION $errstr);
$VERSION = '1.09';
$VERSION = $VERSION;
$errstr  = '';

###############################################################################
# Constants
###############################################################################
use constant RECORD_ACTIVE  => "\x01";
use constant RECORD_DELETED => "\x00";
use constant MAX_VARCHAR    => 255;
use constant INT_MAX        =>  2147483647;
use constant INT_MIN        => -2147483648;
use constant IDX_MAGIC      => "SDBIDX1\n";
use constant IDX_MAGIC_LEN  => 8;
use constant REC_NO_SIZE    => 4;

my %TYPE_SIZE = (
    INT     => 4,
    FLOAT   => 8,
    CHAR    => undef,
    VARCHAR => undef,
    DATE    => 10,
);

###############################################################################
# Constructor
###############################################################################
sub new {
    my($class, %args) = @_;
    my $self = {
        base_dir => ($args{base_dir} || 'simpledbms_data'),
        db_name  => ($args{db_name}  || ''),
        _tables  => {},
        _locks   => {},
    };
    bless $self, $class;
    if (($self->{db_name} ne '') && !_valid_name($self->{db_name})) {
        my $bad = _shown_name($self->{db_name});
        $errstr = "Invalid database name '$bad'";
        return undef;
    }
    unless (-d $self->{base_dir}) {
        eval {
            File::Path::mkpath($self->{base_dir});
        };
        if ($@) {
            $errstr = "Cannot create base_dir: $@";
            return undef;
        }
    }
    return $self;
}

###############################################################################
# Database-level
###############################################################################
sub create_database {
    my($self, $db_name) = @_;
    unless (_valid_name($db_name)) {
        my $bad = _shown_name($db_name);
        $errstr = "Invalid database name '$bad'";
        return 0;
    }
    my $path = $self->_db_path($db_name);
    if (-d $path) {
        $errstr = "Database '$db_name' already exists";
        return 0;
    }
    eval {
        File::Path::mkpath($path);
    };
    if ($@) {
        $errstr = "Cannot create database '$db_name': $@";
        return 0;
    }
    return 1;
}

sub use_database {
    my($self, $db_name) = @_;
    unless (_valid_name($db_name)) {
        my $bad = _shown_name($db_name);
        $errstr = "Invalid database name '$bad'";
        return 0;
    }
    my $path = $self->_db_path($db_name);
    unless (-d $path) {
        $errstr = "Database '$db_name' does not exist";
        return 0;
    }
    $self->{db_name} = $db_name;
    $self->{_tables} = {};
    return 1;
}

sub drop_database {
    my($self, $db_name) = @_;
    unless (_valid_name($db_name)) {
        my $bad = _shown_name($db_name);
        $errstr = "Invalid database name '$bad'";
        return 0;
    }
    my $path = $self->_db_path($db_name);
    unless (-d $path) {
        $errstr = "Database '$db_name' does not exist";
        return 0;
    }
    eval {
        File::Path::rmtree($path);
    };
    if ($@) {
        $errstr = "Cannot drop database '$db_name': $@";
        return 0;
    }
    $self->{db_name} = '' if $self->{db_name} eq $db_name;
    return 1;
}

sub list_databases {
    my($self) = @_;
    my $base = $self->{base_dir};
    local *DH;
    opendir(DH, $base) or do { $errstr = "Cannot open base_dir: $!"; return (); };
    my @dbs = grep { !/^\./ && -d File::Spec->catdir($base, $_) } readdir(DH);
    closedir DH;
    return sort @dbs;
}

###############################################################################
# Table-level
###############################################################################
sub create_table {
    my($self, $table, $columns) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    return $self->_err("Invalid table name '" . _shown_name($table) . "'")
        unless _valid_name($table);
    my $sch_file = $self->_file($table, 'sch');
    return $self->_err("Table '$table' already exists") if -f $sch_file;

    my @cols;
    my $rec_size = 1;
    for my $col (@$columns) {
        my($name, $type, $size) = @$col;
        $type = uc($type);
        return $self->_err("Unknown type '$type'") unless exists $TYPE_SIZE{$type};
        my $store;
        if ($type eq 'CHAR') {
            return $self->_err("CHAR requires a size") unless $size && ($size > 0);
            $store = int($size);
        }
        elsif ($type eq 'VARCHAR') {
            $store = MAX_VARCHAR;
        }
        else {
            $store = $TYPE_SIZE{$type};
        }
        $rec_size += $store;
        # decl is the declared size (from CREATE TABLE); for VARCHAR it may
        # differ from the physical storage size (MAX_VARCHAR).
        my $decl = (defined $size && $size > 0) ? int($size) : $store;
        push @cols, { name=>$name, type=>$type, size=>$store, decl=>$decl };
    }

    local *FH;
    open(FH, "> $sch_file") or return $self->_err("Cannot write schema: $!");
    my $ok = print FH "VERSION=1\n";
    $ok &&= print FH "RECSIZE=$rec_size\n";
    for my $c (@cols) {
        $ok &&= print FH "COL=$c->{name}:$c->{type}:$c->{size}:$c->{decl}\n";
    }
    my $err = $!;
    unless ($ok && close(FH)) {
        $err = $! if $ok;
        close FH if $ok;
        unlink $sch_file;
        return $self->_err("Cannot write schema: $err");
    }

    local *FH;
    my $dat_file = $self->_file($table, 'dat');
    open(FH, "> $dat_file") or return $self->_err("Cannot create dat: $!");
    binmode FH;
    unless (close FH) {
        my $e = $!;
        unlink $sch_file;
        return $self->_err("Cannot create dat: $e");
    }
    return 1;
}

sub drop_table {
    my($self, $table) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    return $self->_err("Invalid table name '" . _shown_name($table) . "'")
        unless _valid_name($table);
    my $sch = $self->_load_schema($table);
    if ($sch && $sch->{indexes}) {
        for my $ix (values %{$sch->{indexes}}) {
            my $f = $self->_idx_file($table, $ix->{name});
            unlink $f if -f $f;
        }
    }
    for my $ext (qw(sch dat lck)) {
        my $f = $self->_file($table, $ext);
        unlink $f if -f $f;
    }
    my $dir = $self->_db_path($self->{db_name});
    local *DH;
    if (opendir DH, $dir) {
        for my $f (readdir DH) {
            unlink File::Spec->catfile($dir, $f) if $f =~ /^\Q${table}\E\.[^.]+\.idx$/;
        }
        closedir DH;
    }
    delete $self->{_tables}{$table};
    return 1;
}

sub list_tables {
    my($self) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    my $dir = $self->_db_path($self->{db_name});
    local *DH;
    opendir(DH, $dir) or return ();
    my @tbls = map { /^(.+)\.sch$/ ? $1 : () } readdir DH;
    closedir DH;
    return sort @tbls;
}

sub describe_table {
    my($self, $table) = @_;
    my $sch = $self->_load_schema($table) or return undef;
    return $sch->{cols};
}

###############################################################################
# INDEX DDL
###############################################################################
sub create_index {
    my($self, $idxname, $table, $colname, $unique) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    return $self->_err("Invalid index name '" . _shown_name($idxname) . "'")
        unless _valid_name($idxname);
    my $sch = $self->_load_schema($table) or return undef;

    my($col_def) = grep { $_->{name} eq $colname } @{$sch->{cols}};
    return $self->_err("Column '$colname' not found in '$table'") unless $col_def;
    return $self->_err("Index '$idxname' already exists on '$table'") if $sch->{indexes}{$idxname};

    $unique = $unique ? 1 : 0;

    my $sch_file = $self->_file($table, 'sch');
    local *FH;
    open(FH, ">> $sch_file") or return $self->_err("Cannot update schema: $!");
    my $ok = print FH "IDX=$idxname:$colname:$unique\n";
    my $err = $!;
    unless ($ok && close(FH)) {
        $err = $! if $ok;
        close FH if $ok;
        return $self->_err("Cannot update schema: $err");
    }

    $sch->{indexes}{$idxname} = {
        name    => $idxname,
        col     => $colname,
        unique  => $unique,
        keysize => $col_def->{size},
        coltype => $col_def->{type},
    };

    return $self->_rebuild_index($table, $idxname);
}

sub drop_index {
    my($self, $idxname, $table) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    return $self->_err("Invalid index name '" . _shown_name($idxname) . "'")
        unless _valid_name($idxname);
    my $sch = $self->_load_schema($table) or return undef;
    return $self->_err("Index '$idxname' does not exist on '$table'") unless $sch->{indexes}{$idxname};

    unlink $self->_idx_file($table, $idxname);
    delete $sch->{indexes}{$idxname};
    return $self->_rewrite_schema($table, $sch);
}

sub list_indexes {
    my($self, $table) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    my $sch = $self->_load_schema($table) or return undef;
    return [ values %{$sch->{indexes}} ];
}

###############################################################################
# DML: INSERT
###############################################################################
sub insert {
    my($self, $table, $row) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    my $sch = $self->_load_schema($table) or return undef;

    for my $col (@{$sch->{cols}}) {
        my $cn = $col->{name};
        if ((!defined($row->{$cn}) || ($row->{$cn} eq '')) && defined $sch->{defaults}{$cn}) {
            $row->{$cn} = $sch->{defaults}{$cn};
        }
    }

    # UNIQUE check.  It runs after DEFAULT has been applied, so that the
    # value actually stored is the one compared.  NULL is the empty string
    # here and SQL-92 lets a UNIQUE column hold any number of NULLs, so an
    # absent value is not compared at all.
    for my $ix (values %{$sch->{indexes}}) {
        next unless $ix->{unique};
        my $val = $row->{$ix->{col}};
        next unless defined($val) && ($val ne '');
        if ($self->_idx_lookup_exact($table, $ix, $val) >= 0) {
            return $self->_err("UNIQUE constraint violated on '$ix->{name}' (col '$ix->{col}', value '$val')");
        }
    }

    for my $cn (keys %{$sch->{notnull} || {}}) {
        return $self->_err("NOT NULL constraint violated on column '$cn'") unless defined($row->{$cn}) && ($row->{$cn} ne '');
    }
    for my $cn (keys %{$sch->{checks} || {}}) {
        next unless defined($row->{$cn}) && ($row->{$cn} ne '');
        return $self->_err("CHECK constraint failed on column '$cn'") unless eval_bool($sch->{checks}{$cn}, $row);
    }
    # VARCHAR / CHAR length check: reject values longer than the declared size.
    for my $col (@{$sch->{cols}}) {
        my $cn = $col->{name};
        next unless ($col->{type} eq 'VARCHAR' || $col->{type} eq 'CHAR');
        my $decl = defined($col->{decl}) ? $col->{decl} : $col->{size};
        next unless defined($decl) && ($decl < MAX_VARCHAR);
        next unless defined($row->{$cn}) && ($row->{$cn} ne '');
        if (length($row->{$cn}) > $decl) {
            return $self->_err(
                "Value too long for column '$cn': "
                . "declared $col->{type}($decl), got "
                . length($row->{$cn}) . " bytes"
            );
        }
    }
    # Type check: INT range and DATE validity.
    for my $col (@{$sch->{cols}}) {
        my $msg = _type_error($col, $row->{$col->{name}});
        return $self->_err($msg) if defined $msg;
    }
    my $packed = $self->_pack_record($sch, $row) or return undef;
    my $dat = $self->_file($table, 'dat');
    local *FH;
    open(FH, ">> $dat") or return $self->_err("Cannot open dat for append: $!");
    binmode FH;
    _autoflush(\*FH);
    _lock_ex(\*FH);
    my $file_size = (stat FH)[7];
    my $rec_no    = int($file_size / $sch->{recsize});
    unless (print FH $packed) {
        my $e = $!;
        _unlock(\*FH);
        close FH;
        return $self->_err("Cannot write record: $e");
    }

    # The .dat lock is held until every index is updated, so that another
    # process never sees the new record without its index entries.
    for my $ix (values %{$sch->{indexes}}) {
        $self->_idx_insert($table, $ix, $row->{$ix->{col}}, $rec_no);
    }
    _unlock(\*FH);
    unless (close FH) {
        return $self->_err("Cannot flush record: $!");
    }
    return 1;
}

sub delete_rows {
    my($self, $table, $where_info) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    my $sch       = $self->_load_schema($table) or return undef;
    my $where_sub = _to_where_sub($where_info);
    my $dat       = $self->_file($table, 'dat');
    my $recsize   = $sch->{recsize};
    my $count     = 0;

    local *FH;
    open(FH, "+< $dat") or return $self->_err("Cannot open dat for delete: $!");
    binmode FH;
    _autoflush(\*FH);
    _lock_ex(\*FH);

    seek(FH, 0, 0);
    my($pos, $rec_no) = (0, 0);
    while (1) {
        seek(FH, $pos, 0);
        my $raw = '';
        my $n = read(FH, $raw, $recsize);
        last unless defined($n) && ($n == $recsize);
        if (substr($raw, 0, 1) ne RECORD_DELETED) {
            my $row = $self->_unpack_record($sch, $raw);
            if (!$where_sub || $where_sub->($row)) {
                seek(FH, $pos, 0);
                unless (print FH RECORD_DELETED) {
                    my $e = $!;
                    _unlock(\*FH);
                    close FH;
                    return $self->_err("Cannot mark record deleted: $e");
                }
                $count++;
                for my $ix (values %{$sch->{indexes}}) {
                    $self->_idx_delete($table, $ix, $row->{$ix->{col}}, $rec_no);
                }
            }
        }
        $pos += $recsize;
        $rec_no++;
    }
    _unlock(\*FH);
    unless (close FH) {
        return $self->_err("Cannot flush dat: $!");
    }
    return $count;
}

###############################################################################
# VACUUM
###############################################################################
sub vacuum {
    my($self, $table) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    my $sch     = $self->_load_schema($table) or return undef;
    my $dat     = $self->_file($table, 'dat');
    my $tmp     = $dat . '.tmp';
    my $recsize = $sch->{recsize};

    local *IN_FH;
    open(IN_FH,  "< $dat") or return $self->_err("Cannot open dat: $!");
    local *OUT_FH;
    open(OUT_FH, "> $tmp") or do { close IN_FH; return $self->_err("Cannot open tmp: $!"); };
    binmode IN_FH;
    binmode OUT_FH;
    _lock_ex(\*IN_FH);

    my $kept = 0;
    while (1) {
        my $raw = '';
        my $n = read(IN_FH, $raw, $recsize);
        last unless defined($n) && ($n == $recsize);
        if (substr($raw, 0, 1) ne RECORD_DELETED) {
            unless (print OUT_FH $raw) {
                my $e = $!;
                close OUT_FH;
                _unlock(\*IN_FH);
                close IN_FH;
                unlink $tmp;
                return $self->_err("Cannot write tmp: $e");
            }
            $kept++;
        }
    }
    # close() flushes, so the replacement file is complete on disk before
    # the exclusive lock on the original is released.
    my $out_ok  = close(OUT_FH);
    my $out_err = $!;
    _unlock(\*IN_FH);
    close IN_FH;
    unless ($out_ok) {
        unlink $tmp;
        return $self->_err("Cannot flush tmp: $out_err");
    }
    rename($tmp, $dat) or do {
        my $e = $!;
        unlink $tmp;
        return $self->_err("Cannot replace dat: $e");
    };

    for my $ix (values %{$sch->{indexes}}) {
        $self->_rebuild_index($table, $ix->{name}) or return undef;
    }
    return $kept;
}

###############################################################################
# execute()
###############################################################################
sub execute {
    my($self, $sql) = @_;
    $sql = _strip_sql_comments($sql);
    $sql =~ s/^\s+|\s+$//g;
    $sql = _normalize_sql_space($sql);

    # Detect subqueries: any SELECT that contains a nested (SELECT ...)
    # Route through the subquery engine, but guard against infinite recursion
    # by only routing non-trivial top-level statements (not pure SELECT).
    if ($sql =~ /\(\s*SELECT\b/i) {

        # Only intercept DML/DDL statements and complex SELECTs here;
        # pure inner SELECTs (called recursively) pass through normally.
        # Top-level statements that may contain subqueries:
        if ($sql =~ /^(?:SELECT|INSERT|UPDATE|DELETE)\b/i) {
            return $self->execute_with_subquery($sql);
        }
    }

    if ($sql =~ /^CREATE\s+DATABASE\s+(\w+)$/i) {
        return $self->create_database($1)
            ? { type=>'ok',    message=>"Database '$1' created" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^USE\s+(\w+)$/i) {
        return $self->use_database($1)
            ? { type=>'ok',    message=>"Using database '$1'" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^DROP\s+DATABASE\s+(\w+)$/i) {
        return $self->drop_database($1)
            ? { type=>'ok',    message=>"Database '$1' dropped" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^SHOW\s+DATABASES$/i) {
        return { type=>'list', data=>[ $self->list_databases() ] };
    }
    if ($sql =~ /^SHOW\s+TABLES$/i) {
        return { type=>'list', data=>[ $self->list_tables() ] };
    }
    if ($sql =~ /^SHOW\s+(?:INDEXES|INDICES|INDEX)\s+(?:ON|FROM)\s+(\w+)$/i) {
        my $ixs = $self->list_indexes($1);
        return defined($ixs)
            ? { type=>'indexes', table=>$1, data=>$ixs }
            : { type=>'error',   message=>$errstr };
    }
    if ($sql =~ /^DESCRIBE\s+(\w+)$/i) {
        my $cols = $self->describe_table($1);
        return $cols
            ? { type=>'describe', data=>$cols }
            : { type=>'error',    message=>$errstr };
    }
    if ($sql =~ /^CREATE\s+TABLE\s+(\w+)\s*\((.+)\)$/si) {
        my($tbl, $col_str) = ($1, $2);
        my @col_defs = _split_col_defs($col_str);
        my(@cols, %nn, %defs, %chks, %uniq, $pk);
        for my $cd (@col_defs) {
            $cd =~ s/^\s+|\s+$//g;
            if ($cd =~ /^PRIMARY\s+KEY\s*\(\s*(\w+)\s*\)$/si) {
                $pk = $1;
                next;
            }
            # Table-level UNIQUE (col): enforced through a unique index,
            # exactly like the column-level UNIQUE modifier below.
            if ($cd =~ /^UNIQUE\s*\(\s*(\w+)\s*\)$/si) {
                $uniq{$1} = 1;
                next;
            }
            # FOREIGN KEY (...) REFERENCES ...: table-level constraint.
            # Accepted silently (constraint is not enforced).
            if ($cd =~ /^FOREIGN\s+KEY\b/si) {
                next;
            }
            my($cn, $ct, $cs, $rest);
            if ($cd =~ /^(\w+)\s+(CHAR|VARCHAR)\s*\(\s*(\d+)\s*\)(.*)/si) {
                ($cn, $ct, $cs, $rest) = ($1, uc($2), $3, $4);
            }
            elsif ($cd =~ /^(\w+)\s+(\w+)(.*)/si) {
                ($cn, $ct, $rest) = ($1, uc($2), $3);
                $cs = undef;
            }
            else {
                return { type=>'error', message=>"Cannot parse column def: $cd" };
            }
            push @cols, [ $cn, $ct, $cs ];
            $rest      = '' unless defined $rest;
            $pk        = $cn if $rest =~ /\bPRIMARY\s+KEY\b/si;
            $nn{$cn}   = 1 if $rest =~ /\b(?:NOT\s+NULL|PRIMARY\s+KEY)\b/si;
            $defs{$cn} = (defined($1) ? $1 : $2) if $rest =~ /\bDEFAULT\s+(?:'([^']*)'|(-?\d+\.?\d*))/si;
            $chks{$cn} = $1 if $rest =~ /\bCHECK\s*\((.+)\)/si;
            # UNIQUE is looked for with the CHECK expression removed, so
            # that a CHECK body that happens to mention the word cannot
            # produce a false hit.
            my $ukw = $rest;
            $ukw =~ s/\bCHECK\s*\(.+\)//si;
            $uniq{$cn} = 1 if $ukw =~ /\bUNIQUE\b/si;
        }
        $nn{$pk} = 1 if defined $pk;
        $self->create_table($tbl, [ @cols ]) or return { type=>'error', message=>$errstr };
        if (%nn || %defs || %chks || defined $pk) {
            my $sch = $self->_load_schema($tbl) or return { type=>'error', message=>$errstr };
            $sch->{notnull}  = { %nn   };
            $sch->{defaults} = { %defs };
            $sch->{checks}   = { %chks };
            $sch->{pk}       = $pk if defined $pk;
            $self->_rewrite_schema($tbl, $sch);
        }

        # PRIMARY KEY and UNIQUE are enforced by insert() and update()
        # through a unique index, so one has to be created here.  Without
        # it both constraints were silently accepted and never checked.
        # A column that is both PRIMARY KEY and UNIQUE gets a single index.
        my(@auto_idx, %seen_idx);
        if (defined $pk) {
            push @auto_idx, [ $pk, $pk . '_pk' ];
            $seen_idx{$pk} = 1;
        }
        for my $c (@cols) {
            my $cn = $c->[0];
            next unless $uniq{$cn};
            next if $seen_idx{$cn}++;
            push @auto_idx, [ $cn, $cn . '_unique' ];
        }
        for my $ai (@auto_idx) {
            next if $self->create_index($ai->[1], $tbl, $ai->[0], 1);
            my $msg = $errstr;
            $self->drop_table($tbl);
            return { type=>'error', message=>$msg };
        }

        my $fk_note = ($col_str =~ /\bREFERENCES\b/si
                       || $col_str =~ /\bFOREIGN\s+KEY\b/si)
            ? " (NOTE: FOREIGN KEY constraints are not enforced)"
            : "";
        return { type=>'ok', message=>"Table '$tbl' created$fk_note" };
    }
    if ($sql =~ /^DROP\s+TABLE\s+(\w+)$/i) {
        return $self->drop_table($1)
            ? { type=>'ok',    message=>"Table '$1' dropped" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^CREATE\s+(UNIQUE\s+)?INDEX\s+(\w+)\s+ON\s+(\w+)\s*\(\s*(\w+)\s*\)$/i) {
        my($uniq, $idxname, $tbl, $col) = ($1, $2, $3, $4);
        return $self->create_index($idxname, $tbl, $col, $uniq ? 1 : 0)
            ? { type=>'ok',    message=>"Index '$idxname' created on '$tbl'('$col')" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^DROP\s+INDEX\s+(\w+)\s+ON\s+(\w+)$/i) {
        return $self->drop_index($1, $2)
            ? { type=>'ok',    message=>"Index '$1' dropped" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^VACUUM\s+(\w+)$/i) {
        my $n = $self->vacuum($1);
        return defined($n)
            ? { type=>'ok',    message=>"Vacuum done, $n records kept" }
            : { type=>'error', message=>$errstr };
    }
    # INSERT INTO table VALUES (...)  -- no column list: use schema order
    if ($sql =~ /^INSERT\s+INTO\s+(\w+)\s+VALUES\s*\((.+)\)$/si) {
        my($tbl, $val_str) = ($1, $2);
        my $sch = $self->_load_schema($tbl)
            or return { type=>'error', message=>"Table '$tbl' does not exist" };
        my @cols = map { $_->{name} } @{$sch->{cols}};
        my @v = _parse_values($val_str);
        if (@v != @cols) {
            return { type=>'error',
                     message=>"INSERT: " . scalar(@v) . " value(s) for "
                              . scalar(@cols) . " column(s) in table '$tbl'" };
        }
        my %row;
        @row{@cols} = @v;
        return $self->insert($tbl, { %row })
            ? { type=>'ok',    message=>"1 row inserted" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^INSERT\s+INTO\s+(\w+)\s*\(([^)]+)\)\s*VALUES\s*\((.+)\)$/si) {
        my($tbl, $col_str, $val_str) = ($1, $2, $3);
        my @c = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } split /,/, $col_str;
        my @v = _parse_values($val_str);
        my %row;
        @row{@c} = @v;
        return $self->insert($tbl, { %row })
            ? { type=>'ok',    message=>"1 row inserted" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^INSERT\s+INTO\s+(\w+)\s*\(([^)]+)\)\s+(SELECT\b.+)$/si) {
        my($tbl, $cs, $sel) = ($1, $2, $3);
        my @dst_cols = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } split /,/, $cs;

        # Extract SELECT column list in declaration order.
        # The engine stores rows as hashes (alphabetical key order), so we
        # must parse the SELECT list to know the intended positional mapping.
        my @src_cols;
        if ($sel =~ /^SELECT\s+(.*?)\s+FROM\s+/si) {
            @src_cols = map { my $c = $_; $c =~ s/^\s+|\s+$//g; $c =~ s/\s+AS\s+\w+$//si; $c } split /,/, $1;
        }
        my $res = $self->execute($sel);
        return { type=>'error', message=>$res->{message} } if $res->{type} eq 'error';
        my $n = 0;
        for my $r (@{$res->{data}}) {

            # Map SELECT result columns to INSERT destination columns.
            #
            # Name-based mapping (preferred): when every dst column name
            # exists as a key in the result row, map by name regardless of
            # position.  This handles INSERT INTO dst(a,b) SELECT b,a FROM src
            # correctly and is insensitive to SELECT column order.
            #
            # Position-based fallback: used when dst and src columns differ
            # (e.g. INSERT INTO dst(x,y) SELECT a,b FROM src) or when src
            # columns could not be parsed (SELECT *).
            my %row;
            my %rkeys = map { $_ => 1 } keys %$r;
            my $name_based = @dst_cols
                && !grep { !$rkeys{$_} } @dst_cols;
            if ($name_based) {
                for my $col (@dst_cols) {
                    $row{$col} = $r->{$col};
                }
            }
            else {
                my @src_keys = @src_cols ? @src_cols : sort keys %$r;
                for my $i (0 .. $#dst_cols) {
                    $row{$dst_cols[$i]} = defined($src_keys[$i])
                                         ? $r->{$src_keys[$i]} : undef;
                }
            }
            $self->insert($tbl, { %row }) and $n++;
        }
        return { type=>'ok', message=>"$n row(s) inserted" };
    }
    if ($sql =~ /^SELECT\b/i) {
        my $sel_res = $self->select($sql);
        return $sel_res if defined $sel_res;
        return { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^UPDATE\s+(\w+)\s+SET\s+(.+?)(\s+WHERE\s+.+)?$/si) {
        my($tbl, $set_str, $wc) = ($1, $2, (defined($3) ? $3 : ''));
        my %se = parse_set_exprs($set_str);
        my $ws;
        if ($wc =~ /\bWHERE\s+(.+)/si) {
            (my $e = $1) =~ s/^\s+|\s+$//g;
            $ws = where_sub($e);
        }
        my $n = $self->update($tbl, { %se }, $ws);
        return defined($n)
            ? { type=>'ok',    message=>"$n row(s) updated" }
            : { type=>'error', message=>$errstr };
    }
    if ($sql =~ /^DELETE\s+FROM\s+(\w+)(.*)?$/si) {
        my($tbl, $rest) = ($1, (defined($2) ? $2 : ''));
        my $ws;
        if ($rest =~ /\bWHERE\s+(.+)/si) {
            (my $e = $1) =~ s/^\s+|\s+$//g;
            $ws = where_sub($e);
        }
        my $n = $self->delete_rows($tbl, $ws);
        return defined($n)
            ? { type=>'ok',    message=>"$n row(s) deleted" }
            : { type=>'error', message=>$errstr };
    }
    return { type=>'error', message=>"Unsupported SQL: $sql" };
}

###############################################################################
# SUBQUERY ENGINE
#
# Supported subquery positions:
#
#  1. WHERE col IN     (SELECT single_col FROM ...)
#  2. WHERE col NOT IN (SELECT single_col FROM ...)
#  3. WHERE col OP     (SELECT single_col FROM ...)   OP = = != < > <= >=
#  4. WHERE EXISTS     (SELECT ... FROM ...)
#  5. WHERE NOT EXISTS (SELECT ... FROM ...)
#  6. FROM (SELECT ...) AS alias          -- derived table / inline view
#  7. SELECT (SELECT single_col ...) AS alias  -- scalar subquery in SELECT list
#
# Nesting: subqueries may themselves contain subqueries (recursive expansion).
# Correlated subqueries: outer row values injected via _subq_context hashref.
###############################################################################

# ---------------------------------------------------------------------------
# Public wrapper: expand all subqueries in a SQL string, then execute.
# Called by execute() when a subquery token is detected.
# ---------------------------------------------------------------------------
sub execute_with_subquery {
    my($self, $sql) = @_;

    # Handle derived table in FROM:  FROM (SELECT ...) AS alias
    if ($sql =~ /\bFROM\s*\(/i) {
        return $self->_exec_derived_table($sql);
    }

    # Handle scalar subqueries in SELECT list:  SELECT (SELECT ...) AS alias
    if ($sql =~ /^SELECT\s*\(/i) {
        return $self->_exec_scalar_select_subquery($sql);
    }

    # Expand WHERE-clause subqueries iteratively (innermost first)
    my $expanded = $self->_expand_where_subqueries($sql, {});
    return $expanded if ref($expanded) eq 'HASH'; # error hash

    # If correlated subqueries remain (still contain (SELECT), use row-level evaluator
    if ($expanded =~ /\(\s*SELECT\b/i) {
        return $self->_exec_correlated_select($expanded);
    }

    return $self->execute($expanded);
}

# ---------------------------------------------------------------------------
# Execute a SELECT with correlated subqueries in the WHERE clause.
# Scans each row, evaluates the subquery with the row as outer context.
# ---------------------------------------------------------------------------
sub _exec_correlated_select {
    my($self, $sql) = @_;

    # Must be a plain SELECT (no JOIN, no derived table)
    unless ($sql =~ /^SELECT\s+(.+?)\s+FROM\s+(\w+)(.*)?$/i) {
        return { type=>'error', message=>"Cannot execute correlated query: $sql" };
    }
    my($col_str, $tbl, $rest) = ($1, $2, (defined($3) ? $3 : ''));

    my $sch = $self->_load_schema($tbl) or return { type=>'error', message=>$errstr };

    # Parse col list
    my @sel_cols;
    unless ($col_str =~ /^\*$/) {
        @sel_cols = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } split /,/, $col_str;
    }

    # Strip ORDER BY / LIMIT / OFFSET
    my %opts;
    if ($rest =~ s/\bLIMIT\s+(\d+)//i) {
        $opts{limit} = $1;
    }
    if ($rest =~ s/\bOFFSET\s+(\d+)//i) {
        $opts{offset} = $1;
    }
    if ($rest =~ s/\bORDER\s+BY\s+(\w+)(?:\s+(ASC|DESC))?//i) {
        $opts{order_by}  = $1;
        $opts{order_dir} = defined($2) ? $2 : 'ASC';
        my @onames = @sel_cols
            ? map { _order_name_of($_) } @sel_cols
            : map { $_->{name} } @{$sch->{cols}};
        my($obe, $obk) = _resolve_order_ordinal_scalar($opts{order_by}, [ @onames ]);
        return { type=>'error', message=>$obe } if $obe ne '';
        $opts{order_by} = $obk;
    }

    # Extract WHERE expression
    my $where_expr = '';
    if ($rest =~ /\bWHERE\s+(.+)/i) {
        $where_expr = $1;
        $where_expr =~ s/^\s+|\s+$//g;
    }

    # Parse conditions (may include subquery conditions)
    my $conds  = $self->_parse_conditions_with_subq($where_expr);
    my $filter = $self->_compile_where_with_subq($conds);

    # Full scan with per-row subquery evaluation
    my $dat     = $self->_file($tbl, 'dat');
    my $recsize = $sch->{recsize};
    my @results;

    local *FH;
    open(FH, "< $dat") or return { type=>'error', message=>"Cannot open dat: $!" };
    binmode FH;
    _lock_sh(\*FH);
    my $rec_no = 0;
    while (1) {
        my $raw = '';
        my $n   = read(FH, $raw, $recsize);
        last unless defined($n) && ($n == $recsize);
        if (substr($raw, 0, 1) ne RECORD_DELETED) {
            my $row = $self->_unpack_record($sch, $raw);

            # Make row available under both bare and table-qualified names
            my %qrow = %$row;
            for my $c (@{$sch->{cols}}) {
                $qrow{"$tbl.$c->{name}"} = $row->{$c->{name}};
            }
            push @results, { %qrow } if $filter->({ %qrow });
        }
        $rec_no++;
    }
    _unlock(\*FH);
    close FH;

    # ORDER BY
    if (my $ob = $opts{order_by}) {
        my $dir = lc(defined($opts{order_dir}) ? $opts{order_dir} : 'asc');
        @results = sort {
            my($va, $vb) = ($a->{$ob}, $b->{$ob});
            my $cmp = (defined($va) && ($va =~ /^-?\d+\.?\d*$/) &&
                       defined($vb) && ($vb =~ /^-?\d+\.?\d*$/))
                      ? ($va <=> $vb)
                      : ((defined($va) ? $va : '') cmp (defined($vb) ? $vb : ''));
            ($dir eq 'desc') ? -$cmp : $cmp;
        } @results;
    }

    # OFFSET / LIMIT
    my $off = defined($opts{offset}) ? $opts{offset} : 0;
    @results = splice(@results, $off) if $off;
    if (defined $opts{limit}) {
        my $last = $opts{limit} - 1;
        $last = $#results if $last > $#results;
        @results = @results[0..$last];
    }

    # Column projection (remove table-qualified duplicates)
    my @proj;
    for my $r (@results) {
        my %p;
        if (@sel_cols) {
            for my $c (@sel_cols) {
                $p{$c} = $r->{$c};
            }
        }
        else {

            # All bare columns
            for my $c (@{$sch->{cols}}) {
                $p{$c->{name}} = $r->{$c->{name}};
            }
        }
        push @proj, { %p };
    }

    return { type=>'rows', data=>[ @proj ] };
}

# ---------------------------------------------------------------------------
# _expand_where_subqueries($sql, \%outer_row)
#
# Finds the innermost (SELECT ...) in a WHERE clause and replaces it with
# its evaluated result (a literal list or scalar).  Repeats until no
# subqueries remain.  Returns the rewritten SQL string, or error hashref.
# ---------------------------------------------------------------------------
sub _expand_where_subqueries {
    my($self, $sql, $outer_row) = @_;
    $outer_row ||= {};

    my $max_depth = 32;
    my $iter      = 0;

    while (($sql =~ /\(\s*SELECT\b/i) && ($iter++ < $max_depth)) {

        # Find the innermost (SELECT ...) -- i.e. the one with no nested (SELECT
        my $pos = _find_innermost_subquery($sql);
        last unless defined $pos;

        my($start, $end) = @$pos;
        my $inner_sql = substr($sql, $start + 1, $end - $start - 1);
        $inner_sql =~ s/^\s+|\s+$//g;

        # Determine context: what precedes the opening paren
        my $prefix = substr($sql, 0, $start);

        # Detect correlated subquery: inner SQL contains tablename.colname
        # references that are NOT from the inner query's own tables.
        # Heuristic: if inner_sql has \w+\.\w+ patterns, check if those
        # table-names appear in the inner FROM clause.
        if (_subquery_is_correlated($inner_sql)) {

            # Cannot pre-evaluate; will be handled per-row in _compile_where_with_subq.
            # Mark as a correlated subquery placeholder and stop expanding here.
            last;
        }

        # Inject outer row values for correlated references
        my $resolved = $self->_resolve_correlated($inner_sql, $outer_row);

        # Execute the inner query
        my $inner_res = $self->execute($resolved);
        if (!$inner_res || ($inner_res->{type} eq 'error')) {
            my $msg = $inner_res ? $inner_res->{message} : $errstr;
            return { type=>'error', message=>"Subquery error: $msg" };
        }

        my @inner_rows = @{ $inner_res->{data} || [] };

        # Determine what kind of subquery this is based on prefix context
        my $replacement;
        if (($prefix =~ /\bIN\s*$/i) || ($prefix =~ /\bNOT\s+IN\s*$/i)) {

            # IN / NOT IN: build a parenthesised list of literal values
            my @vals;
            for my $r (@inner_rows) {
                my @rv = values %$r;
                my $v  = defined($rv[0]) ? $rv[0] : 'NULL';
                if ($v =~ /^-?\d+\.?\d*$/) {
                    push @vals, $v;
                }
                else {
                    push @vals, "'$v'";
                }
            }
            if (@vals) {
                $replacement = '(' . join(',', @vals) . ')';
            }
            else {

                # Empty set semantics:
                #   col IN     (empty) -> always false -> use (NULL)
                #   col NOT IN (empty) -> always true  -> use a value that
                #     never matches col, so NOT IN evaluates to true for
                #     every row.  We inject the sentinel '__EMPTY_SET__'
                #     (not a valid column value) which will not match.
                if ($prefix =~ /\bNOT\s+IN\s*$/i) {
                    $replacement = "('__EMPTY_SET__')";
                }
                else {
                    $replacement = '(NULL)';
                }
            }
        }
        elsif ($prefix =~ /\b(?:EXISTS|NOT\s+EXISTS)\s*$/i) {

            # EXISTS / NOT EXISTS: replace the paren content with 1 or 0
            # The EXISTS keyword stays; we replace just the (SELECT ...) with (1) or (0)
            $replacement = @inner_rows ? '(1)' : '(0)';
        }
        else {

            # Scalar subquery (=, !=, <, >, <=, >=, or bare use)
            if (@inner_rows > 1) {
                return { type=>'error', message=>"Subquery returns more than one row" };
            }
            if (@inner_rows == 0) {
                $replacement = 'NULL';
            }
            else {
                my @rv = values %{ $inner_rows[0] };
                my $v  = defined($rv[0]) ? $rv[0] : 'NULL';
                $replacement = ($v =~ /^-?\d+\.?\d*$/) ? $v : "'$v'";
            }
        }

        # Splice the replacement into the SQL
        substr($sql, $start, $end - $start + 1) = $replacement;
    }

    return $sql;
}

# ---------------------------------------------------------------------------
# Detect whether a subquery SQL string contains correlated outer references.
# A subquery is correlated if it contains  alias.colname  where the alias
# is NOT one of the tables listed in its own FROM clause.
# ---------------------------------------------------------------------------
sub _subquery_is_correlated {
    my($inner_sql) = @_;

    # Find tables in the inner FROM clause
    my %inner_tables;

    # FROM t1 [AS a1] [JOIN t2 AS a2 ON ...]*
    if ($inner_sql =~ /\bFROM\s+(\w+)(?:\s+(?:AS\s+)?(\w+))?/i) {
        $inner_tables{ lc(defined($2) ? $2 : $1) } = 1;
        $inner_tables{ lc($1) } = 1;
    }
    while ($inner_sql =~ /\bJOIN\s+(\w+)(?:\s+(?:AS\s+)?(\w+))?/gi) {
        $inner_tables{ lc(defined($2) ? $2 : $1) } = 1;
        $inner_tables{ lc($1) } = 1;
    }

    # Look for alias.col references in WHERE clause
    while ($inner_sql =~ /\b(\w+)\.(\w+)\b/g) {
        my($tbl, $col) = (lc($1), $2);
        return 1 unless $inner_tables{$tbl};
    }
    return 0;
}

# ---------------------------------------------------------------------------
# Find the innermost (SELECT ...) -- the one whose content has no nested
# (SELECT.  Returns [$start_pos, $end_pos] of the outer parens, or undef.
# ---------------------------------------------------------------------------
sub _find_innermost_subquery {
    my($sql) = @_;
    my $len = length($sql);
    my $best_start;
    my $best_end;

    my $i = 0;
    while ($i < $len) {

        # Look for ( followed (possibly with spaces) by SELECT
        if (substr($sql, $i, 1) eq '(' ) {

            # Check if this opens a SELECT
            my $peek = substr($sql, $i+1);
            $peek =~ s/^\s+//;
            if ($peek =~ /^SELECT\b/i) {

                # Walk to matching close paren, check for no nested SELECT
                my $depth      = 1;
                my $j          = $i + 1;
                my $has_nested = 0;
                my $in_str     = 0;
                while (($j < $len) && ($depth > 0)) {
                    my $ch = substr($sql, $j, 1);
                    if ($ch eq "'") {

                        # Toggle string mode
                        $in_str = !$in_str;
                    }
                    elsif (!$in_str) {
                        if ($ch eq '(') {
                            $depth++;

                            # check for nested SELECT
                            my $p2 = substr($sql, $j+1);
                            $p2 =~ s/^\s+//;
                            $has_nested = 1 if ($depth > 1) && ($p2 =~ /^SELECT\b/i);
                        }
                        elsif ($ch eq ')') {
                            $depth--;
                        }
                    }
                    $j++;
                }
                if (($depth == 0) && !$has_nested) {

                    # This is an innermost SELECT subquery
                    $best_start = $i;
                    $best_end   = $j - 1;

                    # Don't break -- we want the last (innermost) one found
                }
            }
        }
        $i++;
    }

    return defined($best_start) ? [ $best_start, $best_end ] : undef;
}

# ---------------------------------------------------------------------------
# _resolve_correlated($inner_sql, \%outer_row)
#
# Replace references to outer-row columns in a correlated subquery.
# Outer references appear as  outer.colname  or are matched when the column
# name exists in %outer_row but NOT in the inner query's table.
# Simple heuristic: replace  outer.col  tokens with the literal value.
# ---------------------------------------------------------------------------
sub _resolve_correlated {
    my($self, $sql, $outer_row) = @_;
    return $sql unless %$outer_row;

    # Build sorted list: longer (qualified) keys first so alias.col
    # is replaced before bare col to avoid double-substitution.
    my @keys = sort { length($b) <=> length($a) } keys %$outer_row;

    for my $qkey (@keys) {
        my $val = defined($outer_row->{$qkey}) ? $outer_row->{$qkey} : 'NULL';
        my $lit = ($val =~ /^-?\d+\.?\d*$/) ? $val : "'$val'";

        if (index($qkey, '.') >= 0) {

            # Qualified key: e.g. "employees.id"
            # Build regex that matches the full qualified token
            (my $pat = $qkey) =~ s/\./\\./g;
            $sql =~ s/(?<![.\w])$pat(?!\w)/$lit/g;
        }
        else {

            # Bare key: only replace if NOT preceded by a dot
            # (avoids replacing "id" inside "employees.id" already handled above)
            $sql =~ s/(?<![.\w])$qkey(?!\w)/$lit/g;
        }
    }
    return $sql;
}

# ---------------------------------------------------------------------------
# EXISTS / NOT EXISTS correlated subquery evaluation at runtime
#
# These must be evaluated per-outer-row, so they cannot be pre-expanded.
# We detect them in _parse_conditions and defer evaluation.
# ---------------------------------------------------------------------------

# Enhanced _parse_conditions that understands subquery conditions.
# Returns arrayref of condition hashrefs; subquery conditions have:
#   { type   => 'subquery',
#     op     => 'IN'|'NOT_IN'|'EXISTS'|'NOT_EXISTS'|'CMP',
#     col    => colname,     # for IN/NOT_IN/CMP
#     cmp_op => '='|...,     # for CMP
#     subql  => 'SELECT ...',
#   }
sub _parse_conditions_with_subq {
    my($self, $expr) = @_;
    my @conds;

    # Split on AND (but not inside parens/strings)
    my @parts = _split_and_clauses($expr);

    for my $part (@parts) {
        $part =~ s/^\s+|\s+$//g;

        # EXISTS (SELECT ...)
        if ($part =~ /^(NOT\s+)?EXISTS\s*\((.+)\)\s*$/si) {
            my($neg, $subql) = ($1, $2);
            $subql =~ s/^\s+|\s+$//g;
            push @conds, {
                type  => 'subquery',
                op    => ($neg ? 'NOT_EXISTS' : 'EXISTS'),
                subql => $subql,
            };
            next;
        }

        # col [NOT] IN (SELECT ...)
        if ($part =~ /^([\w.]+)\s+(NOT\s+)?IN\s*\((\s*SELECT\b.+)\)\s*$/si) {
            my($col, $neg, $subql) = ($1, $2, $3);
            $subql =~ s/^\s+|\s+$//g;
            push @conds, {
                type  => 'subquery',
                op    => $neg ? 'NOT_IN' : 'IN',
                col   => $col,
                subql => $subql,
            };
            next;
        }

        # col OP (SELECT ...)
        if ($part =~ /^([\w.]+)\s*(=|!=|<>|<=|>=|<|>)\s*\((\s*SELECT\b.+)\)\s*$/si) {
            my($col, $op, $subql) = ($1, uc($2), $3);
            $subql =~ s/^\s+|\s+$//g;
            push @conds, {
                type   => 'subquery',
                op     => 'CMP',
                cmp_op => $op,
                col    => $col,
                subql  => $subql,
            };
            next;
        }

        # Normal condition
        if ($part =~ /^(\w+)\s*(=|!=|<>|<=|>=|<|>|LIKE)\s*(?:'([^']*)'|(-?\d+\.?\d*))$/i) {
            my($col, $op, $sv, $nv) = ($1, $2, $3, $4);
            push @conds, { col=>$col, op=>uc($op), val=>defined($sv) ? $sv : $nv };
        }
    }
    return [ @conds ];
}

# Split WHERE expression on top-level AND (not inside parens or strings)
sub _split_and_clauses {
    my($expr) = @_;
    my @parts;
    my $cur    = '';
    my $depth  = 0;
    my $in_str = 0;
    my $i      = 0;
    my $len    = length($expr);

    while ($i < $len) {
        my $ch = substr($expr, $i, 1);
        if (($ch eq "'") && !$in_str) {
            $in_str = 1;
            $cur .= $ch;
        }
        elsif (($ch eq "'") && $in_str) {
            $in_str = 0;
            $cur .= $ch;
        }
        elsif ($in_str) {
            $cur .= $ch;
        }
        elsif ($ch eq '(') {
            $depth++;
            $cur .= $ch;
        }
        elsif ($ch eq ')') {
            $depth--;
            $cur .= $ch;
        }
        elsif (($depth == 0) && (substr($expr, $i, 5) =~ /^AND\s/i)) {
            push @parts, $cur;
            $cur = '';
            $i += 4; # skip "AND "
            next;
        }
        else {
            $cur .= $ch;
        }
        $i++;
    }
    push @parts, $cur if $cur =~ /\S/;
    return @parts;
}

# ---------------------------------------------------------------------------
# Build a where-filter sub that handles subquery conditions (evaluated
# at filter time with the candidate row as outer context).
# ---------------------------------------------------------------------------
sub _compile_where_with_subq {
    my($self, $conds) = @_;
    return sub { 1 } unless $conds && @$conds;

    my @plain;
    my @subq;
    for my $c (@$conds) {
        if (($c->{type} || '') eq 'subquery') {
            push @subq,  $c;
        }
        else {
            push @plain, $c;
        }
    }

    my $plain_sub = _compile_where_from_conds([ @plain ]);

    return sub {
        my($row) = @_;

        # Plain conditions first (fast path)
        return 0 if $plain_sub && !$plain_sub->($row);

        # Subquery conditions (evaluated per row)
        for my $c (@subq) {
            my $op    = $c->{op};
            my $subql = $self->_resolve_correlated($c->{subql}, $row);
            my $res   = $self->execute($subql);
            my @rows  = ($res && $res->{type} eq 'rows') ? @{$res->{data}} : ();

            if ($op eq 'EXISTS') {
                return 0 unless @rows;
            }
            elsif ($op eq 'NOT_EXISTS') {
                return 0 if @rows;
            }
            elsif (($op eq 'IN') || ($op eq 'NOT_IN')) {
                my $col_val  = defined($row->{$c->{col}}) ? $row->{$c->{col}} : '';
                my $found    = 0;
                my $has_null = 0;
                for my $r (@rows) {
                    my @rv = values %$r;
                    unless (defined $rv[0]) { $has_null = 1; next }
                    my $rv  = $rv[0];
                    my $num = (($col_val =~ /^-?\d+\.?\d*$/) && ($rv =~ /^-?\d+\.?\d*$/));
                    if ($num ? ($col_val == $rv) : ($col_val eq $rv)) {
                        $found = 1;
                        last;
                    }
                }
                return 0 if  $found && ($op eq 'NOT_IN');
                return 0 if !$found && ($op eq 'IN');
                # SQL NULL semantics: NOT IN with NULL in subquery is UNKNOWN
                return 0 if $has_null && !$found && ($op eq 'NOT_IN');
            }
            elsif ($op eq 'CMP') {
                return 0 if @rows > 1;
                my $rhs;
                if (@rows == 0) {
                    $rhs = undef;
                }
                else {
                    my @rv = values %{ $rows[0] };
                    $rhs   = $rv[0];
                }
                return 0 unless defined $rhs;
                my $lhs = defined($row->{$c->{col}}) ? $row->{$c->{col}} : '';
                my $cop = $c->{cmp_op};
                my $num = (($lhs =~ /^-?\d+\.?\d*$/) && ($rhs =~ /^-?\d+\.?\d*$/));
                if ($cop eq '=') {
                    return 0 unless $num ? ($lhs == $rhs) : ($lhs eq $rhs);
                }
                elsif (($cop eq '!=') || ($cop eq '<>')) {
                    return 0 unless $num ? ($lhs != $rhs) : ($lhs ne $rhs);
                }
                elsif ($cop eq '<') {
                    return 0 unless $num ? ($lhs <  $rhs) : ($lhs lt $rhs);
                }
                elsif ($cop eq '>') {
                    return 0 unless $num ? ($lhs >  $rhs) : ($lhs gt $rhs);
                }
                elsif ($cop eq '<=') {
                    return 0 unless $num ? ($lhs <= $rhs) : ($lhs le $rhs);
                }
                elsif ($cop eq '>=') {
                    return 0 unless $num ? ($lhs >= $rhs) : ($lhs ge $rhs);
                }
            }
        }
        return 1;
    };
}

# ---------------------------------------------------------------------------
# Derived table:  FROM (SELECT ...) AS alias  [WHERE ...] [ORDER BY ...]
#
# Evaluates the inner SELECT, materialises the result as an in-memory
# virtual table, then applies the outer WHERE/ORDER BY/LIMIT/OFFSET.
# ---------------------------------------------------------------------------
sub _exec_derived_table {
    my($self, $sql) = @_;

    # Parse:  SELECT outer_cols FROM (inner_sql) AS alias [WHERE ...] [ORDER BY ...] [LIMIT] [OFFSET]
    # Step 1: find the outer SELECT list
    unless ($sql =~ /^SELECT\s+(.+?)\s+FROM\s*\(/si) {
        return { type=>'error', message=>"Cannot parse derived table query" };
    }
    my $outer_cols_str = $1;

    # Step 2: extract the (inner_sql) AS alias part using paren matching
    my $from_pos = index(lc($sql), 'from');
    my $paren_start = index($sql, '(', $from_pos);
    unless ($paren_start >= 0) {
        return { type=>'error', message=>"Cannot find subquery in FROM clause" };
    }

    my($inner_sql, $close_pos) = _extract_paren_content($sql, $paren_start);
    unless (defined $inner_sql) {
        return { type=>'error', message=>"Unmatched parentheses in FROM clause" };
    }
    $inner_sql =~ s/^\s+|\s+$//g;

    # Step 3: parse alias and trailing clauses after the closing paren
    my $after = substr($sql, $close_pos + 1);
    $after =~ s/^\s+//;

    my $alias;
    if ($after =~ s/^(?:AS\s+)?(\w+)\s*//i) {
        $alias = $1;
    }
    else {
        $alias = 'subq';
    }

    # Step 4: parse outer WHERE / ORDER BY / LIMIT / OFFSET
    my %outer_opts;
    if ($after =~ s/\bLIMIT\s+(\d+)//i) {
        $outer_opts{limit} = $1;
    }
    if ($after =~ s/\bOFFSET\s+(\d+)//i) {
        $outer_opts{offset} = $1;
    }
    if ($after =~ s/\bORDER\s+BY\s+([\w.]+)(?:\s+(ASC|DESC))?//i) {
        $outer_opts{order_by}  = $1;
        $outer_opts{order_dir} = ($2 || 'ASC');
        my @onames;
        unless ($outer_cols_str =~ /^\s*(?:\w+\.)?\*\s*$/) {
            @onames = map { _order_name_of($_) } split(/\s*,\s*/, $outer_cols_str);
        }
        my($obe, $obk) = _resolve_order_ordinal_scalar($outer_opts{order_by}, [ @onames ]);
        return { type=>'error', message=>$obe } if $obe ne '';
        $outer_opts{order_by} = $obk;
    }
    my $outer_having = '';
    if ($after =~ s/\bHAVING\s+(.+?)(?=\s*$)//si) {
        $outer_having = $1;
        $outer_having =~ s/^\s+|\s+$//g;
    }
    my @outer_gb;
    if ($after =~ s/\bGROUP\s+BY\s+([\w.,\s]+?)(?=\s*$)//si) {
        @outer_gb = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } split /\s*,\s*/, $1;
    }

    my $outer_where_str = '';
    if ($after =~ /\bWHERE\s+(.+)/si) {
        $outer_where_str = $1;
        $outer_where_str =~ s/^\s+|\s+$//g;
    }

    # Step 5: execute the inner query (recursing through execute_with_subquery)
    my $inner_res = $self->execute_with_subquery($inner_sql);
    if (!$inner_res || ($inner_res->{type} eq 'error')) {
        my $msg = $inner_res ? $inner_res->{message} : $errstr;
        return { type=>'error', message=>"Derived table subquery error: $msg" };
    }

    my @inner_rows = @{ $inner_res->{data} || [] };

    # Step 6: qualify column names with alias (for outer WHERE resolution)
    my @qualified_rows;
    for my $r (@inner_rows) {
        my %qr;
        for my $k (keys %$r) {

            # Strip existing alias prefix if any, re-prefix with outer alias
            my $bare            = ($k =~ /\.(\w+)$/) ? $1 : $k;
            $qr{"$alias.$bare"} = $r->{$k};
            $qr{$bare}          = $r->{$k}; # also keep bare for convenience
        }
        push @qualified_rows, { %qr };
    }

    # Step 7: apply outer WHERE
    if ($outer_where_str =~ /\S/) {
        my $conds  = $self->_parse_conditions_with_subq($outer_where_str);
        my $filter = $self->_compile_where_with_subq($conds);
        @qualified_rows = grep { $filter->($_) } @qualified_rows;
    }

    # An aggregate or a GROUP BY in the outer SELECT list consumes the
    # materialised rows, so ORDER BY / LIMIT / OFFSET have to be applied to
    # the aggregated result instead of to the input.
    my $outer_agg = (@outer_gb || ($outer_having ne '')
                     || ($outer_cols_str =~ /\b(?:COUNT|SUM|AVG|MIN|MAX)\s*\(/i)) ? 1 : 0;

    # Step 8: ORDER BY
    if ((my $ob = $outer_opts{order_by}) && !$outer_agg) {
        my $dir = lc($outer_opts{order_dir} || 'asc');
        # Rows are keyed "alias.col"; fall back to the bare column name so
        # that an unqualified sort key still resolves.  The fallback key is
        # computed once here: deriving it inside the comparator produced an
        # undefined hash subscript whenever the key had no alias prefix.
        my $obb = ($ob =~ /\.(\w+)$/) ? $1 : $ob;
        @qualified_rows = sort {
            my $va = defined($a->{$ob}) ? $a->{$ob} : $a->{$obb};
            my $vb = defined($b->{$ob}) ? $b->{$ob} : $b->{$obb};
            my $cmp = (defined($va) && ($va =~ /^-?\d+\.?\d*$/) &&
                       defined($vb) && ($vb =~ /^-?\d+\.?\d*$/))
                ? ($va <=> $vb)
                : (($va || '') cmp ($vb || ''));
            ($dir eq 'desc') ? -$cmp : $cmp;
        } @qualified_rows;
    }

    # Step 9: OFFSET / LIMIT
    unless ($outer_agg) {
        my $off = ($outer_opts{offset} || 0);
        @qualified_rows = splice(@qualified_rows, $off) if $off;
        if (defined $outer_opts{limit}) {
            my $last = $outer_opts{limit} - 1;
            $last = $#qualified_rows if $last > $#qualified_rows;
            @qualified_rows = @qualified_rows[0..$last];
        }
    }

    # Step 10: outer column projection
    my @proj_rows;
    if ($outer_agg) {
        my @specs = parse_col_list($outer_cols_str);
        @proj_rows = group_and_aggregate([ @qualified_rows ], [ @specs ],
                                         [ @outer_gb ], $outer_having);
        if (my $ob = $outer_opts{order_by}) {
            my $dir = lc($outer_opts{order_dir} || 'asc');
            @proj_rows = sort {
                my $va = defined($a->{$ob}) ? $a->{$ob} : '';
                my $vb = defined($b->{$ob}) ? $b->{$ob} : '';
                my $cmp = (($va =~ /^-?\d+\.?\d*$/) && ($vb =~ /^-?\d+\.?\d*$/))
                    ? ($va <=> $vb) : ($va cmp $vb);
                ($dir eq 'desc') ? -$cmp : $cmp;
            } @proj_rows;
        }
        my $off = ($outer_opts{offset} || 0);
        @proj_rows = splice(@proj_rows, $off) if $off;
        if (defined $outer_opts{limit}) {
            my $last = $outer_opts{limit} - 1;
            $last = $#proj_rows if $last > $#proj_rows;
            @proj_rows = @proj_rows[0..$last];
        }
    }
    elsif ($outer_cols_str =~ /^\s*\*\s*$/) {
        @proj_rows = @qualified_rows;
    }
    else {
        my @want = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } split /,/, $outer_cols_str;
        for my $r (@qualified_rows) {
            my %p;
            for my $w (@want) {
                if (exists $r->{$w}) {
                    $p{$w} = $r->{$w};
                }
                elsif ($w =~ /^$alias\.(\w+)$/ && exists $r->{$1}) {
                    $p{$w} = $r->{$1};
                }
                else {

                    # bare name search
                    for my $k (keys %$r) {
                        if (($k =~ /\.\Q$w\E$/) || ($k eq $w)) {
                            $p{$w} = $r->{$k};
                            last;
                        }
                    }
                }
            }
            push @proj_rows, { %p };
        }
    }

    return { type=>'rows', data=>[ @proj_rows ] };
}

# ---------------------------------------------------------------------------
# Scalar subquery in SELECT list
#  SELECT (SELECT agg_col FROM t WHERE ...) AS label, other_col FROM main_tbl ...
# ---------------------------------------------------------------------------
sub _exec_scalar_select_subquery {
    my($self, $sql) = @_;

    # Strategy: collect all scalar subqueries in the SELECT list,
    # evaluate each, replace with the literal value, then execute the rest.

    # Find all top-level (SELECT ...) AS alias in the SELECT list
    # For simplicity: expand iteratively like WHERE subqueries
    my $expanded = $self->_expand_where_subqueries($sql, {});
    return $expanded if ref($expanded) eq 'HASH';
    return $self->execute($expanded);
}

# ---------------------------------------------------------------------------
# Extract content between matching parens starting at $start_pos.
# Returns ($content_without_outer_parens, $close_paren_pos).
# ---------------------------------------------------------------------------
sub _extract_paren_content {
    my($sql, $start_pos) = @_;
    my $len    = length($sql);
    my $depth  = 0;
    my $in_str = 0;
    for my $i ($start_pos .. $len-1) {
        my $ch = substr($sql, $i, 1);
        if (($ch eq "'") && !$in_str) {
            $in_str = 1;
        }
        elsif (($ch eq "'") && $in_str) {
            $in_str = 0;
        }
        elsif (!$in_str) {
            if ($ch eq '(') {
                $depth++;
            }
            elsif ($ch eq ')') {
                $depth--;
                if ($depth == 0) {
                    return (substr($sql, $start_pos+1, $i-$start_pos-1), $i);
                }
            }
        }
    }
    return (undef, undef);
}

###############################################################################
# Index internals
###############################################################################

sub _idx_file {
    my($self, $table, $idxname) = @_;
    File::Spec->catfile($self->{base_dir}, $self->{db_name}, "$table.$idxname.idx");
}

sub _encode_key {
    my($type, $keysize, $val) = @_;
    $val = '' unless defined $val;
    if ($type eq 'INT') {
        my $iv = _looks_numeric($val) ? int($val) : 0;
        $iv = INT_MAX if $iv > INT_MAX;
        $iv = INT_MIN if $iv < INT_MIN;
        return pack('N', ($iv & 0xFFFFFFFF) ^ 0x80000000);
    }
    elsif ($type eq 'FLOAT') {

        # A value that is not numeric encodes as 0, exactly as it is
        # stored by _pack_record.  The test is made here rather than left
        # to pack() so that -w stays quiet: an index on a FLOAT column
        # used to make a single INSERT emit two "isn't numeric" warnings.
        # my $packed = pack('d>', $val+0);
        my $packed = pack('d', _looks_numeric($val) ? $val+0 : 0);
        $packed = reverse($packed) if unpack("C", pack("S", 1));

        my @b = unpack('C8', $packed);
        if ($b[0] & 0x80) {
            @b = map { $_ ^ 0xFF } @b;
        }
        else {
            $b[0] ^= 0x80;
        }
        return pack('C8', @b);
    }
    else {
        my $sv = substr($val, 0, $keysize);
        $sv .= "\x00" x ($keysize - length($sv));
        return $sv;
    }
}


sub _idx_entry_size {
    $_[0]->{keysize} + REC_NO_SIZE;
}

sub _idx_read_all {
    my($self, $table, $ix) = @_;
    my $idx_file = $self->_idx_file($table, $ix->{name});
    my $entry_size = _idx_entry_size($ix);
    my @entries;
    return [ @entries ] unless -f $idx_file;
    local *FH;
    open(FH, "< $idx_file") or return [ @entries ];
    binmode FH;
    _lock_sh(\*FH);
    my $magic = '';
    read(FH, $magic, IDX_MAGIC_LEN);
    unless ($magic eq IDX_MAGIC) {
        _unlock(\*FH);
        close FH;
        return [ @entries ];
    }
    while (1) {
        my $entry = '';
        my $n = read(FH, $entry, $entry_size);
        last unless defined($n) && ($n == $entry_size);
        push @entries, [ substr($entry, 0, $ix->{keysize}), unpack('N', substr($entry, $ix->{keysize}, REC_NO_SIZE)) ];
    }
    _unlock(\*FH);
    close FH;
    return [ @entries ];
}

sub _idx_write_all {
    my($self, $table, $ix, $entries) = @_;
    my $idx_file = $self->_idx_file($table, $ix->{name});
    local *FH;
    unless (-f $idx_file) {
        open(FH, "> $idx_file") or return $self->_err("Cannot create index: $!");
        close FH;
    }
    # Open without truncating, so that the file is emptied only after the
    # exclusive lock is held.  Opening with '>' truncates at open() time,
    # which destroys a concurrent writer's data while we wait for the lock.
    open(FH, "+< $idx_file") or return $self->_err("Cannot write index: $!");
    binmode FH;
    _autoflush(\*FH);
    _lock_ex(\*FH);
    truncate(FH, 0);
    seek(FH, 0, 0);
    # The whole image is assembled first and written with a single print,
    # so autoflush costs one write() per rebuild rather than one per entry.
    my $image = IDX_MAGIC;
    for my $e (@$entries) {
        $image .= $e->[0] . pack('N', $e->[1]);
    }
    my $ok = print FH $image;
    unless ($ok) {
        my $e = $!;
        _unlock(\*FH);
        close FH;
        return $self->_err("Cannot write index: $e");
    }
    _unlock(\*FH);
    unless (close FH) {
        return $self->_err("Cannot flush index: $!");
    }
    return 1;
}

sub _idx_bisect {
    my($entries, $key_bytes) = @_;
    my($lo, $hi) = (0, scalar @$entries);
    while ($lo < $hi) {
        my $mid = int(($lo + $hi) / 2);
        if ($entries->[$mid][0] lt $key_bytes) {
            $lo = $mid + 1;
        }
        else {
            $hi = $mid;
        }
    }
    return $lo;
}

sub _idx_lookup_exact {
    my($self, $table, $ix, $val) = @_;
    my $key_bytes = _encode_key($ix->{coltype}, $ix->{keysize}, $val);
    my $entries = $self->_idx_read_all($table, $ix);
    my $pos = _idx_bisect($entries, $key_bytes);
    while (($pos < @$entries) && ($entries->[$pos][0] eq $key_bytes)) {
        return $pos;
    }
    return -1;
}

sub _idx_insert {
    my($self, $table, $ix, $val, $rec_no) = @_;
    my $key_bytes = _encode_key($ix->{coltype}, $ix->{keysize}, $val);
    my $entries = $self->_idx_read_all($table, $ix);
    my $pos = _idx_bisect($entries, $key_bytes);
    splice(@$entries, $pos, 0, [$key_bytes, $rec_no]);
    return $self->_idx_write_all($table, $ix, $entries);
}

sub _idx_delete {
    my($self, $table, $ix, $val, $rec_no) = @_;
    my $key_bytes = _encode_key($ix->{coltype}, $ix->{keysize}, $val);
    my $entries = $self->_idx_read_all($table, $ix);
    my $pos = _idx_bisect($entries, $key_bytes);
    my $deleted = 0;
    while (($pos < @$entries) && ($entries->[$pos][0] eq $key_bytes)) {
        if ($entries->[$pos][1] == $rec_no) {
            splice(@$entries, $pos, 1);
            $deleted++;
            last;
        }
        $pos++;
    }
    return $self->_idx_write_all($table, $ix, $entries) if $deleted;
    return 1;
}

sub _idx_range {
    my($self, $table, $ix, $lo_val, $lo_inc, $hi_val, $hi_inc) = @_;
    my $entries = $self->_idx_read_all($table, $ix);
    return [] unless @$entries;

    my $lo_pos = 0;
    if (defined $lo_val) {
        my $lo_key = _encode_key($ix->{coltype}, $ix->{keysize}, $lo_val);
        $lo_pos = _idx_bisect($entries, $lo_key);
        $lo_pos++ while !$lo_inc && ($lo_pos < @$entries) && ($entries->[$lo_pos][0] eq $lo_key);
    }
    my $hi_pos = scalar @$entries;
    if (defined $hi_val) {
        my $hi_key = _encode_key($ix->{coltype}, $ix->{keysize}, $hi_val);
        my $p = _idx_bisect($entries, $hi_key);
        $p++ while $hi_inc && ($p < @$entries) && ($entries->[$p][0] eq $hi_key);
        $hi_pos = $p;
    }
    return [ map { $entries->[$_][1] } $lo_pos .. $hi_pos-1 ];
}

sub _rebuild_index {
    my($self, $table, $idxname) = @_;
    my $sch = $self->_load_schema($table) or return undef;
    my $ix  = $sch->{indexes}{$idxname};
    return $self->_err("Index '$idxname' not found") unless $ix;
    my $dat     = $self->_file($table, 'dat');
    my $recsize = $sch->{recsize};
    my @entries;
    if (-f $dat) {
        local *FH;
        open(FH, "< $dat") or return $self->_err("Cannot read dat: $!");
        binmode FH;
        _lock_sh(\*FH);
        my $rec_no = 0;
        while (1) {
            my $raw = '';
            my $n = read(FH, $raw, $recsize);
            last unless defined($n) && ($n == $recsize);
            if (substr($raw, 0, 1) ne RECORD_DELETED) {
                my $row = $self->_unpack_record($sch, $raw);
                push @entries, [ _encode_key($ix->{coltype}, $ix->{keysize}, $row->{$ix->{col}}), $rec_no ];
            }
            $rec_no++;
        }
        _unlock(\*FH);
        close FH;
    }
    @entries = sort { $a->[0] cmp $b->[0] } @entries;
    return $self->_idx_write_all($table, $ix, [ @entries ]);
}

sub _find_index_for_conds {
    my($self, $table, $sch, $conds) = @_;
    return undef unless $conds && @$conds;
    return undef unless %{$sch->{indexes}};
    my %col2ix;
    for my $ix (values %{$sch->{indexes}}) {
        $col2ix{$ix->{col}} = $ix;
    }
    for my $c (@$conds) {
        my $ix = $col2ix{$c->{col}} or next;
        my $op = $c->{op};
        if ($op eq '=') {
            my $key_bytes = _encode_key($ix->{coltype}, $ix->{keysize}, $c->{val});
            my $entries = $self->_idx_read_all($table, $ix);
            my $pos = _idx_bisect($entries, $key_bytes);
            my @rec_nos;
            while (($pos < @$entries) && ($entries->[$pos][0] eq $key_bytes)) {
                push @rec_nos, $entries->[$pos][1];
                $pos++;
            }
            return [ @rec_nos ];
        }
        elsif ($op eq '<') {
            return $self->_idx_range($table, $ix, undef, 0, $c->{val}, 0);
        }
        elsif ($op eq '<=') {
            return $self->_idx_range($table, $ix, undef, 0, $c->{val}, 1);
        }
        elsif ($op eq '>') {
            return $self->_idx_range($table, $ix, $c->{val}, 0, undef, 0);
        }
        elsif ($op eq '>=') {
            return $self->_idx_range($table, $ix, $c->{val}, 1, undef, 0);
        }
    }
    return undef;
}

# _try_index_and_range($table, $sch, $where_expr)
#
# Attempt to satisfy a two-sided range or BETWEEN predicate using an index.
# Recognises these WHERE patterns (same column, values numeric or quoted):
#   col OP1 val1 AND col OP2 val2   (e.g. id > 5 AND id < 10)
#   col BETWEEN val1 AND val2
# Returns an arrayref of matching record numbers, or undef if no index
# can be applied (caller falls through to a full table scan).
#
sub _try_index_and_range {
    my($self, $table, $sch, $where_expr) = @_;
    return undef unless %{$sch->{indexes}};
    my %col2ix;
    for my $ix (values %{$sch->{indexes}}) {
        $col2ix{$ix->{col}} = $ix;
    }
    my $VAL = qr/(?:'([^']*)'|(-?\d+\.?\d*))/;
    my $OP  = qr/(<=|>=|<|>)/;
    # BETWEEN col BETWEEN val1 AND val2
    if ($where_expr =~ /^(\w+)\s+BETWEEN\s+$VAL\s+AND\s+$VAL\s*$/i) {
        my($col, $lo_s, $lo_n, $hi_s, $hi_n) = ($1, $2, $3, $4, $5);
        my $lo = defined($lo_s) ? $lo_s : $lo_n;
        my $hi = defined($hi_s) ? $hi_s : $hi_n;
        my $ix = $col2ix{$col} or return undef;
        return $self->_idx_range($table, $ix, $lo, 1, $hi, 1);
    }
    # AND: col OP val AND col OP val  (same column)
    if ($where_expr =~ /^(\w+)\s+$OP\s+$VAL\s+AND\s+\1\s+$OP\s+$VAL\s*$/i) {
        my($col, $op1, $v1s, $v1n, $op2, $v2s, $v2n) = ($1, $2, $3, $4, $5, $6, $7);
        my $v1 = defined($v1s) ? $v1s : $v1n;
        my $v2 = defined($v2s) ? $v2s : $v2n;
        my $ix = $col2ix{$col} or return undef;
        # Determine lo (lower bound) and hi (upper bound)
        my($lo, $lo_inc, $hi, $hi_inc);
        if ($op1 eq '>' || $op1 eq '>=') {
            ($lo, $lo_inc) = ($v1, $op1 eq '>=');
            ($hi, $hi_inc) = ($v2, $op2 eq '<=');
        }
        else {
            ($lo, $lo_inc) = ($v2, $op2 eq '>=');
            ($hi, $hi_inc) = ($v1, $op1 eq '<=');
        }
        return $self->_idx_range($table, $ix, $lo, $lo_inc, $hi, $hi_inc);
    }
    return undef;
}

# _try_index_partial_and($table, $sch, $where_expr)
#
# For AND expressions involving multiple columns, pick the single indexed
# column that yields the smallest candidate set and return its record
# numbers.  The caller applies the full WHERE predicate as a post-filter,
# so correctness is guaranteed regardless of which index is chosen.
#
# Recognises AND-connected atoms of the form:
#   col = val   col > val   col >= val   col < val   col <= val
# (quoted or numeric values; no subexpressions, BETWEEN, IN, OR, NOT)
#
# Returns an arrayref of candidate record numbers, or undef when no
# usable index is found (caller falls through to a full table scan).
#
sub _try_index_partial_and {
    my($self, $table, $sch, $where_expr) = @_;
    return undef unless %{$sch->{indexes}};
    # Only handle pure AND expressions (no OR/NOT/BETWEEN/IN/subqueries)
    return undef if $where_expr =~ /\b(?:OR|NOT|BETWEEN|IN)\b/i;
    return undef if $where_expr =~ /\(\s*SELECT\b/i;
    # Split on AND and collect simple  col OP val  atoms
    my @atoms;
    my $VAL  = qr/(?:'[^']*'|-?\d+\.?\d*)/;
    my $OP   = qr/(?:<=|>=|!=|<>|<|>|=)/;
    for my $part (split /\bAND\b/i, $where_expr) {
        $part =~ s/^\s+|\s+$//g;
        if ($part =~ /^(\w+)\s*($OP)\s*($VAL)$/
            || $part =~ /^($VAL)\s*($OP)\s*(\w+)$/) {
            # Normalise so col is always on the left
            my($col, $op, $val);
            if ($part =~ /^(\w+)\s*($OP)\s*($VAL)$/) {
                ($col, $op, $val) = ($1, uc($2), $3);
            }
            else {
                # val OP col  -- reverse the operator
                $part =~ /^($VAL)\s*($OP)\s*(\w+)$/;
                my %rev = ('>' => '<', '<' => '>', '>=' => '<=',
                           '<=' => '>=', '=' => '=', '!=' => '!=',
                           '<>' => '<>');
                ($col, $op, $val) = ($3, $rev{uc($2)} || uc($2), $1);
            }
            $val =~ s/^'|'$//g;   # strip surrounding quotes
            push @atoms, { col => $col, op => $op, val => $val };
        }
        else {
            return undef;  # complex atom -- cannot use index safely
        }
    }
    return undef unless @atoms >= 2;  # single atom handled by Case 1/2
    # Build column -> index map
    my %col2ix;
    for my $ix (values %{$sch->{indexes}}) {
        $col2ix{$ix->{col}} = $ix;
    }
    # Try each atom in turn; return the first index hit
    # (equality index preferred over range for a smaller candidate set)
    my $best_eq  = undef;  # record list from an equality match
    my $best_rng = undef;  # record list from a range match
    for my $a (@atoms) {
        my $ix = $col2ix{$a->{col}} or next;
        my $op = $a->{op};
        next if $op eq '!=' || $op eq '<>';  # inequality gives no benefit
        my $recs;
        if ($op eq '=') {
            my $key = _encode_key($ix->{coltype}, $ix->{keysize}, $a->{val});
            my $entries = $self->_idx_read_all($table, $ix);
            my $pos = _idx_bisect($entries, $key);
            my @r;
            while (($pos < @$entries) && ($entries->[$pos][0] eq $key)) {
                push @r, $entries->[$pos][1];
                $pos++;
            }
            $recs = [ @r ];
            # Equality index: take first found and stop
            $best_eq = $recs and last;
        }
        elsif ($op eq '<') {
            $recs = $self->_idx_range($table, $ix, undef, 0, $a->{val}, 0);
        }
        elsif ($op eq '<=') {
            $recs = $self->_idx_range($table, $ix, undef, 0, $a->{val}, 1);
        }
        elsif ($op eq '>') {
            $recs = $self->_idx_range($table, $ix, $a->{val}, 0, undef, 0);
        }
        elsif ($op eq '>=') {
            $recs = $self->_idx_range($table, $ix, $a->{val}, 1, undef, 0);
        }
        $best_rng = $recs if defined $recs && !defined $best_rng;
    }
    return $best_eq if defined $best_eq;
    return $best_rng;
}

# _try_index_in($table, $sch, $where_expr)
#
# Attempt to satisfy a  col IN (v1, v2, ...)  or  col NOT IN (v1, v2, ...)
# predicate using an index.  For IN, performs one equality lookup per value
# and returns the union of matching record numbers.  NOT IN is not optimised
# (returns undef so the caller falls through to a full table scan).
#
# The WHERE expression must consist of exactly one IN predicate with a
# literal value list (no sub-selects, no OR/AND, no NOT IN).
#
# Returns an arrayref of candidate record numbers, or undef when no index
# can be applied.
#
sub _try_index_in {
    my($self, $table, $sch, $where_expr) = @_;
    return undef unless %{$sch->{indexes}};
    # Match: col IN (literal-list)   no NOT IN, no sub-select
    return undef unless $where_expr =~ /^\s*(\w+)\s+IN\s*\(([^)]*)\)\s*$/si;
    my($col, $list_str) = ($1, $2);
    # Find index for this column
    my $ix;
    for my $candidate (values %{$sch->{indexes}}) {
        if ($candidate->{col} eq $col) {
            $ix = $candidate;
            last;
        }
    }
    return undef unless defined $ix;
    # Parse the value list
    my @vals;
    my $ls = $list_str;
    while ($ls =~ s/^\s*(?:'((?:[^']|'')*)'|(-?\d+\.?\d*)|(NULL))\s*(?:,|$)//i) {
        my($sv, $nv, $nl) = ($1, $2, $3);
        if (defined $nl) {
            # NULL in IN list: no index lookup possible for NULL
            return undef;
        }
        elsif (defined $sv) {
            (my $x = $sv) =~ s/''/'/g;
            push @vals, $x;
        }
        else {
            push @vals, $nv;
        }
    }
    return undef unless @vals;  # empty IN list: caller handles
    # Perform one equality index lookup per value, union the results
    my %seen;
    my @rec_nos;
    my $entries = $self->_idx_read_all($table, $ix);
    for my $val (@vals) {
        my $key = _encode_key($ix->{coltype}, $ix->{keysize}, $val);
        my $pos = _idx_bisect($entries, $key);
        while (($pos < @$entries) && ($entries->[$pos][0] eq $key)) {
            my $rn = $entries->[$pos][1];
            push @rec_nos, $rn unless $seen{$rn}++;
            $pos++;
        }
    }
    return [ @rec_nos ];
}

# _try_index_or($table, $sch, $where_expr)
#
# Attempt to satisfy a pure OR expression using indexes.
#
# Every atom in the OR chain must be a simple condition that can be served
# by an index on the relevant column.  If any atom has no usable index the
# function returns undef and the caller falls through to a full table scan.
#
# Recognised atom forms (same column or different columns):
#   col = val             col != val  (not optimised -- returns undef)
#   col OP val            (OP: <, <=, >, >=)
#   col BETWEEN lo AND hi
#   col IN (v1, v2, ...)
#
# Returns an arrayref of deduplicated record numbers, or undef.
#
sub _try_index_or {
    my($self, $table, $sch, $where_expr) = @_;
    return undef unless %{$sch->{indexes}};
    # Must be a pure OR expression -- no AND, no NOT, no subqueries
    return undef if $where_expr =~ /\b(?:AND|NOT)\b/i;
    return undef if $where_expr =~ /\(\s*SELECT\b/i;
    # Split on OR
    my @atoms = DB::Handy::bool_split($where_expr, 'OR');
    return undef unless @atoms >= 2;
    # Build column -> index map
    my %col2ix;
    for my $ix (values %{$sch->{indexes}}) {
        $col2ix{$ix->{col}} = $ix;
    }
    my $VAL = qr/(?:'(?:[^']|'')*'|-?\d+\.?\d*)/;
    my $OP  = qr/(?:<=|>=|<|>|=)/;
    # Collect record numbers for each atom
    my %seen;
    my @all_recs;
    for my $atom (@atoms) {
        $atom =~ s/^\s+|\s+$//g;
        my $recs;
        # col BETWEEN lo AND hi
        if ($atom =~ /^(\w+)\s+BETWEEN\s+($VAL)\s+AND\s+($VAL)\s*$/i) {
            my($col, $lo, $hi) = ($1, $2, $3);
            my $ix = $col2ix{$col} or return undef;
            $lo =~ s/^'(.*)'$/$1/s; $hi =~ s/^'(.*)'$/$1/s;
            $recs = $self->_idx_range($table, $ix, $lo, 1, $hi, 1);
        }
        # col IN (val, ...)
        elsif ($atom =~ /^(\w+)\s+IN\s*\(([^)]*)\)\s*$/i) {
            my($col, $list) = ($1, $2);
            my $ix = $col2ix{$col} or return undef;
            $recs = $self->_try_index_in($table, $sch, $atom);
            return undef unless defined $recs;
        }
        # col OP val  (equality or range, not !=/<>)
        elsif ($atom =~ /^(\w+)\s*($OP)\s*($VAL)$/) {
            my($col, $op, $val) = ($1, uc($2), $3);
            return undef if $op eq '!=' || $op eq '<>';
            my $ix = $col2ix{$col} or return undef;
            $val =~ s/^'(.*)'$/$1/s;
            if ($op eq '=') {
                my $key = _encode_key($ix->{coltype}, $ix->{keysize}, $val);
                my $entries = $self->_idx_read_all($table, $ix);
                my $pos = _idx_bisect($entries, $key);
                my @r;
                while (($pos < @$entries) && ($entries->[$pos][0] eq $key)) {
                    push @r, $entries->[$pos][1];
                    $pos++;
                }
                $recs = [ @r ];
            }
            elsif ($op eq '<')  { $recs = $self->_idx_range($table, $ix, undef, 0, $val, 0) }
            elsif ($op eq '<=') { $recs = $self->_idx_range($table, $ix, undef, 0, $val, 1) }
            elsif ($op eq '>')  { $recs = $self->_idx_range($table, $ix, $val,  0, undef, 0) }
            elsif ($op eq '>=') { $recs = $self->_idx_range($table, $ix, $val,  1, undef, 0) }
        }
        else {
            return undef;  # complex atom: cannot use index
        }
        return undef unless defined $recs;
        for my $rn (@$recs) {
            push @all_recs, $rn unless $seen{$rn}++;
        }
    }
    return [ @all_recs ];
}

# _try_index_not_in($table, $sch, $where_expr)
#
# Attempt to satisfy a  col NOT IN (v1, v2, ...)  predicate using an index.
# Collects the record numbers that match the IN list (via index), then
# returns all record numbers in the index that are NOT in that set.
# Efficient when the exclusion list is small relative to total row count.
#
# NULL in the value list causes a fallback to a full table scan (SQL
# semantics: NOT IN with NULL never matches any row).
#
# Returns an arrayref of candidate record numbers, or undef when no index
# can be applied.
#
sub _try_index_not_in {
    my($self, $table, $sch, $where_expr) = @_;
    return undef unless %{$sch->{indexes}};
    # Match: col NOT IN (literal-list)  no sub-select
    return undef unless $where_expr =~ /^\s*(\w+)\s+NOT\s+IN\s*\(([^)]*)\)\s*$/si;
    my($col, $list_str) = ($1, $2);
    # Find index for this column
    my $ix;
    for my $candidate (values %{$sch->{indexes}}) {
        if ($candidate->{col} eq $col) {
            $ix = $candidate;
            last;
        }
    }
    return undef unless defined $ix;
    # Parse the NOT IN value list
    my @vals;
    my $ls = $list_str;
    while ($ls =~ s/^\s*(?:'((?:[^']|'')*)'|(-?\d+\.?\d*)|(NULL))\s*(?:,|$)//i) {
        my($sv, $nv, $nl) = ($1, $2, $3);
        if    (defined $nl) { return undef }  # NULL: fall back to full scan
        elsif (defined $sv) { (my $x = $sv) =~ s/''/'/g; push @vals, $x }
        else                { push @vals, $nv }
    }
    return undef unless @vals;
    # Build set of record numbers to EXCLUDE (those matching the IN list)
    my %exclude;
    my $entries = $self->_idx_read_all($table, $ix);
    for my $val (@vals) {
        my $key = _encode_key($ix->{coltype}, $ix->{keysize}, $val);
        my $pos = _idx_bisect($entries, $key);
        while (($pos < @$entries) && ($entries->[$pos][0] eq $key)) {
            $exclude{$entries->[$pos][1]} = 1;
            $pos++;
        }
    }
    # Return all record numbers in the index that are NOT excluded
    my %seen;
    my @rec_nos;
    for my $entry (@$entries) {
        my $rn = $entry->[1];
        push @rec_nos, $rn unless $exclude{$rn} || $seen{$rn}++;
    }
    return [ @rec_nos ];
}

###############################################################################
# JOIN  --  Public entry point
###############################################################################
# join_select(\@join_specs, \@col_specs, \@where_conds, \%opts)
#
#  join_specs : arrayref of hashrefs, in left-to-right order
#    { table  => 'employees',          # physical table name
#      alias  => 'e',                  # alias (or same as table)
#      type   => 'INNER'|'LEFT'|'RIGHT'|'CROSS',
#      on_left  => 'e.dept_id',        # undef for first/CROSS
#      on_right => 'd.id',             # undef for first/CROSS
#    }
#
#  col_specs : arrayref of  'alias.col'  or  'alias.*'  or  '*'
#              undef = all columns (alias-qualified)
#
#  where_conds : arrayref of condition hashrefs (from _parse_join_conditions)
#                { lhs_alias, lhs_col, op, rhs_alias, rhs_col, val }
#
#  opts : { order_by=>'alias.col'|'col', order_dir=>'ASC', limit=>N, offset=>M }
#
sub join_select {
    my($self, $join_specs, $col_specs, $where_conds, $opts) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    $opts        ||= {};
    $where_conds ||= [];

    # ------------------------------------------------------------------
    # Step 1: load schemas; build alias -> { table, schema } map
    # ------------------------------------------------------------------
    my %alias_info; # alias => { table, sch, rows(lazy) }
    for my $js (@$join_specs) {
        my $sch = $self->_load_schema($js->{table}) or return undef;
        $alias_info{ $js->{alias} } = {
            table => $js->{table},
            sch   => $sch,
        };
    }

    # ------------------------------------------------------------------
    # Step 2: load the leftmost (driving) table fully into memory
    # ------------------------------------------------------------------
    my $first    = $join_specs->[0];
    my @cur_rows = @{ $self->_scan_table_all($first->{table}, $first->{alias}) };
    return undef unless defined($cur_rows[0]) || !$self->{_last_err};

    # ------------------------------------------------------------------
    # Step 3: for each subsequent table, apply the JOIN
    # ------------------------------------------------------------------
    for my $i (1 .. $#$join_specs) {
        my $js        = $join_specs->[$i];
        my $join_type = uc($js->{type} || 'INNER');

        # Parse ON  alias1.col1 = alias2.col2
        # A CROSS JOIN is unconditional, so an ON written on one is accepted
        # and ignored rather than checked.
        my($on_l_alias, $on_l_col, $on_r_alias, $on_r_col);
        if (($join_type ne 'CROSS') && $js->{on_left} && $js->{on_right}) {
            ($on_l_alias, $on_l_col) = _split_qualified($js->{on_left});
            ($on_r_alias, $on_r_col) = _split_qualified($js->{on_right});

            # An equality is symmetric, but the code below is not: the left
            # operand has to name the accumulated left-hand side and the right
            # operand the table being joined in.  "ON b.k = a.x" is as valid
            # as "ON a.x = b.k", and before 1.09 it produced a silent cross
            # join, so the operands are swapped here when they are the other
            # way round.
            if (defined($on_l_alias) && defined($on_r_alias)
                && ($on_l_alias eq $js->{alias}) && ($on_r_alias ne $js->{alias})) {
                ($on_l_alias, $on_l_col, $on_r_alias, $on_r_col) =
                    ($on_r_alias, $on_r_col, $on_l_alias, $on_l_col);
            }

            # Both operands have to be table-qualified.  An unqualified name
            # cannot be looked up in a result row, whose keys are all
            # "alias.col", so before 1.09 "ON x = k" fell through to the
            # Cartesian-product branch without a word.
            unless (defined($on_l_alias) && defined($on_r_alias)) {
                return $self->_err(
                    "Unqualified column in the ON clause of JOIN "
                    . "$js->{table}; write ON <table>.<col> = <table>.<col>");
            }

            # A qualified operand has to name a table in this query.
            for my $qa ($on_l_alias, $on_r_alias) {
                next if $alias_info{$qa};
                return $self->_err(
                    "Unknown table or alias '$qa' in the ON clause of "
                    . "JOIN $js->{table}");
            }
            if ($on_r_alias ne $js->{alias}) {
                return $self->_err(
                    "The ON clause of JOIN $js->{table} does not reference "
                    . "'$js->{alias}'; a join condition has to compare a "
                    . "column of '$js->{alias}' with a column of a table "
                    . "already joined");
            }
        }

        # Load the right-side table
        my @right_rows = @{ $self->_scan_table_all($js->{table}, $js->{alias}) };

        # Build hash on right side if possible (index-nested-loop join)
        my %right_hash;
        my $use_hash = 0;
        if (defined($on_r_alias) && defined($on_r_col)) {
            for my $rr (@right_rows) {
                my $rkey = defined($rr->{"$on_r_alias.$on_r_col"})
                    ? $rr->{"$on_r_alias.$on_r_col"}
                    : '';
                push @{ $right_hash{$rkey} }, $rr;
            }
            $use_hash = 1;
        }

        my @next_rows;

        if (($join_type eq 'CROSS') || (!defined $on_l_alias)) {

            # Cartesian product
            for my $lr (@cur_rows) {
                for my $rr (@right_rows) {
                    push @next_rows, { %$lr, %$rr };
                }
            }
        }
        elsif ($join_type eq 'INNER') {
            for my $lr (@cur_rows) {
                my $lkey = defined($lr->{"$on_l_alias.$on_l_col"})
                    ? $lr->{"$on_l_alias.$on_l_col"}
                    : '';
                my $matches = $use_hash ? ($right_hash{$lkey} || []) : [ @right_rows ];
                for my $rr (@$matches) {
                    next if ($use_hash == 0) && !_join_row_matches($lr, $rr, $on_l_alias, $on_l_col, $on_r_alias, $on_r_col);
                    push @next_rows, { %$lr, %$rr };
                }
            }
        }
        elsif ($join_type eq 'LEFT') {
            for my $lr (@cur_rows) {
                my $lkey = defined($lr->{"$on_l_alias.$on_l_col"})
                    ? $lr->{"$on_l_alias.$on_l_col"}
                    : '';
                my $matches = $use_hash ? ($right_hash{$lkey} || [])
                                        : [ grep { _join_row_matches($lr, $_, $on_l_alias, $on_l_col, $on_r_alias, $on_r_col) }
                                            @right_rows
                                          ];
                if (@$matches) {
                    for my $rr (@$matches) {
                        push @next_rows, { %$lr, %$rr };
                    }
                }
                else {

                    # NULL-fill right side
                    my %null_right = _make_null_row($js->{alias}, $alias_info{$js->{alias}}{sch});
                    push @next_rows, { %$lr, %null_right };
                }
            }
        }
        elsif ($join_type eq 'RIGHT') {

            # RIGHT JOIN: swap sides, do LEFT, then results are correct
            for my $rr (@right_rows) {
                my $rkey = defined($rr->{"$on_r_alias.$on_r_col"}) ? $rr->{"$on_r_alias.$on_r_col"} : '';
                my $l_alias_key = "$on_l_alias.$on_l_col";
                my @matched_lefts;
                for my $lr (@cur_rows) {
                    my $lkey = defined($lr->{$l_alias_key}) ? $lr->{$l_alias_key} : '';
                    push @matched_lefts, $lr if $lkey eq $rkey;
                }
                if (@matched_lefts) {
                    for my $lr (@matched_lefts) {
                        push @next_rows, { %$lr, %$rr };
                    }
                }
                else {

                    # NULL-fill all left-side aliases seen so far
                    my %null_left;
                    for my $prev_js (@{$join_specs}[0..$i-1]) {
                        my %nr = _make_null_row($prev_js->{alias}, $alias_info{$prev_js->{alias}}{sch});
                        %null_left = (%null_left, %nr);
                    }
                    push @next_rows, { %null_left, %$rr };
                }
            }
        }

        @cur_rows = @next_rows;
    }

    # ------------------------------------------------------------------
    # Step 4: apply WHERE (post-join filter)
    # ------------------------------------------------------------------
    if (@$where_conds) {
        my $wsub  = _compile_join_where($where_conds);
        @cur_rows = grep { $wsub->($_) } @cur_rows;
    }

    # ------------------------------------------------------------------
    # Step 5: ORDER BY
    # ------------------------------------------------------------------
    # order_keys holds every ORDER BY key as [ name, ASC|DESC ]; order_by and
    # order_dir carry the first key so that older callers keep working.
    my @ob_keys;
    if ($opts->{order_keys} && @{$opts->{order_keys}}) {
        @ob_keys = @{$opts->{order_keys}};
    }
    elsif ($opts->{order_by}) {
        @ob_keys = ([ $opts->{order_by}, ($opts->{order_dir} || 'ASC') ]);
    }
    if (@ob_keys) {

        # A result row is keyed "alias.col", so a bare ORDER BY name has to be
        # resolved to the alias that owns it.  An unresolvable key used to
        # leave the rows in scan order without a word.
        my(%qual, %bare);
        for my $js (@$join_specs) {
            my $a = $js->{alias};
            for my $c (@{$alias_info{$a}{sch}{cols}}) {
                $qual{"$a.$c->{name}"} = 1;
                $bare{$c->{name}}      = "$a.$c->{name}"
                    unless exists $bare{$c->{name}};
            }
        }
        for my $k (@ob_keys) {
            next if $qual{$k->[0]};
            if ($bare{$k->[0]}) {
                $k->[0] = $bare{$k->[0]};
                next;
            }
            return $self->_err(
                "Unknown ORDER BY column '$k->[0]' in a JOIN query");
        }

        @cur_rows = sort {
            my $cmp = 0;
            for my $k (@ob_keys) {
                my($key, $dir) = @$k;
                my $va = $a->{$key};
                my $vb = $b->{$key};
                my $c  = (defined($va) && ($va =~ /^-?\d+\.?\d*$/) &&
                          defined($vb) && ($vb =~ /^-?\d+\.?\d*$/))
                       ? ($va <=> $vb)
                       : ((defined($va) ? $va : '') cmp (defined($vb) ? $vb : ''));
                $c = -$c if lc($dir) eq 'desc';
                if ($c != 0) {
                    $cmp = $c;
                    last;
                }
            }
            $cmp;
        } @cur_rows;
    }

    # ------------------------------------------------------------------
    # Step 6: expand the select list and check every item
    # ------------------------------------------------------------------
    my @expanded;
    if ($col_specs && @$col_specs) {

        # Expand wildcards: 'alias.*' or '*'
        for my $cs (@$col_specs) {
            if ($cs eq '*') {

                # all columns from all aliases
                for my $js (@$join_specs) {
                    my $a   = $js->{alias};
                    my $sch = $alias_info{$a}{sch};
                    for my $c (@{$sch->{cols}}) {
                        push @expanded, "$a.$c->{name}";
                    }
                }
            }
            elsif ($cs =~ /^(\w+)\.\*$/) {
                my $a   = $1;
                my $sch = $alias_info{$a} ? $alias_info{$a}{sch} : undef;
                unless ($sch) {
                    return $self->_err("Unknown table or alias '$a' in '$cs'");
                }
                for my $c (@{$sch->{cols}}) {
                    push @expanded, "$a.$c->{name}";
                }
            }
            else {
                push @expanded, $cs;
            }
        }

        # Every item has to name a column of one of the joined tables.  A
        # JOIN select list cannot evaluate an expression or an AS alias, and
        # until 1.09 such an item silently produced a row with no values in
        # it at all: "SELECT a.y AS nm ... JOIN", "SELECT a.x + 1 ... JOIN"
        # and "SELECT DISTINCT a.x ... JOIN" all returned empty rows.
        my %valid_col;
        for my $js (@$join_specs) {
            my $a = $js->{alias};
            for my $c (@{$alias_info{$a}{sch}{cols}}) {
                $valid_col{"$a.$c->{name}"} = 1;
                $valid_col{$c->{name}}      = 1;
            }
        }
        for my $ck (@expanded) {
            next if $valid_col{$ck};
            return $self->_err(
                "Unsupported select item '$ck' in a JOIN query; a JOIN "
                . "select list accepts column names, '*' and '<table>.*' "
                . "only (no expressions and no AS aliases)");
        }
    }

    # ------------------------------------------------------------------
    # Step 7: DISTINCT.  Applied before OFFSET/LIMIT, as SQL requires, and
    # keyed on the select-list values only.
    # ------------------------------------------------------------------
    if ($opts->{distinct}) {
        my @dkeys = @expanded ? @expanded : sort keys %{ $cur_rows[0] || {} };
        my(%seen, @uniq);
        for my $r (@cur_rows) {
            my $k = join("\x00", map {
                defined($r->{$_}) ? $r->{$_} : "\x01"
            } @dkeys);
            push @uniq, $r unless $seen{$k}++;
        }
        @cur_rows = @uniq;
    }

    # ------------------------------------------------------------------
    # Step 8: OFFSET / LIMIT
    # ------------------------------------------------------------------
    my $offset = ($opts->{offset} || 0);
    @cur_rows  = splice(@cur_rows, $offset) if $offset;
    if (defined $opts->{limit}) {
        my $last  = $opts->{limit} - 1;
        $last     = $#cur_rows if $last > $#cur_rows;
        @cur_rows = @cur_rows[0..$last];
    }

    # ------------------------------------------------------------------
    # Step 9: column projection
    # ------------------------------------------------------------------
    if (@expanded) {
        my @proj_rows;
        for my $r (@cur_rows) {
            my %p;
            for my $ck (@expanded) {

                # Try qualified name first, then bare name
                if (exists $r->{$ck}) {
                    $p{$ck} = $r->{$ck};
                }
                else {

                    # bare name: find first matching qualified key
                    for my $k (keys %$r) {
                        if (($k =~ /\.\Q$ck\E$/) || ($k eq $ck)) {
                            $p{$ck} = $r->{$k};
                            last;
                        }
                    }
                }
            }
            push @proj_rows, { %p };
        }
        return [ @proj_rows ];
    }

    return [ @cur_rows ];
}

# Load all active rows from a table, qualifying each column as "alias.col"
sub _scan_table_all {
    my($self, $table, $alias) = @_;
    my $sch     = $self->_load_schema($table) or return [];
    my $dat     = $self->_file($table, 'dat');
    my $recsize = $sch->{recsize};
    my @rows;

    local *FH;
    open(FH, "< $dat") or do { $errstr = "Cannot open dat '$dat': $!"; return []; };
    binmode FH;
    _lock_sh(\*FH);
    while (1) {
        my $raw = '';
        my $n = read(FH, $raw, $recsize);
        last unless defined($n) && ($n == $recsize);
        next if substr($raw, 0, 1) eq RECORD_DELETED;
        my $raw_row = $self->_unpack_record($sch, $raw);

        # Qualify column names with alias
        my %qrow;
        for my $col (@{$sch->{cols}}) {
            $qrow{"$alias.$col->{name}"} = $raw_row->{$col->{name}};
        }
        push @rows, { %qrow };
    }
    _unlock(\*FH);
    close FH;
    return [ @rows ];
}

# Build a row of NULLs for the given alias (for outer joins)
sub _make_null_row {
    my($alias, $sch) = @_;
    my %row;
    for my $col (@{$sch->{cols}}) {
        $row{"$alias.$col->{name}"} = undef;
    }
    return %row;
}

# Split "alias.col" into (alias, col); if no dot, return (undef, col)
sub _split_qualified {
    my($qname) = @_;
    if ($qname =~ /^(\w+)\.(\w+)$/) {
        return ($1, $2);
    }
    return (undef, $qname);
}

# Check if a pair of rows satisfies the ON equality condition
sub _join_row_matches {
    my($lr, $rr, $la, $lc, $ra, $rc) = @_;
    my $lv = defined($la) ? $lr->{"$la.$lc"} : $lr->{$lc};
    my $rv = defined($ra) ? $rr->{"$ra.$rc"} : $rr->{$rc};
    return 0 unless defined($lv) && defined($rv);

    # numeric compare if both look numeric
    if (($lv =~ /^-?\d+\.?\d*$/) && ($rv =~ /^-?\d+\.?\d*$/)) {
        return (($lv == $rv) ? 1 : 0);
    }
    return (($lv eq $rv) ? 1 : 0);
}

###############################################################################
# JOIN WHERE compiler
# Conditions from the WHERE clause after a JOIN may reference qualified
# columns (alias.col) or bare column names.
# Condition hashref keys:
#   lhs_alias, lhs_col   -- left-hand side
#   op                   -- =  !=  <>  <  >  <=  >=  LIKE
#   rhs_alias, rhs_col   -- right-hand side (column comparison)  OR
#   val                  -- literal value
###############################################################################
sub _compile_join_where {
    my($conds) = @_;
    return sub { 1 } unless $conds && @$conds;
    return sub {
        my($row) = @_;
        for my $c (@$conds) {

            # Resolve left-hand value
            my $lv;
            if (defined $c->{lhs_alias}) {
                $lv = $row->{"$c->{lhs_alias}.$c->{lhs_col}"};
            }
            else {

                # bare name: search qualified keys
                for my $k (keys %$row) {
                    if (($k =~ /\.\Q$c->{lhs_col}\E$/) || ($k eq $c->{lhs_col})) {
                        $lv = $row->{$k};
                        last;
                    }
                }
            }
            # IS [NOT] NULL is decided before the coercion below, and uses
            # the same rule as the single-table engine: a NULL is either an
            # undefined value (a NULL-filled outer-join row) or the empty
            # string (the on-disk representation).
            if ($c->{op} eq 'IS_NULL') {
                return 0 if defined($lv) && ($lv ne '');
                next;
            }
            if ($c->{op} eq 'IS_NOT_NULL') {
                return 0 unless defined($lv) && ($lv ne '');
                next;
            }

            $lv = '' unless defined $lv;

            # Resolve right-hand value (literal or column)
            my $rv;
            if (defined $c->{rhs_col}) {
                if (defined $c->{rhs_alias}) {
                    $rv = $row->{"$c->{rhs_alias}.$c->{rhs_col}"};
                }
                else {
                    for my $k (keys %$row) {
                        if (($k =~ /\.\Q$c->{rhs_col}\E$/) || ($k eq $c->{rhs_col})) {
                            $rv = $row->{$k};
                            last;
                        }
                    }
                }
            }
            else {
                $rv = $c->{val};
            }
            $rv = '' unless defined $rv;

            my $op  = $c->{op};

            # IN / NOT IN
            if (($op eq 'IN') || ($op eq 'NOT_IN')) {
                my $lhs_val = $lv;
                my $found   = 0;
                my $has_null = 0;
                for my $cv (@{$c->{vals}}) {
                    unless (defined $cv) { $has_null = 1; next }
                    my $num2 = (($lhs_val =~ /^-?\d+\.?\d*$/) && ($cv =~ /^-?\d+\.?\d*$/));
                    if ($num2 ? ($lhs_val == $cv) : ($lhs_val eq $cv)) {
                        $found = 1;
                        last;
                    }
                }
                return 0 if  $found && ($op eq 'NOT_IN');
                return 0 if !$found && ($op eq 'IN');
                # SQL NULL semantics: NOT IN with NULL in list is UNKNOWN
                # when the row value was not found in the non-NULL values.
                return 0 if $has_null && !$found && ($op eq 'NOT_IN');
                next;
            }

            my $num = (($lv =~ /^-?\d+\.?\d*$/) && ($rv =~ /^-?\d+\.?\d*$/));

            if ($op eq '=') {
                return 0 unless $num ? ($lv == $rv) : ($lv eq $rv);
            }
            elsif (($op eq '!=') || ($op eq '<>')) {
                return 0 unless $num ? ($lv != $rv) : ($lv ne $rv);
            }
            elsif ($op eq '<') {
                return 0 unless $num ? ($lv <  $rv) : ($lv lt $rv);
            }
            elsif ($op eq '>') {
                return 0 unless $num ? ($lv >  $rv) : ($lv gt $rv);
            }
            elsif ($op eq '<=') {
                return 0 unless $num ? ($lv <= $rv) : ($lv le $rv);
            }
            elsif ($op eq '>=') {
                return 0 unless $num ? ($lv >= $rv) : ($lv ge $rv);
            }
            elsif ($op eq 'LIKE') {
                my $p = _like_to_re($rv);
                return 0 unless $lv =~ /^$p$/i;
            }
        }
        return 1;
    };
}

###############################################################################
# JOIN SQL parser
# Handles:
#   SELECT col_list
#   FROM   t1 [AS a1]
#   [INNER|LEFT [OUTER]|RIGHT [OUTER]|CROSS] JOIN t2 [AS a2] ON a1.c = a2.c
#   [ JOIN t3 [AS a3] ON ... ]
#   [WHERE ...]
#   [ORDER BY alias.col [ASC|DESC]]
#   [LIMIT n] [OFFSET m]
###############################################################################
# A table alias in a FROM clause is optional, so the token that follows a
# table name has to be checked before it is accepted as one.  Without this
# guard "FROM a LEFT JOIN b ON a.id = b.bid" read LEFT as the alias of a,
# which turned the LEFT JOIN into a plain JOIN and left every "a.col"
# reference unresolvable, and "JOIN b ON ..." read ON as the alias of b,
# which dropped the join condition and produced a silent cross join.
sub _is_join_keyword {
    my($word) = @_;
    return 0 unless defined $word;
    return $word =~ /^(?:INNER|LEFT|RIGHT|FULL|OUTER|CROSS|NATURAL|JOIN|ON|USING|WHERE|GROUP|ORDER|HAVING|LIMIT|OFFSET|UNION)$/i ? 1 : 0;
}

sub _parse_join_sql {
    my($sql) = @_;
    # sql has been normalised: single spaces, trimmed

    # ---------------------------------------------------------------
    # 1. Extract SELECT column list and the FROM...rest portion
    # ---------------------------------------------------------------
    return undef unless $sql =~ /^SELECT\s+(.+?)\s+FROM\s+(.+)$/si;
    my($sel_str, $from_rest) = ($1, $2);

    # ---------------------------------------------------------------
    # 2. Strip trailing ORDER BY / LIMIT / OFFSET
    #    (strip right-to-left to avoid greedy issues)
    # ---------------------------------------------------------------
    my %opts;

    # Strip suffixes right-to-left: OFFSET, LIMIT, ORDER BY
    # (ORDER BY may precede LIMIT/OFFSET, so strip LIMIT+OFFSET first)
    if ($from_rest =~ s/\s+OFFSET\s+(\d+)\s*$//i) {
        $opts{offset} = $1;
    }
    if ($from_rest =~ s/\s+LIMIT\s+(\d+)\s*$//i) {
        $opts{limit} = $1;
    }
    # ORDER BY accepts a comma-separated key list.  Before 1.09 only a single
    # key was matched here, so "ORDER BY a.y, a.x DESC" failed to match, was
    # swallowed by the WHERE strip below and then dropped by the condition
    # parser -- the rows came back in scan order with no error.
    if ($from_rest =~ s/\s+ORDER\s+BY\s+([\w.]+(?:\s+(?:ASC|DESC))?(?:\s*,\s*[\w.]+(?:\s+(?:ASC|DESC))?)*)\s*$//i) {
        my $ob_str = $1;
        my @ob_keys;
        for my $k (split(/\s*,\s*/, $ob_str)) {
            $k =~ s/^\s+|\s+$//g;
            my $dir = 'ASC';
            $dir = uc($1) if $k =~ s/\s+(ASC|DESC)\s*$//i;
            push @ob_keys, [ $k, $dir ];
        }
        if (@ob_keys) {
            $opts{order_keys} = [ @ob_keys ];
            $opts{order_by}   = $ob_keys[0][0];
            $opts{order_dir}  = $ob_keys[0][1];
        }
    }

    # ---------------------------------------------------------------
    # 3. Extract WHERE clause (everything after WHERE keyword,
    #    which must come after all JOIN...ON clauses)
    # ---------------------------------------------------------------
    my $where_str = '';

    # WHERE must appear after the last ON clause; we find the last WHERE
    if ($from_rest =~ s/\s+WHERE\s+(.+)$//i) {
        $where_str = $1;
        $where_str =~ s/^\s+|\s+$//g;
    }

    # ---------------------------------------------------------------
    # 4. Parse the FROM clause using iterative regex matching
    #    Grammar: table [AS alias]
    #             { join_type JOIN table [AS alias] ON qcol = qcol }*
    # ---------------------------------------------------------------
    my @join_specs;

    # Parse the driving (first) table
    my $fr = $from_rest;
    $fr =~ s/^\s+//;
    unless ($fr =~ s/^(\w+)//) {
        return undef;
    }
    my $first_tbl   = $1;
    my $first_alias = $first_tbl;
    if ($fr =~ /^\s+(?:AS\s+)?(\w+)/i) {
        my $cand = $1;
        unless (_is_join_keyword($cand)) {
            $fr =~ s/^\s+(?:AS\s+)?\w+//i;
            $first_alias = $cand;
        }
    }
    push @join_specs, { table => $first_tbl, alias => $first_alias, type => 'FIRST' };

    # Iteratively match JOIN clauses.
    #
    # The join-type words, the table and its alias are matched first; the ON
    # expression is then taken as everything up to the start of the next JOIN
    # clause (or the end of the FROM text) and checked separately.  Until 1.09
    # the ON clause was part of this pattern as an *optional* group matching
    # only "col = col", so every ON the pattern could not read simply failed
    # to participate: on_left and on_right stayed undef and join_select fell
    # through to its Cartesian-product branch.  "ON a.x = b.k AND a.id < b.id",
    # "ON a.x < b.k", "ON b.k = a.x" (operands the other way round), USING,
    # NATURAL and FULL OUTER all returned a silent cross join instead of an
    # error.  Anything not executable is now collected in $err.
    my $err = '';
    while ($fr =~ s/^\s+((?:(?:INNER|LEFT|RIGHT|FULL|CROSS|NATURAL|OUTER)\s+)*)JOIN\s+(\w+)(?:\s+(?:AS\s+)?((?!(?:INNER|LEFT|RIGHT|FULL|OUTER|CROSS|NATURAL|JOIN|ON|USING|WHERE|GROUP|ORDER|HAVING|LIMIT|OFFSET|UNION)\b)\w+))?//i) {
        my($type_kw, $tbl, $alias) = ($1, $2, $3);
        $type_kw = '' unless defined $type_kw;
        $type_kw =~ s/\s+$//;
        my $type = 'INNER';
        if ($type_kw =~ /NATURAL/i) {
            $err = "NATURAL JOIN is not supported; name the join columns "
                 . "with ON <left>.<col> = <right>.<col>"
                unless $err ne '';
        }
        elsif ($type_kw =~ /FULL/i) {
            $err = "FULL OUTER JOIN is not supported; use LEFT JOIN or "
                 . "RIGHT JOIN, or combine the two with UNION"
                unless $err ne '';
        }
        elsif ($type_kw =~ /CROSS/i) {
            $type = 'CROSS';
        }
        elsif ($type_kw =~ /LEFT/i) {
            $type = 'LEFT';
        }
        elsif ($type_kw =~ /RIGHT/i) {
            $type = 'RIGHT';
        }
        $alias = $tbl unless defined $alias;

        # USING (col, ...) -- recognised only so that it can be rejected.
        if ($fr =~ s/^\s+USING\s*\(([^)]*)\)//i) {
            $err = "JOIN ... USING is not supported; use "
                 . "ON <left>.<col> = <right>.<col>"
                unless $err ne '';
        }

        # ON <expr>, up to the next JOIN clause or the end of the FROM text.
        my($on_left, $on_right);
        if ($fr =~ s/^\s+ON\s+(.*?)(?=\s+(?:(?:INNER|LEFT|RIGHT|FULL|CROSS|NATURAL|OUTER)\s+)*JOIN\b|$)//is) {
            my $on_expr = $1;
            $on_expr =~ s/^\s+|\s+$//g;
            if ($on_expr =~ /^([\w.]+)\s*=\s*([\w.]+)$/) {
                ($on_left, $on_right) = ($1, $2);
            }
            else {
                $err = "Unsupported JOIN condition 'ON $on_expr'; a JOIN "
                     . "accepts a single equality between two columns, as in "
                     . "ON <left>.<col> = <right>.<col>.  Move any further "
                     . "restriction into the WHERE clause"
                    unless $err ne '';
            }
        }
        elsif ($type ne 'CROSS') {
            $err = "JOIN $tbl has no ON clause; add "
                 . "ON <left>.<col> = <right>.<col>, or write CROSS JOIN for "
                 . "a deliberate Cartesian product"
                unless $err ne '';
        }

        push @join_specs, {
            table    => $tbl,
            alias    => $alias,
            type     => $type,
            on_left  => $on_left,
            on_right => $on_right,
        };
    }

    # Must have at least 2 tables to be a JOIN.  A JOIN that appears only
    # inside a subquery lands here too, so this returns undef without an
    # error and lets the ordinary SELECT parser take over.
    return undef if @join_specs < 2;

    # Text left over in the FROM chain used to be discarded without a word.
    if (($err eq '') && ($fr =~ /\S/)) {
        my $left = $fr;
        $left =~ s/^\s+|\s+$//g;
        $err = "Unsupported text in FROM clause: '$left'";
    }

    return [ undef, undef, undef, undef, $err ] if $err ne '';

    # ---------------------------------------------------------------
    # 5. Parse SELECT column list
    # ---------------------------------------------------------------
    my @col_specs;

    # DISTINCT used to be left glued to the first select item, which made the
    # item unresolvable: every row came back empty and nothing was deduplicated.
    if ($sel_str =~ s/^\s*DISTINCT\s+//i) {
        $opts{distinct} = 1;
    }
    if ($sel_str =~ /^\s*\*\s*$/) {
        @col_specs = (); # empty = all columns (expanded later)
    }
    else {
        for my $cs (split /\s*,\s*/, $sel_str) {
            $cs =~ s/^\s+|\s+$//g;
            push @col_specs, $cs;
        }
    }

    # ---------------------------------------------------------------
    # 6. Parse WHERE conditions
    # ---------------------------------------------------------------
    my @where_conds;
    if ($where_str =~ /\S/) {
        my($wc, $werr) = _parse_join_conditions($where_str);
        return [ undef, undef, undef, undef, $werr ] if $werr ne '';
        @where_conds = @$wc;
    }

    return [ [ @join_specs ], [ @col_specs ], [ @where_conds ], { %opts }, '' ];
}

# Parse WHERE expression containing possibly qualified column names
# Returns arrayref of condition hashrefs
sub _parse_join_conditions {
    my($expr) = @_;
    return ([], '') unless defined($expr) && ($expr =~ /\S/);
    my @conds;

    # Split on AND.  BETWEEN carries an AND of its own that is not a
    # conjunction, so a part that opened a BETWEEN is glued back together
    # with the part that follows it.
    my @raw = split(/\s+AND\s+/i, $expr);
    my @parts;
    while (@raw) {
        my $p = shift @raw;
        if (($p =~ /\bBETWEEN\b/i) && ($p !~ /\bBETWEEN\b.*\bAND\b/i) && @raw) {
            $p .= ' AND ' . shift(@raw);
        }
        push @parts, $p;
    }

    for my $part (@parts) {
        $part =~ s/^\s+|\s+$//g;
        next unless $part =~ /\S/;

        # col IS [NOT] NULL.  Without this a LEFT JOIN anti-join
        # ("WHERE right.col IS NULL") matched no pattern at all and was
        # dropped, so every joined row came back unfiltered.
        if ($part =~ /^((?:\w+\.)?\w+)\s+IS\s+(NOT\s+)?NULL$/i) {
            my($lhs, $neg) = ($1, $2);
            my($la, $lc)   = _split_qualified($lhs);
            push @conds, {
                lhs_alias => $la,
                lhs_col   => $lc,
                op        => ($neg ? 'IS_NOT_NULL' : 'IS_NULL'),
            };
            next;
        }

        # col BETWEEN lo AND hi  ->  col >= lo, col <= hi
        if ($part =~ /^((?:\w+\.)?\w+)\s+BETWEEN\s+(?:'([^']*)'|(-?\d+\.?\d*))\s+AND\s+(?:'([^']*)'|(-?\d+\.?\d*))$/i) {
            my($lhs, $lo_s, $lo_n, $hi_s, $hi_n) = ($1, $2, $3, $4, $5);
            my($la, $lc) = _split_qualified($lhs);
            my $lo = defined($lo_s) ? $lo_s : $lo_n;
            my $hi = defined($hi_s) ? $hi_s : $hi_n;
            push @conds, { lhs_alias=>$la, lhs_col=>$lc, op=>'>=', val=>$lo };
            push @conds, { lhs_alias=>$la, lhs_col=>$lc, op=>'<=', val=>$hi };
            next;
        }

        # col-vs-col:   alias1.col1 OP alias2.col2
        if (($part =~ /^((?:\w+\.)?\w+)\s*(=|!=|<>|<=|>=|<|>)\s*((?:\w+\.)?\w+)$/i) && ($part !~ /'/)) {
            my($lhs, $op, $rhs) = ($1, uc($2), $3);

            # Heuristic: if rhs looks like a number, treat as literal
            if ($rhs =~ /^-?\d+\.?\d*$/) {
                my($la, $lc) = _split_qualified($lhs);
                push @conds, { lhs_alias=>$la, lhs_col=>$lc, op=>$op, val=>$rhs };
            }
            else {
                my($la, $lc) = _split_qualified($lhs);
                my($ra, $rc) = _split_qualified($rhs);
                push @conds, { lhs_alias=>$la, lhs_col=>$lc, op=>$op, rhs_alias=>$ra, rhs_col=>$rc };
            }
            # col [NOT] IN (val, val, ...)
        }
        elsif ($part =~ /^((?:\w+\.)?\w+)\s+(NOT\s+)?IN\s*\(([^)]*)\)\s*$/i) {
            my($lhs, $neg, $list_str) = ($1, $2, $3);
            my($la, $lc) = _split_qualified($lhs);
            my @vals;
            my $ls = $list_str;
            while ($ls =~ s/^\s*(?:'([^']*)'|(-?\d+\.?\d*)|(NULL))\s*(?:,|$)//i) {
                my($sv, $nv, $nl) = ($1, $2, $3);
                push @vals, defined($nl) ? undef : (defined($sv) ? $sv : $nv);
            }
            push @conds, {
                lhs_alias => $la,
                lhs_col   => $lc,
                op        => ($neg ? 'NOT_IN' : 'IN'),
                vals      => [ @vals ],
            };
            # col-vs-literal
        }
        elsif ($part =~ /^((?:\w+\.)?\w+)\s*(=|!=|<>|<=|>=|<|>|LIKE)\s*(?:'([^']*)'|(-?\d+\.?\d*))$/i) {
            my($lhs, $op, $sv, $nv) = ($1, uc($2), $3, $4);
            my($la, $lc) = _split_qualified($lhs);
            push @conds, { lhs_alias=>$la, lhs_col=>$lc, op=>$op, val=>defined($sv) ? $sv : $nv };
        }
        else {

            # Until 1.09 a part that matched none of the patterns above was
            # dropped in silence, so "WHERE a.x = 1 OR a.x = 2", "WHERE NOT
            # a.x = 1" and "WHERE (a.x = 1)" returned the whole join result
            # as though no WHERE had been written at all.
            return ([], "Unsupported WHERE condition in a JOIN query: "
                      . "'$part'.  A JOIN accepts AND-separated comparisons "
                      . "between a column and a column or literal, IN, "
                      . "NOT IN, LIKE, BETWEEN and IS [NOT] NULL; OR, NOT "
                      . "and parentheses are not supported here");
        }
    }
    return ([ @conds ], '');
}

###############################################################################
# General helpers
###############################################################################
sub _err {
    my($self, $msg) = @_;
    $errstr = $msg;
    return undef;
}

# Identifier validation.
#
# Database, table and index names are used directly as path components by
# _db_path(), _file() and _idx_file().  Without a check, a caller of the
# low-level API could escape base_dir entirely -- drop_database('../x')
# would hand '../x' to File::Path::rmtree() and delete a directory tree
# outside the database.  The SQL layer already restricts every identifier
# to \w+, so this only holds the documented Perl-level methods to the
# same rule; no name that SQL can produce is rejected here.
sub _valid_name {
    my($name) = @_;
    return 0 unless defined $name;
    return 0 unless $name =~ /^\w+\z/;
    return 1;
}

# Render a name for an error message without interpolating undef.
sub _shown_name {
    my($name) = @_;
    return defined($name) ? $name : '';
}

sub _db_path {
    my($self, $db) = @_;
    File::Spec->catdir($self->{base_dir}, $db);
}

sub _file {
    my($self, $table, $ext) = @_;
    File::Spec->catfile($self->{base_dir}, $self->{db_name}, "$table.$ext");
}

sub _load_schema {
    my($self, $table) = @_;
    unless (_valid_name($table)) {
        my $bad = _shown_name($table);
        $errstr = "Invalid table name '$bad'";
        return undef;
    }
    return $self->{_tables}{$table} if $self->{_tables}{$table};
    my $sch_file = $self->_file($table, 'sch');
    unless (-f $sch_file) {
        $errstr = "Table '$table' does not exist";
        return undef;
    }
    local *FH;
    open(FH, "< $sch_file") or do { $errstr = "Cannot read schema: $!"; return undef; };
    my($sch, @cols, %indexes);
    $sch = {};
    $sch->{notnull}  = {};
    $sch->{defaults} = {};
    $sch->{checks}   = {};
    $sch->{pk}       = undef;
    local $_;
    while (<FH>) {
        chomp;
        if (/^RECSIZE=(\d+)/) {
            $sch->{recsize} = $1;
        }
        elsif (/^COL=(\w+):(\w+):(\d+)(?::(\d+))?/) {
            # 4th field is decl (declared size); absent in old schema files
            push @cols, { name=>$1, type=>$2, size=>$3,
                          decl=>(defined($4) ? $4+0 : $3+0) };
        }
        elsif (/^NOTNULL=(\w+)/) {
            $sch->{notnull}{$1} = 1;
        }
        elsif (/^DEFAULT=(\w+):(.+)/) {
            $sch->{defaults}{$1} = $2;
        }
        elsif (/^CHECK=(\w+):(.+)/) {
            $sch->{checks}{$1} = $2;
        }
        elsif (/^PK=(\w+)/) {
            $sch->{pk}          = $1;
            $sch->{notnull}{$1} = 1;
        }
        elsif (/^IDX=(\w+):(\w+):([01])/) {
            my($iname, $icol, $iuniq) = ($1, $2, $3);
            my($cdef) = grep { $_->{name} eq $icol } @cols;
            $indexes{$iname} = {
                name    => $iname,
                col     => $icol,
                unique  => $iuniq+0,
                keysize => ($cdef ? $cdef->{size} : 0),
                coltype => ($cdef ? $cdef->{type} : 'VARCHAR'),
            };
        }
    }
    close FH;
    $sch->{cols}               = [ @cols ];
    $sch->{indexes}            = { %indexes };
    $self->{_tables}{$table} = $sch;
    return $sch;
}

sub _rewrite_schema {
    my($self, $table, $sch) = @_;
    my $sch_file = $self->_file($table, 'sch');
    local *FH;
    open(FH, "> $sch_file") or return $self->_err("Cannot rewrite schema: $!");
    my $ok = print FH "VERSION=1\n";
    $ok &&= print FH "RECSIZE=$sch->{recsize}\n";
    for my $c (@{$sch->{cols}}) {
        $ok &&= print FH "COL=$c->{name}:$c->{type}:$c->{size}:"
            . (defined($c->{decl}) ? $c->{decl} : $c->{size}) . "\n";
    }
    for my $ix (values %{$sch->{indexes}}) {
        $ok &&= print FH "IDX=$ix->{name}:$ix->{col}:$ix->{unique}\n";
    }
    for my $c (sort keys %{$sch->{notnull} || {}}) {
        $ok &&= print FH "NOTNULL=$c\n";
    }
    for my $c (sort keys %{$sch->{defaults} || {}}) {
        $ok &&= print FH "DEFAULT=$c:$sch->{defaults}{$c}\n";
    }
    for my $c (sort keys %{$sch->{checks} || {}}) {
        $ok &&= print FH "CHECK=$c:$sch->{checks}{$c}\n";
    }
    $ok &&= print FH "PK=$sch->{pk}\n" if $sch->{pk};
    my $err = $!;
    unless ($ok && close(FH)) {
        $err = $! if $ok;
        close FH if $ok;
        return $self->_err("Cannot rewrite schema: $err");
    }
    return 1;
}

# Does $v look like a number that Perl can use in arithmetic without
# complaining under -w?  Leading and trailing whitespace is allowed, an
# optional sign, a decimal part and an exponent; everything else -- the
# empty string, 'abc', '12abc', '0x10', 'Inf', 'NaN' -- is not numeric.
#
# The same test used to be written out three times (index key encoding,
# type validation and record packing) and the FLOAT paths had no test at
# all, which is how "isn't numeric" warnings escaped from inside this
# module.  Keep it in one place so the three callers cannot drift apart.
sub _looks_numeric {
    my($v) = @_;
    return 0 unless defined $v;
    return $v =~ /^\s*[-+]?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?\s*$/ ? 1 : 0;
}

# Is $v a well-formed calendar date in YYYY-MM-DD form?
sub _valid_date {
    my($v) = @_;
    return 0 unless $v =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/;
    my($y, $m, $d) = ($1, $2, $3);
    return 0 if ($m < 1) || ($m > 12);
    return 0 if $d < 1;
    my @mdays = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
    my $max = $mdays[$m-1];
    if ($m == 2) {
        $max = 29 if ((($y % 4) == 0) && (($y % 100) != 0)) || (($y % 400) == 0);
    }
    return 0 if $d > $max;
    return 1;
}

# Return an error message when $v cannot be stored in column $col, or undef
# when it can.  NULL (undef or the empty string) is always storable.
sub _type_error {
    my($col, $v) = @_;
    return undef unless defined($v) && ($v ne '');
    my $cn = $col->{name};
    if ($col->{type} eq 'INT') {
        # A value that is not numeric at all keeps its historical
        # behaviour and is stored as 0.  Only a numeric value too large
        # for the 4-byte field is rejected, because that used to be
        # silently clamped to the nearest limit.
        return undef unless _looks_numeric($v);
        return undef if ($v >= INT_MIN) && ($v <= INT_MAX);
        return "Integer out of range for column '$cn': '$v' "
             . '(INT holds ' . INT_MIN . ' .. ' . INT_MAX . ')';
    }
    if ($col->{type} eq 'DATE') {
        return undef if _valid_date($v);
        return "Invalid DATE for column '$cn': '$v' (expected YYYY-MM-DD)";
    }
    return undef;
}

sub _pack_record {
    my($self, $sch, $row) = @_;
    my $data = RECORD_ACTIVE;
    for my $col (@{$sch->{cols}}) {
        my $v = defined($row->{$col->{name}}) ? $row->{$col->{name}} : '';
        my $t = $col->{type};
        my $s = $col->{size};
        if ($t eq 'INT') {
            # A value that is not numeric is stored as 0.  It is tested
            # here rather than left to int() so that -w stays quiet.
            my $iv = _looks_numeric($v) ? int($v) : 0;
            $iv = INT_MAX if $iv > INT_MAX;
            $iv = INT_MIN if $iv < INT_MIN;
            $data .= pack('N', $iv&0xFFFFFFFF);
        }
        elsif ($t eq 'FLOAT') {
            # Same rule as INT, and for the same reason: a value that is
            # not numeric is stored as 0 without a warning.  Up to 1.08
            # this branch handed the raw value to pack() and any string
            # that was not a number leaked an "isn't numeric" warning out
            # of the module, whatever the caller's warning settings were.
            $data .= pack('d', _looks_numeric($v) ? $v+0 : 0);
        }
        else {
            my $sv = substr($v, 0, $s);
            $sv .= "\x00" x ($s-length($sv));
            $data .= $sv;
        }
    }
    return $data;
}

sub _unpack_record {
    my($self, $sch, $raw) = @_;
    my %row;
    my $offset = 1;
    for my $col (@{$sch->{cols}}) {
        my $t = $col->{type};
        my $s = $col->{size};
        my $chunk = substr($raw, $offset, $s);
        if ($t eq 'INT') {
            my $uv = unpack('N', $chunk);
            $uv -= 4294967296 if $uv > 2147483647;
            $row{$col->{name}} = $uv;
        }
        elsif ($t eq 'FLOAT') {
            $row{$col->{name}} = unpack('d', $chunk);
        }
        else {
            (my $sv = $chunk) =~ s/\x00+$//;
            $row{$col->{name}} = $sv;
        }
        $offset += $s;
    }
    return { %row };
}

sub _lock_ex { flock($_[0], LOCK_EX) }
sub _lock_sh { flock($_[0], LOCK_SH) }
sub _unlock  { flock($_[0], LOCK_UN) }

# Put a write handle into autoflush mode.
#
# print() buffers, and the buffer is written out by close(), which runs
# after _unlock().  Without this the data would reach the file only after
# the exclusive lock had already been handed to another process.  With
# autoflush on, every print() reaches the file while the lock is still
# held.  IO::Handle->autoflush is avoided on purpose: the select() idiom
# needs no module and works on every Perl from 5.005_03 onwards.
sub _autoflush {
    my $old = select($_[0]);
    $| = 1;
    select($old);
}

sub _to_where_sub {
    my($wi) = @_;
    return undef unless defined $wi;
    return $wi if ref($wi) eq 'CODE';
    return _compile_where_from_conds($wi) if ref($wi) eq 'ARRAY';
    return undef;
}

sub _split_col_defs {
    my($str) = @_;
    my @parts;
    my $cur   = '';
    my $depth = 0;
    for my $ch (split //, $str) {
        if ($ch eq '(') {
            $depth++;
            $cur .= $ch;
        }
        elsif ($ch eq ')') {
            $depth--;
            $cur .= $ch;
        }
        elsif (($ch eq ',') && ($depth == 0)) {
            push @parts, $cur;
            $cur = '';
        }
        else {
            $cur .= $ch;
        }
    }
    push @parts, $cur if $cur =~ /\S/;
    return @parts;
}

sub _parse_values {
    my($str) = @_;
    my @vals;
    while (length $str) {
        $str =~ s/^\s+//;
        last unless length $str;
        if ($str =~ s/^'((?:[^']|'')*)'(?:\s*,\s*|\s*$)//) {
            my $s = $1;
            $s =~ s/''/'/g;
            push @vals, $s;
        }
        elsif ($str =~ s/^(NULL)(?:\s*,\s*|\s*$)//i) {
            push @vals, undef;
        }
        elsif ($str =~ s/^(-?\d+\.?\d*)(?:\s*,\s*|\s*$)//) {
            push @vals, $1;
        }
        else {
            last;
        }
    }
    return @vals;
}

sub _parse_conditions {
    my($expr) = @_;
    my @conds;

    # Use paren-aware AND splitter
    my @parts = _split_and_clauses($expr);
    for my $part (@parts) {
        $part =~ s/^\s+|\s+$//g;

        # col [NOT] IN (val, val, ...)  -- expanded from subquery or literal list
        if ($part =~ /^(\w+)\s+(NOT\s+)?IN\s*\(([^)]*)\)\s*$/i) {
            my($col, $neg, $list_str) = ($1, $2, $3);
            my @vals;

            # parse list: numbers or quoted strings or NULL
            my $ls = $list_str;
            while ($ls =~ s/^\s*(?:'([^']*)'|(-?\d+\.?\d*)|(NULL))\s*(?:,|$)//i) {
                my($sv, $nv, $nl) = ($1, $2, $3);
                push @vals, defined($nl) ? undef : (defined($sv) ? $sv : $nv);
            }
            push @conds, {
                col  => $col,
                op   => $neg ? 'NOT_IN' : 'IN',
                vals => [ @vals ],
            };
            next;
        }

        # EXISTS (1) or EXISTS (0) -- already evaluated by subquery expander
        if ($part =~ /^(NOT\s+)?EXISTS\s*\((\d+)\)$/i) {
            my($neg, $val) = ($1, $2);
            my $truth = $val ? 1 : 0;
            $truth = 1 - $truth if $neg;
            push @conds, { op => 'CONST', val => $truth };
            next;
        }

        # EXISTS (1) or NOT EXISTS (0) without outer parens (legacy)
        if ($part =~ /^(NOT\s+)?EXISTS\s+(\d+)$/i) {
            my($neg, $val) = ($1, $2);
            my $truth = $val ? 1 : 0;
            $truth = 1 - $truth if $neg;
            push @conds, { op => 'CONST', val => $truth };
            next;
        }

        # col OP NULL -- SQL NULL semantics: comparison with NULL is always false
        if ($part =~ /^(\w+)\s*(=|!=|<>|<=|>=|<|>)\s*NULL$/i) {
            push @conds, { op => 'CONST', val => 0 };
            next;
        }

        # IS [NOT] NULL
        if ($part =~ /^(\w+)\s+IS\s+(NOT\s+)?NULL$/i) {
            my($col, $neg) = ($1, $2);
            push @conds, { col=>$col, op=>$neg ? 'IS_NOT_NULL' : 'IS_NULL' };
            next;
        }

        # Normal col OP literal
        if ($part =~ /^(\w+)\s*(=|!=|<>|<=|>=|<|>|LIKE)\s*(?:'([^']*)'|(-?\d+\.?\d*))$/i) {
            my($col, $op, $sv, $nv) = ($1, $2, $3, $4);
            push @conds, { col=>$col, op=>uc($op), val=>(defined($sv) ? $sv : $nv) };
        }
    }
    return [ @conds ];
}

sub _compile_where_from_conds {
    my($conds) = @_;
    return undef unless $conds && @$conds;
    return sub {
        my($row) = @_;
        for my $c (@$conds) {
            my $op = $c->{op};

            # Constant (pre-evaluated EXISTS/NOT EXISTS)
            if ($op eq 'CONST') {
                return 0 unless $c->{val};
                # IN / NOT IN with value list
            }
            elsif (($op eq 'IN') || ($op eq 'NOT_IN')) {
                my $rv = defined($row->{$c->{col}}) ? $row->{$c->{col}} : '';
                my $found    = 0;
                my $has_null = 0;
                for my $cv (@{$c->{vals}}) {
                    unless (defined $cv) { $has_null = 1; next }
                    my $num = (($rv =~ /^-?\d+\.?\d*$/) && ($cv =~ /^-?\d+\.?\d*$/));
                    if ($num ? ($rv == $cv) : ($rv eq $cv)) {
                        $found = 1;
                        last;
                    }
                }
                return 0 if  $found && ($op eq 'NOT_IN');
                return 0 if !$found && ($op eq 'IN');
                # SQL NULL semantics: NOT IN with NULL in list is UNKNOWN
                # when the row value was not found in the non-NULL values.
                return 0 if $has_null && !$found && ($op eq 'NOT_IN');
                # IS NULL / IS NOT NULL
            }
            elsif ($op eq 'IS_NULL') {
                return 0 unless !defined($row->{$c->{col}}) || ($row->{$c->{col}} eq '');
            }
            elsif ($op eq 'IS_NOT_NULL') {
                return 0 unless defined($row->{$c->{col}}) && ($row->{$c->{col}} ne '');
                # Standard comparison
            }
            else {
                my $rv = defined($row->{$c->{col}}) ? $row->{$c->{col}} : '';
                my $cv = $c->{val};
                my $num = (($rv =~ /^-?\d+\.?\d*$/) && defined($cv) && ($cv =~ /^-?\d+\.?\d*$/));
                if ($op eq '=') {
                    return 0 unless $num ? ($rv == $cv) : ($rv eq $cv);
                }
                elsif (($op eq '!=') || ($op eq '<>')) {
                    return 0 unless $num ? ($rv != $cv) : ($rv ne $cv);
                }
                elsif ($op eq '<') {
                    return 0 unless $num ? ($rv <  $cv) : ($rv lt $cv);
                }
                elsif ($op eq '>') {
                    return 0 unless $num ? ($rv >  $cv) : ($rv gt $cv);
                }
                elsif ($op eq '<=') {
                    return 0 unless $num ? ($rv <= $cv) : ($rv le $cv);
                }
                elsif ($op eq '>=') {
                    return 0 unless $num ? ($rv >= $cv) : ($rv ge $cv);
                }
                elsif ($op eq 'LIKE') {
                    my $p = _like_to_re($cv);
                    return 0 unless $rv =~ /^$p$/i;
                }
            }
        }
        return 1;
    };
}

###############################################################################
# SQL-92 Engine
###############################################################################

# =============================================================================
# Expression evaluator  eval_expr($expr, \%row) -> scalar
# =============================================================================
sub eval_expr {
    my($expr, $row) = @_;
    return undef unless defined $expr;
    $expr =~ s/^\s+|\s+$//g;
    return undef unless length($expr);
    return undef if $expr =~ /^NULL$/i;
    return $expr + 0 if $expr =~ /^-?\d+\.?\d*$/;
    if ($expr =~ /^'((?:[^']|'')*)'$/) {
        (my $s = $1) =~ s/''/'/g;
        return $s;
    }
    if (($expr =~ /^\((.+)\)$/s) && ($1 !~ /^\s*SELECT\b/i)) {
        return eval_expr($1, $row);
    }
    if ($expr =~ /^CASE\b(.*)\bEND$/si) {
        return eval_case($1, $row);
    }
    if ($expr =~ /^COALESCE\s*\((.+)\)$/si) {
        for my $a (args($1)) {
            my $v = eval_expr($a, $row);
            return $v if defined($v) && ($v ne '');
        }
        return undef;
    }
    if ($expr =~ /^NULLIF\s*\((.+)\)$/si) {
        my @a = args($1);
        return undef unless @a == 2;
        my($va, $vb) = (eval_expr($a[0], $row), eval_expr($a[1], $row));
        if (defined($va) && defined($vb)) {
            return undef if ((($va =~ /^-?\d+\.?\d*$/) && ($vb =~ /^-?\d+\.?\d*$/)) ? ($va == $vb) : ($va eq $vb));
        }
        return $va;
    }
    if ($expr =~ /^CAST\s*\(\s*(.+?)\s+AS\s+(\w+(?:\s*\(\s*\d+\s*\))?)\s*\)$/si) {
        my($ie, $t) = ($1, uc($2));
        my $v = eval_expr($ie, $row);
        return undef unless defined $v;
        return int($v) if $t =~ /^INT/i;
        return $v + 0  if $t =~ /^(FLOAT|REAL|DOUBLE|NUMERIC|DECIMAL)/i;
        return "$v";
    }
    if ($expr =~ /^(UPPER|LOWER|LENGTH|ABS|SIGN|TRIM|LTRIM|RTRIM)\s*\((.+)\)$/si) {
        my($fn, $arg) = (uc($1), $2);
        my $v = eval_expr($arg, $row);
        return undef unless defined $v;
        return uc($v)      if $fn eq 'UPPER';
        return lc($v)      if $fn eq 'LOWER';
        return length($v)  if $fn eq 'LENGTH';
        return abs($v + 0) if $fn eq 'ABS';
        return (($v > 0) ? 1 : ($v < 0) ? -1 : 0) if $fn eq 'SIGN';
        if ($fn eq 'TRIM') {
            (my $s = $v) =~ s/^\s+|\s+$//g;
            return $s;
        }
        if ($fn eq 'LTRIM') {
            (my $s = $v) =~ s/^\s+//;
            return $s;
        }
        if ($fn eq 'RTRIM') {
            (my $s = $v) =~ s/\s+$//;
            return $s;
        }
    }
    if ($expr =~ /^ROUND\s*\((.+)\)$/si) {
        my @a = args($1);
        my $v = eval_expr($a[0], $row);
        return undef unless defined $v;
        my $d = (@a > 1) ? int(eval_expr($a[1], $row) || 0) : 0;
        return sprintf("%.${d}f", $v+0) + 0;
    }
    if ($expr =~ /^(FLOOR|CEIL(?:ING)?)\s*\((.+)\)$/si) {
        my($fn, $arg) = (uc($1), $2);
        my $v = eval_expr($arg, $row);
        return undef unless defined $v;
        return $fn eq 'FLOOR' ? POSIX::floor($v+0) : POSIX::ceil($v+0);
    }
    if ($expr =~ /^MOD\s*\((.+)\)$/si) {
        my @a = args($1);
        return undef unless @a == 2;
        my($a, $b) = (eval_expr($a[0], $row)+0, eval_expr($a[1], $row)+0);
        return undef if $b == 0;
        return $a % $b;
    }
    if ($expr =~ /^(?:SUBSTR|SUBSTRING)\s*\((.+)\)$/si) {
        my $inner = $1;
        my($se, $ste, $le);
        if ($inner =~ /^(.+?)\s+FROM\s+(\S+)(?:\s+FOR\s+(.+))?$/si) {
            ($se, $ste, $le) = ($1, $2, $3);
        }
        else {
            ($se, $ste, $le) = args($inner);
        }
        my $s = eval_expr($se, $row);
        return undef unless defined $s;
        my $st = int(eval_expr($ste, $row) || 1);
        $st = 1 if $st < 1;
        return defined($le)
            ? substr($s, $st-1, int(eval_expr($le, $row) || 0))
            : substr($s, $st-1);
    }
    if ($expr =~ /^CONCAT\s*\((.+)\)$/si) {
        my @args = args($1);
        my $r = '';
        for (@args) {
            my $v = eval_expr($_, $row);
            $r .= defined($v) ? $v : '';
        }
        return $r;
    }

    # Binary operator: find rightmost at depth 0 (precedence low->high: || then +/- then */%)
    for my $op ('\\|\\|', '[+\\-]', '[*/%]') {
        my $p = find_binop($expr, $op);
        if (defined $p) {
            my $opsym = substr($expr, $p->{s}, $p->{l});
            my $lv = eval_expr(substr($expr, 0, $p->{s}), $row);
            my $rv = eval_expr(substr($expr, $p->{s}+$p->{l}), $row);
            if ($opsym eq '||') {
                return (defined($lv) ? $lv : '').(defined($rv) ? $rv : '');
            }
            return undef unless defined($lv) && defined($rv);
            my($l, $r) = ($lv + 0, $rv + 0);
            return $l + $r if $opsym eq '+';
            return $l - $r if $opsym eq '-';
            return $l * $r if $opsym eq '*';
            return undef   if (($opsym eq '/') || ($opsym eq '%')) && ($r == 0);
            return $l / $r if $opsym eq '/';
            return $l % $r if $opsym eq '%';
        }
    }
    if ($expr =~ /^-([\w('.].*)$/s) {
        my $v = eval_expr($1, $row);
        return undef unless defined $v;
        return - ($v + 0);
    }
    if ($expr =~ /^(\w+)\.(\w+)$/) {
        my($a, $c) = ($1, $2);
        return exists($row->{"$a.$c"}) ? $row->{"$a.$c"} : $row->{$c};
    }
    return $row->{$expr} if $expr =~ /^\w+$/;
    return undef;
}

sub eval_case {
    my($body, $row) = @_;
    $body =~ s/^\s+|\s+$//g;
    my $base;
    unless ($body =~ /^\s*WHEN\b/i) {
        $body =~ s/^(.+?)\s+(?=WHEN\b)//si and $base = $1;
    }
    my $else;
    $body =~ s/\s*\bELSE\b\s+(.+?)\s*$//si and $else = $1;
    while ($body =~ s/^\s*WHEN\s+(.+?)\s+THEN\s+(.+?)(?=\s+WHEN\b|\s*$)//si) {
        my($we, $te) = ($1, $2);
        my $m;
        if (defined $base) {
            my($bv, $wv) = (eval_expr($base, $row), eval_expr($we, $row));
            $m = defined($bv) && defined($wv) && ((($bv =~ /^-?\d+\.?\d*$/) && ($wv =~ /^-?\d+\.?\d*$/)) ? ($bv == $wv) : ($bv eq $wv));
        }
        else {
            $m = eval_bool($we, $row);
        }
        return eval_expr($te, $row) if $m;
    }
    return defined($else) ? eval_expr($else, $row) : undef;
}

sub eval_bool {
    my($expr, $row) = @_;
    $expr =~ s/^\s+|\s+$//g;
    if ($expr =~ /^(.+?)\s*(=|!=|<>|<=|>=|<|>)\s*(.+)$/s) {
        my($l, $op, $r) = ($1, uc($2), $3);
        my($lv, $rv) = (eval_expr($l, $row), eval_expr($r, $row));
        return 0 unless defined($lv) && defined($rv);
        my $n = (($lv =~ /^-?\d+\.?\d*$/) && ($rv =~ /^-?\d+\.?\d*$/));
        return $n ? ($lv == $rv) : ($lv eq $rv) if $op eq '=';
        return $n ? ($lv != $rv) : ($lv ne $rv) if $op =~ /^(!|<>)/;
        return $n ? ($lv <  $rv) : ($lv lt $rv) if $op eq '<';
        return $n ? ($lv >  $rv) : ($lv gt $rv) if $op eq '>';
        return $n ? ($lv <= $rv) : ($lv le $rv) if $op eq '<=';
        return $n ? ($lv >= $rv) : ($lv ge $rv) if $op eq '>=';
    }
    if ($expr =~ /^(.+)\s+IS\s+(NOT\s+)?NULL$/si) {
        my $v = eval_expr($1, $row);
        return $2 ? (defined($v) && ($v ne '')) : (!defined($v) || ($v eq ''));
    }
    return 0;
}

# Argument splitter (handles parentheses and string literals)
sub args {
    my($str) = @_;
    my @parts;
    my $cur  = '';
    my $d    = 0;
    my $in_q = 0;
    for my $ch (split //, $str) {
        if (($ch eq "'") && !$in_q) {
            $in_q = 1;
            $cur .= $ch;
        }
        elsif (($ch eq "'") && $in_q) {
            $in_q = 0;
            $cur .= $ch;
        }
        elsif ($in_q) {
            $cur .= $ch;
        }
        elsif ($ch eq '(') {
            $d++;
            $cur .= $ch;
        }
        elsif ($ch eq ')') {
            $d--;
            $cur .= $ch;
        }
        elsif (($ch eq ',') && ($d == 0)) {
            push @parts, $cur;
            $cur = '';
        }
        else {
            $cur .= $ch;
        }
    }
    push @parts, $cur if $cur =~ /\S/;
    return @parts;
}

# Find rightmost binary operator at depth 0
sub find_binop {
    my($expr, $op_pat) = @_;
    my $d    = 0;
    my $in_q = 0;
    my $best = undef;
    for my $i (0 .. length($expr)-1) {
        my $ch = substr($expr, $i, 1);
        if (($ch eq "'") && !$in_q) {
            $in_q = 1;
        }
        elsif (($ch eq "'") && $in_q) {
            $in_q = 0;
        }
        elsif (!$in_q && ($ch eq '(')) {
            $d++;
        }
        elsif (!$in_q && ($ch eq ')')) {
            $d--;
        }
        elsif (!$in_q && ($d == 0) && ($i > 0)) {
            if (substr($expr, $i) =~ /^($op_pat)/) {
                $best = { s=>$i, l=>length($1) };
            }
        }
    }
    return $best;
}

# =============================================================================
# WHERE engine  where_sub($expr) -> coderef
# =============================================================================
sub where_sub {
    my($expr) = @_;
    return sub{1} unless defined($expr) && ($expr =~ /\S/);
    return compile_tree(parse_bool($expr));
}

sub parse_bool {
    my($expr) = @_;
    $expr =~ s/^\s+|\s+$//g;
    my @or = bool_split($expr, 'OR');
    return { op=>'OR', kids=>[map{parse_bool($_)}@or] } if @or > 1;
    my @and = bool_split($expr, 'AND');
    return { op=>'AND', kids=>[map{parse_bool($_)}@and] } if @and > 1;
    return { op=>'NOT', kids=>[parse_bool($1)] } if $expr =~ /^NOT\s+(.+)$/si;
    if (($expr =~ /^\((.+)\)$/s) && ($1 !~ /^\s*SELECT\b/i)) {
        return parse_bool($1);
    }
    return { op=>'LEAF', cond=>parse_leaf($expr) };
}

sub bool_split {
    my($expr, $kw) = @_;
    my $kl   = length($kw);
    my @parts;
    my $cur  = '';
    my $d    = 0;
    my $in_q = 0;
    my $i    = 0;
    my $len  = length($expr);
    while ($i < $len) {
        my $ch = substr($expr, $i, 1);
        if (($ch eq "'") && !$in_q) {
            $in_q = 1;
            $cur .= $ch;
        }
        elsif (($ch eq "'") && $in_q) {
            $in_q = 0;
            $cur .= $ch;
        }
        elsif ($in_q) {
            $cur .= $ch;
        }
        elsif ($ch eq '(') {
            $d++;
            $cur .= $ch;
        }
        elsif ($ch eq ')') {
            $d--;
            $cur .= $ch;
        }
        elsif (($d == 0)
            && !$in_q
            && (uc(substr($expr, $i, $kl)) eq $kw)
            && (($i == 0) || (substr($expr, $i-1, 1) =~ /\s/))
            && (($i+$kl) < $len)
            && (substr($expr, $i+$kl, 1) =~ /\s/)
        ) {

            # For AND: do not split the AND inside BETWEEN x AND y
            if ($kw eq 'AND') {
                my $before = $cur;
                $before =~ s/^\s+|\s+$//g;
                if ($before =~ /\bBETWEEN\s+\S+\s*$/i) {
                    $cur .= $ch;
                    $i++;
                    next;
                }
            }
            push @parts, $cur;
            $cur = '';
            $i += $kl;
            next;
        }
        else {
            $cur .= $ch;
        }
        $i++;
    }
    push @parts, $cur;
    @parts = grep {/\S/} @parts;
    return @parts > 1 ? @parts : ($expr);
}

# Split $sql into alternating chunks of [ is_literal, text ] so that a
# placeholder inside a quoted string is never mistaken for a bind marker.
sub _split_sql_literals {
    my($sql) = @_;
    my @parts;
    my $len = length $sql;
    my $i   = 0;
    my $cur = '';
    while ($i < $len) {
        if (substr($sql, $i, 1) eq "'") {
            push @parts, [ 0, $cur ] if length $cur;
            $cur  = '';
            my $j = $i + 1;
            while ($j < $len) {
                if (substr($sql, $j, 1) ne "'") { $j++; next }
                last unless substr($sql, $j+1, 1) eq "'";
                $j += 2;
            }
            $j = $len if $j > $len;
            push @parts, [ 1, substr($sql, $i, $j-$i+1) ];
            $i = $j + 1;
            next;
        }
        $cur .= substr($sql, $i, 1);
        $i++;
    }
    push @parts, [ 0, $cur ] if length $cur;
    return @parts;
}

# Collapse each run of whitespace to a single space, but leave string
# literals byte for byte alone: a newline or a tab inside a literal is
# part of the value, not statement layout.
sub _normalize_sql_space {
    my($sql) = @_;
    my $out = '';
    for my $part (_split_sql_literals($sql)) {
        if ($part->[0]) { $out .= $part->[1]; next }
        my $chunk = $part->[1];
        $chunk =~ s/\s+/ /g;
        $out .= $chunk;
    }
    return $out;
}

sub _strip_sql_comments {
    my($sql) = @_;
    my $out  = '';
    my $len  = length($sql);
    my $i    = 0;
    while ($i < $len) {
        my $ch = substr($sql, $i, 1);
        if ($ch eq "'") {
            my $j = $i + 1;
            while ($j < $len) {
                if (substr($sql, $j, 1) ne "'") { $j++; next }
                last unless substr($sql, $j+1, 1) eq "'";
                $j += 2;
            }
            $j = $len if $j > $len;
            $out .= substr($sql, $i, $j-$i+1);
            $i = $j + 1;
            next;
        }
        if (substr($sql, $i, 2) eq '--') {
            $i += 2;
            $i++ while ($i < $len) && (substr($sql, $i, 1) ne "\n");
            $out .= ' ';
            next;
        }
        if (substr($sql, $i, 2) eq '/*') {
            $i += 2;
            $i++ while ($i < $len) && (substr($sql, $i, 2) ne '*/');
            $i += 2;
            $out .= ' ';
            next;
        }
        $out .= $ch;
        $i++;
    }
    $out =~ s/^\s+|\s+$//g;
    return $out;
}

sub _like_to_re {
    my($pat) = @_;
    my $re   = '';
    for my $i (0 .. length($pat)-1) {
        my $ch = substr($pat, $i, 1);
        if    ($ch eq '%') { $re .= '.*' }
        elsif ($ch eq '_') { $re .= '.'  }
        else               { $re .= quotemeta($ch) }
    }
    return $re;
}

sub parse_leaf {
    my($part) = @_;
    $part =~ s/^\s+|\s+$//g;
    if ($part =~ /^(NOT\s+)?EXISTS\s*\((\d+)\)$/i) {
        my($neg, $v) = ($1, $2);
        my $t = $v ? 1 : 0;
        $t = 1 - $t if $neg;
        return { op=>'CONST', val=>$t };
    }
    if ($part =~ /^([\w.]+)\s+(NOT\s+)?IN\s*\(([^)]*)\)$/si) {
        my($col, $neg, $ls) = ($1, $2, $3);
        my @vals;
        while ($ls =~ s/^\s*(?:'((?:[^']|'')*)'|(-?\d+\.?\d*)|(NULL))\s*(?:,|$)//i) {
            my($sv, $nv, $nl) = ($1, $2, $3);
            if (defined $nl) {
                push @vals, undef;
            }
            elsif (defined $sv) {
                (my $x = $sv) =~ s/''/'/g;
                push @vals, $x;
            }
            else {
                push @vals, $nv;
            }
        }
        return { op=>($neg ? 'NOT_IN' : 'IN'), col=>$col, vals=>[ @vals ] };
    }
    return { op=>'CONST', val=>0 } if $part =~ /^[\w.]+\s*(?:=|!=|<>|<=|>=|<|>)\s*NULL$/si;
    if ($part =~ /^([\w.]+)\s+IS\s+(NOT\s+)?NULL$/si) {
        return { op=>($2 ? 'IS_NOT_NULL' : 'IS_NULL'), col=>$1 };
    }
    if ($part =~ /^([\w.]+)\s+(NOT\s+)?BETWEEN\s+(.+?)\s+AND\s+(.+)$/si) {
        my($col, $neg, $lo, $hi) = ($1, $2, $3, $4);
        $lo =~ s/^'(.*)'$/$1/s;
        $hi =~ s/^'(.*)'$/$1/s;
        return { op=>($neg ? 'NOT_BETWEEN' : 'BETWEEN'), col=>$col, lo=>$lo, hi=>$hi };
    }
    if ($part =~ /^(.+?)\s+(NOT\s+)?LIKE\s+('(?:[^']|'')*'|\S+)$/si) {
        my($lhs, $neg, $pat) = ($1, $2, $3);
        $pat =~ s/^'(.*)'$/$1/s;
        $pat =~ s/''/'/g;
        my $re = _like_to_re($pat);
        return { op=>($neg ? 'NOT_LIKE' : 'LIKE'), lhs=>$lhs, re=>$re };
    }
    if ($part =~ /^(.+?)\s*(=|!=|<>|<=|>=|<|>)\s*(.+)$/s) {
        my($lhs, $op, $rhs) = ($1, uc($2), $3);
        $lhs =~ s/^\s+|\s+$//g;
        $rhs =~ s/^\s+|\s+$//g;
        my $rv;
        if ($rhs =~ /^'((?:[^']|'')*)'$/) {
            ($rv = $1) =~ s/''/'/g;
        }
        else {
            $rv = $rhs;
        }
        return{ op=>$op, lhs=>$lhs, rhs_expr=>$rhs, rhs_val=>$rv };
    }
    return{ op=>'CONST', val=>0 };
}

sub compile_tree {
    my($tree) = @_;
    my $op = $tree->{op};
    if ($op eq 'AND') {
        my @s = map {compile_tree($_)} @{$tree->{kids}};
        return sub { for my $s(@s) { return 0 unless $s->($_[0]) } 1 };
    }
    if ($op eq 'OR') {
        my @s = map { compile_tree($_) } @{$tree->{kids}};
        return sub { for my $s(@s) { return 1 if  $s->($_[0]) } 0 };
    }
    if ($op eq 'NOT') {
        my $s = compile_tree($tree->{kids}[0]);
        return sub{ $s->($_[0]) ? 0 : 1 };
    }
    return compile_leaf($tree->{cond});
}

sub compile_leaf {
    my($c) = @_;
    my $op = defined($c->{op}) ? $c->{op} : '';
    return sub { $c->{val} ? 1 : 0 } if $op eq 'CONST';
    if ($op eq 'IS_NULL') {
        my $col = $c->{col};
        return sub { my $v = $_[0]{$col}; !defined($v) || ($v eq '') };
    }
    if ($op eq 'IS_NOT_NULL') {
        my $col = $c->{col};
        return sub { my $v = $_[0]{$col}; defined($v) && ($v ne '') };
    }
    if (($op eq 'BETWEEN') || ($op eq 'NOT_BETWEEN')) {
        my($col, $lo, $hi, $neg) = ($c->{col}, $c->{lo}, $c->{hi}, $op eq 'NOT_BETWEEN');
        return sub {
            my $v = $_[0]{$col};
            return 0 unless defined $v;
            my $n = (($v =~ /^-?\d+\.?\d*$/) && ($lo =~ /^-?\d+\.?\d*$/) && ($hi =~ /^-?\d+\.?\d*$/));
            my $in_q = $n ? (($v>=$lo) && ($v<=$hi)) : (($v ge $lo) && ($v le $hi));
            $neg ? !$in_q : $in_q;
        };
    }
    if (($op eq 'IN') || ($op eq 'NOT_IN')) {
        my($col, $vals, $neg) = ($c->{col}, $c->{vals}, $op eq 'NOT_IN');
        return sub {
            my $rv = defined($_[0]{$col}) ? $_[0]{$col} : '';
            my $f        = 0;
            my $has_null = 0;
            for my $cv (@$vals) {
                unless (defined $cv) { $has_null = 1; next }
                my $n = (($rv =~ /^-?\d+\.?\d*$/) && ($cv =~ /^-?\d+\.?\d*$/));
                if ($n ? ($rv == $cv) : ($rv eq $cv)) {
                    $f = 1;
                    last;
                }
            }
            # SQL NULL semantics: NOT IN with NULL in list is UNKNOWN
            # when value not found -> treat as false (exclude the row).
            return 0 if $neg && $has_null && !$f;
            $neg ? !$f : $f;
        };
    }
    if (($op eq 'LIKE') || ($op eq 'NOT_LIKE')) {
        my($lhs, $re, $neg) = ($c->{lhs}, $c->{re}, $op eq 'NOT_LIKE');
        return sub {
            my $v = eval_expr($lhs, $_[0]);
            $v = '' unless defined $v;
            my $m = ($v =~ /^$re$/si) ? 1 : 0;
            $neg ? !$m : $m;
        };
    }
    my($lhs, $op2, $rv_lit, $rhs_expr) = @{$c}{qw(lhs op rhs_val rhs_expr)};
    return sub {
        my $row = $_[0];
        my $lv  = eval_expr($lhs, $row);
        return 0 unless defined $lv;
        my $rv = (($rhs_expr =~ /^[\w.]+$/) && ($rhs_expr !~ /^-?\d+\.?\d*$/)) ? eval_expr($rhs_expr, $row) : $rv_lit;
        $rv    = '' unless defined $rv;
        my $n = (($lv =~ /^-?\d+\.?\d*$/) && ($rv =~ /^-?\d+\.?\d*$/));
        return $n ? ($lv == $rv) : ($lv eq $rv)  if $op2 eq '=';
        return $n ? ($lv != $rv) : ($lv ne $rv)  if $op2 =~ /^(!|<>)/;
        return $n ? ($lv <  $rv) : ($lv lt $rv)  if $op2 eq '<';
        return $n ? ($lv >  $rv) : ($lv gt $rv)  if $op2 eq '>';
        return $n ? ($lv <= $rv) : ($lv le $rv)  if $op2 eq '<=';
        return $n ? ($lv >= $rv) : ($lv ge $rv)  if $op2 eq '>=';
        return 0;
    };
}

# =============================================================================
# SELECT dispatcher
# =============================================================================
sub select {
    my($self, $sql) = @_;
    # Window functions are not supported; detect and reject early.
    # Strip string literals before checking to avoid false positives.
    my $sql_nostr = $sql;
    $sql_nostr =~ s/'(?:[^']|'')*'/''/g;
    if ($sql_nostr =~ /\bOVER\s*\(/i) {
        return $self->_err(
            "Window functions (OVER clause) are not supported. "
            . "Use GROUP BY with aggregate functions instead."
        );
    }
    my @up = split_union($sql);
    return $self->exec_union([ @up ]) if @up > 1;
    if ($sql =~ /\bJOIN\b/i) {

        # Parse GROUP BY / HAVING from the SQL before handing off to _parse_join_sql
        my $join_sql = $sql;
        my(@gb_join, $having_join);
        $having_join = '';
        if ($join_sql =~ s/\bHAVING\s+(.+?)(?=\s*(?:ORDER\s+BY|LIMIT|OFFSET|$))//si) {
            $having_join = $1;
            $having_join =~ s/^\s+|\s+$//g;
        }
        if ($join_sql =~ s/\bGROUP\s+BY\s+(.+?)(?=\s*(?:HAVING|ORDER\s+BY|LIMIT|OFFSET|$))//si) {
            my $gbs = $1;
            $gbs =~ s/^\s+|\s+$//g;
            @gb_join = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } split /\s*,\s*/, $gbs;
        }
        my $has_agg = ($sql =~ /\b(?:COUNT|SUM|AVG|MIN|MAX)\s*\(/si);
        my $needs_groupby = (@gb_join || ($having_join ne '') || $has_agg);

        my $parsed = _parse_join_sql($join_sql);

        # A JOIN construct the parser cannot execute is reported here rather
        # than left to fall through to the single-table parser, which used to
        # accept it and return rows that answered a different question.
        if ($parsed && ($parsed->[4] ne '')) {
            return { type=>'error', message=>$parsed->[4] };
        }
        if ($parsed && $parsed->[0]) {
            my($js, $cs, $wc, $opts) = @$parsed;

            # ORDER BY <position>: resolve against the select list.  In the
            # aggregate branch the sort runs on projected rows keyed by
            # alias, in the plain branch on raw rows keyed by expression.
            my @sel_names =
                map { $needs_groupby ? _order_alias_of($_) : _order_name_of($_) } @$cs;
            my @ob_keys = $opts->{order_keys} ? @{$opts->{order_keys}} : ();
            for my $k (@ob_keys) {
                my($obe, $obk) = _resolve_order_ordinal_scalar($k->[0], [ @sel_names ]);
                return { type=>'error', message=>$obe } if $obe ne '';
                $k->[0] = $obk if defined $obk;
            }
            if (@ob_keys) {
                $opts->{order_keys} = [ @ob_keys ];
                $opts->{order_by}   = $ob_keys[0][0];
                $opts->{order_dir}  = $ob_keys[0][1];
            }

            # If GROUP BY / HAVING / aggregate: fetch raw rows with SELECT *
            my $rows;
            if ($needs_groupby) {

                # Fetch all columns as raw data for aggregation
                my $raw_opts = {%$opts};
                delete $raw_opts->{order_by};
                delete $raw_opts->{order_dir};
                delete $raw_opts->{order_keys};
                delete $raw_opts->{limit};
                delete $raw_opts->{offset};
                delete $raw_opts->{distinct};
                $rows = $self->join_select($js, [], $wc, $raw_opts);
            }
            else {
                $rows = $self->join_select($js, $cs, $wc, $opts);
            }
            return{ type=>'error', message=>$errstr } unless $rows;

            if ($needs_groupby) {

                # Parse col_specs from the original SQL for aggregate evaluation
                my @col_specs_raw;
                if ($sql =~ /^SELECT\s+(.+?)\s+FROM\b/si) {
                    my $cs_str = $1;
                    for my $c (split /\s*,\s*/, $cs_str) {
                        $c =~ s/^\s+|\s+$//g;
                        if ($c =~ /^(.+?)\s+AS\s+(\w+)\s*$/si) {
                            push @col_specs_raw, [ $1, $2 ];
                        }
                        else {
                            my $alias = ($c =~ /^(\w+)\.(\w+)$/) ? $2 : $c;
                            push @col_specs_raw, [ $c, $alias ];
                        }
                    }
                }

                # Group rows
                my(%gr, @go);
                if (@gb_join) {
                    for my $row (@$rows) {

                        # resolve GROUP BY key: try qualified then unqualified
                        my $k = join("\x00", map {
                            my $col = $_;
                            my $v = defined($row->{$col})
                                ? $row->{$col}
                                : (($col =~ /^(\w+)\.(\w+)$/) && defined $row->{$2})
                                    ? $row->{$2}
                                    : '';
                            defined($v) ? $v : '';
                        } @gb_join);
                        push @go, $k unless exists $gr{$k};
                        push @{$gr{$k}}, $row;
                    }
                }
                else {
                    @go          = ('__all__');
                    $gr{__all__} = $rows;
                }

                my @results;
                for my $gk (@go) {
                    my $grp = $gr{$gk};
                    my $rep = $grp->[0];
                    my %out;
                    for my $spec (@col_specs_raw) {
                        my($expr, $alias) = @$spec;
                        $out{$alias} = eval_agg($expr, $grp, $rep);
                    }
                    if ($having_join ne '') {
                        my $h = $having_join;
                        my $cnt = scalar @$grp;
                        $h =~ s/COUNT\s*\(\s*\*\s*\)/$cnt/gsi;
                        $h =~ s/\b(SUM|AVG|MIN|MAX|COUNT)\s*\(([^)]+)\)/eval_agg("$1($2)", $grp, $rep)/geis;
                        next unless where_sub($h)->({ %out });
                    }
                    push @results, { %out };
                }

                # ORDER BY from opts (every key, in order)
                my @gob = $opts->{order_keys} ? @{$opts->{order_keys}}
                        : (defined($opts->{order_by})
                            ? ([ $opts->{order_by}, ($opts->{order_dir} || 'ASC') ])
                            : ());
                if (@gob && @results) {

                    # An aggregate result row is keyed by the select-list
                    # alias, so "ORDER BY a.y" over "SELECT a.y, COUNT(*)"
                    # has to resolve to the key 'y'.  Before 1.09 it resolved
                    # to nothing and the sort quietly did not happen.
                    for my $k (@gob) {
                        next if exists $results[0]{$k->[0]};
                        if (($k->[0] =~ /^\w+\.(\w+)$/) && exists($results[0]{$1})) {
                            $k->[0] = $1;
                            next;
                        }
                        return { type=>'error', message=>
                            "ORDER BY column '$k->[0]' is not in the select "
                            . "list of this aggregate query" };
                    }
                }
                if (@gob) {
                    @results = sort {
                        my $cmp = 0;
                        for my $k (@gob) {
                            my($key, $dir) = @$k;
                            my $va = defined($a->{$key}) ? $a->{$key} : '';
                            my $vb = defined($b->{$key}) ? $b->{$key} : '';
                            my $c = (($va =~ /^-?\d+\.?\d*$/) && ($vb =~ /^-?\d+\.?\d*$/))
                                  ? ($va <=> $vb)
                                  : ($va cmp $vb);
                            $c = -$c if lc($dir) eq 'desc';
                            if ($c != 0) {
                                $cmp = $c;
                                last;
                            }
                        }
                        $cmp;
                    } @results;
                }
                if (defined($opts->{offset}) && ($opts->{offset} > 0)) {
                    @results = splice(@results, $opts->{offset});
                }
                if (defined $opts->{limit}) {
                    my $l = $opts->{limit} - 1;
                    $l = $#results if $l > $#results;
                    @results = @results[0 .. $l];
                }
                return { type=>'rows', data=>[ @results ] };
            }
            return { type=>'rows', data=>$rows };
        }
    }
    my $p = $self->parse_select($sql) or return { type=>'error', message=>"Cannot parse SELECT: $sql" };
    my($distinct, $col_specs, $tbl, $where_expr, $gb, $having, $ob, $limit, $offset) = @$p;
    my $needs_agg = (@$gb || ($having ne '') || grep { $_->[0] =~ /\b(?:COUNT|SUM|AVG|MIN|MAX)\s*\(/si } @$col_specs);
    return $self->exec_groupby($tbl, $col_specs, $where_expr, $gb, $having, $ob, $limit, $offset) if $needs_agg;
    my $sch = $self->_load_schema($tbl) or return { type=>'error', message=>$errstr };
    my $obe = _resolve_order_ordinals($ob, $col_specs, $sch);
    return { type=>'error', message=>$obe } if $obe ne '';
    my $dat = $self->_file($tbl, 'dat');
    my $ws;
    if ($where_expr ne '') {
        # Case 1: single condition  col OP val  (no AND/OR/NOT/BETWEEN/IN)
        if (($where_expr =~ /^(\w+)\s*(=|!=|<>|<=|>=|<|>)\s*(?:'([^']*)'|(-?\d+\.?\d*))$/)
            && ($where_expr !~ /\b(?:OR|AND|NOT|BETWEEN|IN)\b/i)
        ) {
            my($col, $op, $sv, $nv) = ($1, $2, $3, $4);
            my $cond = [{ col=>$col, op=>uc($op), val=>defined($sv) ? $sv : $nv }];
            my $idx = $self->_find_index_for_conds($tbl, $sch, $cond);
            if (defined $idx) {
                my $wsub = where_sub($where_expr);
                my @rows;
                local *FH;
                open(FH, "< $dat") or return $self->_err("Cannot open dat: $!");
                binmode FH;
                _lock_sh(\*FH);
                my $rs = $sch->{recsize};
                for my $rn (sort { $a <=> $b } @$idx) {
                    seek(FH, $rn*$rs, 0);
                    my $raw = '';
                    my $n   = read(FH, $raw, $rs);
                    next unless defined($n) && ($n == $rs);
                    next if substr($raw, 0, 1) eq RECORD_DELETED;
                    my $row = $self->_unpack_record($sch, $raw);
                    push @rows, $row if !$wsub || $wsub->($row);
                }
                _unlock(\*FH);
                close FH;
                return{ type=>'rows', data=>[$self->project([ @rows ], $col_specs, $distinct, $ob, $limit, $offset)] };
            }
        }
        # Case 2: AND of two range conditions on the same indexed column
        #   col OP1 val1 AND col OP2 val2  (e.g. id > 5 AND id < 10)
        #   also: col BETWEEN val1 AND val2
        my $idx_range = $self->_try_index_and_range($tbl, $sch, $where_expr);
        if (defined $idx_range) {
            my $wsub = where_sub($where_expr);
            my @rows;
            local *FH;
            open(FH, "< $dat") or return $self->_err("Cannot open dat: $!");
            binmode FH;
            _lock_sh(\*FH);
            my $rs = $sch->{recsize};
            for my $rn (sort { $a <=> $b } @$idx_range) {
                seek(FH, $rn*$rs, 0);
                my $raw = '';
                my $n   = read(FH, $raw, $rs);
                next unless defined($n) && ($n == $rs);
                next if substr($raw, 0, 1) eq RECORD_DELETED;
                my $row = $self->_unpack_record($sch, $raw);
                push @rows, $row if !$wsub || $wsub->($row);
            }
            _unlock(\*FH);
            close FH;
            return{ type=>'rows', data=>[$self->project([ @rows ], $col_specs, $distinct, $ob, $limit, $offset)] };
        }
        # Case 3: AND across different indexed columns.
        # Use the best available single-column index to narrow the candidate
        # record set, then apply the full WHERE predicate as a post-filter.
        # Example: WHERE dept = 'Eng' AND salary > 70000
        my $idx_partial = $self->_try_index_partial_and($tbl, $sch, $where_expr);
        if (defined $idx_partial) {
            my $wsub = where_sub($where_expr);
            my @rows;
            local *FH;
            open(FH, "< $dat") or return $self->_err("Cannot open dat: $!");
            binmode FH;
            _lock_sh(\*FH);
            my $rs = $sch->{recsize};
            for my $rn (sort { $a <=> $b } @$idx_partial) {
                seek(FH, $rn*$rs, 0);
                my $raw = '';
                my $n   = read(FH, $raw, $rs);
                next unless defined($n) && ($n == $rs);
                next if substr($raw, 0, 1) eq RECORD_DELETED;
                my $row = $self->_unpack_record($sch, $raw);
                push @rows, $row if !$wsub || $wsub->($row);
            }
            _unlock(\*FH);
            close FH;
            return{ type=>'rows', data=>[$self->project([ @rows ], $col_specs, $distinct, $ob, $limit, $offset)] };
        }
        # Case 4: col IN (v1, v2, ...)  -- equality index per value, union.
        my $idx_in = $self->_try_index_in($tbl, $sch, $where_expr);
        if (defined $idx_in) {
            my $wsub = where_sub($where_expr);
            my @rows;
            local *FH;
            open(FH, "< $dat") or return $self->_err("Cannot open dat: $!");
            binmode FH;
            _lock_sh(\*FH);
            my $rs = $sch->{recsize};
            for my $rn (sort { $a <=> $b } @$idx_in) {
                seek(FH, $rn*$rs, 0);
                my $raw = '';
                my $n   = read(FH, $raw, $rs);
                next unless defined($n) && ($n == $rs);
                next if substr($raw, 0, 1) eq RECORD_DELETED;
                my $row = $self->_unpack_record($sch, $raw);
                push @rows, $row if !$wsub || $wsub->($row);
            }
            _unlock(\*FH);
            close FH;
            return{ type=>'rows', data=>[$self->project([ @rows ], $col_specs, $distinct, $ob, $limit, $offset)] };
        }
        # Case 5: pure OR of simple indexed conditions.
        # Every atom must have an index; returns union of all matching records.
        my $idx_or = $self->_try_index_or($tbl, $sch, $where_expr);
        if (defined $idx_or) {
            my $wsub = where_sub($where_expr);
            my @rows;
            local *FH;
            open(FH, "< $dat") or return $self->_err("Cannot open dat: $!");
            binmode FH;
            _lock_sh(\*FH);
            my $rs = $sch->{recsize};
            for my $rn (sort { $a <=> $b } @$idx_or) {
                seek(FH, $rn*$rs, 0);
                my $raw = '';
                my $n   = read(FH, $raw, $rs);
                next unless defined($n) && ($n == $rs);
                next if substr($raw, 0, 1) eq RECORD_DELETED;
                my $row = $self->_unpack_record($sch, $raw);
                push @rows, $row if !$wsub || $wsub->($row);
            }
            _unlock(\*FH);
            close FH;
            return{ type=>'rows', data=>[$self->project([ @rows ], $col_specs, $distinct, $ob, $limit, $offset)] };
        }
        # Case 6: col NOT IN (v1, v2, ...) -- index complement.
        my $idx_not_in = $self->_try_index_not_in($tbl, $sch, $where_expr);
        if (defined $idx_not_in) {
            my $wsub = where_sub($where_expr);
            my @rows;
            local *FH;
            open(FH, "< $dat") or return $self->_err("Cannot open dat: $!");
            binmode FH;
            _lock_sh(\*FH);
            my $rs = $sch->{recsize};
            for my $rn (sort { $a <=> $b } @$idx_not_in) {
                seek(FH, $rn*$rs, 0);
                my $raw = '';
                my $n   = read(FH, $raw, $rs);
                next unless defined($n) && ($n == $rs);
                next if substr($raw, 0, 1) eq RECORD_DELETED;
                my $row = $self->_unpack_record($sch, $raw);
                push @rows, $row if !$wsub || $wsub->($row);
            }
            _unlock(\*FH);
            close FH;
            return{ type=>'rows', data=>[$self->project([ @rows ], $col_specs, $distinct, $ob, $limit, $offset)] };
        }
        $ws = where_sub($where_expr);
    }
    my @raw;
    local *FH;
    open(FH, "< $dat") or return $self->_err("Cannot open dat: $!");
    binmode FH;
    _lock_sh(\*FH);
    my $rs = $sch->{recsize};
    while (1) {
        my $raw = '';
        my $n   = read(FH, $raw, $rs);
        last unless defined($n) && ($n == $rs);
        next if substr($raw, 0, 1) eq RECORD_DELETED;
        my $row = $self->_unpack_record($sch, $raw);
        push @raw, $row if !$ws || $ws->($row);
    }
    _unlock(\*FH);
    close FH;
    return{ type=>'rows', data=>[ $self->project([ @raw ], $col_specs, $distinct, $ob, $limit, $offset) ] };
}

sub parse_select {
    my($self, $sql) = @_;
    $sql =~ s/^\s+|\s+$//g;
    $sql =~ s/^SELECT\s+//si or return undef;
    my $distinct = 0;
    $distinct    = 1 if $sql =~ s/^DISTINCT\s+//si;
    my($col_str, $rest) = split_at_from($sql);
    return undef unless defined($col_str) && defined($rest);
    $rest =~ s/^\s*FROM\s+//si;
    my $tbl;
    ($rest =~ s/^(\w+)//) and ($tbl = $1);

    # Optional alias (consumed only when token is not a SQL keyword)
    if (($rest =~ /^\s+(\w+)/) && ($1 !~ /^(?:WHERE|GROUP|ORDER|HAVING|LIMIT|OFFSET|INNER|LEFT|RIGHT|JOIN|ON|UNION)$/i)) {
        $rest =~ s/^\s+(?:AS\s+)?\w+//si;
    }
    $rest =~ s/^\s+//;
    return undef unless $tbl;
    my($limit, $offset) = (undef, undef);
    $rest =~ s/(?:^|\s+)OFFSET\s+(\d+)\s*$//si and $offset = $1;
    $rest =~ s/(?:^|\s+)LIMIT\s+(\d+)\s*$//si and $limit = $1;
    my @ob;
    if ($rest =~ s/(?:^|\s+)ORDER\s+BY\s+(.+?)(?=\s*(?:LIMIT|OFFSET|$))//si) {
        my $s = $1;
        $s =~ s/^\s+|\s+$//g;
        for my $item (split /\s*,\s*/, $s) {
            $item =~ s/^\s+|\s+$//g;
            my $dir = 'ASC';
            $item =~ s/\s+(ASC|DESC)\s*$//si and $dir = uc($1);
            push @ob, [ $item, $dir ];
        }
    }
    my $having = '';
    $rest =~ s/(?:^|\s+)HAVING\s+(.+?)(?=\s*(?:ORDER|LIMIT|OFFSET|$))//si and $having = $1;
    $having =~ s/^\s+|\s+$//g;
    my @gb;
    if ($rest =~ s/(?:^|\s+)GROUP\s+BY\s+(.+?)(?=\s*(?:HAVING|ORDER|LIMIT|OFFSET|$))//si) {
        @gb = map { my $x = $_; $x =~ s/^\s+|\s+$//g; $x } split /\s*,\s*/, $1;
    }
    my $where = '';
    $rest =~ /(?:^|\s*)WHERE\s+(.+)/si and ($where = $1) =~ s/^\s+|\s+$//g;
    my @cs = parse_col_list($col_str);
    return [ $distinct, [ @cs ], $tbl, $where, [ @gb ], $having, [ @ob ], $limit, $offset ];
}

sub split_at_from {
    my($str) = @_;
    my $d    = 0;
    my $in_q = 0;
    my $len  = length($str);
    for my $i (0 .. $len-1) {
        my $ch = substr($str, $i, 1);
        if (($ch eq "'") && !$in_q) {
            $in_q = 1;
        }
        elsif (($ch eq "'") && $in_q) {
            $in_q = 0;
        }
        elsif (!$in_q && ($ch eq '(')) {
            $d++;
        }
        elsif (!$in_q && ($ch eq ')')) {
            $d--;
        }
        elsif (!$in_q
            && ($d == 0)
            && (uc(substr($str, $i, 4)) eq 'FROM')
            && (($i == 0) || (substr($str, $i-1, 1) =~ /\s/))
            && (($i+4 >= $len) || (substr($str, $i+4, 1) =~ /\s/))
        ) {
            return (substr($str, 0, $i), substr($str, $i));
        }
    }
    return (undef, undef);
}

sub parse_col_list {
    my($cs) = @_;
    $cs =~ s/^\s+|\s+$//g;
    return([ '*', '*' ]) if $cs eq '*';
    my @specs;
    for my $c (args($cs)) {
        $c =~ s/^\s+|\s+$//g;
        my($expr, $alias);
        if ($c =~ /^(.+?)\s+AS\s+(\w+)\s*$/si) {
            ($expr, $alias) = ($1, $2);
            $expr =~ s/^\s+|\s+$//g;
        }
        else {
            $expr  = $c;
            $alias = ($expr =~ /^(\w+)\.(\w+)$/?$2:$expr);
        }
        push @specs, [$expr, $alias];
    }
    return @specs;
}

# SQL-92 lets an ORDER BY key be written as a select-list position instead
# of a column name ("ORDER BY 2 DESC").  Rewrite every such item into the
# name of the column it refers to, so that the comparators further down see
# a name.  Left alone, a bare number was compared as a constant and the
# result came back unsorted with no error at all.
# @$col_specs is the parsed select list; $sch is the table schema, needed
# to resolve a position when the select list is "*".
# Returns '' on success, or an error message for an out-of-range position.
sub _resolve_order_ordinals {
    my($ob, $col_specs, $sch) = @_;
    return '' unless (ref($ob) eq 'ARRAY') && @$ob;
    my $wanted = 0;
    for my $o (@$ob) {
        $wanted = 1 if (ref($o) eq 'ARRAY') && defined($o->[0]) && ($o->[0] =~ /^\d+$/);
    }
    return '' unless $wanted;

    my @names;
    if (ref($col_specs) eq 'ARRAY') {
        if ((@$col_specs == 1) && (ref($col_specs->[0]) eq 'ARRAY')
            && ($col_specs->[0][0] eq '*')) {
            @names = map { $_->{name} } @{$sch->{cols}} if ref($sch) eq 'HASH';
        }
        else {
            @names = map { ref($_) eq 'ARRAY' ? $_->[1] : $_ } @$col_specs;
        }
    }
    for my $o (@$ob) {
        next unless (ref($o) eq 'ARRAY') && defined($o->[0]);
        next unless $o->[0] =~ /^\d+$/;
        my $n = $o->[0] + 0;
        unless (@names && ($n >= 1) && ($n <= scalar @names)) {
            return "ORDER BY position $o->[0] is not in the select list";
        }
        $o->[0] = $names[$n - 1];
    }
    return '';
}

# Scalar counterpart of _resolve_order_ordinals, for the JOIN, derived
# table and correlated subquery paths.  Those carry a single ORDER BY key
# rather than a list of them.  @$names is the output column list in SELECT
# order; when it is empty the position cannot be resolved (a "*" select
# list whose expansion is not known at this point) and the position is
# reported rather than quietly ignored.
# Returns (error_message, key); error_message is '' on success, and key is
# the original one when it was not a position.
sub _resolve_order_ordinal_scalar {
    my($ob, $names) = @_;
    return ('', $ob) unless defined($ob) && ($ob =~ /^\d+$/);
    my $n = $ob + 0;
    unless ((ref($names) eq 'ARRAY') && @$names && ($n >= 1) && ($n <= scalar @$names)) {
        return ("ORDER BY position $ob is not in the select list", $ob);
    }
    return ('', $names->[$n - 1]);
}

# Select-list item as the sort comparators see it before projection: the
# expression with any trailing "AS alias" removed.
sub _order_name_of {
    my($item) = @_;
    return '' unless defined $item;
    $item =~ s/^\s+|\s+$//g;
    $item =~ s/\s+AS\s+\w+\s*$//si;
    return $item;
}

# Select-list item as it is keyed after projection: the explicit alias,
# the bare column of a qualified name, or the expression itself.
sub _order_alias_of {
    my($item) = @_;
    return '' unless defined $item;
    $item =~ s/^\s+|\s+$//g;
    return $1 if $item =~ /\s+AS\s+(\w+)\s*$/si;
    return $2 if $item =~ /^(\w+)\.(\w+)$/;
    return $item;
}

sub project {
    my($self, $rows, $col_specs, $distinct, $ob, $limit, $offset) = @_;    my $star = ((@$col_specs == 1) && ($col_specs->[0][0] eq '*'));

    # ORDER BY must be evaluated against the original (unprojected) rows so that
    # columns not listed in SELECT (e.g. "SELECT name ... ORDER BY score") are
    # still accessible for sorting.
    my @sorted = @$rows;
    if (@$ob) {
        @sorted = sort {
            my($ra, $rb) = ($a, $b);
            for my $o (@$ob) {
                my($e, $dir) = @$o;
                my $va = do { my $vv = eval_expr($e, $ra); defined($vv) ? $vv : (defined($ra->{$e}) ? $ra->{$e} : '') };
                my $vb = do { my $vv = eval_expr($e, $rb); defined($vv) ? $vv : (defined($rb->{$e}) ? $rb->{$e} : '') };
                my $c = (($va =~ /^-?\d+\.?\d*$/) && ($vb =~ /^-?\d+\.?\d*$/)) ? ($va <=> $vb) : ($va cmp $vb);
                $c = -$c if lc($dir) eq 'desc';
                return $c if $c;
            }
            0
        } @sorted;
    }

    # Apply OFFSET / LIMIT on sorted raw rows before projection
    $offset = 0 unless defined $offset;
    @sorted = splice(@sorted, $offset) if $offset;
    if (defined $limit) {
        my $l   = $limit-1;
        $l      = $#sorted if $l>$#sorted;
        @sorted = @sorted[0 .. $l];
    }

    # Project to requested columns
    my @out;
    for my $row (@sorted) {
        if ($star) {
            push @out, { %$row };
        }
        else {
            my %p;
            $p{$_->[1]} = eval_expr($_->[0], $row) for @$col_specs;
            push @out, { %p };
        }
    }

    # DISTINCT (applied after projection so aliases are visible)
    if ($distinct) {
        my %s;
        my @d;
        for my $r (@out) {
            my $k = join("\x00", map{ defined($r->{$_}) ? $r->{$_} : "\x01" } sort keys %$r);
            push @d, $r unless $s{$k}++;
        }
        @out = @d;
    }
    return @out;
}

# =============================================================================
# GROUP BY / HAVING / aggregate functions
# =============================================================================
sub exec_groupby {
    my($self, $tbl, $col_specs, $where_expr, $gb, $having, $ob, $limit, $offset) = @_;
    my $sch = $self->_load_schema($tbl) or return{ type=>'error', message=>$errstr };
    my $obe = _resolve_order_ordinals($ob, $col_specs, $sch);
    return { type=>'error', message=>$obe } if $obe ne '';
    my $dat = $self->_file($tbl, 'dat');
    my $ws = ($where_expr ne '') ? where_sub($where_expr) : undef;
    my @raw;
    local *FH;
    open(FH, "< $dat") or return $self->_err("Cannot open dat: $!");
    binmode FH;
    _lock_sh(\*FH);
    my $rs = $sch->{recsize};
    while (1) {
        my $raw = '';
        my $n   = read(FH, $raw, $rs);
        last unless defined($n) && ($n == $rs);
        next if substr($raw, 0, 1) eq RECORD_DELETED;
        my $row = $self->_unpack_record($sch, $raw);
        push @raw, $row if !$ws || $ws->($row);
    }
    _unlock(\*FH);
    close FH;
    my @results = group_and_aggregate([ @raw ], $col_specs, $gb, $having);
    if (@$ob) {
        @results = sort {
            my($ra, $rb) = ($a, $b);
            for my $o (@$ob) {
                my($e, $dir) = @$o;
                my $va = do { my $vv = eval_expr($e, $ra); defined($vv) ? $vv : (defined($ra->{$e}) ? $ra->{$e} : '') };
                my $vb = do { my $vv = eval_expr($e, $rb); defined($vv) ? $vv : (defined($rb->{$e}) ? $rb->{$e} : '') };
                my $c = (($va =~ /^-?\d+\.?\d*$/) && ($vb =~ /^-?\d+\.?\d*$/)) ? ($va <=> $vb) : ($va cmp $vb);
                $c = -$c if lc($dir) eq 'desc';
                return $c if $c;
            }
            0
        } @results
    }
    $offset = 0 unless defined $offset;
    @results = splice(@results, $offset) if $offset;
    if (defined $limit) {
        my $l = $limit - 1;
        $l = $#results if $l>$#results;
        @results = @results[0..$l];
    }
    return{ type=>'rows', data=>[ @results ] };
}

# Group @$rows by the expressions in @$gb (an empty list means one group
# holding every row), evaluate @$col_specs for each group and drop the
# groups rejected by $having.  Returns the result rows.  The table-backed
# SELECT path and the derived-table path share this, which is why it takes
# rows rather than reading them itself.
sub group_and_aggregate {
    my($rows, $col_specs, $gb, $having) = @_;
    $gb     = []  unless defined $gb;
    $having = ''  unless defined $having;
    my %gr;
    my @go;
    if (@$gb) {
        for my $row (@$rows) {
            my $k = join("\x00", map { my $v = eval_expr($_, $row); defined($v) ? $v : '' } @$gb);
            push @go, $k unless exists $gr{$k};
            push @{$gr{$k}}, $row;
        }
    }
    else {
        @go          = ('__all__');
        $gr{__all__} = [ @$rows ];
    }
    my @results;
    for my $gk (@go) {
        my $grp = $gr{$gk};
        my $rep = defined($grp->[0]) ? $grp->[0] : {};
        my %out;
        $out{$_->[1]} = eval_agg($_->[0], $grp, $rep) for @$col_specs;
        if ($having ne '') {
            my $h   = $having;
            my $cnt = scalar @$grp;
            $h =~ s/COUNT\s*\(\s*\*\s*\)/$cnt/gsi;
            $h =~ s/\b(SUM|AVG|MIN|MAX|COUNT)\s*\(([^)]+)\)/eval_agg("$1($2)", $grp, $rep)/geis;
            next unless where_sub($h)->({ %out });
        }
        push @results, { %out };
    }
    return @results;
}

sub eval_agg {
    my($expr, $grp, $rep) = @_;
    return scalar @$grp if $expr =~ /^COUNT\s*\(\s*\*\s*\)$/si;
    if ($expr =~ /^COUNT\s*\(\s*DISTINCT\s+(.+)\s*\)$/si) {
        my $e = $1;
        my %s;
        for my $r (@$grp) {
            my $vv = eval_expr($e, $r);
            next unless defined($vv) && ($vv ne '');
            $s{$vv}++;
        }
        return scalar keys %s;
    }
    if ($expr =~ /^(COUNT|SUM|AVG|MIN|MAX)\s*\((.+)\)$/si) {
        my($fn, $inner) = (uc($1), $2);
        $inner =~ s/^\s+|\s+$//g;
        my @vals = grep { defined($_) && ($_ ne '') } map { eval_expr($inner, $_) } @$grp;
        return 0 unless @vals;
        return scalar @vals if $fn eq 'COUNT';
        if ($fn eq 'SUM') {
            my $s = 0;
            $s += $_ for @vals;
            return $s;
        }
        if ($fn eq 'AVG') {
            my $s = 0;
            $s += $_ for @vals;
            return $s / @vals;
        }
        if ($fn eq 'MIN') {
            return (sort { (($a =~ /^-?\d+\.?\d*$/) && ($b =~ /^-?\d+\.?\d*$/)) ? ($a<=>$b) : ($a cmp $b) } @vals)[0];
        }
        if ($fn eq 'MAX') {
            return (sort { (($a =~ /^-?\d+\.?\d*$/) && ($b =~ /^-?\d+\.?\d*$/)) ? ($b<=>$a) : ($b cmp $a) } @vals)[0];
        }
    }
    return eval_expr($expr, $rep);
}

# =============================================================================
# UNION / UNION ALL
# =============================================================================
sub split_union {
    my($sql) = @_;
    my @parts;
    my $cur  = '';
    my $d    = 0;
    my $in_q = 0;
    my $i    = 0;
    my $len  = length($sql);
    while ($i < $len) {
        my $ch = substr($sql, $i, 1);
        if (($ch eq "'") && !$in_q) {
            $in_q = 1;
            $cur .= $ch;
        }
        elsif (($ch eq "'") && $in_q) {
            $in_q = 0;
            $cur .= $ch;
        }
        elsif ($in_q) {
            $cur .= $ch;
        }
        elsif ($ch eq '(') {
            $d++;
            $cur .= $ch;
        }
        elsif ($ch eq ')') {
            $d--;
            $cur .= $ch;
        }
        elsif ($d == 0 && !$in_q
            && (($i == 0) || (substr($sql, $i-1, 1) =~ /\s/))) {
            # Detect UNION / INTERSECT / EXCEPT set operators
            my $kw   = '';
            my $klen = 0;
            if ((uc(substr($sql, $i, 5)) eq 'UNION')
                && ($i+5 < $len) && (substr($sql, $i+5, 1) =~ /[\s(]/)) {
                $kw = 'UNION'; $klen = 5;
            }
            elsif ((uc(substr($sql, $i, 9)) eq 'INTERSECT')
                && ($i+9 < $len) && (substr($sql, $i+9, 1) =~ /[\s(]/)) {
                $kw = 'INTERSECT'; $klen = 9;
            }
            elsif ((uc(substr($sql, $i, 6)) eq 'EXCEPT')
                && ($i+6 < $len) && (substr($sql, $i+6, 1) =~ /[\s(]/)) {
                $kw = 'EXCEPT'; $klen = 6;
            }
            if ($klen) {
                push @parts, $cur;
                $cur  = '';
                $i   += $klen;
                while (($i < $len) && (substr($sql, $i, 1) =~ /\s/)) { $i++ }
                # UNION ALL / INTERSECT ALL / EXCEPT ALL
                if (($kw eq 'UNION')
                    && ($i+3 <= $len) && (uc(substr($sql, $i, 3)) eq 'ALL')
                    && (($i+3 >= $len) || (substr($sql, $i+3, 1) =~ /\s/))) {
                    push @parts, 'UNION_ALL';
                    $i += 3;
                    while (($i < $len) && (substr($sql, $i, 1) =~ /\s/)) { $i++ }
                }
                elsif (($kw eq 'INTERSECT')
                    && ($i+3 <= $len) && (uc(substr($sql, $i, 3)) eq 'ALL')
                    && (($i+3 >= $len) || (substr($sql, $i+3, 1) =~ /\s/))) {
                    push @parts, 'INTERSECT_ALL';
                    $i += 3;
                    while (($i < $len) && (substr($sql, $i, 1) =~ /\s/)) { $i++ }
                }
                elsif (($kw eq 'EXCEPT')
                    && ($i+3 <= $len) && (uc(substr($sql, $i, 3)) eq 'ALL')
                    && (($i+3 >= $len) || (substr($sql, $i+3, 1) =~ /\s/))) {
                    push @parts, 'EXCEPT_ALL';
                    $i += 3;
                    while (($i < $len) && (substr($sql, $i, 1) =~ /\s/)) { $i++ }
                }
                else {
                    push @parts, $kw;   # bare UNION / INTERSECT / EXCEPT
                }
                next;
            }
            else {
                $cur .= $ch;
            }
        }
        else {
            $cur .= $ch;
        }
        $i++;
    }
    push @parts, $cur if $cur =~ /\S/;
    return @parts;
}

# Column order of one branch of a set operation, as a list of result-row
# hash keys in select-list order.
sub _branch_col_order {
    my($self, $sql, $data) = @_;
    return [ DB::Handy::Statement::_col_order_from_sql(undef, $sql, $data, $self) ];
}

sub exec_union {
    my($self, $parts) = @_;
    my @p     = @$parts;
    my $first = shift @p;
    my $r0    = $self->execute($first);
    return $r0 if $r0->{type} eq 'error';
    my @rows  = @{$r0->{data}};

    # A result row is a hash keyed by column name, and SQL lines the branches
    # of a set operation up by *position*, taking the result column names from
    # the first branch.  Until 1.09 the branches were merged as they came, so
    # "SELECT x FROM a UNION ALL SELECT p FROM b" produced rows keyed 'p' for
    # the second branch; every value read under the name 'x' was then NULL.
    # The column order of each later branch is therefore mapped onto the
    # first branch's names before the rows are combined.
    my $base = $self->_branch_col_order($first, \@rows);

    while (@p >= 2) {
        my $sep = shift @p;
        my $q   = shift @p;
        my $r   = $self->execute($q);
        return $r if $r->{type} eq 'error';
        my @rhs = @{$r->{data}};
        my $rord = $self->_branch_col_order($q, \@rhs);
        if (@$base && @$rord) {
            if (@$base != @$rord) {
                return { type=>'error', message=>
                    "Each SELECT of a set operation must return the same "
                    . "number of columns (" . scalar(@$base) . " and "
                    . scalar(@$rord) . ")" };
            }
            if (join("\x00", @$base) ne join("\x00", @$rord)) {
                my @mapped;
                for my $row (@rhs) {
                    my %n;
                    for my $i (0 .. $#$base) {
                        $n{ $base->[$i] } = $row->{ $rord->[$i] };
                    }
                    push @mapped, { %n };
                }
                @rhs = @mapped;
            }
        }
        # Build a key string for each row for set operations
        my $_key = sub {
            my($row) = @_;
            join("\x00", map { defined($row->{$_}) ? $row->{$_} : "\x01" } sort keys %$row);
        };
        if ($sep eq 'UNION' || $sep eq '') {
            # UNION: combine then deduplicate
            push @rows, @rhs;
            my %s; my @d;
            for my $row (@rows) {
                push @d, $row unless $s{$_key->($row)}++;
            }
            @rows = @d;
        }
        elsif ($sep eq 'UNION_ALL') {
            # UNION ALL: combine without deduplication
            push @rows, @rhs;
        }
        elsif ($sep eq 'INTERSECT') {
            # INTERSECT: keep only rows present in both (deduplicated)
            my %in_rhs;
            for my $row (@rhs) { $in_rhs{$_key->($row)} = 1 }
            my %seen; my @d;
            for my $row (@rows) {
                my $k = $_key->($row);
                push @d, $row if $in_rhs{$k} && !$seen{$k}++;
            }
            @rows = @d;
        }
        elsif ($sep eq 'INTERSECT_ALL') {
            # INTERSECT ALL: keep rows present in both (with multiplicity)
            my %rhs_cnt;
            for my $row (@rhs) { $rhs_cnt{$_key->($row)}++ }
            my %used; my @d;
            for my $row (@rows) {
                my $k = $_key->($row);
                if (($rhs_cnt{$k} || 0) > ($used{$k} || 0)) {
                    push @d, $row;
                    $used{$k}++;
                }
            }
            @rows = @d;
        }
        elsif ($sep eq 'EXCEPT') {
            # EXCEPT: remove rows that appear in rhs (deduplicated)
            my %in_rhs;
            for my $row (@rhs) { $in_rhs{$_key->($row)} = 1 }
            my %seen; my @d;
            for my $row (@rows) {
                my $k = $_key->($row);
                push @d, $row if !$in_rhs{$k} && !$seen{$k}++;
            }
            @rows = @d;
        }
        elsif ($sep eq 'EXCEPT_ALL') {
            # EXCEPT ALL: remove rows with multiplicity
            my %rhs_cnt;
            for my $row (@rhs) { $rhs_cnt{$_key->($row)}++ }
            my %removed; my @d;
            for my $row (@rows) {
                my $k = $_key->($row);
                if (($rhs_cnt{$k} || 0) > ($removed{$k} || 0)) {
                    $removed{$k}++;
                }
                else {
                    push @d, $row;
                }
            }
            @rows = @d;
        }
    }
    return { type=>'rows', data=>[ @rows ] };
}

# =============================================================================
# UPDATE with expression SET
# =============================================================================
sub parse_set_exprs {
    my($str) = @_;
    my %set;
    for my $part (args($str)) {
        $part =~ s/^\s+|\s+$//g;
        $set{$1} = $2 if $part =~ /^(\w+)\s*=\s*(.+)$/s;
    }
    return %set;
}

sub update {
    my($self, $table, $set_exprs, $ws) = @_;
    return $self->_err("No database selected") unless $self->{db_name};
    my $sch = $self->_load_schema($table) or return undef;
    my $dat = $self->_file($table, 'dat');
    my $rs  = $sch->{recsize};
    my $n   = 0;
    local *FH;
    open(FH, "+< $dat") or return $self->_err("Cannot open dat: $!");
    binmode FH;
    _autoflush(\*FH);
    _lock_ex(\*FH);
    seek(FH, 0, 0);
    my $pos = 0;
    my $rno = 0;
    while (1) {
        seek(FH, $pos, 0);
        my $raw = '';
        my $x   = read(FH, $raw, $rs);
        last unless defined($x) && ($x == $rs);
        if (substr($raw, 0, 1) ne RECORD_DELETED) {
            my $row = $self->_unpack_record($sch, $raw);
            if (!$ws || $ws->($row)) {
                my %old;
                for my $ix (values %{$sch->{indexes}}) {
                    $old{$ix->{name}} = $row->{$ix->{col}}
                }
                my %orig = %$row;
                $row->{$_} = eval_expr($set_exprs->{$_}, { %orig }) for keys %$set_exprs;
                for my $ix (values %{$sch->{indexes}}) {
                    next unless $ix->{unique} && exists $set_exprs->{$ix->{col}};
                    my $nv = $row->{$ix->{col}};
                    next unless defined($nv) && ($nv ne '');
                    my $ep = $self->_idx_lookup_exact($table, $ix, $nv);
                    if ($ep >= 0) {
                        my $ef = $self->_idx_file($table, $ix->{name});
                        my $es = $ix->{keysize} + REC_NO_SIZE;
                        local *IF_FH;
                        open(IF_FH, "< $ef") or next;
                        binmode IF_FH;
                        seek(IF_FH, IDX_MAGIC_LEN + $ep * $es + $ix->{keysize}, 0);
                        my $rn = '';
                        read(IF_FH, $rn, REC_NO_SIZE);
                        close IF_FH;
                        if (unpack('N', $rn) != $rno) {
                            _unlock(\*FH);
                            close FH;
                            return $self->_err("UNIQUE constraint violated on '$ix->{name}'");
                        }
                    }
                }

                # NOT NULL constraint check on UPDATE
                for my $cn (keys %{$sch->{notnull} || {}}) {
                    next unless exists $set_exprs->{$cn};
                    unless (defined($row->{$cn}) && ($row->{$cn} ne '')) {
                        _unlock(\*FH);
                        close FH;
                        return $self->_err("NOT NULL constraint violated on column '$cn'");
                    }
                }
                # CHECK constraint check on UPDATE
                for my $cn (keys %{$sch->{checks} || {}}) {
                    next unless exists $set_exprs->{$cn};
                    next unless defined($row->{$cn}) && ($row->{$cn} ne '');
                    unless (eval_bool($sch->{checks}{$cn}, $row)) {
                        _unlock(\*FH);
                        close FH;
                        return $self->_err("CHECK constraint failed on column '$cn'");
                    }
                }
                # VARCHAR / CHAR length check on UPDATE
                for my $col (@{$sch->{cols}}) {
                    my $cn = $col->{name};
                    next unless ($col->{type} eq 'VARCHAR' || $col->{type} eq 'CHAR');
                    next unless exists $set_exprs->{$cn};
                    my $decl = defined($col->{decl}) ? $col->{decl} : $col->{size};
                    next unless defined($decl) && ($decl < MAX_VARCHAR);
                    next unless defined($row->{$cn}) && ($row->{$cn} ne '');
                    if (length($row->{$cn}) > $decl) {
                        _unlock(\*FH);
                        close FH;
                        return $self->_err(
                            "Value too long for column '$cn': "
                            . "declared $col->{type}($decl), got "
                            . length($row->{$cn}) . " bytes"
                        );
                    }
                }
                # Type check on UPDATE: INT range and DATE validity.
                for my $col (@{$sch->{cols}}) {
                    next unless exists $set_exprs->{$col->{name}};
                    my $msg = _type_error($col, $row->{$col->{name}});
                    next unless defined $msg;
                    _unlock(\*FH);
                    close FH;
                    return $self->_err($msg);
                }
                my $p = $self->_pack_record($sch, $row);
                seek(FH, $pos, 0);
                unless (print FH $p) {
                    my $e = $!;
                    _unlock(\*FH);
                    close FH;
                    return $self->_err("Cannot write record: $e");
                }
                $n++;
                for my $ix (values %{$sch->{indexes}}) {
                    next unless exists $set_exprs->{$ix->{col}};
                    $self->_idx_delete($table, $ix, $old{$ix->{name}}, $rno);
                    $self->_idx_insert($table, $ix, $row->{$ix->{col}}, $rno);
                }
            }
        }
        $pos += $rs;
        $rno++;
    }
    _unlock(\*FH);
    unless (close FH) {
        return $self->_err("Cannot flush dat: $!");
    }
    return $n;
}

###############################################################################
# DBI-like API  --  DB::Handy::Connection / DB::Handy::Statement
#
# A standalone implementation with a DBI-inspired interface.
#
# Usage:
#   my $dbh = DB::Handy->connect("./data", "mydb");
#   my $sth = $dbh->prepare("SELECT * FROM emp WHERE id = ?");
#   $sth->execute(1);
#   while (my $row = $sth->fetchrow_hashref) { ... }
#   $sth->finish;
#   $dbh->disconnect;
###############################################################################

###############################################################################
# DB::Handy::Connection  -- database connection handle (like $dbh)
###############################################################################
package DB::Handy::Connection;
use vars qw($VERSION);
$VERSION = '1.09';   # keep in step with $DB::Handy::VERSION (literal so
$VERSION = $VERSION; # that PAUSE and Module::Metadata can parse it)

use vars qw($errstr);
$errstr = '';

# new($base_dir, $database, \%opts)
sub new {
    my($class, $base_dir, $database, $opts) = @_;
    $opts = {} unless ref($opts) eq 'HASH';

    # DBI code often opens a transaction by connecting with AutoCommit => 0.
    # There are no transactions here, so accepting that silently would leave
    # the caller believing its writes were being batched.
    if (exists($opts->{AutoCommit}) && !$opts->{AutoCommit}) {
        $errstr = "AutoCommit cannot be turned off: DB::Handy has no transactions";
        if ($opts->{RaiseError}) {
            die "DB::Handy connect failed: $errstr\n";
        }
        warn "DB::Handy: $errstr\n" if $opts->{PrintError};
        return undef;
    }
    my $engine = DB::Handy->new(base_dir => $base_dir);
    unless (defined $engine) {
        $errstr = $DB::Handy::errstr;
        if ($opts->{RaiseError}) {
            die "DB::Handy connect failed: $errstr\n";
        }
        return undef;
    }
    my $self = {
        _engine    => $engine,
        _database  => $database || '',
        AutoCommit => 1,
        RaiseError => $opts->{RaiseError} || 0,
        PrintError => (defined($opts->{PrintError}) ? $opts->{PrintError} : 0),
        errstr     => '',
        err        => 0,
    };
    bless $self, $class;
    if ($database && (!defined($opts->{AutoUse}) || $opts->{AutoUse})) {
        my $res = $engine->execute("USE $database");
        if ($res->{type} eq 'error') {
            $engine->execute("CREATE DATABASE $database");
            $res = $engine->execute("USE $database");
        }
        if ($res->{type} eq 'error') {
            $self->_set_err($DB::Handy::errstr || $res->{message});
            return undef;
        }
    }
    return $self;
}

# connect($dsn_or_dir, $database, \%opts)
# Also accepts DSN string: "base_dir=./data;database=mydb"
sub connect {
    my($class, $dsn, $database, $opts) = @_;
    my $base_dir;
    if (defined($dsn)) {
        # Strip optional dbi:Handy: prefix for DBI-style DSN
        $dsn =~ s/^dbi\s*:\s*Handy\s*:\s*//i;
    }
    if (defined($dsn) && ($dsn =~ /[=;]/)) {
        my %p = map { split /=/, $_, 2 } split /;/, $dsn;
        $base_dir = $p{base_dir} || $p{dir} || '.';
        $database = $p{database} || $p{db}  || $database;
    }
    else {
        $base_dir = defined($dsn) ? $dsn : '.';
    }
    $opts = {} unless ref($opts) eq 'HASH';
    return DB::Handy::Connection->new($base_dir, $database, $opts);
}

# do($sql, @bind) -- shortcut for prepare+execute (useful for DDL/DML)
sub do {
    my($self, $sql, @bind) = @_;
    my $sth = $self->prepare($sql) or return undef;
    return $sth->execute(@bind);
}

# prepare($sql) -- returns a statement handle
sub prepare {
    my($self, $sql) = @_;
    $self->_clear_err;
    unless (defined($sql) && ($sql =~ /\S/)) {
        $self->_set_err("prepare: empty SQL");
        return undef;
    }
    return DB::Handy::Statement->new($self, $sql);
}

# selectall_arrayref($sql, \%attr, @bind)
# attr: Slice=>{} for array of hashrefs, Slice=>[] (default) for array of arrayrefs
sub selectall_arrayref {
    my($self, $sql, $attr, @bind) = @_;
    $attr = {} unless ref($attr) eq 'HASH';
    my $sth = $self->prepare($sql) or return undef;
    $sth->execute(@bind) or return undef;
    return $sth->fetchall_arrayref($attr->{Slice});
}

# selectall_hashref($sql, $key_col, \%attr, @bind)
sub selectall_hashref {
    my($self, $sql, $key_col, $attr, @bind) = @_;
    my $rows = $self->selectall_arrayref($sql, {Slice=>{}}, @bind) or return undef;
    my %h;
    for my $row (@$rows) {
        $h{$row->{$key_col}} = $row;
    }
    return { %h };
}

# selectrow_hashref($sql, \%attr, @bind)
sub selectrow_hashref {
    my($self, $sql, $attr, @bind) = @_;
    my $sth = $self->prepare($sql) or return undef;
    $sth->execute(@bind) or return undef;
    my $row = $sth->fetchrow_hashref;
    $sth->finish;
    return $row;
}

# selectrow_arrayref($sql, \%attr, @bind)
sub selectrow_arrayref {
    my($self, $sql, $attr, @bind) = @_;
    my $sth = $self->prepare($sql) or return undef;
    $sth->execute(@bind) or return undef;
    my $row = $sth->fetchrow_arrayref;
    $sth->finish;
    return $row;
}

# quote($val) -- escape a value as a SQL single-quoted literal
sub quote {
    my($self, $val) = @_;
    return 'NULL' unless defined $val;
    $val =~ s/'/''/g;
    return "'$val'";
}

# last_insert_id() -- row count recorded by the most recent INSERT
# last_insert_id($catalog, $schema, $table, $field)
# Arguments are accepted for DBI compatibility but ignored.
sub last_insert_id { return $_[0]->{_last_insert_id} }

# table_info() -- list of tables [{TABLE_NAME=>...}, ...]
sub table_info {
    my($self) = @_;
    my @tables = $self->{_engine}->list_tables();
    return [ map { {TABLE_NAME=>$_, TABLE_TYPE=>'TABLE'} } @tables ];
}

# column_info($table) -- column metadata [{COLUMN_NAME=>..., DATA_TYPE=>...}, ...]
sub column_info {
    my($self, $table) = @_;
    my $cols          = $self->{_engine}->describe_table($table) or return undef;
    my $i             = 0;
    return [ map { {
        COLUMN_NAME      => $_->{name},
        DATA_TYPE        => $_->{type},
        ORDINAL_POSITION => ++$i,
        IS_NULLABLE      => ($_->{not_null} ? 'NO' : 'YES'),
        COLUMN_DEF       => $_->{default},
    } } @$cols ];
}

# disconnect()
sub disconnect {
    my($self) = @_;
    $self->{_disconnected} = 1;
    return 1;
}

# ping() -- returns 1 if connection is active
sub ping { return $_[0]->{_disconnected} ? 0 : 1 }

# AutoCommit -- always on; transactions are not supported
sub AutoCommit { return 1 }

# begin_work / commit / rollback
# Transactions are not supported.  These methods set errstr and return
# undef rather than crashing, consistent with DBI error-handling style.
sub begin_work {
    my($self) = @_;
    $self->_set_err(
        "Transactions are not supported: DB::Handy always operates in "
        . "AutoCommit mode.  begin_work/commit/rollback are not available."
    );
    return undef;
}
sub commit {
    my($self) = @_;
    $self->_set_err(
        "Transactions are not supported: DB::Handy always operates in "
        . "AutoCommit mode.  begin_work/commit/rollback are not available."
    );
    return undef;
}
sub rollback {
    my($self) = @_;
    $self->_set_err(
        "Transactions are not supported: DB::Handy always operates in "
        . "AutoCommit mode.  begin_work/commit/rollback are not available."
    );
    return undef;
}

# errstr / err accessors
sub errstr { return $_[0]->{errstr} }
sub err    { return $_[0]->{err}    }

# _clear_err() -- DBI resets err/errstr at the start of every method that
# talks to the database, so that a stale message from an earlier failure
# is never mistaken for the outcome of the call that just succeeded.
sub _clear_err {
    my($self) = @_;
    $self->{errstr} = '';
    $self->{err}    = 0;
    return;
}

sub _set_err {
    my($self, $msg, $code) = @_;
    $code = 1 unless defined $code;
    $self->{errstr} = $msg;
    $self->{err}    = $code;
    $errstr         = $msg;
    if ($self->{PrintError}) {
        warn "DB::Handy: $msg\n";
    }
    if ($self->{RaiseError}) {
        die "DB::Handy: $msg\n";
    }
}

###############################################################################
# DB::Handy::Statement  -- statement handle (like $sth)
###############################################################################
package DB::Handy::Statement;
use vars qw($VERSION);
$VERSION = '1.09';   # keep in step with $DB::Handy::VERSION (literal so
$VERSION = $VERSION; # that PAUSE and Module::Metadata can parse it)

use vars qw($errstr);
$errstr = '';

sub new {
    my($class, $dbh, $sql) = @_;
    my $self = {
        _dbh          => $dbh,
        _sql          => $sql,
        _rows         => undef,
        _cursor       => 0,
        _executed     => 0,
        _bind_params  => [],
        rows          => 0,
        errstr        => '',
        err           => 0,
        NAME          => [],
        NAME_lc       => [],
        NAME_uc       => [],
        NUM_OF_FIELDS => 0,
        NUM_OF_PARAMS => _count_placeholders($sql),
        Statement     => $sql,
    };
    bless $self, $class;
    return $self;
}

# Number of ? placeholders, ignoring any that sit inside a string literal
# or a comment.  This is the same count execute() will consume.
sub _count_placeholders {
    my($sql) = @_;
    my $n = 0;
    for my $part (DB::Handy::_split_sql_literals(DB::Handy::_strip_sql_comments($sql))) {
        next if $part->[0];
        $n += ($part->[1] =~ tr/?//);
    }
    return $n;
}

# execute(@bind_values) -- substitute ? placeholders and run the statement
sub execute {
    my($self, @bind) = @_;
    $self->_clear_err;

    # merge values pre-set via bind_param()
    if (!@bind && @{$self->{_bind_params}}) {
        @bind = @{$self->{_bind_params}};
    }

    # DBI refuses a bind list whose length does not match the number of
    # placeholders.  Without this check a missing value left a bare "?"
    # in the statement -- which then matched nothing -- and a surplus
    # value was dropped, so either mistake produced a silently wrong
    # result instead of an error.
    my $got  = scalar @bind;
    my $need = $self->{NUM_OF_PARAMS};
    if ($got != $need) {
        $self->_set_err(
            "called with $got bind variable" . (($got  == 1) ? '' : 's')
            . " when $need "                 . (($need == 1) ? 'is' : 'are')
            . " needed"
        );
        return undef;
    }

    # Comments are removed first so that a ? inside one is not mistaken
    # for a placeholder; a ? inside a string literal is left alone too.
    my $sql = DB::Handy::_strip_sql_comments($self->{_sql});

    # substitute ? placeholders with actual values
    if (@bind) {
        my @params = @bind;
        my $out    = '';
        for my $part (DB::Handy::_split_sql_literals($sql)) {
            if ($part->[0]) { $out .= $part->[1]; next }
            my $chunk = $part->[1];
            $chunk =~ s/\?/_dbi_quote(shift @params)/ge;
            $out .= $chunk;
        }
        $sql = $out;
    }

    my $engine = $self->{_dbh}{_engine};
    my $res    = $engine->execute($sql);

    $self->{_result}   = $res;
    $self->{_executed} = 1;

    if ($res->{type} eq 'error') {
        $self->_set_err($res->{message});
        return undef;
    }

    if ($res->{type} eq 'rows') {
        my $data         = $res->{data};
        $self->{_rows}   = $data;
        $self->{_cursor} = 0;
        my $n            = scalar @$data;
        $self->{rows}    = $n;
        # Determine column order: prefer SELECT list order; for SELECT *
        # use schema declaration order; fall back to alphabetical.
        my @name_order = $self->_col_order_from_sql($sql, $data, $engine);
        $self->{NAME}          = [ @name_order ];
        $self->{NAME_lc}       = [ map { lc $_ } @name_order ];
        $self->{NAME_uc}       = [ map { uc $_ } @name_order ];
        $self->{NUM_OF_FIELDS} = scalar @name_order;
        return $n || '0E0';
    }

    # INSERT / UPDATE / DELETE / DDL
    if ($res->{type} eq 'ok') {
        my $affected = 0;
        if (defined($res->{message}) && ($res->{message} =~ /(\d+)\s+row/)) {
            $affected = $1 + 0;
        }
        $self->{rows}          = $affected;
        $self->{_rows}         = undef;
        $self->{NAME}          = [];
        $self->{NAME_lc}       = [];
        $self->{NAME_uc}       = [];
        $self->{NUM_OF_FIELDS} = 0;
        if ($sql =~ /^\s*INSERT\b/i) {
            $self->{_dbh}{_last_insert_id} = $affected;
        }
        return $affected || '0E0';
    }

    # SHOW / DESCRIBE and other statement types
    if (ref($res->{data}) eq 'ARRAY') {
        $self->{_rows}   = $res->{data};
        $self->{_cursor} = 0;
        $self->{rows}    = scalar @{$res->{data}};
    }
    return '0E0';
}

# _col_order_from_sql($sql, $data, $engine)
#
# Return column names in the order they should be presented to the caller.
#
# For named SELECT lists (SELECT a, b, c) the order follows the SELECT list,
# including AS aliases (already handled since 1.01).
#
# For SELECT * on a single table the order follows the CREATE TABLE column
# declaration order, obtained from the schema.
#
# For SELECT * on a JOIN the order follows the table appearance order in
# the FROM/JOIN clause, each table's columns in declaration order, returned
# as 'alias.col' qualified names matching the result-row hash keys.
#
# Falls back to alphabetical (sorted keys of the first data row) when the
# schema cannot be resolved or the SQL cannot be parsed.
#
sub _col_order_from_sql {
    my($self, $sql, $data, $engine) = @_;
    # Fallback: alphabetical from first row (or empty)
    my @fallback = ($data && @$data) ? sort keys %{$data->[0]} : ();
    return @fallback unless defined $sql;
    # Strip leading SELECT keyword
    my $col_str;
    if ($sql =~ /^SELECT\s+(.*?)\s+FROM\b/si) {
        $col_str = $1;
    }
    else {
        return @fallback;
    }
    $col_str =~ s/^DISTINCT\s+//si;
    # SELECT * (or alias.*): try to use schema declaration order
    if ($col_str =~ /^\*$/ || $col_str =~ /^\w+\.\*$/) {
        return @fallback unless defined $engine;
        # Parse FROM clause to get table name and optional alias
        if ($sql =~ /\bFROM\s+(\w+)(?:\s+(?:AS\s+)?(\w+))?\s*(?:WHERE|ORDER|GROUP|LIMIT|OFFSET|$)/si
            && $sql !~ /\bJOIN\b/i) {
            my($tbl, $alias) = ($1, $2);
            my $sch = $engine->_load_schema($tbl);
            return @fallback unless $sch;
            my @names = map { $_->{name} } @{$sch->{cols}};
            # Verify names match result keys
            if (@$data) {
                my %keys = map { $_ => 1 } keys %{$data->[0]};
                return @fallback if grep { !$keys{$_} } @names;
            }
            return @names;
        }
        # JOIN: collect tables in FROM/JOIN order, build alias.col names
        if ($sql =~ /\bJOIN\b/i) {
            return @fallback unless defined $engine;
            my @table_aliases;
            # Extract first table from FROM
            if ($sql =~ /\bFROM\s+(\w+)(?:\s+(?:AS\s+)?(\w+))?/si) {
                push @table_aliases, [ $1, (defined $2 ? $2 : $1) ];
            }
            # Extract subsequent JOIN tables
            my $rest = $sql;
            while ($rest =~ /\bJOIN\s+(\w+)(?:\s+(?:AS\s+)?(\w+))?/gsi) {
                push @table_aliases, [ $1, (defined $2 ? $2 : $1) ];
            }
            my @names;
            for my $ta (@table_aliases) {
                my($tbl, $alias) = @$ta;
                my $sch = $engine->_load_schema($tbl);
                next unless $sch;
                for my $col (@{$sch->{cols}}) {
                    push @names, "$alias.$col->{name}";
                }
            }
            if (@names) {
                # Verify names match result keys
                if (@$data) {
                    my %keys = map { $_ => 1 } keys %{$data->[0]};
                    return @fallback if grep { !$keys{$_} } @names;
                }
                return @names;
            }
            return @fallback;
        }
        return @fallback;
    }
    # Split on commas (not inside parentheses)
    my @parts;
    my($cur, $depth) = ('', 0);
    for my $ch (split //, $col_str) {
        if    ($ch eq '(') { $depth++; $cur .= $ch }
        elsif ($ch eq ')') { $depth--; $cur .= $ch }
        elsif ($ch eq ',' && $depth == 0) { push @parts, $cur; $cur = '' }
        else  { $cur .= $ch }
    }
    push @parts, $cur if length $cur;
    my(@names, @alt);
    for my $part (@parts) {
        $part =~ s/^\s+|\s+$//g;
        # explicit alias:  expr AS alias
        if ($part =~ /\bAS\s+(\w+)\s*$/si) {
            push @names, $1;
            push @alt,   undef;
        }
        # qualified alias.col -> keep as 'alias.col' (JOIN result key format)
        elsif ($part =~ /^(\w+)\.(\w+)$/) {
            push @names, "$1.$2";

            # An aggregate query over a JOIN keys its output rows by the bare
            # column name, so 'a.y' has to be able to resolve to 'y'.  Without
            # this the whole list was rejected below and the alphabetical
            # fallback took over, which put the columns of
            # "SELECT a.y, COUNT(*) ... GROUP BY a.y" in the order
            # COUNT(*), y.
            push @alt, $2;
        }
        # bare column name
        elsif ($part =~ /^(\w+)$/) {
            push @names, $1;
            push @alt,   undef;
        }
        # complex expression without alias -> use the expression text as key
        else {
            push @names, $part;
            push @alt,   undef;
        }
    }
    # Verify that every parsed name exists as a key in the result
    # (guards against mis-parses; also handles 0-row results)
    if (@$data) {
        my %keys = map { $_ => 1 } keys %{$data->[0]};
        for my $i (0 .. $#names) {
            next if $keys{$names[$i]};
            if (defined($alt[$i]) && $keys{$alt[$i]}) {
                $names[$i] = $alt[$i];
                next;
            }
            return @fallback;
        }
    }
    return @names;
}

# fetchrow_hashref -- return next row as hashref (undef at EOF)
sub fetchrow_hashref {
    my($self) = @_;
    return undef unless defined $self->{_rows};
    return undef if $self->{_cursor} >= scalar @{$self->{_rows}};
    my $row = $self->{_rows}[ $self->{_cursor}++ ];
    return { %$row };
}

# fetchrow_arrayref -- return next row as arrayref (columns in NAME order)
sub fetchrow_arrayref {
    my($self) = @_;
    my $href = $self->fetchrow_hashref or return undef;
    my @cols = @{$self->{NAME}} ? @{$self->{NAME}} : sort keys %$href;
    return [ map { $href->{$_} } @cols ];
}

# fetchrow_array -- return next row as a list
sub fetchrow_array {
    my($self) = @_;
    my $aref = $self->fetchrow_arrayref or return ();
    return @$aref;
}

# fetch -- alias for fetchrow_arrayref
sub fetch { return $_[0]->fetchrow_arrayref }

# fetchall_arrayref([$slice])
#   $slice = {}  -> [{col=>val,...}, ...]
#   $slice = []  -> [[val,...], ...]  (default)
sub fetchall_arrayref {
    my($self, $slice) = @_;
    return undef unless defined $self->{_rows};
    my @all;
    if (ref($slice) eq 'HASH') {
        while (my $row = $self->fetchrow_hashref) {
            push @all, $row;
        }
    }
    else {
        while (my $row = $self->fetchrow_arrayref) {
            push @all, $row;
        }
    }
    return [ @all ];
}

# fetchall_hashref($key_col) -- return rows as a hashref keyed by $key_col
sub fetchall_hashref {
    my($self, $key_col) = @_;
    my %h;
    while (my $row = $self->fetchrow_hashref) {
        $h{$row->{$key_col}} = $row;
    }
    return { %h };
}

# bind_param($pos, $val [, $attr]) -- pre-bind a placeholder by position
sub bind_param {
    my($self, $pos, $val, $attr) = @_;
    $self->{_bind_params}[$pos - 1] = $val;
    return 1;
}

# finish -- reset cursor and release resources
sub finish {
    my($self) = @_;
    $self->{_rows}        = undef;
    $self->{_cursor}      = 0;
    $self->{_bind_params} = [];
    return 1;
}

# rows -- number of rows affected or fetched by the last execute
sub rows { return $_[0]->{rows} }

# errstr / err accessors
sub errstr { return $_[0]->{errstr} }
sub err    { return $_[0]->{err}    }

sub _clear_err {
    my($self) = @_;
    $self->{errstr} = '';
    $self->{err}    = 0;
    my $dbh = $self->{_dbh};
    $dbh->_clear_err if ref($dbh);
    return;
}

sub _set_err {
    my($self, $msg, $code) = @_;
    $code = 1 unless defined $code;
    $self->{errstr} = $msg;
    $self->{err}    = $code;
    $errstr         = $msg;
    my $dbh = $self->{_dbh};
    $dbh->_set_err($msg, $code) if ref($dbh);
}

# _dbi_quote($val) -- internal helper for ? placeholder substitution
sub _dbi_quote {
    my($val) = @_;
    return 'NULL' unless defined $val;
    return $val if $val =~ /^-?\d+\.?\d*$/; # numeric: pass through as-is
    $val =~ s/'/''/g;
    return "'$val'";
}

###############################################################################
# Add connect() class method to DB::Handy
###############################################################################
package DB::Handy;

sub connect {
    my($class, $dsn, $database, $opts) = @_;
    return DB::Handy::Connection->connect($dsn, $database, $opts);
}

1;

__END__

=encoding utf-8

=head1 NAME

DB::Handy - Pure-Perl flat-file relational database with DBI-like interface

=head1 VERSION

Version 1.09

=head1 SYNOPSIS

  use DB::Handy;

  # -------------------------------------------------------
  # DBI-like interface (recommended)
  # -------------------------------------------------------

  # 1. Connect to the database (Creates directory and DB if not exists)
  # Note: Uses DB::Handy->connect instead of DBI->connect
  my $dbh = DB::Handy->connect('./mydata', 'mydb', {
      RaiseError => 1,
      PrintError => 0,
  });

  # 2. DDL operations
  $dbh->do("CREATE TABLE emp (
      id     INT         NOT NULL,
      name   VARCHAR(40) NOT NULL,
      dept   VARCHAR(20),
      salary INT         DEFAULT 0
  )");
  $dbh->do("CREATE UNIQUE INDEX emp_id ON emp (id)");

  # 3. DML operations with placeholders
  $dbh->do("INSERT INTO emp (id,name,dept,salary) VALUES (?,?,?,?)",
           1, 'Alice', 'Eng', 75000);
  $dbh->do("INSERT INTO emp (id,name,dept,salary) VALUES (?,?,?,?)",
           2, 'Bob',   'Eng', 60000);
  $dbh->do("INSERT INTO emp (id,name,dept,salary) VALUES (?,?,?,?)",
           3, 'Carol', 'HR',  55000);

  # 4. Querying data (Prepared statement + fetch loop)
  my $sth = $dbh->prepare(
      "SELECT name, salary FROM emp WHERE salary >= ? ORDER BY salary DESC");
  $sth->execute(60000);
  while (my $row = $sth->fetchrow_hashref) {
      printf "%s: %d\n", $row->{name}, $row->{salary};
  }
  $sth->finish;

  # 5. Utility fetching methods
  my $rows = $dbh->selectall_arrayref(
      "SELECT name, dept FROM emp ORDER BY name", {Slice => {}});
  # $rows = [ {name=>'Alice', dept=>'Eng'}, ... ]

  my $row = $dbh->selectrow_hashref(
      "SELECT * FROM emp WHERE id = ?", {}, 1);
  # $row = {id=>1, name=>'Alice', dept=>'Eng', salary=>75000}

  my $h = $dbh->selectall_hashref("SELECT * FROM emp", 'id');
  # $h->{1}{name} eq 'Alice'

  # 6. Error handling
  $dbh->do("INSERT INTO emp (id,name) VALUES (?,?)", 1, 'Dup')
      or die $dbh->errstr;

  # 7. Disconnect
  $dbh->disconnect;

  # -------------------------------------------------------
  # Low-level interface
  # -------------------------------------------------------

  my $db = DB::Handy->new(base_dir => './mydata');
  $db->execute("USE mydb");

  my $res = $db->execute("SELECT * FROM emp WHERE salary > 50000");
  if ($res->{type} eq 'rows') {
      for my $row (@{ $res->{data} }) {
          print "$row->{name}: $row->{salary}\n";
      }
  }

=head1 TABLE OF CONTENTS

=over 4

=item * L</DESCRIPTION>

=item * L</INCLUDED DOCUMENTATION> -- eg/ samples and doc/ cheat sheets

=item * L</DBI COMPATIBILITY> -- What is and is not compatible with DBI

=item * L</METHODS - Connection handle (DB::Handy::Connection)>

=item * L</METHODS - Statement handle (DB::Handy::Statement)>

=item * L</ATTRIBUTES> -- Handle attributes such as RaiseError and NAME

=item * L</METHODS - Low-level API>

=item * L</SUPPORTED SQL> -- Full SQL syntax reference

=item * L</DATA TYPES>

=item * L</CONSTRAINTS>

=item * L</INDEXES>

=item * L</FILE LAYOUT>

=item * L</EXAMPLES> -- Practical usage patterns

=item * L</DIFFERENCES FROM DBI> -- Detailed incompatibility list

=item * L</DIAGNOSTICS> -- Error messages

=item * L</BUGS AND LIMITATIONS>

=item * L</SEE ALSO>

=back

=head1 DESCRIPTION

DB::Handy is a self-contained, pure-Perl relational database engine that
stores data in fixed-length binary flat files.  It requires B<no external
database server, no C compiler, and no XS modules>.

It is designed to be highly portable and works on any environment where
Perl 5.005_03 or later runs.

Key features:

=over 4

=item * B<Zero dependencies> - only core Perl modules (Fcntl, File::Path,
File::Spec, POSIX).

=item * B<DBI-like interface> - C<connect>, C<prepare>, C<execute>,
C<fetchrow_hashref>, etc.  This allows code written for DB::Handy to
be easily adapted to DBI. B<This is the recommended interface.>
B<Note:> DB::Handy is B<not> a DBI driver and does not load the
L<DBI> module.  See L</"DBI COMPATIBILITY">.

=item * B<Low-level interface> - C<< DB::Handy->new >> plus
The native engine interface (C<< DB::Handy->new >> and C<< $db->execute($sql) >>).
SQL statements are executed directly, and results are returned as specific
Perl hash data structures containing execution status and data.

=item * B<SQL support> - SELECT with JOIN, subqueries, UNION/INTERSECT/EXCEPT,
GROUP BY, HAVING, ORDER BY, LIMIT/OFFSET, aggregates, CASE expressions,
and more.  C<IN (...)>, C<NOT IN (...)>, and pure C<OR> expressions on
indexed columns use index lookups.  C<--> and C</* ... */> comments are
removed before parsing, and runs of whitespace between tokens are
collapsed, but neither happens inside a string literal: a newline, tab or
carriage return in a quoted value is stored as written, so a statement
may be laid out across several lines without disturbing its data.

=item * B<File locking> - a shared or exclusive C<flock> is taken on the
data and index files for the duration of every read and write, which
serialises concurrent access from multiple processes on a local file
system.  The return value of C<flock> is not checked; see
L</"BUGS AND LIMITATIONS"> for what that means on a file system where
locking is unavailable.

=item * B<Portable> - works on Windows and UNIX/Linux without modification.

=back

=head1 INCLUDED DOCUMENTATION

The C<doc/> directory contains SQL cheat sheets in 21 languages
for use as learning materials.

=head1 DBI COMPATIBILITY

DB::Handy intentionally mirrors the L<DBI> programming interface so that
application code can be ported between the two with minimal change.
The table below summarises which parts of DBI are supported and which are
not.

=head2 Compatible (works the same way as DBI)

=over 4

=item * B<connect / disconnect> -
C<< DB::Handy->connect($dir, $db, \%opts) >> and C<$dbh->disconnect> follow
DBI conventions.  C<RaiseError> and C<PrintError> behave as in DBI.

=item * B<do> -
C<< $dbh->do($sql, @bind) >> prepares, executes, and discards the result
in one call, returning the number of affected rows or C<'0E0'> for zero
rows, just like DBI.

=item * B<prepare / execute> -
C<< $dbh->prepare($sql) >> returns a statement handle.
C<< $sth->execute(@bind) >> substitutes C<?> positional placeholders and
runs the statement.  The return value semantics (affected rows, C<'0E0'>,
C<undef> on error) match DBI.

=item * B<bind_param> -
C<< $sth->bind_param($pos, $value) >> (1-based position) works the same
as DBI.

=item * B<fetchrow_hashref / fetchrow_arrayref / fetchrow_array / fetch> -
All four fetch methods work as in DBI.  C<fetch> is an alias for
C<fetchrow_arrayref>.

=item * B<fetchall_arrayref> -
Accepts C<{Slice =E<gt> {}}> (array of hash-refs) and C<{Slice =E<gt> []}>
(array of array-refs, the default), matching DBI.

=item * B<fetchall_hashref> - Works as in DBI.

=item * B<selectall_arrayref / selectall_hashref / selectrow_hashref / selectrow_arrayref> -
All four convenience methods have the same signature and return values as
their DBI counterparts.

=item * B<quote> -
Single-quotes a scalar and doubles embedded single-quotes; returns C<NULL>
for C<undef>.  Behaviour matches DBI's default C<quote>.

=item * B<finish> - Resets the cursor; returns 1.

=item * B<rows> -
C<< $sth->rows >> returns the row count for the last execute, as in DBI.

=item * B<errstr / err> -
Both the handle-level accessors (C<< $dbh->errstr >>, C<< $sth->errstr >>)
and the package-level variable (C<$DB::Handy::errstr>) work the same way
as C<$DBI::errstr> / C<$DBI::err>.

=item * B<NAME / NAME_lc / NAME_uc / NUM_OF_FIELDS / NUM_OF_PARAMS / Statement> -
C<< $sth->{NAME} >> (array-ref of column names in SELECT list order
for a named column list, C<CREATE TABLE> declaration order for
C<SELECT *> / JOIN) and
C<< $sth->{NUM_OF_FIELDS} >> (integer count) are set after C<execute>,
matching DBI statement-handle attributes.  C<NAME_lc> and C<NAME_uc>
carry the same list case-folded.  C<< $sth->{NUM_OF_PARAMS} >> and
C<< $sth->{Statement} >> are available as soon as C<prepare> returns.
C<NAME> is also populated from the SQL for zero-row results.

=item * B<table_info / column_info> -
Return data in the same key-naming convention as DBI
(C<TABLE_NAME>, C<TABLE_TYPE>, C<COLUMN_NAME>, C<DATA_TYPE>,
C<ORDINAL_POSITION>, C<IS_NULLABLE>, C<COLUMN_DEF>).

=item * B<ping> - Returns 1 when active, 0 after disconnect.

=back

=head2 Not Compatible (differs from or absent in DBI)

=over 4

=item * B<No DBI DSN format> -
DBI uses C<"dbi:Driver:param=val"> DSNs.  DB::Handy uses a plain directory
path or the proprietary C<"base_dir=DIR;database=DB"> mini-DSN.
C<dbi:Handy:...> strings are B<not> recognised.

=item * B<No transaction support> -
DB::Handy B<always operates in AutoCommit mode>; there is no way to
group statements into an atomic transaction.  C<begin_work>, C<commit>,
and C<rollback> are implemented but always return C<undef> and set
C<errstr>.  C<AutoCommit> always returns C<1>.

=item * B<Column order> -
DB::Handy preserves column order for named SELECT lists (including
C<AS> aliases), C<SELECT *> (uses CREATE TABLE order), and
JOIN with C<SELECT *> (table appearance order, each in CREATE order).
Compatible with DBI.

=item * B<RaiseError / PrintError are standalone> -
In DBI, C<RaiseError> and C<PrintError> are handled by the DBI framework
itself.  In DB::Handy they are implemented by the connection-handle code
only and may not fire in every error path that DBI would cover.

=item * B<No type_info / type_info_all> -
DBI provides C<type_info> and C<type_info_all> to query data-type
capabilities.  These methods are not implemented.

=item * B<Limited statement-level attributes> -
DBI statement handles expose many attributes.  DB::Handy supports
C<NAME>, C<NAME_lc>, C<NAME_uc>, C<NUM_OF_FIELDS>, C<NUM_OF_PARAMS> and
C<Statement>; C<TYPE>, C<PRECISION>, C<SCALE>, C<NULLABLE>,
C<CursorName>, C<ParamValues> and C<RowsInCache> are not implemented.

=item * B<last_insert_id semantics> -
C<last_insert_id> accepts the same four positional arguments as DBI
(C<$catalog>, C<$schema>, C<$table>, C<$field>) but ignores them.
It returns the row count of the most recent INSERT (always 1 for a
single-row insert), B<not> a generated key value: there are no
auto-increment columns, so there is no key to return.  Code ported from
DBI that uses the return value as a row identifier will be wrong.

=item * B<No BLOB / CLOB types> -
DBI supports large-object binding via special type constants.  DB::Handy
has no BLOB/CLOB storage; VARCHAR is capped at 255 bytes.

=item * B<No database-handle cloning or fork safety> -
DBI provides C<clone> and handles C<fork> safely.  DB::Handy does not
implement C<clone> and makes no special provision for forked processes.

=item * B<No HandleError callback> -
DBI supports the C<HandleError> attribute for custom error callbacks.
DB::Handy does not implement C<HandleError>.

=back

=head1 METHODS - Connection handle (DB::Handy::Connection)

A connection handle is returned by C<connect>.  It is an instance of
C<DB::Handy::Connection> and provides a DBI-like interface for executing
SQL and fetching results.

=head2 connect( $dsn, $database [, \%opts] )

  # Positional arguments
  my $dbh = DB::Handy->connect('./data', 'mydb');

  # DSN string
  my $dbh = DB::Handy->connect('base_dir=./data;database=mydb');

  # With options
  my $dbh = DB::Handy->connect('./data', 'mydb', {
      RaiseError => 1,
      PrintError => 0,
  });

Creates and returns a connection handle (C<DB::Handy::Connection>).

The first argument (C<$dsn>) is one of:

=over 4

=item * A plain directory path used as the base storage directory.

=item * A C<dbi:Handy:key=val;...> DSN string (C<dbi:Handy:> prefix
is stripped before parsing).

=item * A bare C<key=val;...> parameter string (no prefix).

=back

Recognised DSN keys: C<base_dir> (alias C<dir>) and C<database>
(alias C<db>).  See L</"dbi:Handy DSN"> in DIFFERENCES FROM DBI for
a full parameter table.

C<$database> is the logical name of the database.  The corresponding
directory (C<$dsn/$database/>) is B<created automatically> if it does
not exist.  To avoid automatic creation, pass C<< AutoUse => 0 >> in the
options hash.

B<Options:>

=over 4

=item C<RaiseError =E<gt> 1>

Die (C<die>) on any error.  Default: 0.  Compatible with DBI.

=item C<PrintError =E<gt> 1>

Warn (C<warn>) on any error.  Default: 0.  Compatible with DBI.

=item C<AutoUse =E<gt> 0>

Do not automatically issue C<USE $database> after connecting.  Useful when
you want to create the database programmatically.  Default: 1 (auto-use).
B<This option does not exist in DBI.>

=back

Returns C<undef> on failure; check C<$DB::Handy::errstr>.

B<DBI note:> In DBI, the DSN is always in the form C<"dbi:Driver:..."> and
the second and third arguments are username and password.  DB::Handy uses
the second argument as the database name and has no authentication concept.

=head2 do( $sql [, @bind_values] )

  $dbh->do("CREATE TABLE t (id INT, val VARCHAR(20))");
  $dbh->do("INSERT INTO t (id,val) VALUES (?,?)", 42, 'hello');
  my $n = $dbh->do("DELETE FROM t WHERE id = ?", 42);

Prepare and execute C<$sql> in one call, discarding the result set.
C<?> placeholders are substituted left-to-right with C<@bind_values>.

Returns:

=over 4

=item * The number of rows affected for INSERT/UPDATE/DELETE.

=item * C<'0E0'> (the string "zero but true") when zero rows are affected.
This is numerically zero but evaluates to true in boolean context.

=item * C<undef> on error.  Check C<$dbh-E<gt>errstr>.

=back

This is the recommended method for DDL statements and DML that does not
return rows.  Compatible with DBI.

=head2 prepare( $sql )

  my $sth = $dbh->prepare("SELECT * FROM emp WHERE dept = ?");

Parses and stores C<$sql>, returning a statement handle
(C<DB::Handy::Statement>).  The SQL is B<not> executed at this point.

C<?> characters in the SQL string are treated as positional placeholders.
Values are supplied at C<execute()> time.

Returns the statement handle, or C<undef> on error.
Compatible with DBI.

=head2 selectall_arrayref( $sql, \%attr, @bind_values )

  # Array of hash-refs (one per row)
  my $rows = $dbh->selectall_arrayref(
      "SELECT * FROM emp WHERE dept = ?",
      {Slice => {}},
      'Eng');

  # Array of array-refs (one per row, columns in SELECT list order)
  my $rows = $dbh->selectall_arrayref(
      "SELECT id, name FROM emp ORDER BY id");

Execute C<$sql> (with optional C<@bind_values>) and return all rows as an
array-ref.

B<Attribute C<Slice>:>

=over 4

=item C<< {Slice => {}} >>

Each row is a hash-ref C<{ column_name =E<gt> value, ... }>.

=item C<< {Slice => []} >> (default, or omit C<\%attr>)

Each row is an array-ref with values in C<< $sth->{NAME} >> order: the SELECT list order for a named
column list, and the C<CREATE TABLE> declaration order for
C<SELECT *> (qualified as C<alias.col>, table by table, for a JOIN).

=back

Returns C<undef> on error.  Compatible with DBI.

=head2 selectall_hashref( $sql, $key_field, \%attr, @bind_values )

  my $emp = $dbh->selectall_hashref("SELECT * FROM emp", 'id');
  print $emp->{1}{name};   # 'Alice'
  print $emp->{2}{salary}; # 60000

Execute C<$sql> and return a hash-ref whose keys are the values of
C<$key_field> and whose values are row hash-refs.

If C<$key_field> appears more than once in the result set, later rows
silently overwrite earlier ones (same behaviour as DBI).

Returns C<undef> on error.  Compatible with DBI.

=head2 selectrow_hashref( $sql, \%attr, @bind_values )

  my $row = $dbh->selectrow_hashref(
      "SELECT * FROM emp WHERE id = ?", {}, 1);
  # $row = {id=>1, name=>'Alice', dept=>'Eng', salary=>75000}
  # or undef if no row matches

Execute C<$sql>, fetch the B<first> row as a hash-ref, then call
C<finish>.  Returns C<undef> if no rows match or on error.
Compatible with DBI.

=head2 selectrow_arrayref( $sql, \%attr, @bind_values )

  my $row = $dbh->selectrow_arrayref(
      "SELECT name, salary FROM emp WHERE id = ?", {}, 1);
  # $row = ['Alice', 75000]  (columns in SELECT list order)

Execute C<$sql>, fetch the first row as an array-ref, then call C<finish>.
Returns C<undef> if no rows match or on error.

B<Note:> Column order follows the SELECT list for named columns;
for C<SELECT *> it follows C<CREATE TABLE> declaration order.
See L</"Column order">.
Compatible with DBI.

=head2 quote( $value )

  my $s = $dbh->quote("O'Brien");  # "'O''Brien'"
  my $n = $dbh->quote(42);         # "'42'"
  my $u = $dbh->quote(undef);      # "NULL"

Return a SQL string literal suitable for direct interpolation into a SQL
statement.  Single-quote the value and double any embedded single-quote
characters.  Return the unquoted string C<NULL> for C<undef>.

B<Note:> Numeric values are also quoted as strings (C<"'42'">), unlike
some DBI drivers that pass integers through unquoted.  Prefer C<?>
placeholders over C<quote> wherever possible.

Compatible with DBI (default C<quote> behaviour).

=head2 last_insert_id()

  $dbh->do("INSERT INTO emp (id,name) VALUES (?,?)", 4, 'Dave');
  my $n = $dbh->last_insert_id;   # 1 (one row was inserted)

Return the row count of the most recent INSERT statement.  This is always
1 on a successful single-row INSERT, or the total count for a bulk
C<INSERT ... SELECT>.

C<last_insert_id> accepts the same four positional arguments as DBI
(C<$catalog, $schema, $table, $field>) but ignores them; only the
connection object is used.  Compatible with DBI.

=head2 disconnect()

  $dbh->disconnect;

Mark the connection as closed.  Subsequent calls to C<do>, C<prepare>,
etc. will fail.  Always returns 1.

In DBI, C<disconnect> may flush uncommitted transactions; DB::Handy has
no transactions, so C<disconnect> is a no-op beyond setting the
disconnected flag.  Compatible with DBI.

=head2 errstr()

  my $msg = $dbh->errstr;

Return the error message from the most recent failed operation on this
handle, or the empty string if there was no error.

Like DBI, DB::Handy resets C<errstr> and C<err> when a statement is
prepared or executed, so a message left over from an earlier failure is
never mistaken for the outcome of a call that has just succeeded.

The package-level variable C<$DB::Handy::errstr> holds the last error
from any handle, analogous to C<$DBI::errstr>.  It is not reset.
Compatible with DBI.

=head2 err()

  my $code = $dbh->err;

Return the error code from the most recent failed operation (always 1 for
any error, 0 for no error).  Reset together with C<errstr>.
Analogous to C<$DBI::err>.
Compatible with DBI.

=head2 ping()

  my $alive = $dbh->ping;

Return true while the handle is usable, false after C<disconnect>.  There
is no server to reach, so this reports the handle's own state.
Compatible with DBI.

=head2 AutoCommit()

  my $ac = $dbh->AutoCommit;   # always 1

Always returns C<1>.  This method, not the C<< $dbh->{AutoCommit} >> hash
key, is the authoritative answer; see L</ATTRIBUTES>.

=head2 begin_work() / commit() / rollback()

  $dbh->begin_work or die $dbh->errstr;

All three always fail: they return C<undef> and set C<errstr> to explain
that DB::Handy has no transactions.  They exist so that ported DBI code
fails visibly instead of appearing to open a transaction.  Connecting with
C<AutoCommit =E<gt> 0> is refused for the same reason.

=head2 table_info()

  my $rows = $dbh->table_info;
  for my $t (@$rows) { print "$t->{TABLE_NAME}\n" }

Return an array reference of hash references, one per table in the current
database.  B<Not compatible with DBI>, in two ways: DBI's C<table_info>
takes four positional arguments (C<$catalog>, C<$schema>, C<$table>,
C<$type>) and returns a statement handle, whereas this method takes no
arguments and returns the rows directly.  The hash keys follow DBI's
naming (C<TABLE_CAT>, C<TABLE_SCHEM>, C<TABLE_NAME>, C<TABLE_TYPE>,
C<REMARKS>).

=head2 column_info( $table )

  my $rows = $dbh->column_info('emp');
  for my $c (@$rows) { print "$c->{COLUMN_NAME} $c->{TYPE_NAME}\n" }

Return an array reference of hash references, one per column of C<$table>,
in declaration order.  B<Not compatible with DBI>: DBI's C<column_info>
takes C<$catalog>, C<$schema>, C<$table>, C<$column> and returns a
statement handle; this method takes B<the table name as its only
argument> and returns the rows directly.  Calling it with DBI's four
arguments passes C<undef> as the table name and returns C<undef>.

The hash keys follow DBI's naming (C<TABLE_CAT>, C<TABLE_SCHEM>,
C<TABLE_NAME>, C<COLUMN_NAME>, C<DATA_TYPE>, C<TYPE_NAME>,
C<COLUMN_SIZE>, C<ORDINAL_POSITION>, C<IS_NULLABLE>, C<COLUMN_DEF>).

=head1 METHODS - Statement handle (DB::Handy::Statement)

A statement handle is created by C<< $dbh->prepare($sql) >>.  It is an
instance of C<DB::Handy::Statement>.

=head2 execute( [@bind_values] )

  $sth->execute;                   # no placeholders
  $sth->execute(42, 'Alice');      # substitute two ? placeholders

Execute the prepared statement.  C<?> placeholders are substituted
left-to-right with the supplied values.  If no values are supplied and
C<bind_param> was called previously, the pre-bound values are used.

The number of values must equal C<< $sth->{NUM_OF_PARAMS} >>.  A
mismatch sets C<errstr> and returns C<undef> rather than running a
statement in which some placeholder was left unsubstituted or some value
was silently dropped.

Returns:

=over 4

=item * For SELECT: the number of rows in the result set, or C<'0E0'>
for zero rows.

=item * For INSERT/UPDATE/DELETE/DDL: the number of affected rows, or
C<'0E0'> for zero.

=item * C<undef> on error.

=back

After a successful execute on a SELECT, call the C<fetch*> methods to
retrieve rows.  Compatible with DBI.

=head2 bind_param( $position, $value [, \%attr] )

  my $sth = $dbh->prepare("INSERT INTO t (id,name) VALUES (?,?)");
  $sth->bind_param(1, 42);
  $sth->bind_param(2, 'Alice');
  $sth->execute;                   # uses pre-bound values

Pre-bind a value to the placeholder at C<$position> (1-based).
The C<\%attr> argument is accepted but ignored (no type coercion is
performed).

The bound values are consumed on the next C<execute()> call that is
invoked with no arguments.  Compatible with DBI.

=head2 fetchrow_hashref( [$name] )

  while (my $row = $sth->fetchrow_hashref) {
      print "$row->{name}: $row->{salary}\n";
  }

Return the next row from the result set as a hash-ref mapping column
names to values.  Returns C<undef> at end of result or if no SELECT has
been executed.

The optional C<$name> argument (C<"NAME">, C<"NAME_lc">, C<"NAME_uc">)
is accepted for DBI compatibility but does not change the returned keys;
column names are always returned in their original (schema-defined) case.

Compatible with DBI.

=head2 fetchrow_arrayref()

  while (my $row = $sth->fetchrow_arrayref) {
      print join(', ', @$row), "\n";
  }

Return the next row as an array-ref with values in the order defined by
C<< $sth->{NAME} >>.  For named SELECT lists the order matches the SELECT
list; for C<SELECT *> and JOIN results it is the C<CREATE TABLE>
declaration order.
Returns C<undef> at end of result.

B<Note:> Column order follows the SELECT list for named columns;
for C<SELECT *> it follows C<CREATE TABLE> declaration order.
See L</"Column order">.
Compatible with DBI.

=head2 fetchrow_array()

  my @row = $sth->fetchrow_array;

Return the next row as a plain list in C<< $sth->{NAME} >> order
(SELECT list order for a named column list, C<CREATE TABLE>
declaration order for C<SELECT *>),
or an empty list at end of result.

B<Note:> Column order matches the SELECT list for named columns.
Compatible with DBI.

=head2 fetch()

Alias for C<fetchrow_arrayref>.  Compatible with DBI.

=head2 fetchall_arrayref( [$slice] )

  # Array of hash-refs
  my $all = $sth->fetchall_arrayref({});

  # Array of array-refs (default)
  my $all = $sth->fetchall_arrayref([]);
  my $all = $sth->fetchall_arrayref;

Consume all remaining rows and return them as an array-ref.  The optional
C<$slice> argument controls the row format:

=over 4

=item Hash-ref slice C<{}>

Each row is returned as a hash-ref C<{ col =E<gt> val, ... }>.

=item Array-ref slice C<[]> or omitted

Each row is returned as an array-ref with values in C<< $sth->{NAME} >> order: the SELECT list order for a named
column list, and the C<CREATE TABLE> declaration order for
C<SELECT *> (qualified as C<alias.col>, table by table, for a JOIN).

=back

B<Column-index slices are not supported.>  DBI lets you pass a list of
column positions, as in C<fetchall_arrayref([0, 2])>, to select a subset
of the columns.  DB::Handy ignores the contents of the array-ref and
always returns every column; name the columns you want in the SELECT
list instead.

B<The C<$max_rows> argument is not supported.>  DBI accepts a second
argument limiting how many rows are fetched, as in
C<fetchall_arrayref(undef, 10)>.  DB::Handy accepts the argument and
ignores it, always returning every remaining row; use C<LIMIT> in the SQL,
or C<fetchrow_hashref> in a loop, instead.

Returns C<undef> if no statement has been executed.

=head2 fetchall_hashref( $key_field )

  my $h = $sth->fetchall_hashref('id');
  print $h->{1}{name};

Consume all remaining rows and return a hash-ref keyed by C<$key_field>.
Each value is a row hash-ref.  If the key column has duplicate values,
later rows overwrite earlier ones.
Compatible with DBI.

=head2 rows()

  my $count = $sth->rows;

Return the number of rows affected by the last DML statement or returned
by the last SELECT.  This value is also the return value of C<execute>.
Compatible with DBI.

=head2 finish()

  $sth->finish;

Reset the cursor to the beginning of the result set and release any
associated resources.  Does not close the statement handle; the same
C<$sth> can be re-executed.  Always returns 1.
Compatible with DBI.

=head2 errstr() / err()

The error message and error code from the most recent failed operation on
this statement handle.  See L</"errstr()"> and L</"err()"> under the
connection handle section.
Compatible with DBI.

=head1 ATTRIBUTES

=head2 Statement-handle attributes

The following attributes are available on C<$sth> after a successful
C<execute>:

=over 4

=item C<$sth-E<gt>{NAME}>

An array-ref of column names in the result set:

=over 4

=item *

Named SELECT list: follows the SELECT list order.
C<SELECT salary, name> gives C<['salary', 'name']>.

=item *

C<SELECT *> on a single table: follows the C<CREATE TABLE> declaration
order.  C<SELECT * FROM emp> where emp has columns (id, name, dept)
gives C<['id', 'name', 'dept']>.

=item *

C<SELECT *> with C<JOIN>: table appearance order (FROM first, then
each JOIN table in order), each table's columns in declaration order,
as qualified names C<alias.col>.

=back

The attribute is set correctly even for zero-row results.
Compatible with DBI.

=item C<$sth-E<gt>{NAME_lc}> / C<$sth-E<gt>{NAME_uc}>

The same list as C<NAME>, lower-cased and upper-cased respectively.
Useful when the SQL and the calling code disagree about identifier case.
Compatible with DBI.

=item C<$sth-E<gt>{NUM_OF_FIELDS}>

The number of columns in the result set (integer).  Set to 0 for
non-SELECT statements.  Compatible with DBI.

=item C<$sth-E<gt>{NUM_OF_PARAMS}>

The number of C<?> placeholders in the prepared statement.  Available
immediately after C<prepare>, before C<execute>.  A C<?> inside a string
literal or a comment is not counted, because C<execute> does not consume
one for it either.  Compatible with DBI.

=item C<$sth-E<gt>{Statement}>

The SQL text passed to C<prepare>, unchanged.  Compatible with DBI.

=back

The following DBI statement-handle attributes are B<not> implemented:
C<TYPE>, C<PRECISION>, C<SCALE>, C<NULLABLE>, C<CursorName>,
C<ParamValues>, C<RowsInCache>.

=head2 Connection-handle attributes

=over 4

=item C<RaiseError>

When true, any error causes an immediate C<die>.  Can be set at
C<connect> time via the options hash.  Compatible with DBI.

=item C<PrintError>

When true, any error causes a C<warn>.  Can be set at C<connect> time.
Compatible with DBI.

=item C<AutoCommit>

Set to C<1> at connect time, so that DBI-style code which reads
C<< $dbh->{AutoCommit} >> gets the expected answer.

The handle is an ordinary hash reference, so B<assigning to this key stores
the value and it reads back> -- it does not enable transactions, and it
does not make C<commit> work.  Only the C<AutoCommit> method is
authoritative: it always returns C<1>.  (Releases up to 1.08 documented
this key as read-only, which it never was.)  Passing
C<AutoCommit =E<gt> 0> to C<connect> is refused outright rather than
accepted and ignored.

=back

The following DBI connection-handle attributes are B<not> implemented:
C<LongReadLen>, C<LongTruncOk>, C<ChopBlanks>,
C<FetchHashKeyName>, C<HandleError>, C<Profile>.

=head1 METHODS - Low-level API

These methods operate directly on the DB::Handy engine object returned by
C<< DB::Handy->new >>.  They are independent of the DBI-like layer.

B<Identifier restriction.>  Database, table and index names become path
components on disk, so every method below restricts them to word
characters (C<[A-Za-z0-9_]>, i.e. C<\w>).  A name containing C</>, C<\>,
C<:> or C<..> is rejected with C<Invalid database name>, C<Invalid table
name> or C<Invalid index name> in C<$DB::Handy::errstr> rather than being
turned into a path.  This matters when a name comes from outside the
program: without the check, C<< $db->drop_database($cgi_param) >> could be
made to delete a directory tree outside C<base_dir>.  The SQL layer has
always applied the same C<\w+> rule, so SQL statements are unaffected.

=head2 new( base_dir =E<gt> $dir [, db_name =E<gt> $name] )

  my $db = DB::Handy->new(base_dir => './mydata');
  my $db = DB::Handy->new(base_dir => './mydata', db_name => 'mydb');

Create a new engine instance.  C<base_dir> is created automatically if it
does not exist.  If C<db_name> is supplied, the database is selected
immediately (equivalent to calling C<use_database> afterwards).

Returns C<undef> on failure; check C<$DB::Handy::errstr>.

=head2 execute( $sql )

  my $res = $db->execute("SELECT * FROM emp WHERE salary > 50000");

Execute any SQL statement and return a result hash-ref.  The hash always
has a C<type> key:

  { type => 'ok',       message => '1 row inserted' }   # DDL/DML success
  { type => 'rows',     data    => [ {...}, ... ]     }  # SELECT result
  { type => 'error',    message => '...'              }  # error
  { type => 'list',     data    => [ 'tbl1', ... ]    }  # SHOW result
  { type => 'describe', data    => [ {...}, ... ]     }  # DESCRIBE result
  { type => 'indexes',  table   => 'emp',
                        data    => [ {...}, ... ]     }  # SHOW INDEXES

For C<type =E<gt> 'rows'>, each element of C<data> is a hash-ref mapping
column names to values.

=head2 create_database( $name )

  $db->create_database('mydb') or die $DB::Handy::errstr;

Create the database directory.  Returns 1 on success, 0 on failure.

=head2 use_database( $name )

  $db->use_database('mydb') or die $DB::Handy::errstr;

Select a database for subsequent operations.  Returns 1 on success, 0 if
the database does not exist.

=head2 drop_database( $name )

  $db->drop_database('mydb') or die $DB::Handy::errstr;

Remove the database directory and all its files.  Returns 1 on success.

=head2 list_databases()

  my @dbs = $db->list_databases;

Return a sorted list of database names found in C<base_dir>.

=head2 create_table( $name, \@col_defs )

  $db->create_table('emp', [
      ['id',     'INT'],
      ['name',   'VARCHAR', 40],
      ['salary', 'INT'],
  ]);

Create a table with the given column definitions.  Each element of
C<\@col_defs> is a three-element array: C<[name, type, size]>.
C<size> is required for C<CHAR> columns and ignored for fixed-size types.

Returns 1 on success, 0 (with C<$DB::Handy::errstr> set) on failure.

=head2 drop_table( $name )

Remove the table and all associated index files.  Returns 1.

=head2 list_tables()

Return a sorted list of table names in the current database.

=head2 describe_table( $table )

Return an array-ref of column-definition hashes for C<$table>:

  [ { name => 'id',   type => 'INT',     size => 4  },
    { name => 'name', type => 'VARCHAR', size => 255 }, ... ]

=head2 create_index( $idxname, $table, $colname, $unique )

  $db->create_index('emp_id', 'emp', 'id', 1);    # unique index
  $db->create_index('emp_dept', 'emp', 'dept', 0); # non-unique index

Create a sorted binary index on C<$colname> of C<$table>.  Set
C<$unique> to a true value to enforce a UNIQUE constraint.

Returns 1 on success, C<undef> on error.

=head2 drop_index( $idxname, $table )

Remove the named index from C<$table>.  Returns 1 on success.

=head2 list_indexes( $table )

Return an array-ref of index-definition hashes for C<$table>.

=head2 insert( $table, \%row )

  $db->insert('emp', { id => 1, name => 'Alice', salary => 75000 });

Insert one row.  Returns 1 on success, C<undef> on error.

=head2 delete_rows( $table, $where )

  $db->delete_rows('emp', sub { $_[0]{id} == 3 });

Mark matching rows as deleted (tombstone).  Returns the number of deleted
rows, or C<undef> on error.  Disk space is not reclaimed until C<vacuum>
is called.

=head2 vacuum( $table )

  my $kept = $db->vacuum('emp');

Rewrite the data file, permanently removing rows that were marked as
deleted.  Returns the number of active rows kept, or C<undef> on error.

Unlike SQL databases that run VACUUM as background maintenance, DB::Handy
requires an explicit call to reclaim space.

=head1 SUPPORTED SQL

DB::Handy implements a surprisingly robust subset of SQL-92 in Pure Perl.

=head2 Data types

  INT          4-byte signed integer
  FLOAT        8-byte IEEE 754 double
  CHAR(n)      Fixed-length string, n bytes (space-padded on write)
  VARCHAR(n)   Variable-length string, stored in 255 bytes
  TEXT         Alias for VARCHAR(255)
  DATE         Fixed 10-byte string (YYYY-MM-DD convention, not enforced)

=head2 DDL

  CREATE DATABASE name
  DROP   DATABASE name
  USE    name
  SHOW   DATABASES

  CREATE TABLE name (col_def, ...)
  DROP   TABLE name
  SHOW   TABLES

  CREATE [UNIQUE] INDEX idxname ON table (col)
  DROP   INDEX   idxname ON table
  SHOW   INDEXES ON table
  SHOW   INDICES ON table

  DESCRIBE table

=head2 DML

  INSERT INTO table (col, ...) VALUES (val, ...)
  INSERT INTO table             VALUES (val, ...)  -- no column list
  INSERT INTO table (col, ...) SELECT ...
  SELECT ...
  UPDATE table SET col=expr [, ...] [WHERE ...]
  DELETE FROM table [WHERE ...]
  VACUUM table

B<Note on INSERT...SELECT column mapping:> Columns are matched
B<by name> when every destination column name appears as a key in the
SELECT result row; otherwise the mapping falls back to positional order
(left-to-right):

  -- same names: name-based (order of SELECT list does not matter)
  INSERT INTO dst (b, a) SELECT a, b FROM src   -- b <- b, a <- a

  -- different names: positional fallback
  INSERT INTO dst (a, b) SELECT x, y FROM src   -- a <- x, b <- y

=head2 SELECT syntax

  SELECT [DISTINCT] col_expr [AS alias], ...
         | *
  FROM   table [AS alias]
         [INNER | LEFT [OUTER] | RIGHT [OUTER]] JOIN table [AS alias]
             ON table.col = table.col
         | CROSS JOIN table [AS alias]
  [WHERE condition]
  [GROUP BY col, ...]
  [HAVING condition]
  [ORDER BY {col | position} [ASC|DESC], ...]
  [LIMIT  n]
  [OFFSET n]

=head2 Subqueries

  WHERE col IN     (SELECT ...)
  WHERE col NOT IN (SELECT ...)
  WHERE col OP     (SELECT ...)    -- OP: = != <> < > <= >=
  WHERE EXISTS     (SELECT ...)
  WHERE NOT EXISTS (SELECT ...)
  FROM  (SELECT ...) AS alias      -- derived table / inline view
  SELECT (SELECT ...) AS alias     -- scalar subquery in SELECT list

Correlated subqueries (referencing outer table columns) are supported.
Nesting depth is limited to 32 levels.

The outer query of a derived table accepts C<WHERE>, C<GROUP BY>,
C<HAVING>, C<ORDER BY>, C<LIMIT> and C<OFFSET>, and its SELECT list may
use the aggregate functions:

  SELECT COUNT(*)      FROM (SELECT ...) AS sub
  SELECT dept, SUM(n)  FROM (SELECT ...) AS sub GROUP BY dept
  SELECT dept          FROM (SELECT ...) AS sub GROUP BY dept HAVING MAX(n) > 10

C<LIMIT> and C<OFFSET> are applied to the aggregated result, not to the
rows going into it, so C<SELECT COUNT(*) FROM (...) AS sub LIMIT 1>
counts every row.

=head2 Set operations

  SELECT ... UNION         SELECT ...
  SELECT ... UNION ALL     SELECT ...
  SELECT ... INTERSECT     SELECT ...
  SELECT ... INTERSECT ALL SELECT ...
  SELECT ... EXCEPT        SELECT ...
  SELECT ... EXCEPT ALL    SELECT ...

Set operators can be chained:
C<SELECT ... UNION SELECT ... INTERSECT SELECT ...>.

B<UNION> combines rows from both queries and removes duplicates.
B<UNION ALL> combines rows without removing duplicates.
B<INTERSECT> returns rows common to both queries (deduplicated).
B<INTERSECT ALL> returns common rows preserving multiplicity
(min of the two counts).
B<EXCEPT> returns rows in the left query not present in the right
(deduplicated).
B<EXCEPT ALL> returns the multiset difference.

=head2 WHERE predicates

  col = val           col != val       col <> val
  col < val           col <= val
  col > val           col >= val
  col BETWEEN low AND high
  col IN (val, ...)   col NOT IN (val, ...)
  col IS NULL         col IS NOT NULL
  col LIKE pattern    col NOT LIKE pattern
  expr AND expr       expr OR expr     NOT expr

=head2 Aggregate functions

  COUNT(*)
  COUNT(DISTINCT expr)
  SUM(expr)
  AVG(expr)
  MIN(expr)
  MAX(expr)

=head2 Scalar functions

  UPPER(str)      LOWER(str)
  LENGTH(str)     SUBSTR(str, pos [, len])
  TRIM(str)
  COALESCE(a, b, ...)
  NULLIF(a, b)
  CAST(expr AS type)

=head2 Conditional expressions

  CASE WHEN cond THEN val [WHEN ...] [ELSE val] END

=head2 Operators

  +   -   *   /   %       arithmetic
  ||                      string concatenation

=head2 Column aliases

  SELECT salary * 1.1 AS new_salary FROM emp

=head2 Ordering by select-list position

  SELECT name, salary FROM emp ORDER BY 2 DESC
  SELECT name, salary FROM emp ORDER BY 2, 1

A sort key written as a plain number is the position of a column in the
SELECT list, counting from 1, as in SQL-92.  With C<SELECT *> the
positions follow the C<CREATE TABLE> column order.  A position outside
that range is an error rather than a sort that quietly does nothing.

An expression is never read as a position, so C<ORDER BY 1+1> still
sorts by the value of that expression.

The one place a position cannot be resolved is C<SELECT *> across a
JOIN, because the combined column list is not known when the sort key is
parsed; use a column name there.

=head1 DATA TYPES

=over 4

=item B<INT>

A 4-byte signed integer stored in big-endian binary form.
Range: -2,147,483,648 to 2,147,483,647.
Stored size on disk: 4 bytes.

A numeric value outside that range is B<rejected> by C<INSERT> and
C<UPDATE> with an "Integer out of range" error; earlier releases clamped
it silently to the nearest limit.  A value with a fractional part is
truncated towards zero (C<1.7> is stored as C<1>), and a value that is
not numeric at all is stored as C<0>; neither is an error.

=item B<FLOAT>

An 8-byte IEEE 754 double.  Stored size on disk: 8 bytes.
Index keys use an order-preserving encoding so that the binary sort
order of the index matches numeric order.  The C<.dat> file itself holds
the machine's native double -- see L</"BUGS AND LIMITATIONS"> for what
that means when a data file is copied between machines.

A value that is not numeric at all is stored as C<0> and is not an
error, the same rule C<INT> follows.  C<'abc'>, C<'12abc'>, C<'0x10'>,
C<'Inf'> and C<'NaN'> are all stored as C<0>; only a leading sign, digits,
a decimal point and an exponent are read as a number.  Up to 1.08 this
column type had no such test and passed the value straight to C<pack>,
so a non-numeric value emitted an C<isn't numeric> warning from inside
DB::Handy -- twice per row when the column was indexed -- regardless of
the caller's warning settings.

=item B<CHAR(n)>

A fixed-length string of exactly C<n> bytes.  Values shorter than C<n> are
NUL-padded on write; trailing NULs are stripped on read.

=item B<VARCHAR(n) / TEXT>

Stored as a fixed 255-byte field regardless of C<n>.  Values are
NUL-padded on write; trailing NULs are stripped on read.
B<Note:> Unlike real databases, VARCHAR and TEXT always occupy 255 bytes
on disk; there is no variable-length storage.

=item B<DATE>

A 10-byte fixed string in C<YYYY-MM-DD> form.  C<INSERT> and C<UPDATE>
B<reject> a value that is not a well-formed calendar date: the format
must be exactly four digits, a hyphen, two digits, a hyphen and two
digits, the month must be 01-12, and the day must exist in that month of
that year (C<2020-02-29> is accepted, C<2021-02-29> is not; the
four-hundred-year rule is applied, so C<2000-02-29> is accepted and
C<1900-02-29> is not).  NULL and the empty string are always accepted.

No date arithmetic is performed.  Comparisons are plain string
comparisons, which give the expected result because the format sorts
chronologically.  Values written by 1.08 or earlier are not re-validated
on read, so an existing file may still hold something that C<INSERT>
would now refuse.

=back

=head1 CONSTRAINTS

The following column constraints are recognised in C<CREATE TABLE>:

=over 4

=item B<NOT NULL>

  id INT NOT NULL

The column may not contain an empty or undefined value.  Enforced on
both B<INSERT> and B<UPDATE>.

=item B<DEFAULT value>

  salary INT DEFAULT 0
  dept   VARCHAR(20) DEFAULT 'unknown'

Applied when an INSERT omits the column or supplies an empty value.

=item B<UNIQUE>

  CREATE TABLE emp (id INT, email VARCHAR(60) UNIQUE)
  CREATE TABLE emp (id INT, email VARCHAR(60), UNIQUE (email))
  CREATE UNIQUE INDEX emp_id ON emp (id)

Enforced at INSERT and UPDATE time.  The column modifier and the
table-level constraint both create a unique index called
C<< <column>_unique >>; C<CREATE UNIQUE INDEX> names the index itself.
Multiple NULL (empty string) values are allowed, as SQL-92 requires.

=item B<PRIMARY KEY>

  CREATE TABLE emp (id INT PRIMARY KEY, name VARCHAR(40))
  CREATE TABLE emp (id INT, name VARCHAR(40), PRIMARY KEY (id))

Implies C<NOT NULL> and creates a unique index called
C<< <column>_pk >>, so duplicate keys are rejected on INSERT and on
UPDATE.  A column that is both C<PRIMARY KEY> and C<UNIQUE> gets one
index, not two.  The index is created with the table, so a table that
was created by DB::Handy 1.08 or earlier does not have one; add it with
C<CREATE UNIQUE INDEX> if the older table needs the constraint.

=item B<CHECK>

  salary INT CHECK (salary >= 0)

A simple expression evaluated on both B<INSERT and UPDATE>.
Supported in C<CREATE TABLE> column definitions only;
table-level CHECK constraints are not supported.

=back

B<FOREIGN KEY> constraints are not supported.

=head1 INDEXES

DB::Handy uses sorted binary index files to accelerate equality lookups.

=over 4

=item B<Structure>

Each index file (C<E<lt>tableE<gt>.E<lt>idxnameE<gt>.idx>) begins with an
8-byte magic header (C<"SDBIDX1\n">) followed by fixed-size entries sorted
ascending by key.  Each entry is C<[key_bytes][rec_no (4 bytes big-endian)]>.

=item B<Key encoding>

  INT    Sign-bit-flipped big-endian uint32 (order-preserving)
  FLOAT  IEEE 754 order-preserving 8-byte encoding
  Other  NUL-padded fixed-width string

=item B<When indexes are used>

The query engine uses an index when the WHERE clause contains:

=over 4

=item *

A simple equality or range condition on an indexed column:
C<WHERE id = 42>, C<WHERE id E<gt> 10>, C<WHERE id E<lt>= 100>.

=item *

A two-sided AND range on a single indexed column:
C<WHERE id E<gt> 10 AND id E<lt> 20>.

=item *

A C<BETWEEN> predicate on an indexed column:
C<WHERE id BETWEEN 10 AND 20>.

=item *

An AND condition spanning B<different> indexed columns.  The engine
picks the best single-column index to narrow the candidate set, then
applies the full WHERE predicate as a post-filter:
C<WHERE dept = 'Eng' AND salary E<gt> 70000>.

=item *

A C<col IN (v1, v2, ...)> predicate on an indexed column.  The engine
performs one equality index lookup per value and returns the union of
matching records:
C<WHERE id IN (10, 20, 30)>.

=item *

A B<pure OR> expression where every atom has an index on its column.
The engine performs one index lookup per OR atom and returns the union
of matching records:
C<WHERE dept = 'Eng' OR dept = 'HR'>,
C<WHERE id = 1 OR id E<gt> 100>.
If any atom has no index the engine falls back to a full table scan.

=item *

A C<col NOT IN (v1, v2, ...)> predicate on an indexed column.  The engine
collects the record numbers that match the IN list via the index, then
returns all other records (index complement).  If the column has no index
a full table scan is used.  C<NOT IN> with C<NULL> in the value list
always falls back to a full table scan.

=back

=item B<Index maintenance>

Indexes are updated in-place on every INSERT, UPDATE, and DELETE.
C<VACUUM> rebuilds all indexes for a table.

=back

=head1 FILE LAYOUT

DB::Handy stores data in flat files inside the specified C<base_dir>.

  <base_dir>/
    <database>/
      <table>.sch           schema definition (text, key=value lines)
      <table>.dat           record data (fixed-length binary, big-endian)
      <table>.<idxname>.idx sorted index file (binary)

B<Schema file format> (C<.sch>):

  VERSION=1
  RECSIZE=<bytes per record including the 1-byte active flag>
  COL=<name>:<type>:<size>
  [IDX=<idxname>:<colname>:<unique 0|1>]
  [NN=<colname>]            NOT NULL
  [DEF=<colname>:<val>]     DEFAULT value
  [PK=<colname>]            PRIMARY KEY (also recorded as an IDX line)

B<Data file format> (C<.dat>):

Each record is C<RECSIZE> bytes. Because files are fixed-length binary, C<read> and C<seek> are used for fast record traversal.

The first byte is the active flag:

C<0x01> for an active record, C<0x00> for a deleted record and are skipped during scans.

The remaining bytes are the column values in declaration order, packed in the type-specific binary format.

Use the C<VACUUM> SQL command to physically remove deleted records and compact the data file.

=head1 EXAMPLES

=head2 Creating a database and table

  use DB::Handy;

  my $dbh = DB::Handy->connect('./data', 'hr');

  $dbh->do(<<'SQL');
  CREATE TABLE employee (
      id         INT         NOT NULL,
      name       VARCHAR(50) NOT NULL,
      department VARCHAR(30) DEFAULT 'Unassigned',
      salary     INT         DEFAULT 0,
      hire_date  DATE
  )
  SQL

  $dbh->do("CREATE UNIQUE INDEX emp_pk ON employee (id)");
  $dbh->do("CREATE INDEX emp_dept ON employee (department)");

=head2 Inserting rows with a prepared statement

  my $ins = $dbh->prepare(
      "INSERT INTO employee (id,name,department,salary,hire_date)
       VALUES (?,?,?,?,?)");

  $ins->execute(1, 'Alice',   'Engineering', 90000, '2020-03-01');
  $ins->execute(2, 'Bob',     'Engineering', 75000, '2021-06-15');
  $ins->execute(3, 'Carol',   'HR',          65000, '2019-11-20');
  $ins->execute(4, 'Dave',    'Engineering', 80000, '2022-01-10');
  $ins->execute(5, 'Eve',     'HR',          70000, '2020-08-05');

=head2 Basic SELECT

  my $sth = $dbh->prepare(
      "SELECT name, salary FROM employee
       WHERE department = ? AND salary >= ?
       ORDER BY salary DESC");
  $sth->execute('Engineering', 80000);
  while (my $row = $sth->fetchrow_hashref) {
      printf "%-15s %6d\n", $row->{name}, $row->{salary};
  }
  $sth->finish;
  # Alice            90000
  # Dave             80000

=head2 Aggregation and GROUP BY

  my $rows = $dbh->selectall_arrayref(<<'SQL', {Slice=>{}});
  SELECT department,
         COUNT(*) AS cnt,
         AVG(salary) AS avg_sal,
         MAX(salary) AS top_sal
  FROM employee
  GROUP BY department
  ORDER BY avg_sal DESC
  SQL

  for my $r (@$rows) {
      printf "%-15s  n=%d  avg=%d  max=%d\n",
          $r->{department}, $r->{cnt}, $r->{avg_sal}, $r->{top_sal};
  }

=head2 JOIN

  $dbh->do("CREATE TABLE dept (
      code  VARCHAR(30) NOT NULL,
      mgr   VARCHAR(50)
  )");
  $dbh->do("INSERT INTO dept (code,mgr) VALUES (?,?)", 'Engineering', 'Alice');
  $dbh->do("INSERT INTO dept (code,mgr) VALUES (?,?)", 'HR',          'Carol');

  my $rows = $dbh->selectall_arrayref(<<'SQL', {Slice=>{}});
  SELECT e.name, e.salary, d.mgr
  FROM employee AS e
  LEFT JOIN dept AS d ON e.department = d.code
  ORDER BY e.name
  SQL

What a JOIN accepts is narrower than the rest of the SELECT support, so it
is worth stating plainly:

=over 4

=item *

The C<ON> clause is B<one equality between two table-qualified columns>.
Either operand order is fine (C<ON e.department = d.code> and
C<ON d.code = e.department> are the same join).  A second condition, a
comparison other than C<=>, an unqualified name, C<USING> and
C<NATURAL> are all rejected with an error.  Put any further restriction in
the C<WHERE> clause.

=item *

C<CROSS JOIN> needs no C<ON>; every other join type requires one.  An
C<ON> written on a C<CROSS JOIN> is accepted and ignored.

=item *

C<FULL OUTER JOIN> is not supported.  Combine a C<LEFT JOIN> and a
C<RIGHT JOIN> with C<UNION> instead.

=item *

The C<WHERE> clause of a JOIN query takes AND-separated comparisons
between a column and a column or literal, plus C<IN>, C<NOT IN>, C<LIKE>,
C<BETWEEN> and C<IS [NOT] NULL>.  C<OR>, C<NOT> and parentheses are
rejected with an error.

=item *

The select list takes column names, C<*> and C<table.*>.  An expression or
an C<AS> alias is rejected, B<except> in an aggregate query (one with
C<GROUP BY>, C<HAVING> or an aggregate function), where C<AS> works
normally.

=item *

C<SELECT DISTINCT> and a multi-key C<ORDER BY> both work.

=back

Every construct listed above as rejected returns an error naming the
offending text.  Up to 1.08 most of them were accepted and quietly turned
into a Cartesian product or an unfiltered result; see
L</"BUGS AND LIMITATIONS">.

=head2 Anti-join with LEFT JOIN

  # Employees whose department is not in the dept table
  my $rows = $dbh->selectall_arrayref(<<'SQL', {Slice=>{}});
  SELECT e.name
  FROM employee AS e
  LEFT JOIN dept AS d ON e.department = d.code
  WHERE d.code IS NULL
  ORDER BY e.name
  SQL

=head2 Subquery

  # Employees earning above the company average
  my $rows = $dbh->selectall_arrayref(<<'SQL', {Slice=>{}});
  SELECT name, salary
  FROM employee
  WHERE salary > (SELECT AVG(salary) FROM employee)
  ORDER BY salary DESC
  SQL

=head2 Error handling with RaiseError

  use DB::Handy;
  my $dbh = DB::Handy->connect('./data', 'mydb', {RaiseError => 1});
  eval {
      $dbh->do("INSERT INTO employee (id,name) VALUES (?,?)", 1, 'Dup');
  };
  if ($@) {
      print "Caught: $@";   # UNIQUE constraint violated
  }

=head2 Using the low-level API

  use DB::Handy;
  my $db = DB::Handy->new(base_dir => './data');
  $db->execute("USE hr");

  my $res = $db->execute(
      "SELECT department, COUNT(*) AS n FROM employee GROUP BY department");
  if ($res->{type} eq 'rows') {
      for my $r (@{ $res->{data} }) {
          print "$r->{department}: $r->{n}\n";
      }
  }
  elsif ($res->{type} eq 'error') {
      die $res->{message};
  }

=head2 Reclaiming space with VACUUM

  $dbh->do("DELETE FROM employee WHERE salary < 70000");

  # The .dat file still contains tombstone records.
  # Remove them to reclaim disk space:
  my $kept = $dbh->{_engine}->vacuum('employee');
  print "$kept active rows retained\n";

=head1 DIFFERENCES FROM DBI

DB::Handy provides a I<DBI-inspired> interface but is B<not> a DBI driver
and does B<not> require the L<DBI> module.  This section gives a detailed
account of every known incompatibility.  See also L</"DBI COMPATIBILITY">
for the overview table.

A few entries below record the opposite: a place where DBI users often
expect a difference and there is none.  Those entries say so explicitly.

=head2 dbi:Handy DSN

C<connect> accepts a C<dbi:Handy:key=val;...> prefix in addition to a
plain directory path or a bare C<key=val;...> parameter string.
Recognised DSN keys:

  Key          Meaning
  -----------  --------------------------------------------------
  dir          Base storage directory (alias for base_dir)
  base_dir     Base storage directory
  db           Database name (alias for database)
  database     Database name

Examples:

  DB::Handy->connect('dbi:Handy:dir=./data;db=mydb', undef);
  DB::Handy->connect('dbi:Handy:base_dir=./data;database=mydb', undef);
  DB::Handy->connect('dir=./data;db=mydb');       # no dbi:Handy: prefix
  DB::Handy->connect('./data', 'mydb');            # positional args

Note: DB::Handy cannot be loaded as a DBI driver via C<DBI->connect>;
use C<DB::Handy->connect> directly.

=head2 No transaction support

DBI provides C<begin_work>, C<commit>, and C<rollback> to group statements
into atomic transactions.  DB::Handy B<always operates in AutoCommit mode>:
every INSERT, UPDATE, and DELETE is immediately written to disk.  The
C<begin_work>, C<commit>, and C<rollback> methods are implemented and return
C<undef> with C<errstr> set rather than crashing.  C<AutoCommit> always
returns C<1>.

=head2 Column order

DB::Handy presents columns in the order they are declared in
C<CREATE TABLE>:

  # Named SELECT list: order follows the SELECT list
  # "SELECT salary, name FROM emp" -> NAME = ['salary', 'name']

  # SELECT *: order follows CREATE TABLE declaration order
  # "SELECT * FROM emp" -> NAME = ['id', 'name', 'dept', 'salary']

  # JOIN with SELECT *: table appearance order, each in CREATE order
  # "SELECT * FROM emp AS e JOIN dept AS d ON ..."
  #   -> NAME = ['e.id', 'e.name', 'e.dept', 'e.salary',
  #               'd.did', 'd.dname', 'd.budget']

No difference here: this is what DBI drivers do.  The entry exists because
earlier releases of DB::Handy sorted the names alphabetically instead.

The one exception is an aggregate query over a JOIN, whose rows are keyed
by the select-list alias rather than by C<alias.col>; the order still
follows the select list.

=head2 RaiseError / PrintError are standalone

In DBI, C<RaiseError> and C<PrintError> are managed by the DBI framework
itself and fire for all error paths.  In DB::Handy these attributes are
implemented only in the connection-handle and statement-handle code; some
low-level engine errors may not trigger them.

=head2 last_insert_id semantics

DBI's C<last_insert_id> returns the auto-generated key value from the
most recent INSERT.  DB::Handy's C<last_insert_id> accepts the same four
arguments (C<$catalog, $schema, $table, $field>) but ignores them and
instead returns the row count of the most recent INSERT (always 1 for a
single-row insert, or the total count for INSERT...SELECT).

=head2 table_info and column_info return array-refs, not statement handles

DBI's C<table_info> and C<column_info> return a statement handle that
must be fetched with the usual C<fetch*> methods.  DB::Handy returns a
plain array-ref directly.

=head2 INSERT without a column list

Standard SQL and DBI drivers support C<INSERT INTO t VALUES (v1, v2, ...)>
without an explicit column list.  DB::Handy also supports this form;
values are assigned to columns in C<CREATE TABLE> declaration order.
If the number of values does not match the number of columns, an error
is returned.  No difference here; the entry exists only because the form
is easy to assume unsupported in a driver this small.

=head2 INTERSECT / EXCEPT

C<INTERSECT>, C<INTERSECT ALL>, C<EXCEPT>, and C<EXCEPT ALL> are
supported in addition to C<UNION> and C<UNION ALL>.
These follow standard SQL set-operation semantics.  DBI is not a SQL
engine and imposes nothing here, so there is no DBI behaviour to differ
from; the entry records the support because most small drivers lack it.

The branches of a set operation are matched B<by position>, and the result
column names come from the first branch, as SQL requires.  Up to 1.08 they
were matched by column name, so a branch whose column names differed from
the first branch's contributed rows of C<NULL>.

=head2 VARCHAR is always 255 bytes on disk

Regardless of the declared C<VARCHAR(n)>, DB::Handy stores every VARCHAR
value in a fixed 255-byte field on disk.  There is no variable-length
storage.  However, the declared size B<is> enforced on INSERT and UPDATE:
a value longer than the declared C<n> causes an error.  C<VARCHAR> without
a size and C<VARCHAR(255)> accept any value up to 255 bytes.

=head2 No WINDOW functions

SQL window functions (C<ROW_NUMBER()>, C<RANK()>, C<PARTITION BY>, etc.)
are not supported.  Any C<SELECT> containing an C<OVER (...)> clause
returns a C<type='error'> result with a message explaining the limitation.
Use C<GROUP BY> with aggregate functions (C<SUM>, C<COUNT>, C<AVG>, etc.)
as an alternative.

=head2 No FOREIGN KEY or VIEW

B<FOREIGN KEY>: The C<REFERENCES> and C<FOREIGN KEY ... REFERENCES> syntax
is accepted in C<CREATE TABLE> for SQL compatibility, but the constraint is
B<not enforced>.  INSERT and UPDATE succeed regardless of whether the
referenced row exists.  The C<CREATE TABLE> success message includes a note
that the constraint is not enforced.

B<VIEW>: C<CREATE VIEW> returns a C<type='error'> result.

=head2 No BLOB / CLOB

There is no large-object storage type.  VARCHAR is the largest type and
is limited to 255 bytes.

=head1 DIAGNOSTICS

=head2 Error attributes

Error handling in DB::Handy via the DBI-like API is controlled by the
C<RaiseError> and C<PrintError> attributes.

=over 4

=item C<RaiseError> (set to 1)

If an error occurs (e.g., SQL syntax error, missing table, unique constraint
violation), the module will call C<die> with the error message.
It is highly recommended to enable this and use C<eval { ... }> to catch
exceptions.

=item C<PrintError> (set to 1)

If an error occurs, the module will call C<warn> with the error message, but
execution will continue (methods will return C<undef>).

=back

=head2 Error variables

  $DB::Handy::errstr         last error from any handle (package-level)
  $dbh->errstr               last error on this connection handle
  $sth->errstr               last error on this statement handle

The two handle-level accessors are set on every failed operation and
cleared on success.  The package-level C<$DB::Handy::errstr> is only ever
overwritten by the next error, so it still holds the last error seen by
I<any> handle after a subsequent success; test the handle accessor, or the
return value of the method, rather than the package variable.

=head2 Common error messages

=over 4

=item C<No database selected>

A table operation was attempted before calling C<use_database> (or before
connecting to a named database).

=item C<Table 'E<lt>nameE<gt>' already exists>

C<create_table> (or C<CREATE TABLE>) was called for a table that already has
a C<.sch> file.

=item C<Table 'E<lt>nameE<gt>' does not exist>

A DML or DDL operation referenced a table for which no C<.sch> file was found.

=item C<UNIQUE constraint violated on 'E<lt>idxnameE<gt>' ...>

An INSERT or UPDATE would have created a duplicate value in a column covered
by a UNIQUE index.  The index behind a C<PRIMARY KEY> is named
C<< <column>_pk >> and the one behind a C<UNIQUE> column or table
constraint is named C<< <column>_unique >>.

=item C<called with E<lt>nE<gt> bind variables when E<lt>mE<gt> are needed>

C<< $sth->execute >> was given a number of values that does not match the
number of C<?> placeholders in the statement.

=item C<ORDER BY position E<lt>nE<gt> is not in the select list>

A numeric C<ORDER BY> key referred to a select-list position that does not
exist.  Positions start at 1, and they cannot be used with C<SELECT *>
across a JOIN.

=item C<NOT NULL constraint violated on column 'E<lt>colE<gt>'>

An INSERT or UPDATE supplied a NULL or empty string for a column declared
C<NOT NULL>.

=item C<Subquery returns more than one row>

A scalar subquery (used in a context that expects a single value) returned
multiple rows.

=item C<Cannot parse column def: E<lt>textE<gt>>

The C<CREATE TABLE> parser could not interpret a column definition.

=item C<Unsupported SQL: E<lt>sqlE<gt>>

The SQL string does not match any known pattern.

=item C<Invalid database name 'E<lt>nameE<gt>'>

A database name was passed to C<new>, C<create_database>, C<use_database>
or C<drop_database> that is not a plain identifier.  Names are restricted
to word characters (C<[A-Za-z0-9_]>) because they are used directly as
directory names; C<..>, C</> and C<\\> are therefore rejected.

=item C<Invalid table name 'E<lt>nameE<gt>'>

A table name that is not a plain identifier was passed to C<create_table>,
C<drop_table>, or to any method that loads a schema.  See
C<Invalid database name> above for the rule.

=item C<Invalid index name 'E<lt>nameE<gt>'>

An index name that is not a plain identifier was passed to C<create_index>
or C<drop_index>.  See C<Invalid database name> above for the rule.

=item C<Database 'E<lt>nameE<gt>' already exists>

C<create_database> was called for a database directory that already exists.

=item C<Database 'E<lt>nameE<gt>' does not exist>

C<connect> or C<drop_database> was called for a database directory that
does not exist.

=item C<Cannot open base_dir: E<lt>reasonE<gt>>

The base directory passed to C<new> (or C<connect>) could not be opened.
Check that the path exists and that the process has read permission.

=item C<Cannot open dat 'E<lt>fileE<gt>': E<lt>reasonE<gt>>

A C<.dat> record file could not be opened for reading or writing.
Check file permissions and disk space.

=item C<Cannot read schema: E<lt>reasonE<gt>>

A C<.sch> schema file exists but could not be read.
Check file permissions.

=item C<Cannot create base_dir: E<lt>reasonE<gt>>

C<new> could not create the base directory.
Check parent-directory write permissions.

=item C<Cannot create database 'E<lt>nameE<gt>': E<lt>reasonE<gt>>

C<create_database> could not create the database subdirectory.
Check disk space and write permissions on C<base_dir>.

=item C<Cannot drop database 'E<lt>nameE<gt>': E<lt>reasonE<gt>>

C<drop_database> could not remove the database directory tree.
Check that no files are locked and that write permission is granted.

=item C<DB::Handy connect failed: E<lt>messageE<gt>>

The low-level C<connect> call failed.  C<$DB::Handy::errstr> contains
the underlying error set by the failing operation.

=item C<DB::Handy: E<lt>messageE<gt>>

A fatal internal error was raised directly via C<die>.
C<RaiseError> must be enabled (the default) for this message to propagate.

=item C<AutoCommit cannot be turned off: DB::Handy has no transactions>

C<connect> was called with C<AutoCommit =E<gt> 0>.  DB::Handy has no
transactions, so the request cannot be honoured and the connection is
refused rather than accepted with a promise it could not keep.

=item C<Value too long for column 'E<lt>colE<gt>': declared E<lt>typeE<gt>(E<lt>nE<gt>), got E<lt>mE<gt> bytes>

An C<INSERT> or C<UPDATE> supplied a value longer than the declared
C<CHAR> or C<VARCHAR> size.  The value is rejected; it is never truncated.

=item C<Integer out of range for column 'E<lt>colE<gt>': 'E<lt>valueE<gt>' ...>

An C<INSERT> or C<UPDATE> supplied a value outside the range the declared
integer type can hold.

=item C<Invalid DATE for column 'E<lt>colE<gt>': 'E<lt>valueE<gt>' (expected YYYY-MM-DD)>

A C<DATE> column was given a value that is not an ISO-8601 calendar date.

=item C<CHECK constraint failed on column 'E<lt>colE<gt>'>

An C<INSERT> or C<UPDATE> supplied a value the column's C<CHECK>
expression rejected.

=item C<FULL OUTER JOIN is not supported ...>

=item C<NATURAL JOIN is not supported ...>

=item C<JOIN ... USING is not supported ...>

=item C<Unsupported JOIN condition 'ON E<lt>exprE<gt>' ...>

=item C<Unqualified column in the ON clause of JOIN E<lt>tableE<gt> ...>

=item C<Unsupported WHERE condition in a JOIN query: 'E<lt>partE<gt>' ...>

=item C<Unsupported select item 'E<lt>itemE<gt>' in a JOIN query ...>

=item C<Unknown ORDER BY column 'E<lt>colE<gt>' in a JOIN query>

The query used a JOIN construct the engine cannot execute.  See
L</JOIN> for what a JOIN accepts.  Each of these messages names the
offending text and says what to write instead.  Before 1.09 these
constructs were accepted and quietly answered a different question, so
code that used to "work" may now report an error; see L</BUGS AND
LIMITATIONS>.

=item C<Each SELECT of a set operation must return the same number of columns (E<lt>nE<gt> and E<lt>mE<gt>)>

The branches of a C<UNION>, C<INTERSECT> or C<EXCEPT> disagree on how
many columns they return.

=back

=head1 BUGS AND LIMITATIONS

Please report any bugs or feature requests by e-mail to
E<lt>ina.cpan@gmail.comE<gt>.

When reporting a bug, please include:

=over 4

=item *

A minimal, self-contained test script that reproduces the problem.

=item *

The version of DB::Handy:

  perl -MDB::Handy -e 'print DB::Handy->VERSION, "\n"'

=item *

Your Perl version:

  perl -V

=item *

Your operating system and file system (Windows NTFS, Linux ext4, etc.)

=back

Known limitations:

=over 4

=item *

B<A JOIN accepts only a single-equality C<ON> clause.>  The condition has
to be one C<=> between two table-qualified columns; either operand order
is accepted.  A second condition, any other comparison operator, an
unqualified name, C<USING> and C<NATURAL> are rejected with an error, as
is C<FULL OUTER JOIN>.  Move extra restrictions into the C<WHERE> clause,
and build a full outer join from a C<LEFT JOIN> and a C<RIGHT JOIN>
combined with C<UNION>.

=item *

B<The C<WHERE> clause of a JOIN query does not accept C<OR>, C<NOT> or
parentheses.>  It takes AND-separated comparisons between a column and a
column or literal, plus C<IN>, C<NOT IN>, C<LIKE>, C<BETWEEN> and
C<IS [NOT] NULL>.  Anything else is rejected with an error.  A
single-table C<WHERE> has no such restriction.

=item *

B<The select list of a non-aggregate JOIN query does not accept
expressions or C<AS> aliases.>  Column names, C<*> and C<table.*> only.
An aggregate JOIN query (C<GROUP BY>, C<HAVING> or an aggregate function)
does accept C<AS>.

=item *

B<Up to 1.08 these JOIN restrictions were silent.>  An C<ON> clause the
parser could not read, C<USING>, C<NATURAL>, C<FULL OUTER JOIN> and an
operand order of C<ON right.col = left.col> all produced a Cartesian
product; an unsupported C<WHERE> condition was dropped and the rows came
back unfiltered; C<SELECT DISTINCT> over a JOIN returned empty rows; and a
multi-key C<ORDER BY> was ignored.  1.09 answers correctly where it can
(reversed operand order, C<DISTINCT>, multi-key C<ORDER BY>,
C<IS [NOT] NULL>, C<BETWEEN>) and reports an error where it cannot.  Code
written against 1.08 that appeared to work may now raise an error -- the
error is the bug report.

=item *

B<A single-table C<WHERE> clause is not syntax-checked.>  The JOIN parser
rejects a condition it cannot read, but the single-table parser does not:
a condition it fails to understand simply matches nothing.
C<WHERE x = 1 GARBAGE>, C<WHERE x ==== 1>, C<WHERE x = 1 AND> and
C<WHERE (x = 1> all return zero rows instead of reporting a syntax error,
so a typo in a C<WHERE> clause looks like a query that legitimately found
nothing.  C<DELETE> and C<UPDATE> are affected in the safe direction --
an unreadable condition matches no rows, so nothing is changed or
removed -- but a C<SELECT> gives a plausible empty answer to a question
it never asked.  Until this is fixed, treat an unexpected empty result
set as a possible typo and check the C<WHERE> clause before concluding
that the table holds no matching rows.

=item *

B<Set-operation branches are matched by position.>  C<UNION>,
C<UNION ALL>, C<INTERSECT> and C<EXCEPT> line the branches up by column
position and take the result column names from the first branch, as SQL
requires.  Up to 1.08 they were matched by column name, so
C<SELECT a FROM t1 UNION SELECT b FROM t2> returned C<NULL> for every row
contributed by the second branch.  A mismatch in the number of columns is
now an error.

=item *

B<No transaction support.>  C<begin_work>, C<commit>, and C<rollback>
are implemented and return C<undef> with C<errstr> set rather than
crashing.  C<AutoCommit> always returns C<1>.  Every write is
immediately committed.

=item *

B<VARCHAR is always 255 bytes on disk.>  Declaring C<VARCHAR(10)> does not
save disk space; the full 255 bytes are always reserved per record.
However, the declared size I<is> enforced on INSERT and UPDATE: a value
longer than C<n> causes an error.  C<VARCHAR> without a size and
C<VARCHAR(255)> accept any value up to 255 bytes.

=item *

B<C<NULL> is represented as the empty string.>  There is no separate NULL
marker on disk.  For C<CHAR>, C<VARCHAR> and C<DATE> columns a NULL value
and an empty string are the same value, and C<IS NULL> is true for both.
For C<INT> and C<FLOAT> columns a NULL value is stored as C<0> and reads
back as C<0>, so C<NULL> and C<0> cannot be told apart and C<IS NULL> is
never true for a numeric column.  Use a companion C<CHAR(1)> flag column
if a numeric column has to distinguish "unknown" from zero.

=item *

B<Aggregates over an empty set return C<0>, not C<NULL>.>  C<SUM>, C<AVG>,
C<MIN> and C<MAX> return C<0> when no row qualifies; SQL-92 requires
C<NULL> for these four and C<0> only for C<COUNT>.  C<COUNT(col)> and
C<COUNT(DISTINCT col)> do skip NULL values, as SQL-92 requires.

=item *

B<C<LIKE> is case-insensitive.>  SQL-92 compares C<LIKE> patterns using
the column collation, which is normally case-sensitive.  DB::Handy always
matches without regard to case, so C<LIKE 'abc'> and C<LIKE 'ABC'> select
the same rows.  Wrap the column in C<UPPER()> or C<LOWER()> on both sides
if a deterministic comparison is needed.

=item *

B<A column name that does not exist yields C<NULL> instead of an error.>
C<SELECT nosuchcol FROM t> returns one C<NULL> per row rather than
failing, so a typo in a column name is silent.

=item *

B<C<FLOAT> data files are not portable between machines.>  C<INT> columns
and every index file are written in a fixed byte order, but C<FLOAT>
values in the C<.dat> file use the machine's native 8-byte double.  A
C<.dat> file holding C<FLOAT> columns is therefore readable only on
machines with the same floating-point representation and byte order.
Copying such a file between a little-endian and a big-endian machine will
misread those columns.  This is kept as-is so that data files written by
earlier releases stay readable; C<INT>, C<CHAR>, C<VARCHAR> and C<DATE>
columns are unaffected.

=item *

B<An unterminated C</*> comments out the rest of the statement.>
C<--> to end of line and C</* ... */> are stripped before parsing
(a marker inside a string literal is left alone), but a C</*> with no
closing C<*/> silently swallows everything after it instead of raising
a syntax error.

=item *

B<Declared column sizes are counted in bytes, not characters.>  DB::Handy
stores byte strings and never decodes them, so a C<VARCHAR(10)> column
holds ten bytes.  Three Japanese characters encoded in UTF-8 occupy nine
bytes and fit; six characters occupy eighteen bytes and are rejected.
The same applies to C<CHAR> and to the C<keysize> of an index.  Decode to
characters in your own code if you need character-based limits.

=item *

B<A trailing NUL byte in a value is not preserved.>  C<CHAR>, C<VARCHAR>
and C<DATE> values are padded with NUL bytes on disk, and the padding is
stripped when the record is read back, so a value that legitimately ends
in C<"\0"> loses those bytes.  Interior NUL bytes are preserved.

=item *

B<A table created before 1.09 has no PRIMARY KEY index.>  C<PRIMARY KEY>
and C<UNIQUE> are enforced through an index that C<CREATE TABLE> builds,
so a C<.sch> file written by DB::Handy 1.08 or earlier still accepts
duplicate keys.  The data files are otherwise unchanged and are read and
written normally; add C<CREATE UNIQUE INDEX> to an older table if the
constraint is wanted there too.

=item *

B<C<ORDER BY> by position does not work with C<SELECT *> across a JOIN.>
The combined column list of the joined tables is not known at the point
the sort key is parsed, so the position is reported as an error.  Name
the column instead.  Positions do work with C<SELECT *> on a single
table, and with an explicit select list anywhere.

=item *

B<No FOREIGN KEY constraints or VIEW support.>

=item *

B<No WINDOW functions> (ROW_NUMBER, RANK, LEAD, LAG, etc.).

=item *

B<No BLOB/CLOB> large-object types.

=item *

B<Single-column indexes only.>  Composite (multi-column) indexes are not
supported.

=item *

B<NOT IN with C<NULL> in the value list returns no rows>, as SQL
semantics require.  C<col NOT IN (v1, NULL, v2)> is UNKNOWN for every
row when the value is not found in the non-NULL elements, so no row
matches.  When the column is indexed the engine falls back to a full
table scan before applying this rule.

=item *

B<No query planner.>  All queries have fixed execution plans; there is no
cost-based optimiser.

=item *

B<The return value of C<flock> is not checked.>  Every read takes a
shared lock and every write an exclusive lock on the C<.dat> file and on
each index file, and a write is flushed before the lock is released, so
concurrent access is serialised wherever C<flock> works.  Where it does
not -- NFS with no lock daemon, some network shares, a platform that
implements C<flock> as a no-op -- the call fails silently and the access
proceeds unlocked, so two processes writing the same table at the same
time can interleave.  The failure is ignored on purpose, because raising
an error would make the module unusable on those file systems for the
single-process use it is designed for; assume a single writer if the
data directory is not on a local file system.

=item *

Cannot be used as a drop-in replacement via C<DBI-E<gt>connect>.

=back

=head1 SEE ALSO

L<DBI> - the standard Perl database interface that DB::Handy's API is
modelled after.

L<DBD::SQLite> - a full-featured, embeddable SQL database accessible via DBI,
recommended when transaction support or a richer SQL dialect is needed.

Other modules by the same author:

L<HTTP::Handy>, L<LTSV::LINQ>, L<mb>, L<UTF8::R2>,
L<Jacode>, L<Jacode4e>, L<Jacode4e::RoundTrip>, L<mb::JSON>

=head1 AUTHOR

INABA Hitoshi E<lt>ina.cpan@gmail.comE<gt>

This project was originated by INABA Hitoshi.

=head1 COPYRIGHT AND LICENSE

This software is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
