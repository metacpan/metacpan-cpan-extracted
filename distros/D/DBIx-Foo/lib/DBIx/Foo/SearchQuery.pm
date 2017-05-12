package DBIx::Foo::SearchQuery;

use strict;

use Storable;

sub new {

        my $class = $_[0];
		my $query = $_[1];
		my $page = $_[2] || 1;
		my $pagesize = $_[3] || 20;
		my $relation = $_[4] || ' and ';

        my $self = {
                query 	=> $query,
				page 	=> $page,
				pagesize => $pagesize,
				relation => $relation,
                debug 	=> 0
        };

        bless $self, $class;

        return $self;
}

####################################################
# Properties
#

sub IsEmptySearch {

	my $self = $_[0];

	return 0 if scalar keys %{$self->{filter_fields}} > 0;
	return 0 if scalar keys %{$self->{search_fields}} > 0;
	return 0 if scalar keys %{$self->{match_fields}} > 0;
	return 0 unless $self->{sql_fields};

	return 1;
}

sub CurrentPage {

	my $self = $_[0];

	return $self->{page};

}

sub PageSize {

	my $self = $_[0];

	return $self->{pagesize};

}


sub RowcountQuery {

	my $self = $_[0];

	my ($where, @args) = $self->WhereClause();

	my $query = $self->{query} . $where;

	$query = "select count(*) " . substr($query, index($query, "from"));

	return $query, @args;
}

sub DoSearch {

	my ($self, $dbh) = @_;

	my ($query, @args) = $self->Query();

	return $dbh->selectall_arrayref($query, { Slice => {} }, @args);
}

sub DoSearchAsArray {

	my ($self, $dbh) = @_;

	my ($query, @args) = $self->Query();

	return $dbh->selectall_arrayref($query, { Slice => () }, @args);
}

sub DoSearchAsColArray {

	my ($self, $dbh) = @_;

	my ($query, @args) = $self->Query();

	return $dbh->selectcol_arrayref($query, @args);
}

sub GetRowcount {

	my ($self, $dbh) = @_;

	my ($query, @args) = $self->RowcountQuery();

	return $dbh->selectrow_array($query, {}, @args);
}

sub Query {

	my $self = $_[0];

    my $logger = Log::Log4perl->get_logger('db.searchquery.query');

	my $caller = ( caller(2) )[3];

	my ($where, @args) = $self->WhereClause();

	my $query = $self->{query} . $where . $self->SortOrder . $self->Limit;

	$logger->debug("$query (" . join(", ", @args) . ") called by $caller");

	return $query, @args;
}

sub WhereClause {

	my $self = $_[0];

	my $search = "";
	my $filter = "";
	my $sql_fields = "";
	my $match = "";
	my $predicate = "";

	my @args;

	for my $field (keys %{$self->{search_fields}}) {

		$search .= $self->{relation} if $search;
		$search .= "$field like ?";
		push @args, '%' . $self->{search_fields}->{$field} . '%';
	}

	$search = "($search)" if scalar keys %{$self->{search_fields}} > 1;

	for my $field (keys %{$self->{filter_fields}}) {

		# TODO May need to handle various data types here e.g. numeric, date
		# but for now mysql will accept these as strings

		$filter .= " and " if $filter;

		if (ref($self->{filter_fields}->{$field}) eq 'ARRAY') {

			my @placeholders;

			foreach my $value (@{$self->{filter_fields}->{$field}}) {

				push @placeholders, '?';
				push @args, $value;
			}

			$filter .= "$field in (" . (join ',', @placeholders) . ')';
		}
		else {
			$filter .= "$field = ?";
			push @args, $self->{filter_fields}->{$field};
		}
	}

	for my $field (keys %{$self->{match_fields}}) {

		$match .= " and " if $match;

		$match .= "match ($field) against (?)";
		push @args, $self->{match_fields}->{$field};
	}

	$predicate = $self->{predicate_fields}->{predicate};

	if ($self->{sql_fields}) {
		for my $field (@{$self->{sql_fields}}) {

			$sql_fields .= " and " if $sql_fields;
			$sql_fields .= $field;
		}
	}

	# Match ... against ...

	my $where = '';

	$where = " where " if $filter || $search || $sql_fields || $match || $predicate;
	$where .= "$search " if $search;

	$where .= "and " if $search && $filter;
	$where .= "$filter " if $filter;

	$where .= "and " if ($filter || $search) && $sql_fields;
	$where .= "$sql_fields " if $sql_fields;

	$where .= "and " if ($filter || $search || $sql_fields) && $match;
	$where .= "$match " if $match;

	$where .= "and " if ($filter || $search || $sql_fields ||$match) && $predicate;
	$where .= "$predicate " if $predicate;

	return $where, @args;
}

sub SortOrder {

	my $self = $_[0];

	my $orderby;

	# TODO Add logic to build sort order clause from array
	if ($self->{sort}) {

		foreach my $sortfield (@{$self->{sort}}) {

			$orderby .= ", " if $orderby;

			$orderby .= $sortfield;
		}
	}

	$orderby = " order by $orderby" if $orderby;

	return $orderby;
}

sub Limit {

	my $self = $_[0];

	# TODO Add logic to build limit clause from object properties, and handle pages

	my $start = $self->{pagesize} * ($self->{page} - 1);
	my $rows = $self->{pagesize};

	return " limit $start, $rows";
}


####################################################
# Methods
#

sub addSearch
{
	my ($self, $field, $value) = @_;

	if ($value) {
		$self->{search_fields}->{$field} = $value;
	}
}


sub addFilter
{
	my ($self, $field, $value) = @_;

	if ($value) {
		$self->{filter_fields}->{$field} = $value;
	}
}

sub addMatch
{
	my ($self, $field, $value) = @_;

	if ($value) {
		$self->{match_fields}->{$field} = $value;
	}
}

sub addPredicate {

	my $self = $_[0];
	my $value = $_[1];

	$self->{predicate_fields}->{predicate} = $value;

}

sub addSql
{
	# Allows addition of free sql as an extra field
	# intended use e.g. $query->addSql("OtherID in (select OtherID from others where OtherName like '%" . $self->param('other') . "%')" ) if $self->param('other');

	my ($self, $value) = @_;

	$self->{sql_fields} = [] unless $self->{sql_fields};

	if ($value) {
		push @{$self->{sql_fields}}, $value;
	}
}

sub addSort {

	my $self = shift;
	my $field = shift;
	my $order = shift || "ASC";

	if (ref($field) eq 'HASH') {

		my $data = \%{$field};

		$field = $data->{sortfield};
		$order = $data->{sortorder};
	}

	if ($field) {
		push(@{$self->{sort}}, "$field $order");
	}
}

sub freeze {

	my $self = shift;

	return Storable::freeze($self);
}



1;

