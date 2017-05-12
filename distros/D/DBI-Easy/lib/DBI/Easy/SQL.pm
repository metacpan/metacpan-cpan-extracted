package DBI::Easy;
# $Id: SQL.pm,v 1.6 2009/07/20 18:00:08 apla Exp $

use Class::Easy;

use DBI;

# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
# sql generation stuff
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

our %BIND_TYPES = (
#	VARCHAR2 => {ora_type => 1},
	CLOB => {ora_type => 112},
	BLOB => {ora_type => 113}
);

sub sql_range {
	my $self = shift;
	my $length = shift || 0;
	
	if (ref $length eq 'ARRAY') {
		$length = $#$length + 1;
	}  
	
	return
		unless $length > 0;

	return join ', ', ('?') x $length;
} 

sub sql_names_range { # now with AI
	my $self   = shift;
	my $list   = shift;
	my $fields = shift;
	
	return join ', ', @$list;
} 

sub sql_order {
	my $self  = shift;
	my $field = shift;
	my $dir   = shift;
	
	my $sort_col = $self->fields->{$field}->{quoted_column_name};
	
	if (!$field || !$sort_col || $dir !~ /^(?:asc|desc)$/i) {
		return '';
	}
	
	return "order by $sort_col $dir";
}

sub sql_limit {
	my $self  = shift;
	
	my $s = $#_;
	die if $s > 1 || $s == -1;
	
	return "limit " . join ', ', @_;
}

sub sql_chunks_for_fields {
	my $self = shift;
	my $hash = shift;
	my $mode = shift || 'where'; # also 'set' and 'insert'

	my @sql;
	my @bind;
	
	foreach my $k (keys %$hash) {
		next if $k =~ /^\:/;
		my $v = $hash->{$k};
		
		my $is_sql = 0;
		if ($k =~ /^_(\w+)$/) { # when we get param as _param, then we interpret it as sql
			$is_sql = 1;
			$k = $1;
		}
		
		my $type = $self->columns->{$k}->{type_name};
		
		my $qk = $self->dbh->quote_identifier ($k);
		$qk = $k
			if $self->dbh_vendor eq 'oracle';
		
		if (ref $v eq 'ARRAY') {
			
			die "can't use sql statement as arrayref"
				if $is_sql;
			
			die "can't set/insert multiple values: " . join (', ', @$v)
				unless $mode eq 'where';
			
			my $range;
			if (! scalar @$v) {
				$range = 'null';
			} else {
				$range = $self->sql_range ($v);
			}
			push @sql, qq($qk in ($range));
			push @bind, @$v;
		} elsif ($is_sql) {
			my @ph;
			my $re = '(^|[\=\,\s\(])(:\w+)([\=\,\s\)]|$)';
			while ($v =~ /$re/gs) {
				push @ph, $2;
			}
			
			$v =~ s/$re/ \? /gs;
			
			if ($mode eq 'insert') {
				push @{$sql[0]}, $qk;
				push @{$sql[1]}, $v;
			} else {
				push @sql, qq($qk $v);
			}
			
			push @bind, map {$hash->{$_}} @ph;
		} else {
			if ($mode eq 'insert') {
				push @{$sql[0]}, $qk;
				push @{$sql[1]}, '?';
			} else {
				push @sql, qq($qk = ?);
			}
			
			$v = [$v, $type, $k]
				if defined $type and exists $BIND_TYPES{$type};
			
			push @bind, $v;
		}
	}
	
	return \@sql, \@bind;
}

# get sql statement for insert

sub sql_where {
	my $self = shift;
	my $where_hash = shift;
	
	if (ref $where_hash eq 'ARRAY') {
		
		my (@where_acc, @bind_acc);
		
		foreach (@$where_hash) {
			my ($where, $bind) = $self->sql_where ($_);
			push @where_acc, $where
				if defined $where and $where ne '';
			push @bind_acc,  @{$bind || []};
		}
		
		return join (' and ', @where_acc), \@bind_acc;
	}
	
    return if ! defined $where_hash or $where_hash eq '';
    return $where_hash if !ref $where_hash;
    return if ref $where_hash ne 'HASH' || scalar keys %$where_hash == 0;
    
    my ($where, $bind) = $self->sql_chunks_for_fields ($where_hash, 'where');

	return join (' and ', @$where), $bind;
}

# Получаем список выражений для SET 
# как строку вида 'param1 = ?, param2 = ?'
# и массив значений для bind,
# построенные на основе заданного хэша
sub sql_set {
	my $self = shift;
	my $param_hash = shift;
	my $where_hash = shift;
	
	unless (ref($param_hash) eq 'HASH') {
		warn "please specify parameters hash";
		return;
	}
	
	my ($set, $bind) = $self->sql_chunks_for_fields ($param_hash, 'set');
	
	my $sql_set = join ', ', @$set;
	
	if (!defined $where_hash or ref($where_hash) !~ /HASH|ARRAY/) {
		return ($sql_set, $bind);
	} else {
		my ($where_set, $bind_add) = $self->sql_where ($where_hash);
		push @$bind, @$bind_add;
		return ($sql_set, $bind, $where_set);
	}
}

# real sql statements

sub sql_insert {
	my $self = shift;
	my $hash = shift || $self->field_values;
	
	my ($set, $bind) = $self->sql_chunks_for_fields ($hash, 'insert');
	
	my $table_name = $self->table_quoted;
	my $statement = "insert into $table_name (" .
		join (', ', @{$set->[0]}) . ") values (" .
		join (', ', @{$set->[1]}) . ")";
	
	return $statement, $bind;
}

sub sql_update {
	my $self = shift;
	my $set_values;
	my $where_values;
	my $suffix = '';
	my $update_all = 0;
	
	my $params;
	
	if (ref $_[0]) {
		$set_values = shift;
		$where_values = shift;
		$suffix = shift || '';
	} else {
		$params = {@_};
		$set_values   = $params->{set};
		$where_values = $params->{where};
		$suffix       = $params->{suffix} || '';
		$update_all   = $params->{all};
	}
	
	warn ("nothing to set in update"), return unless $set_values;
	warn ("please use update_all for update everything"), return unless $where_values;
	
	my $table_name = $self->table_quoted;
	
	my ($set_statement, $bind, $where_statement)
		= $self->sql_set ($set_values, $where_values);
	
	my $statement = "update $table_name set $set_statement";
	$statement .= " where $where_statement"
		if $where_statement;
	
	return $statement . ' ' . $suffix, $bind;
}

sub sql_delete {
	my $self = shift;
	my $where_values;
	my $suffix = '';
	my $update_all = 0;
	
	my $params;
	
	if (ref $_[0]) {
		$where_values = shift;
		$suffix = shift || '';
	} else {
		$params = {@_};
		$where_values = $params->{where};
		$suffix       = $params->{suffix} || '';
		$update_all   = $params->{all};
	}
	
	warn ("please use delete_all for delete everything"), return
		unless $where_values;
	
	my $table_name = $self->table_quoted;
	
	my ($where_statement, $bind)
		= $self->sql_where ($where_values);
	
	my $statement = "delete from $table_name";
	if (!$where_statement) {
		warn "you can't delete all data from table, use delete_all or truncate";
		return;
	}
	
	$statement .= " where $where_statement";
	debug $statement;
	return $statement . ' ' . $suffix, $bind;
}

sub sql_delete_by_pk {
	my $self   = shift;
	# BAD!!! needs to be rewritten
	my $where  = shift || {};
	my $suffix = shift || '';
	
	my $_pk_column_ = $self->_pk_column_;
	my $_pk_        = $self->_pk_;
	my $where_hash = {%$where, $_pk_column_ => $self->$_pk_};
	
	return $self->sql_delete (where => $where_hash, suffix => $suffix);
	
}


sub sql_select_by_pk {
	my $self   = shift;
	my %params = @_;
	
	my $where = {};
	
	if ($params{where}) {
		$where = delete $params{where};
	}
	
	my $_pk_column_ = $self->_pk_column_;
	
	return $self->sql_select (where => [
		$where, $_pk_column_ => $self->{$self->_pk_}
	], %params);
	
}

sub sql_update_by_pk {
	my $self   = shift;
	my %params = @_;
	
	my $set_hash = $params{set} || $self->fields_to_columns;
	
	my $_pk_column_ = $self->_pk_column_;
	my $_pk_ = $self->_pk_;
	
	return unless $self->{column_values}->{$_pk_column_} || $self->{field_values}->{$_pk_};
	
	my $where_hash = {
		%{$params{where} || {}},
		$_pk_column_ => $self->{column_values}->{$_pk_column_} || $self->{field_values}->{$_pk_}
	};
	
	my ($sql, $bind) = $self->sql_update (
		set => $set_hash, where => $where_hash, suffix => $params{suffix}
	);
	
	return $sql, $bind;
	
}

sub sql_column_list {
	my $self = shift;
	my $fieldset = shift;
	unless (defined $fieldset) {
		$fieldset = $self->fieldset;
	}
	
	return '*'
		if !defined $fieldset or !$fieldset;
	
	return $fieldset
		unless ref $fieldset;
	
	die "can't recognize what you want, provide arrayref or string as fetch fields"
		if ref $fieldset ne 'ARRAY' or ! scalar @$fieldset;
	
	my $col_list = [];
	
	my $fields = $self->fields;
	
	foreach my $field (@$fieldset) {
		if (exists $fields->{$field}) {
			push @$col_list, $fields->{$field}->{quoted_column_name};
		} else {
			# may be erratical
			push @$col_list, $field;
		}
	}
	
	return join ', ', @$col_list;
}

sub sql_select {
	my $self   = shift;
	
	my %params = @_;
	
	my $where  = $params{where} || {};
	my $suffix = $params{suffix} || '';
	my $fieldset = $params{fieldset};
	
	my $fieldset_method = $params{fieldset_name};
	
	if (defined $fieldset and defined $fieldset_method) {
		critical "you must use only fieldset with field names/expressions or fieldset_name for method who return fieldset";
	}
	
	if (defined $fieldset_method) {
		$fieldset = $self->$fieldset_method;
	}
	
	my $cols_statement = $self->sql_column_list ($fieldset);

	# TODO: multiple condition/expression (group|order)_by

	my $group_by = '';

	if (defined $params{group_by}) {
		
		# try to translate field => column, and copy field if failed
		my $group = $self->fields->{$params{group_by}}->{quoted_column_name};
		$group = $params{group_by}
			unless $group;
		
		$group_by = "group by $group"
			if $group;
	}

	my $limits = '';
	
	# parameter expansion here
	if (defined $params{limit} and $params{limit} =~ /^(\d+)$/) {
		# TODO: limit/offset by driver
		# and SQL:2008 OFFSET start { ROW | ROWS }
		# FETCH { FIRST | NEXT } [ count ] { ROW | ROWS } ONLY
		$limits .= "limit $1";
		if (defined $params{offset} and $params{offset} =~ /^(\d+)$/) {
			$limits .= " offset $1";
		}
		
		unless ($params{sort_field}) {
			warn "you must use sort_(field|order) when you use limit/offset, we decide to set sort_field to primary key";
			$params{sort_field} = $self->_pk_;
		}
	}
	
	my $order_by = '';

	if (defined $params{sort_field}) {
		
		my $order_expr = $self->fields->{$params{sort_field}}->{quoted_column_name};
		$order_expr = $params{sort_field}
			unless $order_expr;
		
		my $order = $params{sort_order};
		$order = 'desc' unless $order;
		
		$order_by = "order by $order_expr $order";
	}
	
	my $table_name = $self->table_quoted;
	
	my $statement = "select $cols_statement from $table_name";
	
	if ($self->can ('join_table')) {
		my $join = $self->join_table;
		if (defined $join and $join !~ /^\s*$/) {
			$statement .= ' ' . $join;
		}
	}
	
	my ($where_statement, $bind);
	($where_statement, $bind) = $self->sql_where ($where);
	
	$statement .= " where $where_statement"
		if defined $where_statement and $where_statement !~ /^\s*$/;
	
	return
		join (' ', $statement, $group_by, $suffix, $order_by, $limits),
		$bind;
}

sub sql_select_count {
	my $self   = shift;

	my $where  = {};
	my $suffix = '';
	
	my %params;
	
	if (ref $_[0]) {
		$where = shift;
		if (@_ % 2) {
			$suffix = shift;
		}
		%params = (@_);
	} else {
		%params = (@_);
		$where = $params{where} || {};
	}
	
	return $self->sql_select (where => $where, suffix => $suffix, %params, fieldset => 'count(*)');
	
}


1;

=head1 NAME

DBI::Easy::SQL - handling sql for DBI::Easy

=head1 ABSTRACT

This module is a SQL expressions constructor for DBI::Easy. 
So DBI::Easy::SQL is a wrapper between SQL and the rest part of DBI::Easy 


=head1 SYNOPSIS

SYNOPSIS


=head1 FUNCTIONS

=head2 sql_column_list

returns a list of SQL columns

=cut

=head2 sql_delete, sql_delete_by_pk

creates a SQL DELETE query

=cut

=head2 sql_insert

creates a SQL INSERT query

=cut

=head2 sql_limit

adds limits to SQL query

=cut

=head2 sql_names_range

TODO

=cut

=head2 sql_order

add ORDER BY to SQL query

=cut

=head2 sql_range

create placeholders for ranged sql statements, as example by

	... where column in (?, ?) ...
	insert into table (col1, col2) values (?, ?) ...

receive number of placeholders to generate or arrayref, returns

	join ', ', ('?' x $num)

=cut

=head2 sql_select, sql_select_by_pk, sql_select_count

creates SELECT SQL query

=cut

=head2 sql_set

creates SET SQL expression (for UPDATE query as an example)

=cut

=head2 sql_update, sql_update_by_pk

creates UPDATE SQL query

=cut

=head2 sql_where

creates WHERE SQL expression

=cut


=head1 AUTHOR

Ivan Baktsheev, C<< <apla at the-singlers.us> >>

=head1 BUGS

Please report any bugs or feature requests to my email address,
or through the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Easy>. 
I will be notified, and then you'll automatically be notified
of progress on your bug as I make changes.

=head1 SUPPORT



=head1 ACKNOWLEDGEMENTS



=head1 COPYRIGHT & LICENSE

Copyright 2008-2009 Ivan Baktsheev

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
