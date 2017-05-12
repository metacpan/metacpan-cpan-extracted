package App::Model::SQLBuilder;
use Dwarf::Pragma;
use parent 'Dwarf::Module';
use Dwarf::DSL;

sub new_query {
	my $self = shift;
	return SQLBuilder::Query->new->new_query(@_);
}

package SQLBuilder::Query;
use Dwarf::Pragma;
use Dwarf::Accessor {
	ro => [qw/
		queries
		binds
		select_queries
		from_queries
		join_queries
		where_queries
		group_by_queries
		having_queries
		order_by_queries
		limit_queries
		offset_queries
	/],
	rw => [qw//]
};

my %sort_key_map = (
);

sub new {
	my $class = shift;
	my $self = bless { @_ }, $class;
	return $self;
}

sub new_query {
	my ($self, $query) = @_;
	$self->{queries} = [];

	$self->new_binds;
	$self->new_select_queries;
	$self->new_from_queries;
	$self->new_join_queries;
	$self->new_where_queries;
	$self->new_group_by_queries;
	$self->new_having_queries;
	$self->new_order_by_queries;
	$self->new_limit_queries;
	$self->new_offset_queries;

	# 古いバージョンへの互換性のためのハック
	if (defined $query) {
		if ($query =~ /WHERE (.+)$/) {
			$self->where($1);
			$query =~ s/WHERE .+$//;
		}
		push @{ $self->{queries} }, $query;
	}
	
	return $self;
}

sub new_binds            { $_[0]->{binds}            = [] };
sub new_select_queries   { $_[0]->{select_queries}   = [] };
sub new_from_queries     { $_[0]->{from_queries}     = [] };
sub new_join_queries     { $_[0]->{join_queries}     = [] };
sub new_where_queries    { $_[0]->{where_queries}    = [] };
sub new_group_by_queries { $_[0]->{group_by_queries} = [] };
sub new_having_queries   { $_[0]->{having_queries}   = [] };
sub new_order_by_queries { $_[0]->{order_by_queries} = [] };
sub new_limit_queries    { $_[0]->{limit_queries}    = [] };
sub new_offset_queries   { $_[0]->{offset_queries}   = [] };

sub add_query {
	my $self = shift;
	push @{ $self->{queries} }, @_;
	return $self;
}

sub add_binds {
	my ($self, @params) = @_;
	push @{ $self->{binds} }, @params;
	return $self;
}

sub to_teng {
	my ($self) = @_;
	return ($self->sql, $self->binds);
}

sub sql {
	my ($self) = @_;

	my $query          = join ' ',  @{ $self->queries };
	my $select_query   = join ', ', @{ $self->select_queries };
	my $from_query     = join ', ', @{ $self->from_queries };
	my $join_query     = join ' ',  @{ $self->join_queries };
	my $where_query    = join ' ',  @{ $self->where_queries };
	my $group_by_query = join ', ', @{ $self->group_by_queries };
	my $having_query   = join ', ', @{ $self->having_queries };
	my $order_by_query = join ', ', @{ $self->order_by_queries };
	my $limit_query    = join ' ',  @{ $self->limit_queries };
	my $offset_query   = join ' ',  @{ $self->offset_queries };

	$query .= qq{ SELECT $select_query} if $select_query;
	$query .= qq{ FROM $from_query} if $from_query;
	$query .= qq{ $join_query} if $join_query;
	$query .= qq{ WHERE $where_query} if $where_query;
	$query .= qq{ GROUP BY $group_by_query} if $group_by_query;
	$query .= qq{ HAVING $having_query} if $having_query;
	$query .= qq{ ORDER BY $order_by_query} if $order_by_query;
	$query .= qq{ LIMIT $limit_query} if $limit_query;
	$query .= qq{ OFFSET $offset_query } if $offset_query;

	return $query;
}

sub select {
	my $self = shift;
	return unless @_;
	return $self->select_with_hash(@_) if @_ > 1;
	return $self->select_with_hashref(@_) if ref $_[0] eq 'HASH';
	push @{ $self->{select_queries} }, $_[0];
	return $self;
}

sub select_with_hashref {
	my ($self, $data) = @_;

	my @list;
	for my $k (keys %$data) {
		my $table_name = $k;

		if (ref $data->{$k} eq 'ARRAY') {
			for my $row (@{ $data->{$k} }) {
				my $column_name = $row;
				my $label = $row;

				if (ref $row eq 'ARRAY') {
					$column_name = $row->[0];
					$label       = $row->[1];
				}

				push @list, $table_name . '.' . $column_name . ' AS ' . $label;
			}
		} else {
			my $column_name = $data->{$k};
			my $label = $data->{$k};
			push @list, $table_name . '.' . $column_name . ' AS ' . $label;
		}
	}

	push @{ $self->{select_queries} }, @list;
	return $self;
}

sub select_with_hash {
	my ($self, %data) = @_;

	my @list;
	for my $k (keys %data) {
		my $sql = $k;
		my $label = $data{$k};
		push @list, $sql . ' AS ' . $label;
	}

	push @{ $self->{select_queries} }, @list;
	return $self;
}

sub from {
	my $self = shift;
	return $self->from_with_array(@_) if @_ > 1;
	push @{ $self->{from_queries} }, $_[0];
	return $self;
}

sub from_with_array {
	my ($self, @data) = @_;

	my @list;
	while (@data) {
		my $sql = shift @data;
		my $label = shift @data;
		push @list, $sql . ' ' . $label;
	}

	push @{ $self->{from_queries} }, @list;
	return $self;
}

sub add_join {
	my $self = shift;
	push @{ $self->{join_queries} }, @_;
	return $self;
}

sub where {
	my $self = shift;
	push @{ $self->{where_queries} }, $_[0];
	return $self;
}

sub add_where_if_defined {
	my ($self, $key, $value, $glue) = @_;
	return $self unless defined $value;
	$glue //= @{ $self->{where_queries} } == 0 ? "" : "AND";
	push @{ $self->{where_queries} }, qq{ $glue $key = ? };
	push @{ $self->{binds} }, $value;
	return $self;
}

sub add_where_if_not_blank {
	my ($self, $key, $value, $glue) = @_;
	return $self if not defined $value or $value eq '';
	$glue //= @{ $self->{where_queries} } == 0 ? "" : "AND";
	push @{ $self->{where_queries} }, qq{ $glue $key = ? };
	push @{ $self->{binds} }, $value;
	return $self;
}

sub add_where_as_like_if_defined {
	my ($self, $key, $value, $glue) = @_;
	return $self unless defined $value;
	$glue //= @{ $self->{where_queries} } == 0 ? "" : "AND";
	push @{ $self->{where_queries} }, qq{ $glue $key LIKE '%' || ? || '%' };
	push @{ $self->{binds} }, $value;
	return $self;
}

sub group_by {
	my $self = shift;
	push @{ $self->{group_by_queries} }, @_;
	return $self;
}

sub having {
	my $self = shift;
	push @{ $self->{having_queries} }, @_;
	return $self;
}

sub order_by {
	my $self = shift;
	if (@_ == 1) {
		push @{ $self->{order_by_queries} }, @_;
	} else {
		push @{ $self->{order_by_queries} }, $self->_order_by(@_);
	}
	return $self;
}

sub _order_by {
	my ($self, $sort_key, $sort_order) = @_;
	my @k = split '\.', $sort_key;
	$sort_key = pop @k;
	$sort_key = $sort_key_map{$sort_key} if exists $sort_key_map{$sort_key};
	$sort_key = $k[0] . '.' . $sort_key if @k;
	
	my $order_by = join ' ', $sort_key, $sort_order;
	return $order_by;
}

sub limit {
	my $self = shift;
	push @{ $self->{limit_queries} }, @_;
	return $self;
}

sub offset {
	my $self = shift;
	push @{ $self->{offset_queries} }, @_;
	return $self;
}

1;
