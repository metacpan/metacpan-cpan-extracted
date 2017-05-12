package DBI::Easy::Record;
# $Id: Record.pm,v 1.6 2009/07/20 18:00:08 apla Exp $

use Class::Easy;

use DBI::Easy;
use base qw(DBI::Easy);

our $wrapper = 1;

sub _init {
	my $class = shift;
	
	my $params;
	
	if (@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH') {
		# old school
		$params->{field_values} = $_[0];
	} else {
		$params = {@_};
	}
	
	return $params;
}

sub save {
	my $self = shift;
	
	my $result;
	
	return unless $self->field_values;
	
	my $pk_column = $self->_pk_column_;
	
	if ($pk_column and $pk_column ne '' and defined $self->column_values and $self->column_values->{$pk_column}) {
		# try to update
		$result = $self->update_by_pk;
	} else {
		$result = $self->create;
	}
	
	return $result;
}

sub fetched {
	return 1 if defined shift->{field_values};
}

# update by pk
sub update_by_pk {
	my $self   = shift;
	my %params = @_;
	
	# there we make decision:
	# a) programmmer can provide update values
	#    we simply reject field values
	# b) field_values already contains update values
	
	my $column_values;
	
	if (exists $params{set} and ref $params{set} and ref $params{set} eq 'HASH') {
		$column_values = $self->fields_to_columns ($params{set});
	} else {
		$column_values = $self->fields_to_columns;
	}
	
	my ($sql, $bind) = $self->sql_update_by_pk (%params);
	
	return unless defined $sql;
	
	debug "sql: $sql => " . (defined $bind and scalar @$bind ? join ', ', @$bind : '[]');
	
	my $result = $self->no_fetch ($sql, $bind);
	
	foreach my $k (keys %$column_values) {
		$self->column_values->{$k} = $column_values->{$k};
	}

	delete $self->{field_values};
	
	return $result
}

# delete by pk
sub delete_by_pk {
	my $self = shift;
	
	my ($sql, $bind) = $self->sql_delete_by_pk (@_);
	
	debug "sql: $sql => " . (defined $bind and scalar @$bind ? join ', ', @$bind : '[]');
	
	return $self->no_fetch ($sql, $bind);
	
}

sub create {
	my $self = shift;
	
	my $t = timer ('fields to columns translation');
	
	my $column_values = $self->fields_to_columns;
	
	$t->lap ('sql generation');
	
	my ($sql, $bind) = $self->sql_insert ($column_values);
	
	debug "sql: $sql => " . (defined $bind and scalar @$bind ? join ', ', @$bind : '[]');
	
	$t->lap ('insert');
	
	# sequence is available for oracle insertions
	my $pk_col = $self->_pk_column_;
	my $seq;
	
	if ($pk_col and exists $column_values->{"_$pk_col"} and $column_values->{"_$pk_col"} =~ /^\s*(\w+)\.nextval\s*$/si) {
		$seq = $1;
	}

	my $id = $self->no_fetch ($sql, $bind, $seq); 
	
	$t->lap ('perl wrapper for id');
	
	return unless defined $id;
	
	delete $self->{field_values};
	$self->{column_values} = $column_values;
	
	return $id if $id =~ /^0E\d+$/;
	
	$self->{column_values}->{$pk_col} = $id
		if $pk_col; # sometimes no primary keys in table

	$t->end;
	
	$t->total;
	
	return 1;
}

sub fetch {
	my $class   = shift;
	my $params  = shift;
	my $cols    = shift;
	
	my $prefixed_params = $class->fields_to_columns ($params);
	
	my ($statement, $bind) = $class->sql_select (where => $prefixed_params, fieldset => $cols);
	
	debug "sql: '$statement'";
	
	my $record = $class->fetch_row ($statement, $bind);
	
	return
		unless ref $record;
	
	return $class->new (
		column_values => $record
	);
	
}

sub fetch_or_create {
	my $class = shift;
	my $params = shift;
	
	my $record = $class->fetch ($params);
	
	unless (defined $record) {
		$record = $class->new ($params);
		$record->create;
	}
	
	return $record;
}

sub hash {
	my $self = shift;
	
	my $result = {};
	
	# we need to return everything we got from db + changes
	my $result = {map {$_ => $self->{field_values}->{$_}}
		grep {defined $self->{field_values}->{$_}}
		keys %{$self->fields}};
	
	foreach my $col_name (keys %{$self->{column_values}}) {
		my $col_meta = $self->columns->{$col_name};
		my $col_value = $self->{column_values}->{$col_name};
		
		next unless defined $col_value;
		
		$result->{$col_name} = $col_value, next
			if ! defined $col_meta and ! exists $result->{$col_meta->{field_name}};
		
		$result->{$col_meta->{field_name}} = (
			exists $col_meta->{decoder} ? $col_meta->{decoder}->($self): $col_value
		) if ! exists $result->{$col_meta->{field_name}};
	}
	
	return {%{$self->{embed}}, %$result};
}

*TO_JSON = \&hash;
*TO_XML  = \&hash;

sub embed {
	my $self = shift;
	my $what = shift;
	
	if (@_ == 1) {
		die "cannot embed '$what' into ". ref $self
			if exists $self->fields->{$what};
		$self->{embed}->{$what} = $_[0];
	} elsif (@_ > 1) {
		die "too many parameters";
	}
	
	return $self->{embed}->{$what};
	
}

# example usage: $domain->is_related_to ('contacts', {
# 	isa => 'My::Entity::Contact::Collection',
# 	relation => [domain_key => domain_key_in_contacts], # optional, by default natural join
# 	many_to_many => 'My::Entity::Domain_Contact::Collection',
# 	filter => {}
# });

# памятка использования is_related_to
#$ref->is_related_to (
#	‘entity’,  # название сущности, доступной у объекта
#	           # после вызова этого метода
#	‘entity_pack’, # имя класса, корое используется в 
#	               # качестве фабрики для сущностей
#	filter => {}, # хэш фильтров для ограничения выборки
#	relation => ['key_in_ref', 'key_in_entity'] # отношение
#);

sub is_related_to {
	my $ref    = shift;
	my $entity = shift;
	my $pack   = shift;
	my %params = @_;

	my $t = timer ('all');
	
	debug "$entity";
	
	my $filter = $params{filter} || {};
	
	$params{relation} = []
		unless defined $params{relation};
	
	my $column     = $params{relation}->[0] || $ref->_pk_;
	my $ref_column = $params{relation}->[1] || ($ref->column_prefix
		? $ref->column_prefix
		: $ref->table_name . '_'
	) . $column;
	
	try_to_use ($pack);
	
	# warn "column $column from table ".$ref->table_name." is related to column $ref_column from table ". $pack->table_name;
	
	my $sub;
	my $ref_sub;
	
	
	if ($pack->is_collection) {
		$sub = sub {
			my $self = shift;
			
			return $pack->new ({filter => {%$filter, $ref_column => $self->$column}});
		};
		$ref_sub = sub {
			my $self = shift;
			
			return $pack->new ({filter => {%$filter, $ref_column => $self->$column}});
		};
	} else {
		
		$sub = sub {
			my $self = shift;
			
			return $pack->fetch_or_create ({%$filter, $ref_column => $self->$column});
		};
	}
	
	make_accessor ($ref, $entity, default => $sub);
	
	$t->end;
}

sub validation_errors {
	my $self = shift;
	
	my $errors = {};
	
	debug "field validation";
	
	foreach my $field (keys %{$self->fields}) {
		# first, we need to validate throught db schema
		# TODO
		if (0) {
			$errors->{$field} = 'schema-validation-error';
		}
		# second, we validate throught custom validators
		my $method = "${field}_valid";
		if ($self->can ($method)) {
			debug "custom validation for $field";
			my $error_code = $self->$method;
			if ($error_code) {
				$errors->{$field} = $error_code;
				debug "failed: $error_code";
			}
		}
	}
	
	return unless scalar keys %$errors;
	
	return $errors;
}

sub dump_fields_exclude {
	 #TODO
}

sub apply_request_params {
	my $self   = shift;
	my $request = shift;
	
	foreach my $field (keys %{$self->fields}) {
		# TODO: check for primary key. we don't want primary key value here
		my $value = $request->param ($field);
		next if !defined $value or $value eq '';
		$self->{$field} = $value;
	}

	my $values = {};
	
	foreach my $field (keys %{$self->columns}) {
		# TODO: check for primary key. we don't want primary key value here
		my $value = $request->param ($field);
		next if !defined $value or $value eq '';
		$values->{$field} = $value;
	}
	
	my $fields = $self->columns_to_fields ($values);

	foreach my $field (keys %{$fields}) {
		my $value = $fields->{$field};
		next if !defined $value or $value eq '';
		$self->{$field} = $value;
	}
}

1;