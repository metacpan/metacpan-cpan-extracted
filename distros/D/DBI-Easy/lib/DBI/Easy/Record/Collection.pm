package DBI::Easy::Record::Collection;

use Class::Easy;

use base qw(DBI::Easy);

our $wrapper = 1;

has 'filter', is => 'rw', default => {};
has 'join_table', is => 'rw';

sub new_record {
	my $self   = shift;
	my $params = shift || {};
	
	my $rec_pack = $self->record_package;
	
	my $rec = $rec_pack->new ({%$params, %{$self->filter || {}}});
}

sub natural_join {
	my $self   = shift;
	
	my $join = join ' ', map {'natural join ' . $_->table_quoted} @_;
	$self->join_table ($join);
}

sub make_sql_and_bind {
	my $self   = shift;
	my $method = shift;
	
	my $set;
	my $where  = {};
	my $suffix = '';
	my $bind_suffix;
	
	my %args;
	
	# legacy syntax
	if (! defined $_[0] or ref $_[0]) {
		$set    = shift;
		$where  = shift || {};
		$suffix = shift || '';

		$bind_suffix = shift;
		%args = (@_);
	} else {
		%args        = (@_);
		$where       = delete $args{where} || {};
		$set         = delete $args{set};
		$suffix      = delete $args{suffix} || '';
		$bind_suffix = delete $args{bind};
	}

	# if we call collection method from package name, we must create collection
	# object automatically
	$self = $self->new
		unless ref $self;
	
	my $filter = $self->filter;
	
	my %params = (
		where => [
			$self->fields_to_columns ($filter),
			$self->fields_to_columns ($where)
		],
		suffix => $suffix,
		%args
	);
	
	if ($method eq 'sql_update') {
		$params{set} = $self->fields_to_columns ($set);
	}
	
#	use Data::Dumper;
#	warn "$method => " . Dumper \%params;
	
	my ($select, $bind) = $self->$method (%params);
	
	push @$bind, @{$bind_suffix || []};
	
	debug 'sql: \'', $select, '\' => ', defined $bind ? join ', ', @$bind : '[empty]';
	
	return ($select, $bind);
	
}

# legacy
sub list {
	my $self   = shift;
	my $where  = shift || {};
	my $suffix = shift || '';
	my $bind_suffix = shift || [];
	my %params = @_;
	
	return $self->records (where => $where, suffix => [$suffix, @$bind_suffix], %params);
}

sub records {
	my $self   = shift;
	my $where;
	my %params;

	if (ref $_[0]) {
		$where = shift;
		%params = @_;
	} else {
		%params = @_;
		$where = delete $params{where} || {};
	}
	
	my $suffix = '';
	my $bind_suffix = [];
	
	#TODO: REGRESSION FIX !!!
	
	if ($params{suffix} and ref $params{suffix} and ref $params{suffix} eq 'ARRAY') {
		$suffix = shift @{$params{suffix}} || '';
		$bind_suffix = delete $params{suffix};
	} elsif ($params{suffix}) {
		$suffix = delete $params{suffix} || '';
	}
	
	my @fetch_params = $self->make_sql_and_bind ('sql_select', undef, $where, $suffix, $bind_suffix, %params);
	
	if ($params{fetch_handler} and ref $params{fetch_handler} eq 'CODE') {
		
		debug "fetch by record";
		
		$self->fetch_handled (@fetch_params, sub {
			my $row = shift;
			
			my $rec = $self->record_package->new (column_values => $row);
			
			return $params{fetch_handler}->($rec);
		});
		
		
	} else {
		my $db_result = $self->fetch_arrayref (@fetch_params);
		
		debug "result count: ", $#$db_result+1;
		
		$self->columns_to_fields_in_place ($db_result);
		
		return $db_result;
	}
}

sub list_of_record_hashes {
	my $self = shift;
	my $records = $self->records (@_);
	
	my $list_of_hashes = [map {$_->hash} @$records];
	
	return $list_of_hashes;
}

sub update {
	my $self   = shift;
	
	my ($sql, $bind) = $self->make_sql_and_bind ('sql_update', @_);
		
	my $db_result = $self->no_fetch ($sql, $bind);
	
	debug "rows affected: ", $db_result;
	
	return $db_result;
}


sub count {
	my $self   = shift;
	
	my ($select, $bind);
	
	if (ref $_[0] or @_ % 2) { # make_sql_and_bind (set, where, suffix, bind)
		($select, $bind) = $self->make_sql_and_bind ('sql_select_count', undef, @_);
		
	} else { # make_sql_and_bind (set => set, where => where, ...)
		($select, $bind) = $self->make_sql_and_bind ('sql_select_count', @_);
	}
	
	my $db_result = $self->fetch_single ($select, $bind);
	
	debug "result count: ", $db_result;
	
	return $db_result;
	
}

sub delete {
	my $self   = shift;
	
	my ($select, $bind);
	
	if (ref $_[0] or @_ % 2) { # make_sql_and_bind (set, where, suffix, bind)
		($select, $bind) = $self->make_sql_and_bind ('sql_delete', undef, @_);
		
	} else { # make_sql_and_bind (set => set, where => where, ...)
		($select, $bind) = $self->make_sql_and_bind ('sql_delete', @_);
	}
		
	my $db_result = $self->no_fetch ($select, $bind);
	
	debug "rows affected: ", $db_result;
	
	return $db_result;
}

sub tree {
	my $self   = shift;
	my $keys   = shift;
	my $where  = shift;
	my $suffix = shift;
	
	my $ref = ref $self;

	my $where_w_filter = $where;
	my $filter = $self->filter;
	$where_w_filter = {%$where, %$filter}
		if defined $filter and ref $filter eq 'HASH';
	
	my $where_prefixed = $self->fields_to_columns ($where_w_filter);
	
	my ($select, $bind) = $self->sql_select (where => $where_prefixed, suffix => $suffix);
	
	# warn $select, ' => ', defined $bind ? join ', ', @$bind : '[empty]';
	
	my $db_result = $self->fetch_hashref ($select, $keys, $bind);
	#my $db_result = $self->fetch_arrayref ($select, $bind);
	
	$self->columns_to_fields_in_place ($db_result, $keys);
	
	return $db_result;
	
}

sub item {
	my $self   = shift;
	my $where  = shift;
	my $suffix = shift || '';
	
	my $result = $self->list ($where, $suffix . ' limit 1');
	
	# programmer must be warned about multiple values
	return $result->[0];
}

sub new_record_from_request {
	my $self    = shift;
	my $request = shift;

	my $rec_pack = $self->record_package;
	
	my $rec = $rec_pack->new ({%{$self->filter}});
	$rec->apply_request_params ($request);
	
	return $rec;
}

sub columns_to_fields_in_place {
	my $self = shift;
	my $rows = shift;
	
	my $rec_pack = $self->record_package;
	
	if (UNIVERSAL::isa ($rows, 'ARRAY')) {
	
		foreach my $row_counter (0 .. $#$rows) {
			
			my $row = $rows->[$row_counter];
			
			$rows->[$row_counter] = $rec_pack->new (column_values => $row);
		}
	} elsif (UNIVERSAL::isa ($rows, 'HASH')) {
	
		foreach my $row_key (keys %$rows) {
			
			my $row = $rows->{$row_key};
			
			$rows->{$row_key} = $rec_pack->new (column_values => $row);
		}
	}
}

our $MAX_LIMIT = 300;

sub ordered_list {
	my $self = shift;
	
	my $order = shift;
	my $dir   = shift;
	my $limit = shift;
	my $start = shift;
	
	my $filter = shift;
	my $bind   = shift || [];
	
	my $fields = $self->fields;
	
	my $sort_col;
	if (exists $fields->{$order}) {
		$sort_col = $fields->{$order}->{quoted_column_name};
	} elsif ($self->_pk_) {
		# we assume primary key ordering unless ordered column known
		$sort_col = $fields->{$self->_pk_}->{quoted_column_name};
	}
	
	if ($dir =~ /^(asc|desc)$/i) {
		$dir = lc($1);
	} else {
		$dir = ''; # default sort
	}
	
	# When using LIMIT, it is important to use an ORDER BY clause that
	# constrains the result rows into a unique order. Otherwise you will
	# get an unpredictable subset of the query's rows. You might be asking
	# for the tenth through twentieth rows, but tenth through twentieth
	# in what ordering? The ordering is unknown, unless you specified ORDER BY.
	if (!$sort_col or $start !~ /\d+/ or $limit !~ /\d+/) {
		return {
			count => 0,
			error => "ordering-undefined"
		};
	}
	
	$start =~ s/(\d+)/$1/;
	$limit =~ s/(\d+)/$1/;
	
	my $count = $self->count ($filter, '', $bind);

	if ($start > $count) {
		$start = $count - $limit;
		$start = 0 if $start < 0;
	}
	
	if ($limit > $MAX_LIMIT or ! $limit > 0) { # try undef -)
		$limit = $MAX_LIMIT;
	}

	my $suffix = "order by $sort_col $dir limit $limit offset $start";
	# debug "suffix: $suffix";
	
	my $list  = $self->list ($filter, $suffix, $bind);

	return {
		items => $list,
		total_count => $count,
		version => 1,
	};
}

# page_size, count, page_num, pages_to_show
sub pager {
	my $self = shift;
	my $param = shift;

	my $page_size = $param->{page_size} || 20;
	my %pager;

	my $number_of_pages = int(($param->{count} + $page_size - 1) / $page_size);

	$pager{pager_needed} = ($param->{count} > $page_size);
	
	unless ($pager{pager_needed}) {
		return;
	}
	
	my $page_number = $param->{page_num} || 0;

	my $pages_to_show = $param->{pages_to_show} || 10;
	my $quarter_to_show = int ($pages_to_show / 4);

	my @pages;
	
	if ($param->{count} <= $pages_to_show) {
		return [1 .. $param->{count}];
	}
	
	if ($page_number <= $quarter_to_show * 2 + 1) {
		return [
			1 .. $quarter_to_show * 3 + 1,
			undef,
			$number_of_pages - $quarter_to_show + 1 .. $number_of_pages
		];
	}

	if ($page_number >= $number_of_pages - ($quarter_to_show * 2 + 1)) {
		return [
			1 .. $quarter_to_show,
			undef,
			$number_of_pages - ($quarter_to_show * 3 + 1) .. $number_of_pages
		];
	}
	
	return [
		1 .. $quarter_to_show,
		undef,
		$page_number - $quarter_to_show .. $page_number + $quarter_to_show,
		undef,
		$number_of_pages - $quarter_to_show + 1 .. $number_of_pages
	];
	
}


1;
