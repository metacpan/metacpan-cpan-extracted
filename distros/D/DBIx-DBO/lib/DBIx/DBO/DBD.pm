package # hide from PAUSE
    DBIx::DBO::DBD;

use strict;
use warnings;
use Carp 'croak';
use Scalar::Util 'blessed';
use constant PLACEHOLDER => "\x{b1}\x{a4}\x{221e}";

our @CARP_NOT = qw(DBIx::DBO DBIx::DBO::DBD DBIx::DBO::Table DBIx::DBO::Query DBIx::DBO::Row);
*DBIx::DBO::CARP_NOT = \@CARP_NOT;
*DBIx::DBO::Table::CARP_NOT = \@CARP_NOT;
*DBIx::DBO::Query::CARP_NOT = \@CARP_NOT;
*DBIx::DBO::Row::CARP_NOT = \@CARP_NOT;

our $placeholder = PLACEHOLDER;
$placeholder = qr/\Q$placeholder/;

sub _isa {
    my($me, @class) = @_;
    if (blessed $me) {
        $me->isa($_) and return 1 for @class;
    }
}

sub _init_dbo {
    my($class, $me) = @_;
    return $me;
}

sub _get_table_schema {
    my($class, $me, $schema, $table) = @_;

    my $q_schema = $schema;
    my $q_table = $table;
    $q_schema =~ s/([\\_%])/\\$1/g if defined $q_schema;
    $q_table =~ s/([\\_%])/\\$1/g;

    # First try just these types
    my $info = $me->rdbh->table_info(undef, $q_schema, $q_table,
        'TABLE,VIEW,GLOBAL TEMPORARY,LOCAL TEMPORARY,SYSTEM TABLE')->fetchall_arrayref;
    # Then if we found nothing, try any type
    $info = $me->rdbh->table_info(undef, $q_schema, $q_table)->fetchall_arrayref if $info and @$info == 0;
    croak 'Invalid table: '.$class->_qi($me, $schema, $table) unless $info and @$info == 1 and $info->[0][2] eq $table;
    return $info->[0][1];
}

sub _get_column_info {
    my($class, $me, $schema, $table) = @_;

    my $cols = $me->rdbh->column_info(undef, $schema, $table, '%');
    $cols = $cols && $cols->fetchall_arrayref({}) || [];
    croak 'Invalid table: '.$class->_qi($me, $schema, $table) unless @$cols;

    return map { $_->{COLUMN_NAME} => $_->{ORDINAL_POSITION} } @$cols;
}

sub _get_table_info {
    my($class, $me, $schema, $table) = @_;

    my %h;
    $h{Column_Idx} = { $class->_get_column_info($me, $schema, $table) };
    $h{Columns} = [ sort { $h{Column_Idx}{$a} <=> $h{Column_Idx}{$b} } keys %{$h{Column_Idx}} ];

    $h{PrimaryKeys} = [];
    $class->_set_table_key_info($me, $schema, $table, \%h);

    return $me->{TableInfo}{defined $schema ? $schema : ''}{$table} = \%h;
}

sub _set_table_key_info {
    my($class, $me, $schema, $table, $h) = @_;

    if (my $sth = $me->rdbh->primary_key_info(undef, $schema, $table)) {
        $h->{PrimaryKeys}[$_->{KEY_SEQ} - 1] = $_->{COLUMN_NAME} for @{$sth->fetchall_arrayref({})};
    }
}

sub _unquote_table {
    my($class, $me, $table) = @_;
    # TODO: Better splitting of: schema.table or `schema`.`table` or "schema"."table"@"catalog" or ...
    $table =~ /^(?:("|)(.+)\1\.|)("|)(.+)\3$/ or croak "Invalid table: \"$table\"";
    return ($2, $4);
}

sub _selectrow_array {
    my($class, $me, $sql, $attr, @bind) = @_;
    $class->_sql($me, $sql, @bind);
    $me->rdbh->selectrow_array($sql, $attr, @bind);
}

sub _selectrow_arrayref {
    my($class, $me, $sql, $attr, @bind) = @_;
    $class->_sql($me, $sql, @bind);
    $me->rdbh->selectrow_arrayref($sql, $attr, @bind);
}

sub _selectrow_hashref {
    my($class, $me, $sql, $attr, @bind) = @_;
    $class->_sql($me, $sql, @bind);
    $me->rdbh->selectrow_hashref($sql, $attr, @bind);
}

sub _selectall_arrayref {
    my($class, $me, $sql, $attr, @bind) = @_;
    $class->_sql($me, $sql, @bind);
    $me->rdbh->selectall_arrayref($sql, $attr, @bind);
}

sub _selectall_hashref {
    my($class, $me, $sql, $key, $attr, @bind) = @_;
    $class->_sql($me, $sql, @bind);
    $me->rdbh->selectall_hashref($sql, $key, $attr, @bind);
}

sub _qi {
    my($class, $me, @id) = @_;
    return $me->rdbh->quote_identifier(@id) if $me->config('QuoteIdentifier');
    # Strip off any null/undef elements (ie schema)
    shift(@id) while @id and not (defined $id[0] and length $id[0]);
    return join '.', @id;
}

sub _sql {
    my $class = shift;
    my $me = shift;
    if (my $hook = $me->config('HookSQL')) {
        $hook->($me, @_);
    }
    my $dbg = $me->config('DebugSQL') or return;
    my($sql, @bind) = @_;

    require Carp::Heavy if eval "$Carp::VERSION < 1.12";
    my $loc = Carp::short_error_loc();
    my %i = Carp::caller_info($loc);
    my $trace;
    if ($dbg > 1) {
        $trace = "\t$i{sub_name} called at $i{file} line $i{line}\n";
        $trace .= "\t$i{sub_name} called at $i{file} line $i{line}\n" while %i = Carp::caller_info(++$loc);
    } else {
        $trace = "\t$i{sub} called at $i{file} line $i{line}\n";
    }
    warn $sql."\n(".join(', ', map $me->rdbh->quote($_), @bind).")\n".$trace;
}

sub _do {
    my($class, $me, $sql, $attr, @bind) = @_;
    $class->_sql($me, $sql, @bind);
    $me->dbh->do($sql, $attr, @bind);
}

sub _build_sql_select {
    my($class, $me) = @_;
    my $sql = 'SELECT '.$class->_build_show($me);
    $sql .= ' FROM '.$class->_build_from($me);
    my $clause;
    $sql .= ' WHERE '.$clause if $clause = $class->_build_where($me);
    $sql .= ' GROUP BY '.$clause if $clause = $class->_build_group($me);
    $sql .= ' HAVING '.$clause if $clause = $class->_build_having($me);
    $sql .= ' ORDER BY '.$clause if $clause = $class->_build_order($me);
    $sql .= ' '.$clause if $clause = $class->_build_limit($me);
    return $sql;
}

sub _bind_params_select {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    map {
        exists $h->{$_} ? @{$h->{$_}} : ()
    } qw(Show_Bind From_Bind Where_Bind Group_Bind Having_Bind Order_Bind);
}

sub _build_sql_update {
    my($class, $me, @arg) = @_;
    croak 'Update is not valid with a GROUP BY clause' if $class->_build_group($me);
    croak 'Update is not valid with a HAVING clause' if $class->_build_having($me);
    my $sql = 'UPDATE '.$class->_build_from($me);
    $sql .= ' SET '.$class->_build_set($me, @arg);
    my $clause;
    $sql .= ' WHERE '.$clause if $clause = $class->_build_where($me);
    $sql .= ' ORDER BY '.$clause if $clause = $class->_build_order($me);
    $sql .= ' '.$clause if $clause = $class->_build_limit($me);
    $sql;
}

sub _bind_params_update {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    map {
        exists $h->{$_} ? @{$h->{$_}} : ()
    } qw(From_Bind Set_Bind Where_Bind Order_Bind);
}

sub _build_sql_delete {
    my($class, $me) = @_;
    croak 'Delete is not valid with a GROUP BY clause' if $class->_build_group($me);
    my $sql = 'DELETE FROM '.$class->_build_from($me);
    my $clause;
    $sql .= ' WHERE '.$clause if $clause = $class->_build_where($me);
    $sql .= ' ORDER BY '.$clause if $clause = $class->_build_order($me);
    $sql .= ' '.$clause if $clause = $class->_build_limit($me);
    $sql;
}

sub _bind_params_delete {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    map {
        exists $h->{$_} ? @{$h->{$_}} : ()
    } qw(From_Bind Where_Bind Order_Bind);
}

sub _build_table {
    my($class, $me, $t) = @_;
    my $from = $t->_from($me->{build_data});
    my $alias = $me->_table_alias($t);
    $alias = defined $alias ? ' '.$class->_qi($me, $alias) : '';
    return $from.$alias;
}

sub _build_show {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    return $h->{show} if defined $h->{show};
    my $distinct = $h->{Show_Distinct} ? 'DISTINCT ' : '';
    undef @{$h->{Show_Bind}};
    return $h->{show} = $distinct.'*' unless @{$h->{Showing}};
    my @flds;
    for my $fld (@{$h->{Showing}}) {
        if (_isa($fld, 'DBIx::DBO::Table', 'DBIx::DBO::Query')) {
            push @flds, $class->_qi($me, $me->_table_alias($fld) || $fld->{Name}).'.*';
        } else {
            $h->{_subqueries}{$fld->[0][0]} = $fld->[0][0]->sql if _isa($fld->[0][0], 'DBIx::DBO::Query');
            push @flds, $class->_build_val($me, $h->{Show_Bind}, @$fld);
        }
    }
    return $h->{show} = $distinct.join(', ', @flds);
}

sub _build_from {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    return $h->{from} if defined $h->{from};
    undef @{$h->{From_Bind}};
    my @tables = $me->tables;
    $h->{from} = $class->_build_table($me, $tables[0]);
    for (my $i = 1; $i < @tables; $i++) {
        $h->{from} .= $h->{Join}[$i].$class->_build_table($me, $tables[$i]);
        $h->{from} .= ' ON '.join(' AND ', $class->_build_where_chunk($me, $h->{From_Bind}, 'OR', $h->{Join_On}[$i]))
            if $h->{Join_On}[$i];
    }
    return $h->{from};
}

sub _parse_col_val {
    my($class, $me, $col, %c) = @_;
    unless (defined $c{Aliases}) {
        (my $method = (caller(1))[3]) =~ s/.*:://;
        $c{Aliases} = $class->_alias_preference($me, $method);
    }
    return $class->_parse_val($me, $col, Check => 'Column', %c) if ref $col;
    return [ $class->_parse_col($me, $col, $c{Aliases}) ];
}

# In some cases column aliases can be used, but this differs by DB and where in the statement it's used.
# The $method is the method we were called from: (join_on|column|where|having|_del_where|order_by|group_by)
# This method provides a way for DBs to override the default which is always 1 except for join_on.
# Return values: 0 = Don't use aliases, 1 = Check aliases then columns, 2 = Check columns then aliases
sub _alias_preference {
#    my($class, $me, $method) = @_;
    return $_[2] eq 'join_on' ? 0 : 1;
}

sub _valid_col {
    my($class, $me, $col) = @_;
    # Check if the object is an alias
    return $col if $col->[0] == $me;
    # TODO: Sub-queries
    # Check if the column is from one of our tables
    for my $tbl ($me->tables) {
        return $col if $col->[0] == $tbl;
    }
    croak 'Invalid column, the column is from a table not included in this query';
}

sub _parse_col {
    my($class, $me, $col, $_check_aliases) = @_;
    if (ref $col) {
        return $class->_valid_col($me, $col) if _isa($col, 'DBIx::DBO::Column');
        croak 'Invalid column: '.$col;
    }
    # If $_check_aliases is not defined dont accept an alias
    $me->_inner_col($col, $_check_aliases || 0);
}

sub _build_col {
    my($class, $me, $col) = @_;
    $class->_qi($me, $me->_table_alias($col->[0]), $col->[1]);
}

sub _parse_val {
    my($class, $me, $fld, %c) = @_;
    $c{Check} = '' unless defined $c{Check};

    my $func;
    my $opt;
    if (ref $fld eq 'SCALAR') {
        croak 'Invalid '.($c{Check} eq 'Column' ? 'column' : 'field').' reference (scalar ref to undef)'
            unless defined $$fld;
        $func = $$fld;
        $fld = [];
    } elsif (ref $fld eq 'HASH') {
        $func = $fld->{FUNC} if exists $fld->{FUNC};
        $opt->{AS} = $fld->{AS} if exists $fld->{AS};
        if (exists $fld->{ORDER}) {
            croak 'Invalid ORDER, must be ASC or DESC' if $fld->{ORDER} !~ /^(A|DE)SC$/i;
            $opt->{ORDER} = uc $fld->{ORDER};
        }
        $opt->{COLLATE} = $fld->{COLLATE} if exists $fld->{COLLATE};
        if (exists $fld->{COL}) {
            croak 'Invalid HASH containing both COL and VAL' if exists $fld->{VAL};
            my @cols = ref $fld->{COL} eq 'ARRAY' ? @{$fld->{COL}} : $fld->{COL};
            $fld = [ map $class->_parse_col($me, $_, $c{Aliases}), @cols ];
        } else {
            $fld = exists $fld->{VAL} ? $fld->{VAL} : [];
        }
    } elsif (_isa($fld, 'DBIx::DBO::Column')) {
        return [ $class->_valid_col($me, $fld) ];
    }
    $fld = [$fld] unless ref $fld eq 'ARRAY';

    # Swap placeholders
    my $with = @$fld;
    if (defined $func) {
        my $need = $class->_substitute_placeholders($me, $func);
        croak "The number of params ($with) does not match the number of placeholders ($need)" if $need != $with;
    } elsif ($with != 1 and $c{Check} ne 'Auto') {
        croak 'Invalid '.($c{Check} eq 'Column' ? 'column' : 'field')." reference (passed $with params instead of 1)";
    }
    return ($fld, $func, $opt);
}

sub _substitute_placeholders {
    my($class, $me) = @_;
    my $num_placeholders = 0;
    $_[2] =~ s/((?<!\\)(['"`]).*?[^\\]\2|\?)/$1 eq '?' ? (++$num_placeholders, PLACEHOLDER) : $1/eg;
    return $num_placeholders;
}

sub _build_val {
    my($class, $me, $bind, $fld, $func, $opt) = @_;
    my $extra = '';
    $extra .= ' COLLATE '.$me->rdbh->quote($opt->{COLLATE}) if exists $opt->{COLLATE};
    $extra .= ' AS '.$class->_qi($me, $opt->{AS}) if exists $opt->{AS};
    $extra .= " $opt->{ORDER}" if exists $opt->{ORDER};

    my @ary = map {
        if (!ref $_) {
            push @$bind, $_;
            '?';
        } elsif (_isa($_, 'DBIx::DBO::Column')) {
            $class->_build_col($me, $_);
        } elsif (ref $_ eq 'SCALAR') {
            $$_;
        } elsif (_isa($_, 'DBIx::DBO::Query')) {
            $_->_from($me->{build_data});
        } else {
            croak 'Invalid field: '.$_;
        }
    } @$fld;
    unless (defined $func) {
        die "Number of placeholders and values don't match!" if @ary != 1;
        return $ary[0].$extra;
    }
    # Add one value to @ary to make sure the number of placeholders & values match
    push @ary, 'Error';
    $func =~ s/$placeholder/shift @ary/ego;
    # At this point all the values should have been used and @ary must only have 1 item!
    die "Number of placeholders and values don't match!" if @ary != 1;
    return $func.$extra;
}

# Construct the WHERE clause
sub _build_where {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    return $h->{where} if defined $h->{where};
    undef @{$h->{Where_Bind}};
    my @where;
    push @where, $class->_build_quick_where($me, $h->{Where_Bind}, @{$h->{Quick_Where}}) if exists $h->{Quick_Where};
    push @where, $class->_build_where_chunk($me, $h->{Where_Bind}, 'OR', $h->{Where_Data}) if exists $h->{Where_Data};
    return $h->{where} = join ' AND ', @where;
}

# Construct the WHERE contents of one set of parentheses
sub _build_where_chunk {
    my($class, $me, $bind, $ag, $whs) = @_;
    my @str;
    # Make a copy so we can hack at it
    my @whs = @$whs;
    while (my $wh = shift @whs) {
        my @ary;
        if (ref $wh->[0]) {
            @ary = $class->_build_where_chunk($me, $bind, $ag eq 'OR' ? 'AND' : 'OR', $wh);
        } else {
            @ary = $class->_build_where_piece($me, $bind, @$wh);
            my($op, $fld, $fld_func, $fld_opt, $val, $val_func, $val_opt, $force) = @$wh;
            # Group AND/OR'ed for same fld if $force or $op requires it
            if ($ag eq ($force || _op_ag($op))) {
                for (my $i = $#whs; $i >= 0; $i--) {
                    # Right now this starts with the last @whs and works backwards
                    # It splices when the ag is the correct AND/OR and the funcs match and all flds match
                    next if ref $whs[$i][0] or $ag ne ($whs[$i][7] || _op_ag($whs[$i][0]));
                    no warnings 'uninitialized';
                    next if $whs[$i][2] ne $fld_func;
                    use warnings 'uninitialized';
#                    next unless $fld_func ~~ $whs[$i][2];
                    my $l = $whs[$i][1];
                    next if ((ref $l eq 'ARRAY' ? "@$l" : $l) ne (ref $fld eq 'ARRAY' ? "@$fld" : $fld));
#                    next unless $fld ~~ $whs[$i][1];
                    push @ary, $class->_build_where_piece($me, $bind, @{splice @whs, $i, 1});
                }
            }
        }
        push @str, @ary == 1 ? $ary[0] : '('.join(' '.$ag.' ', @ary).')';
    }
    return @str;
}

sub _op_ag {
    return 'OR' if $_[0] eq '=' or $_[0] eq 'IS' or $_[0] eq '<=>' or $_[0] eq 'IN' or $_[0] eq 'BETWEEN';
    return 'AND' if $_[0] eq '<>' or $_[0] eq 'IS NOT' or $_[0] eq 'NOT IN' or $_[0] eq 'NOT BETWEEN';
}

# Construct one WHERE expression
sub _build_where_piece {
    my($class, $me, $bind, $op, $fld, $fld_func, $fld_opt, $val, $val_func, $val_opt) = @_;
    $class->_build_val($me, $bind, $fld, $fld_func, $fld_opt)." $op ".$class->_build_val($me, $bind, $val, $val_func, $val_opt);
}

# Construct one WHERE expression (simple)
sub _build_quick_where {
    croak 'Wrong number of arguments' unless @_ & 1;
    my($class, $me, $bind) = splice @_, 0, 3;
    my @where;
    while (my($col, $val) = splice @_, 0, 2) {
        # FIXME: What about aliases in quick_where?
        push @where, $class->_build_col($me, $class->_parse_col($me, $col)) . do {
                if (ref $val eq 'SCALAR' and $$val =~ /^\s*(?:NOT\s+)NULL\s*$/is) {
                    ' IS ';
                } elsif (ref $val eq 'ARRAY') {
                    croak 'Invalid value argument, IN requires at least 1 value' unless @$val;
                    $val = { FUNC => '('.join(',', ('?') x @$val).')', VAL => $val };
                    ' IN ';
                } elsif (defined $val) {
                    ' = ';
                } else {
                    $val = \'NULL';
                    ' IS ';
                }
            } . $class->_build_val($me, $bind, $class->_parse_val($me, $val));
    }
    return join ' AND ', @where;
}

sub _parse_set {
    croak 'Wrong number of arguments' if @_ & 1;
    my($class, $me, @arg) = @_;
    my @update;
    my %remove_duplicates;
    while (@arg) {
        my @val = $class->_parse_val($me, pop @arg);
        my $col = $class->_parse_col($me, pop @arg);
        unshift @update, $col, \@val unless $remove_duplicates{$col}++;
    }
    return @update;
}

sub _build_set {
    my($class, $me, @arg) = @_;
    my $h = $me->_build_data;
    undef @{$h->{Set_Bind}};
    my @set;
    while (@arg) {
        push @set, $class->_build_col($me, shift @arg).' = '.$class->_build_val($me, $h->{Set_Bind}, @{shift @arg});
    }
    return join ', ', @set;
}

sub _build_group {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    return $h->{group} if defined $h->{group};
    undef @{$h->{Group_Bind}};
    return $h->{group} = join ', ', map $class->_build_val($me, $h->{Group_Bind}, @$_), @{$h->{GroupBy}};
}

# Construct the HAVING clause
sub _build_having {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    return $h->{having} if defined $h->{having};
    undef @{$h->{Having_Bind}};
    my @having;
    push @having, $class->_build_where_chunk($me, $h->{Having_Bind}, 'OR', $h->{Having_Data}) if exists $h->{Having_Data};
    return $h->{having} = join ' AND ', @having;
}

sub _build_order {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    return $h->{order} if defined $h->{order};
    undef @{$h->{Order_Bind}};
    return $h->{order} = join ', ', map $class->_build_val($me, $h->{Order_Bind}, @$_), @{$h->{OrderBy}};
}

sub _build_limit {
    my($class, $me) = @_;
    my $h = $me->_build_data;
    return $h->{limit} if defined $h->{limit};
    return $h->{limit} = '' unless defined $h->{LimitOffset};
    $h->{limit} = 'LIMIT '.$h->{LimitOffset}[0];
    $h->{limit} .= ' OFFSET '.$h->{LimitOffset}[1] if $h->{LimitOffset}[1];
    return $h->{limit};
}

sub _get_config {
    my($class, $opt, @confs) = @_;
    defined $_->{$opt} and return $_->{$opt} for @confs;
    return;
}

sub _set_config {
    my($class, $ref, $opt, $val) = @_;
    croak "Invalid value for the 'OnRowUpdate' setting"
        if $opt eq 'OnRowUpdate' and $val and $val ne 'empty' and $val ne 'simple' and $val ne 'reload';
    croak "Invalid value for the 'UseHandle' setting"
        if $opt eq 'UseHandle' and $val and $val ne 'read-only' and $val ne 'read-write';
    my $old = $ref->{$opt};
    $ref->{$opt} = $val;
    return $old;
}


# Query methods
sub _rows {
    my($class, $me) = @_;
    $me->_sth and ($me->{sth}{Executed} or $me->run)
        or croak $me->rdbh->errstr;
    my $rows = $me->_sth->rows;
    $me->{Row_Count} = $rows == -1 ? undef : $rows;
}

sub _calc_found_rows {
    my($class, $me) = @_;
    local $me->{build_data}{limit} = '';
    $me->{Found_Rows} = $me->count_rows;
}


# Table methods
sub _save_last_insert_id {
    #my($class, $me, $sth) = @_;
    # Should be provided in a DBD specific method
    # It is called after insert and must return the autogenerated ID
    #return $sth->{Database}->last_insert_id(undef, @$me{qw(Schema Name)}, undef);
}

sub _fast_bulk_insert {
    my($class, $me, $sql, $cols, %opt) = @_;

    my @vals;
    my @bind;
    if (ref $opt{rows}[0] eq 'ARRAY') {
        for my $row (@{$opt{rows}}) {
            push @vals, '('.join(', ', map $class->_build_val($me, \@bind, $class->_parse_val($me, $_)), @$row).')';
        }
    } else {
        for my $row (@{$opt{rows}}) {
            push @vals, '('.join(', ', map $class->_build_val($me, \@bind, $class->_parse_val($me, $_)), @$row{@$cols}).')';
        }
    }

    $sql .= join(",\n", @vals);
    $class->_do($me, $sql, undef, @bind);
}

sub _safe_bulk_insert {
    my($class, $me, $sql, $cols, %opt) = @_;

    # TODO: Wrap in a transaction
    my $rv;
    my $sth;
    my $prev_vals = '';
    if (ref $opt{rows}[0] eq 'ARRAY') {
        for my $row (@{$opt{rows}}) {
            my @bind;
            my $vals = '('.join(', ', map $class->_build_val($me, \@bind, $class->_parse_val($me, $_)), @$row).')';
            $class->_sql($me, $sql.$vals, @bind);
            if ($prev_vals ne $vals) {
                $sth = $me->dbh->prepare($sql.$vals) or return undef;
                $prev_vals = $vals;
            }
            $rv += $sth->execute(@bind) or return undef;
        }
    } else {
        for my $row (@{$opt{rows}}) {
            my @bind;
            my $vals = '('.join(', ', map $class->_build_val($me, \@bind, $class->_parse_val($me, $_)), @$row{@$cols}).')';
            $class->_sql($me, $sql.$vals, @bind);
            if ($prev_vals ne $vals) {
                $sth = $me->dbh->prepare($sql.$vals) or return undef;
                $prev_vals = $vals;
            }
            $rv += $sth->execute(@bind) or return undef;
        }
    }

    return $rv || '0E0';
}
*_bulk_insert = \&_safe_bulk_insert;


# Row methods
sub _reset_row_on_update {
    my($class, $me, @update) = @_;
    my $on_row_update = $me->config('OnRowUpdate') || 'simple';

    if ($on_row_update ne 'empty') {
        # Set the row values if they are simple expressions
        my @cant_update;
        for (my $i = 0; $i < @update; $i += 2) {
            # Keep a list of columns we can't update, and skip them
            next if $cant_update[ $me->_column_idx($update[0]) ] = (
                defined $update[1][1] or @{$update[1][0]} != 1 or (
                    ref $update[1][0][0] and (
                        not _isa($update[1][0][0], 'DBIx::DBO::Column')
                            or $cant_update[ $me->_column_idx($update[1][0][0]) ]
                    )
                )
            );
            my($col, $val) = splice @update, $i, 2;
            $val = $val->[0][0];
            $val = $$me->{array}[ $me->_column_idx($val) ] if ref $val;
            $$me->{array}[ $me->_column_idx($col) ] = $val;
            $i -= 2;
        }
        # If we were able to update all the columns then return
        grep $_, @cant_update or return;

        if ($on_row_update eq 'reload') {
            # Attempt reload
            my @cols = map $$me->{build_data}{Quick_Where}[$_ << 1], 0 .. $#{$$me->{build_data}{Quick_Where}} >> 1;
            my @cidx = map $me->_column_idx($_), @cols;
            unless (grep $cant_update[$_], @cidx) {
                my %bd = %{$$me->{build_data}};
                delete $bd{Where_Data};
                delete $bd{where};
                $bd{Quick_Where} = [map { $cols[$_] => $$me->{array}[ $cidx[$_] ] } 0 .. $#cols];
                my($sql, @bind) = do {
                    local $$me->{build_data} = \%bd;
                    ($class->_build_sql_select($me), $class->_bind_params_select($me));
                };
                return $me->_load($sql, @bind);
            }
        }
    }
    # If we can't update or reload then empty the Row
    undef $$me->{array};
    $$me->{hash} = {};
}

sub _build_data_matching_this_row {
    my($class, $me) = @_;
    # Identify the row by the PrimaryKeys if any, otherwise by all Columns
    my @quick_where;
    for my $tbl (@{$$me->{Tables}}) {
        for my $col (map $tbl ** $_, @{$tbl->{ @{$tbl->{PrimaryKeys}} ? 'PrimaryKeys' : 'Columns' }}) {
            my $i = $me->_column_idx($col);
            defined $i or croak 'The '.$class->_qi($me, $tbl->{Name}, $col->[1]).' field needed to identify this row, was not included in this query';
            push @quick_where, $col => $$me->{array}[$i];
        }
    }
    my %h = (
        Showing => $$me->{build_data}{Showing},
        from => $$me->{build_data}{from},
        Quick_Where => \@quick_where
    );
    $h{From_Bind} = $$me->{build_data}{From_Bind} if exists $$me->{build_data}{From_Bind};
    return \%h;
}


# require the DBD module if it exists
my %inheritance;
sub _require_dbd_class {
    my($class, $dbd) = @_;
    my $dbd_class = $class.'::'.$dbd;

    my $rv;
    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, join '', @_ };
        $rv = eval "require $dbd_class";
    }
    if ($rv) {
        warn @warn if @warn;
    } else {
        (my $file = $dbd_class.'.pm') =~ s'::'/'g;
        if ($@ !~ / \Q$file\E in \@INC /) {
            (my $err = $@) =~ s/\n.*$//; # Remove the last line
            chomp @warn;
            chomp $err;
            croak join "\n", @warn, $err, "Can't load $dbd driver";
        }

        $@ = '';
        delete $INC{$file};
        $INC{$file} = 1;
    }

    # Set the derived DBD class' inheritance
    unless (exists $inheritance{$class}{$dbd}) {
        no strict 'refs';
        unless (@{$dbd_class.'::ISA'}) {
            my @isa = map $_->_require_dbd_class($dbd), grep $_->isa(__PACKAGE__), @{$class.'::ISA'};
            @{$dbd_class.'::ISA'} = ($class, @isa);
            if (@isa) {
                mro::set_mro($dbd_class, 'c3');
                Class::C3::initialize() if $] < 5.009_005;
            }
        }
        push @CARP_NOT, $dbd_class;
        $inheritance{$class}{$dbd} = $dbd_class;
    }

    return $inheritance{$class}{$dbd};
}

1;
