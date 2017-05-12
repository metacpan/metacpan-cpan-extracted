package DBI::Easy::Helper;

use Class::Easy;
use Time::Piece;

# collection constructor
sub _connector_maker {
	my $class = shift;
	my $type  = shift;
	my $name  = shift; # actually, is entity name
	
	if ($type !~ /^(Collection|Record)$/i) {
		warn "no correct type supplied - '$type' (expecting 'collection' or 'record')";
		return;
	}
	
	my %params = @_;
	my $prefix = $params{prefix} || 'Entity';
	
	my @pack_chunks = ($prefix, package_from_table ($name));
	push @pack_chunks, 'Collection'
		if $type =~ /^collection$/i;
	
	my $pack = join '::', @pack_chunks;
	
	debug "creation package $pack";
	
	# check for existing package
	return $pack
		if try_to_use_inc_quiet ($pack);
	
	my $code;

	
	if ($params{entity}) {
		my $table_name = '';
		$table_name = "has 'table_name', global => 1, is => 'rw', default => '" . $params{table_name} . "';\n"
			if $params{table_name};

		my $column_prefix = '';
		$column_prefix = "has 'column_prefix', global => 1, is => 'rw', default => '" . $params{column_prefix} . "';\n"
			if $params{column_prefix};
		
		$code = "package $pack;\nuse Class::Easy;\nuse base '$params{entity}';\n$table_name$column_prefix\npackage main;\nimport $pack;\n";
		
	} else {
		warn "error: no entity package provided";
		return;
	}
	
	eval $code;
	
	if ($@) {
		warn "something wrong happens: $@";
		return;
	} else {
		return $pack;
	}
}

# collection constructor
sub c {
	my $self = shift;
	return $self->_connector_maker ('collection', @_);
}

# record constructor
sub r {
	my $self = shift;
	return $self->_connector_maker ('record', @_);
}

our $types;

map {
	$types->{$_} = 'date'
} split (/\|/, 'DATE|TIMESTAMP(6)|DATETIME|TIMESTAMP|timestamp|timestamp without time zone');

sub is_rich_type {
	my $pack = shift;
	my $type = shift;
	
	return $types->{$type}
		if defined $type and exists $types->{$type};
}

sub value_from_type {
	my $pack  = shift;
	my $type  = shift;
	my $value = shift;
	my $model = shift; # check for driver
	
	if (defined $type and $types->{$type} eq 'date') {
	
		my $t = localtime;
		my $timestamp = eval {(Time::Piece->strptime ($value, $model->_datetime_format) - $t->tzoffset)->epoch};
		return 0
			if $t->tzoffset->seconds + $timestamp == 0;

		return $timestamp
			if $timestamp;
	}
	
	return $value;
	 
}

sub value_to_type {
	my $pack  = shift;
	my $type  = shift;
	my $value = shift;
	my $model = shift; # check for driver
	
#	warn "$type => $value, $types->{$type} ".$model->_datetime_format."\n";
	
	if (defined $type and $types->{$type} eq 'date') {
		my $timestamp = Time::Piece->new ([CORE::localtime ($value)])->strftime ($model->_datetime_format);
		return $timestamp
			if $timestamp;
	}
	
	return $value;

}

sub table_from_package {
	my $entity = shift;
	
	lc join ('_', split /(?=\p{IsUpper}\p{IsLower})/, $entity);
}

sub package_from_table {
	my $table = shift;
	
	join '', map {ucfirst} split /_/, $table;
}

1;

__DATA__
