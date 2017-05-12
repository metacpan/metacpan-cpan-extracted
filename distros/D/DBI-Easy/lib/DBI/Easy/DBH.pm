package DBI::Easy;

# use Hash::Merge;

use Class::Easy;

sub statement {
	my $self       = shift;
	my $statement  = shift;
	my $dbh_method = shift || 'dbh';
	
	my $dbh = $self->$dbh_method;
	
	my $sth;
	if (ref $statement eq 'DBI::st') {
		$sth = $statement;
	} elsif (ref $statement) {
		die "can't use '$statement' as sql statement";
	} else {
		
		my $prepare_method = $self->prepare_method;
		$sth = $dbh->$prepare_method (($statement, {}, $self->prepare_param));
	}
	
	return $sth;
}

sub bind_values {
	my $self = shift;
	my $sth  = shift;
	my $bind = shift;
	
	foreach my $i (0 .. $#$bind) {
		my $v = $bind->[$i];
		my @bind_v = ($v);
		if (ref $v eq 'ARRAY') {
			die "you must supply bind type within \%DBI::Easy::BIND_TYPES"
				unless exists $DBI::Easy::BIND_TYPES{$v->[1]};
			
			my $opts = $DBI::Easy::BIND_TYPES{$v->[1]};
			
			#if (exists $opts->{ora_type}) {
			#	
			#	warn Encode::is_utf8 ($v->[0]); 
			#	$opts->{ora_csform} = 1;
			#}
			
			$opts->{ora_field} = $v->[2];
			
			@bind_v = ($v->[0], $opts);
			#use Data::Dumper;
			#warn "bind for param ", $i + 1, ", for " . Dumper $opts;
		}
		$sth->bind_param ($i + 1, @bind_v);
	}
}

# for every query except select we must use this routine
sub no_fetch {
	my $self = shift;
	my $statement = shift;
	my $params = shift;
	my $seq = shift;
	
	$params = [defined $params ? $params : ()]
		unless ref $params;
	
	my $dbh_method = 'dbh_modify';
	
	my $dbh = $self->dbh_modify;
	my $rows_affected;
	
	eval {
		my $sth = $self->statement ($statement, $dbh_method);
		$self->bind_values ($sth, $params);

		$rows_affected = $sth->execute;
		# $sth->finish;
		
		if (! ref $statement and $statement =~ /^\s*insert/io and defined $rows_affected) { 
			if (defined $seq) {
				
				$rows_affected = $self->fetch_single ("select ${seq}.currval as maxid from dual");

			} elsif ($self->dbh_vendor ne 'oracle' and defined $self->_pk_) {
				$rows_affected = $dbh->last_insert_id (
					undef,
					undef,
					$self->table_name,
					$self->_pk_column_
				);
			} else {
				# try to deal with return of pk id instead rows_affected
				$rows_affected = "0E$rows_affected"; 
			}
		}
		
	};
	
	return undef
		if $self->_dbh_error ($@);
	
	return $rows_affected || 0;
}

sub fetch_single {
	my $self = shift;
	my $statement = shift;
	my $params = shift;
	
	$params = [defined $params ? $params : ()]
		unless ref $params;
	
	my $dbh = $self->dbh;
	
	my $single;
	eval {
		
		my $sth = $self->statement ($statement);
		
		$self->bind_values ($sth, $params);

		die unless $sth->execute;
		
		$sth->bind_columns (\$single);
 
		$sth->fetch;
	};
	
	return if $self->_dbh_error ($@);
	
	return $single;
}

sub fetch_column {
	my $self = shift;
	my $statement = shift;
	my $params = shift;
	
	$params = [defined $params ? $params : ()]
		unless ref $params;
	
	my $dbh = $self->dbh;
	
	my $single;
	my $column;
	eval {
		my $sth = $dbh->prepare_cached($statement, {}, 3);

		$self->bind_values ($sth, $params);
		my $rows_affected = $sth->execute;

		$sth->bind_columns(\$single);
 
		while ($sth->fetch) {
			push @$column, $single;
		}
	};
	
	return if $self->_dbh_error ($@);
	
	return $column;
}

sub fetch_columns {
	my $self = shift;
	my $statement = shift;
	my $params = shift;
	
	$params = [defined $params ? $params : ()]
		unless ref $params;
	
	my $dbh = $self->dbh;
	
	my $columns = [];
	eval {
		my $sth = $dbh->prepare_cached($statement, {}, 3);

		$self->bind_values ($sth, $params);
		my $rows_affected = $sth->execute;

		while (my @arr = $sth->fetchrow_array) {
			foreach (0 .. $#arr) {
				push @{$columns->[$_]}, $arr[$_];
			}
		}
	};
	
	return if $self->_dbh_error ($@);
	
	return $columns;
}

sub fetch_row {
	my $self = shift;
	my $statement = shift;
	my $params = shift;
	
	$params = [defined $params ? $params : ()]
		unless ref $params;
	
	my $dbh = $self->dbh;
	
	my $row;
	eval {
		my $sth = $dbh->prepare_cached($statement, {}, 3);

		$row = $dbh->selectrow_hashref ($sth, {}, @$params);
	};
	
	return if $self->_dbh_error ($@);
		
	return $row;
}

sub fetch_row_in_place {
	my $self = shift;
	
	my $row = $self->fetch_row (@_);
	
	# Hash::Merge::set_clone_behavior (0);

	# Hash::Merge::specify_behavior(
		{
			'SCALAR' => {
				'SCALAR' => sub { $_[1] },
				'ARRAY'  => \&strict_behavior_error,
				'HASH'   => \&strict_behavior_error,
			},
			'ARRAY' => {
				'SCALAR' => \&strict_behavior_error,
				'ARRAY'  => sub { $_[1] },
				'HASH'   => \&strict_behavior_error, 
			},
			'HASH' => {
				'SCALAR' => \&strict_behavior_error,
				'ARRAY'  => \&strict_behavior_error,
				'HASH'   => sub { Hash::Merge::_merge_hashes( $_[0], $_[1] ) }, 
			},
		}, 
		'Strict Override', 
	#);
	
	# return unless "$structure" =~ /^(?:([^=]+)=)?([A-Z]+)\(0x([^\)]+)\)$/;
	#	
	# my ($type, $address) = ($2, $3);
	
	# warn Dumper $self, $row;
	
	# Hash::Merge::merge ($self, $row);
	
	# warn Dumper $self;
}

sub strict_behavior_error {
	die "'", ref $_[0], "' to '", ref $_[1], "' not supported";
}

sub fetch_hashref {
	my $self = shift;
	my $statement = shift;
	my $key = shift;
	my $params = shift;
	$params ||= [];

	my $dbh = $self->dbh;
	my $result;
	my $rows_affected;

	eval {
		my $sth = $self->statement ($statement);
		
		$self->bind_values ($sth, $params);
		$rows_affected = $sth->execute;
		$result = $sth->fetchall_hashref($key);
	};

	return if $self->_dbh_error ($@);

	return $result;
}

sub fetch_arrayref {
	my $self = shift;
	my $statement = shift;
	my $params = shift;
	$params ||= [];
	
	my $sql_args = shift;
	$sql_args ||= {Slice => {}, MaxRows => undef};
	
	my $fetch_handler = shift;
	
	my $dbh = $self->dbh;
	my $result;
	my $rows_affected;

	eval {
		my $sth = $self->statement ($statement);
		$self->bind_values ($sth, $params);
		$rows_affected = $sth->execute;
		$result = $sth->fetchall_arrayref ($sql_args->{Slice}, $sql_args->{MaxRows});
	};

	return if $self->_dbh_error ($@);

	return $result;
}

sub fetch_handled {
	my $self = shift;
	my $statement = shift;
	my $params = shift;
	$params ||= [];
	
	my $fetch_handler = shift;
	
	my $dbh = $self->dbh;
	my $result;
	my $rows_affected;
	
	my $failed = 0;
	
	eval {
		my $sth = $self->statement ($statement);
		$self->bind_values ($sth, $params);
		$rows_affected = $sth->execute;
		while (my $row = $sth->fetchrow_hashref) {
			unless (defined &$fetch_handler ($row)) {
				$failed = 1;
				last;
			}
		}
	};

	return if $self->_dbh_error ($@);

	return $rows_affected;
}


1;