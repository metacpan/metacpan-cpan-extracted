#
# $Id: OracleIO.pm,v 1.2 2002/07/20 02:37:37 rsandberg Exp $
#

package DBIx::IO::OracleIO;

use DBIx::IO;

@ISA = qw(DBIx::IO);

use strict;

use DBD::Oracle qw(
    ORA_CLOB
    ORA_BLOB
    ORA_LONG
);

use DBIx::IO::OracleLib ();
use DBIx::IO::GenLib ();

my %long_lob_types = (
    $DBIx::IO::GenLib::LONG_TYPE => ORA_LONG,
    $DBIx::IO::GenLib::BLOB_TYPE => ORA_BLOB,
    $DBIx::IO::GenLib::CLOB_TYPE => ORA_CLOB,
);

my %all_table_col_types;
my %all_table_col_defaults;
my %all_table_col_required;
my %all_table_col_lengths;
my %all_table_col_scale;
my %all_table_cols;
my %all_table_pk;
my %all_table_col_list;

my %datetime_types =
(
    $DBIx::IO::GenLib::DATETIME_TYPE => 1,
    # qualify() will not treat a date type any differently than a datetime type
    $DBIx::IO::GenLib::DATE_TYPE => 1,
    DATE => 1,
);
my %date_types =
(
    $DBIx::IO::GenLib::DATE_TYPE => 1,
    DATE => 1,
);
my %interval_types =
(
    INTERVAL => 1,
    TIMESTAMP => 1,
);
my %numeric_types =
(
    $DBIx::IO::GenLib::NUMERIC_TYPE => 1,
    NUMBER => 1,
    FLOAT => 1,
    BINARY_FLOAT => 1,
    BINARY_DOUBLE => 1,
);
my %char_types =
(
    $DBIx::IO::GenLib::CHAR_TYPE => 1,
    CHAR => 1,
    NCHAR => 1,
    VARCHAR2 => 1,
    NVARCHAR2 => 1,
    RAW => 1,
    'LONG RAW' => 1,
);
my %rowid_types =
(
    $DBIx::IO::GenLib::ROWID_TYPE => 1,
    ROWID => 1,
    UROWID => 1,
);
my %long_types =
(
    $DBIx::IO::GenLib::LONG_TYPE => 1,
    LONG => 1,
);
my %lob_types =
(
    $DBIx::IO::GenLib::LOB_TYPE => 1,
    CLOB => 1,
    BLOB => 1,
    NCLOB => 1,
);
my %ignore_types = (
    BFILE => 1,
);


=head1 NAME

DBIx::IO::OracleIO - DBIx::IO driver for Oracle

=head1 DESCRIPTION

See DBIx::IO.

=head1 METHOD DETAILS

=over 4

See superclass DBIx::IO for more


=cut
sub qualify
{
    my ($self,$val,$field,$date_format,$type) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    if (defined($type))
    {
        $type = uc($type);
    }
    else
    {
        $field = uc($field);
        my $col_types = $self->column_types();
        $type = $col_types->{$field};
    }
    defined($type) || ($self->_alert("Data type not defined"), return undef);

    if (is_long_type($type))
    {
        return '' unless length($val);
        return $val;
    }

    length($val) || return 'NULL';
    
    if (exists($rowid_types{$type}))
    {
        return "'$val'";
    }
    elsif (exists($numeric_types{$type}))
    {
        return $val;
    }
    elsif (exists($datetime_types{$type}))
    {
        return $val if uc($val) eq 'SYSDATE';
        return $val if $val =~ /^DATE\b/i;
        $date_format ||= $DBIx::IO::OracleLib::NORMAL_DATETIME_FORMAT;
        if ($date_format eq $DBIx::IO::GenLib::UNKNOWN_DATE_FORMAT)
        {
            my $parse_val = DBIx::IO::GenLib::normalize_date($val);
            length($parse_val) || ($self->_alert("The date format of: $val could not be recognized"),return undef);
            $date_format = $DBIx::IO::OracleLib::NORMAL_DATETIME_FORMAT;
            $val = $parse_val;
        }
        return "TO_DATE('$val','$date_format')";
    }
    elsif (exists($interval_types{$type}))
    {
        # Hopefully the operator knows what they're doing in this case
        return $val;
    }
    elsif (exists($char_types{$type}))
    {
        $val =~ s/\000//g;
        length($val) || return 'NULL';
        $val = $self->{dbh}->quote($val);
        return undef if $self->{dbh}->err;
        return $val;
    }
    $self->_alert("Unhandled data type: $type");
    return undef;
}

sub verify_datatype
{
    my ($self,$val,$field,$type) = @_;
    if (defined($type))
    {
        $type = uc($type);
    }
    else
    {
        $field = uc($field);
        my $col_types = $self->column_types();
        $type = $col_types->{$field};
    }
    defined($type) || ($self->_alert("Data type not defined"), return undef);

    if ($numeric_types{$type})
    {
        if ($self->{scale}{$field})
        {
            # This is a real number
            return DBIx::IO::GenLib::isreal($val);
        }
        else
        {
            return -1 unless DBIx::IO::GenLib::isint($val);
        }
    }
    return 1;
}

sub is_long_type
{
    my $type = shift;
    return (exists($lob_types{$type}) || exists($long_types{$type}));
}

sub is_lob_type
{
    my ($self,$type) = @_;
    return exists($lob_types{$type});
}

sub is_ignore_type
{
    my ($self,$type) = @_;
    return (exists($lob_types{$type}) || exists($ignore_types{$type}));
}

sub _assign_table_attrs
{
    my $self = shift;
    my $table_name = shift;
    $table_name = uc($table_name);
    my $rv;
    unless ($rv = $self->SUPER::_assign_table_attrs($table_name,@_))
    {
        return $rv;
    }

    my $table = $self->table_name();
    my $owner;
    ($table,$owner) = $self->_strip_owner($table);
    $self->{sequence_name} = ($owner ? "${owner}." : "") . "SEQ_" . uc($table);

    return 1;
}

sub column_attrs
{
    my ($self,$table) = @_;
    ref($self) || (warn("\$self not an object"),return undef);

    if (exists($all_table_col_types{$table}))
    {
        $self->{scale} = $all_table_col_scale{$table};
        $self->{defaults} = $all_table_col_defaults{$table};
        $self->{required} = $all_table_col_required{$table};
        $self->{lengths} = $all_table_col_lengths{$table};
        $self->{pk} = $all_table_pk{$table};
        $self->{select_cols} = $all_table_cols{$table};
        $self->{col_list} = $all_table_col_list{$table};
        # do not alter this hash ref!!!
        return ($self->{column_types} = $all_table_col_types{$table});
    }

    my $pksth = $self->make_cursor("SELECT cc.column_name FROM user_cons_columns cc,user_constraints c " .
        "WHERE c.constraint_name = cc.constraint_name " .
        "AND c.constraint_type = 'P' " .
        "AND cc.table_name = '$table' " .
        "AND c.status = 'ENABLED'") || return undef;
    my $res = $pksth->fetchall_arrayref() || return undef;
    return undef if $pksth->err();
    my @pk = map($_->[0],@$res);

    my $sth = $self->make_cursor("SELECT utc.column_name,utc.data_type,ut.tablespace_name,utc.data_length, " .
        "utc.data_precision,utc.data_scale,utc.nullable,utc.data_default " .
        "FROM user_tab_columns utc, user_tables ut " .
        "WHERE utc.table_name = '$table' " .
        "AND ut.table_name(+) = utc.table_name") || return undef;
    my ($col,$type,$null,$length,$prec,$scale,$default,$tablespace,%attrs,%defaults,%lengths,%required,%scale,$cols,@cols);
    while (($col,$type,$tablespace,$length,$prec,$scale,$null,$default) = $sth->fetchrow_array)
    {
        $col = uc($col);
        $type = uc($type);
        $type =~ s/\W.*// unless $type eq 'LONG RAW';
        $attrs{$col} = $type;
        $attrs{$DBIx::IO::OracleLib::ROWID_COL_NAME} = $DBIx::IO::GenLib::ROWID_TYPE if $tablespace;
        $default = $1 if $default =~ /\s*\'(.*)\'\s*/;
        $defaults{$col} = $default;
        $required{$col} = uc($null) eq 'N';
        $length = _lengthof($type,$length,$prec,$scale);
        $lengths{$col} = $length;
        $scale{$col} = $scale;
        push(@cols,$col);

        # Build a list of select columns, LOB types error out if selected via DBI so skip them
        next if $lob_types{$type} || $ignore_types{$type} || $type eq 'INTERVAL';
        $cols .= ($datetime_types{$type} ? "TO_CHAR($col,'$DBIx::IO::OracleLib::NORMAL_DATETIME_FORMAT') $col," :
            "$col,");
    }
    return undef if $sth->err;
    %attrs || ($self->_alert("table: $table doesn't seem to exist or have any columns"), return 0);
    chop $cols;

    # do not alter these hash refs!!!
##at subclasses should cache these
    $self->{scale} = $all_table_col_scale{$table} = \%scale;
    $self->{defaults} = $all_table_col_defaults{$table} = \%defaults;
    $self->{required} = $all_table_col_required{$table} = \%required;
    $self->{lengths} = $all_table_col_lengths{$table} = \%lengths;
    $self->{pk} = $all_table_pk{$table} = \@pk;
    $self->{select_cols} = $all_table_cols{$table} = $cols;
    $self->{col_list} = $all_table_col_list{$table} = \@cols;
    return ($self->{column_types} = $all_table_col_types{$table} = \%attrs);
}

sub _lengthof
{
    my ($type,$length,$prec,$scale) = @_;
    return 50 if exists($interval_types{$type});
    return 25 if $type eq 'BINARY_DOUBLE';
    return 15 if $type eq 'BINARY_FLOAT';
    return $length unless !$length || $type eq 'NUMBER' || $type eq 'FLOAT';
    my $ll = abs($prec) + abs($scale);
    if ($type eq 'NUMBER' && $prec)
    {
        # 1 for optional (-) and 1 for optional '.'
        return abs($prec) + 1 + ($scale > 0);
    }
    elsif ($type eq 'NUMBER' || $type eq 'FLOAT')
    {
        return 126;
    }
    return 255;
}

sub insert_hash
{
    my ($self,$orig_insert,$date_format) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    ref($orig_insert) || ($self->_alert("\$insert_hash not a hash ref"),return undef);
    my $insert = { %$orig_insert };
    my $attrs = $self->column_types();
    my $dbh = $self->{dbh};
    my $table = $self->table_name();
    my $pkname = $self->key_name();
    my $pk;
    if (exists($attrs->{$pkname}) && !exists($insert->{$pkname}))
    {
        $pk = $self->key_nextval();
        defined($pk) || ($self->_alert("Can't generate key for $table"), return undef);
        $insert->{$pkname} = $pk;
    }
    else
    {
        $pk = $insert->{$pkname};
    }

    %$insert || return -1.1;
    delete $insert->{ROWID};

    my ($fields,$values,$field,$qual_val,%bind);
    foreach $field (keys %$insert)
    {
        $field = uc($field);
        $fields .= "$field,";
        $qual_val = $self->qualify($insert->{$field},$field,$date_format);
        if (is_long_type($attrs->{$field}))
        {
            $bind{":$field"} = [ $field,$qual_val ];
            $qual_val = ":$field";
        }
        unless (defined($qual_val))
        {
            $self->_alert("Unable to qualify insert value: qualify($insert->{$field},$field,$date_format)");
            return undef;
        }
        $values .= "$qual_val,";
    }
    chop($fields);
    chop($values);
    my $sql = "INSERT INTO $table ($fields) VALUES ($values)";
    my $sth = $dbh->prepare($sql) || ($self->_alert("Can't prepare $sql"), return undef);
    my ($bind_field,$bind_val);
    while (($bind_field,$bind_val) = each %bind)
    {
        my ($field,$val) = @$bind_val;
        my $type = $long_lob_types{$attrs->{$field}};
        $sth->bind_param($bind_field,$val,{ ora_type => $type, ora_field => $field }) || ($self->_alert("Error binding $bind_field"), return undef);
    }
    my $rv = $sth->execute();
    unless ($rv)
    {
        if ($sth->err == 1)
        {
            return -1.4;
        }
        else
        {
            return undef;
        }
    }

    return (length($pk) ? $pk : -1.2);
}


=pod

=item C<sequence_name>

 $sequence_name = $io->sequence_name([$sequence_name]);

Get/set the name of the sequence that generates key values
for inserts. Defaults to the name of the table prepended with "SEQ_".

=cut
sub sequence_name
{
    my ($self,$sequence_name) = @_;
    if (defined($sequence_name))
    {
        return $self->{sequence_name} = $sequence_name;
    }
    return $self->{sequence_name};
}


=pod

=item C<key_nextval>

 $next_seq_val = $io->key_nextval([$seq_name]);

Returns the next value in the Oracle sequence object named
$seq_name or the table name prepended with "SEQ_"
All sequence statement handles are cached per $dbh for performance
reasons. A new $sth will be prepared unless the object that calls
this method has previously called it with the same sequence request.

Returns undef if error.

=cut
sub key_nextval
{
    my ($self,$seq) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    my $dbh = $self->{dbh};
    $seq ||= $self->{sequence_name};
##at DBI version requirement prepare_cached
    my $crs = $dbh->prepare_cached("SELECT $seq.NEXTVAL FROM DUAL") || return undef;
    $crs->execute() || return undef;
    return (($crs->fetchrow_array)[0]);
}

sub update_hash
{
    my ($self,$update,$key,$date_format,$hint) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    ref($update) || ($self->_alert("\$update not a hash ref"), return undef);
    %$update || return -1;
    my $dbh = $self->dbh();
    my $table = $self->table_name();
    unless (ref($key))
    {
        $key = { $self->key_name() => $key };
    }

    my $where = $self->_build_where_clause($key) || return undef;

    my $set_sql;
    my $attrs = $self->column_types();
    my %bind;
    my ($col,$val);
    while (($col,$val) = each %$update)
    {
        $col = uc($col);
##at does insert implement it's optional $hint feature?
        $val = $self->qualify($val,$col,$date_format);
        if (is_long_type($attrs->{$col}))
        {
            $bind{":$col"} = [ $col,$val ];
            $val = ":$col";
        }
        unless (defined($val))
        {
            $self->_alert("Unable to qualify insert value: qualify($val,$col,$date_format)");
            return undef;
        }
        $set_sql .= "$col = $val,";
    }
    chop($set_sql);
    my ($bind_field,$bind_val);
    my $sql = "UPDATE $hint $table SET $set_sql $where";
    my $sth = $dbh->prepare($sql) || ($self->_alert("Can't prepare $sql"), return undef);
    while (($bind_field,$bind_val) = each %bind)
    {
        my ($field,$val) = @$bind_val;
        my $type = $long_lob_types{$attrs->{$field}};
        $sth->bind_param($bind_field,$val,{ ora_type => $type, ora_field => $field }) || ($self->_alert("Error binding $bind_field"), return undef);
    }
    return $sth->execute();
}

##at should normalize the data types, e.g. $io->{column_types}{$column} = $DBIx::IO::GenLib::NORMAL_DATETIME_TYPE

=pod

=item C<existing_table_names>

 $sorted_arrayref = DBIx::IO::OracleIO->existing_table_names([$dbh]);

Return a sorted arrayref of table names found in the
data dictionary.

Class or object method.
$dbh is required if called as a class method.

Return undef if db error.

=cut
sub existing_table_names
{
    my ($caller,$dbh) = @_;
    $dbh ||= $caller->dbh();
    my $rv = $dbh->selectcol_arrayref('SELECT DISTINCT table_name FROM user_tab_columns ORDER BY table_name');
    return undef if $dbh->err;
    return $rv;
}


=pod

=item C<is_datetime>

 $bool = $io->is_datetime($column_name);

Determine if $column_name is of a datetime type.

=cut
sub is_datetime
{
    my ($self,$column_name) = @_;
    my $types = $self->column_types();
    return $datetime_types{$types->{$column_name}};
}

=pod

=item C<is_date>

 $bool = $io->is_date($column_name);

Determine if $column_name is of a date type.

=cut
sub is_date
{
    my ($self,$column_name) = @_;
    my $types = $self->column_types();
    return $date_types{$types->{$column_name}};
}

=pod

=item C<is_char>

 $bool = $io->is_char($column_name);

Determine if $column_name is of a character type.

=cut
sub is_char
{
    my ($self,$column_name) = @_;
    my $types = $self->column_types();
    return $char_types{$types->{$column_name}};
}

=pod

=item C<limit>

 $sql = $io->limit($sql,$limit);

Modify the given $sql to return a limited set
of records.

=cut
sub limit
{
    my ($self,$sql,$limit,$where) = @_;
    return "$sql $where ROWNUM < ($limit + 1)";
}

=pod

=item C<lc_func>

 $function = $io->lc_func($column);

Apply the function
for modifying $column to lower case.

=cut
sub lc_func
{
    my ($self,$column) = @_;
    return "LOWER($column)";
}

=pod

=back

=cut


1;

__END__

=head1 BUGS

No known bugs.

=head1 SEE ALSO

L<DBIx::IO::Table>, L<DBIx::IO::Search>, L<DBIx::IO>, L<DBIx::IO::OracleLIB>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

