#
# $Id$
#

package DBIx::IO::mysqlIO;

use DBIx::IO;

@ISA = qw(DBIx::IO);

use strict;

use DBIx::IO::mysqlLib ();
use DBIx::IO::GenLib ();

my %all_table_col_types;
my %all_table_col_defaults;
my %all_table_col_required;
my %all_table_col_lengths;
my %all_table_cols;
my %all_table_pk;
my %all_table_col_list;
my %all_table_col_picklist;

my %datetime_types =
(
    $DBIx::IO::GenLib::DATETIME_TYPE => 1,
    DATETIME => 1,
    TIMESTAMP => 1,
);
my %date_types =
(
    $DBIx::IO::GenLib::DATE_TYPE => 1,
    DATE => 1,
);
my %time_types =
(
    $DBIx::IO::GenLib::TIME_TYPE => 1,
    TIME => 1,
);
my %year_types =
(
    $DBIx::IO::GenLib::YEAR_TYPE => 1,
    YEAR => 1,
);
my %numeric_types =
(
    $DBIx::IO::GenLib::NUMERIC_TYPE => 1,
    NUMERIC => 1,
    TINYINT => 1,
    SMALLINT => 1,
    MEDIUMINT => 1,
    INT => 1,
    INTEGER => 1,
    BIGINT => 1,
    FLOAT => 1,
    DOUBLE => 1,
#    'DOUBLE PRECISION' => 1,  # now truncating type so equiv to DOUBLE
#    REAL => 1,   # Synonym for DOUBLE
    DECIMAL => 1,
);
##at should make longs, blobs default to 'TEXTAREA' in CGI::AutoForm
my %char_types =
(
    $DBIx::IO::GenLib::CHAR_TYPE => 1,
    CHAR => 1,
    'NATIONAL CHAR' => 1,
    VARCHAR => 1,
    'NATIONAL VARCHAR' => 1,
    TINYBLOB => 1,
    TINYTEXT => 1,
    BLOB => 1,
    TEXT => 1,
    MEDIUMBLOB => 1,
    MEDIUMTEXT => 1,
    LONGBLOB => 1,
    LONGTEXT => 1,
    BINARY => 1,
    VARBINARY => 1,
    ENUM =>1,
    SET =>1,
);
my %set_types = 
(
    ENUM =>1,
    SET =>1,
);
my %long_types =
(
);
my %lob_types =
(
);
my %ignore_types = (
);



=head1 NAME

DBIx::IO::mysqlIO - DBIx::IO driver for MySQL

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

    length($val) || return 'NULL';
    return "''" if $val eq $DBIx::IO::GenLib::EMPTY_STRING;
    
    my $trunc_type = $type;
    $trunc_type =~ s/\s.*//;
    if (exists($numeric_types{$trunc_type}))
    {
        return $val;
    }
    elsif (exists($datetime_types{$type}) || exists($date_types{$type}) || exists($time_types{$type}) || exists($year_types{$type}))
    {
        return 'NOW()' if uc($val) eq 'SYSDATE';
        if ($date_format eq $DBIx::IO::GenLib::UNKNOWN_DATE_FORMAT)
        {
            my $parse_val = DBIx::IO::GenLib::normalize_date($val);
            length($parse_val) || ($self->_alert("The date format of: $val could not be recognized"),return undef);
            if (exists($datetime_types{$type}))
            {
                $val = $parse_val;
                return "'$val'";
            }
            elsif (exists($date_types{$type}))
            {
                $val = substr($parse_val,0,8);
                $date_format = $DBIx::IO::mysqlLib::NORMAL_DATE_FORMAT;
            }
            elsif (exists($time_types{$type}))
            {
                #$val = substr($parse_val,-6);
                #$date_format = $DBIx::IO::mysqlLib::NORMAL_TIME_FORMAT;
                return "'$val'";
            }
            elsif (exists($year_types{$type}))
            {
                #$val = substr($parse_val,0,4);
                #$date_format = $DBIx::IO::mysqlLib::NORMAL_YEAR_FORMAT;
                return "'$val'";
            }
            else
            {
                die("A horrible death");
            }
            return "STR_TO_DATE('$val','$date_format')";
        }
        elsif (length($date_format))
        {
            return "STR_TO_DATE('$val','$date_format')";
        }
        return "'$val'";
    }
    elsif (exists($char_types{$type}))
    {
        $val =~ s/\000//g;
        $val = $self->{dbh}->quote($val);
        return undef if $self->{dbh}->err;
        return $val;
    }
    $self->_alert("Unhandled data type: $type");
    return undef;
}

sub verify_datatype
{
##at should make it optional to submit a scalar reference for $val
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

    my $trunc_type = $type;
    $trunc_type =~ s/\s.*//;
    if ($numeric_types{$trunc_type})
    {
        if ($trunc_type =~ /int/i)
        {
            return -1 unless DBIx::IO::GenLib::isint($val);
            if ($type =~ /zerofill|unsigned/i)
            {
                return -2 unless $val > 0;
            }
        }
        else
        {
            return DBIx::IO::GenLib::isreal($val);
        }
    }
    return 1;
}

sub _assign_table_attrs
{
    my $self = shift;
    my $table_name = shift;
    my $rv;
    unless ($rv = $self->SUPER::_assign_table_attrs($table_name,@_))
    {
        return $rv;
    }

    return 1;
}

sub column_attrs
{
    my ($self,$table) = @_;
    ref($self) || (warn("\$self not an object"),return undef);

    if (exists($all_table_col_types{$table}))
    {
        $self->{defaults} = $all_table_col_defaults{$table};
        $self->{required} = $all_table_col_required{$table};
        $self->{lengths} = $all_table_col_lengths{$table};
        $self->{pk} = $all_table_pk{$table};
        $self->{select_cols} = $all_table_cols{$table};
        $self->{col_list} = $all_table_col_list{$table};
        $self->{picklist} = $all_table_col_picklist{$table};
        # do not alter this hash ref!!!
        return ($self->{column_types} = $all_table_col_types{$table});
    }

    my $sth = $self->make_cursor("DESCRIBE $table");
    unless ($sth)
    {
        ($self->{dbh}->err() == 1146) || return undef;
        return 0;
    }
##at should use the 'Extra' column of output with a value of auto_increment to validate the sequence number generated was indeed
##at for the column it was ASSUMED to be.
    my ($col,$type,$null,$key,$default,%attrs,%defaults,%lengths,%required,$cols,@pk,@cols,@picklist,%picklist);
    while (($col,$type,$null,$key,$default) = $sth->fetchrow_array)
    {
        @picklist = ();
        $col = uc($col);
        $key = uc($key);
        push(@pk,$col) if $key =~ /PRI/;
        $type =~ s/\((.*)\)//;  #strip length specs
        my $specs = $1;
        $type = uc($type);

        my ($length,$scale);

        if ($set_types{$type})
        {
            my $specs_orig = $specs;

            # Lose the empty strings and NULLs
            my $ucsp = uc($specs);
            my $idx = 0;
            while (($idx = index($ucsp,",'',")) > -1)
            {
                substr($specs,$idx,3) = '';
                substr($ucsp,$idx,3) = '';
            }
            while (($idx = index($ucsp,",NULL,")) > -1)
            {
                substr($specs,$idx,5) = '';
                substr($ucsp,$idx,5) = '';
            }
            $specs =~ s/^(''|NULL),//i;
            $specs =~ s/,(''|NULL)$//i;
            $specs =~ s/''/\\'/g;
            my @elems = eval("($specs)");
            $self->_alert("Couldn't parse MySQL set list, setting picklist to empty [$@]: $specs_orig") if $@;

            $length = 1;
            my $l = 0;
            foreach my $elem (@elems)
            {
                $l = length($elem);
                $length = $l if $l > $length;
                push(@picklist, { ID => $elem, MASK => $elem });
            }

            $length = 250 if $type eq 'SET';
        }
##at use "show index from u;" to get unique keys where there is no PK
        else
        {
            ($length,$scale) = split(/[,]/,$specs);
        }
        
        $attrs{$col} = $type;
        undef($default) if uc($default) eq 'NULL';
        $defaults{$col} = $default;
        $required{$col} = !$null || $null eq 'NO';
        $length = _lengthof($type,$length);
        $lengths{$col} = $length;
        $picklist{$col} = [ @picklist ];
        push(@cols,$col);
        # Build a list of select columns
        # by using syntax select COLUMN_NAME vs column_name, mysql will actually return COLUMN_NAME vs column_name a COLUMN_ALIAS could also be used
        if ($datetime_types{$type})
        {
            $cols .= "DATE_FORMAT($table.$col,'$DBIx::IO::mysqlLib::NORMAL_DATETIME_FORMAT') $col,";
        }
        elsif ($date_types{$type})
        {
            $cols .= "DATE_FORMAT($table.$col,'$DBIx::IO::mysqlLib::NORMAL_DATE_FORMAT') $col,";
        }
        elsif ($time_types{$type})
        {
            #$cols .= "DATE_FORMAT($table.$col,'$DBIx::IO::mysqlLib::NORMAL_TIME_FORMAT') $col,";
            $cols .= "$table.$col,";
        }
        elsif ($year_types{$type})
        {
            $cols .= "$table.$col,";
        }
        else
        {
            $cols .= "$table.$col,";
        }
    }
    return undef if $sth->err;
    %attrs || ($self->_alert("table: $table doesn't seem to exist or have any columns"), return 0);
    chop $cols;
    # Cache types for each table
    # do not alter these hash refs!!!
##at all subclasses should cache these
    $self->{defaults} = $all_table_col_defaults{$table} = \%defaults;
    $self->{required} = $all_table_col_required{$table} = \%required;
    $self->{lengths} = $all_table_col_lengths{$table} = \%lengths;
    $self->{pk} = $all_table_pk{$table} = \@pk;
    $self->{select_cols} = $all_table_cols{$table} = $cols;
    $self->{col_list} = $all_table_col_list{$table} = \@cols;
    $self->{picklist} = $all_table_col_picklist{$table} = \%picklist;
    return ($self->{column_types} = $all_table_col_types{$table} = \%attrs);
}

sub _lengthof
{
    my ($type,$length) = @_;
    return $length if $length;
    return 24 if $type =~ /float/i;
    return 53 if $type =~ /double/i;
    return 255;
}

sub insert_hash
{
    my ($self,$insert,$date_format) = @_;
    ref($self) || (warn("\$self not an object"),return undef);
    ref($insert) || ($self->_alert("\$insert_hash not a hash ref"),return undef);
    my $dbh = $self->{dbh};
    my $table = $self->table_name();

    %$insert || return -1.1;

    my ($fields,$values,$field,$qual_val);
    foreach $field (keys %$insert)
    {
        $field = uc($field);
        $fields .= "$field,";
        $qual_val = $self->qualify($insert->{$field},$field,$date_format);
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
    my $rv = $sth->execute();
    unless ($rv)
    {
        if ($sth->err == 1062)
        {
            return -1.4;
        }
        else
        {
            return undef;
        }
    }

    my $pkname = $self->key_name();
    my $pk;
    if ($pkname && !exists($insert->{$pkname}))
    {
        $pk = $sth->{mysql_insertid};
    }
    elsif (exists($insert->{$pkname}))
    {
        $pk = $insert->{$pkname};
    }
    return (length($pk) ? $pk : -1.2);
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
    my ($col,$val);
    while (($col,$val) = each %$update)
    {
        $col = uc($col);
##at does insert implement it's optional $hint feature?
        $val = $self->qualify($val,$col,$date_format);
        unless (defined($val))
        {
            $self->_alert("Unable to qualify insert value: qualify($val,$col,$date_format)");
            return undef;
        }
        $set_sql .= "$col = $val,";
    }
    chop($set_sql);
    my $sql = "UPDATE $hint $table SET $set_sql $where";
    my $sth = $dbh->prepare($sql) || ($self->_alert("Can't prepare $sql"), return undef);
    return $sth->execute();
}

=pod

=item C<existing_table_names>

 $sorted_arrayref = DBIx::IO::mysqlIO->existing_table_names([$dbh]);

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
    my $rv = $dbh->selectcol_arrayref('SHOW TABLES');
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


=pod

=item C<limit>

 $sql = $io->limit($sql,$limit);

Modify the given $sql to return a limited set
of records.

=cut
sub limit
{
    my ($self,$sql,$limit) = @_;
    return "$sql LIMIT $limit";
}

=pod

=item C<lc_func>

 $function = $io->lc_func($column);

Apply the MySQL specific function
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

L<DBIx::IO::Table>, L<DBIx::IO::Search>, L<DBIx::IO>, L<DBIx::IO::mysqlLIB>

=head1 AUTHOR

Reed Sandberg, E<lt>reed_sandberg Ӓ yahooE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2000-2008 Reed Sandberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

