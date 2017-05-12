package DBIx::Foo::UpdateQuery;

use strict;

use Tie::IxHash;
use Log::Any qw($log);

####################################################
# Constructor
#

sub new {

	my ($class, $table, $dbh) = @_;

	die "No Table name passed to UpdateQuery" unless $table;

	my $self = {
		table 	=> $table,
		dbh 	=> $dbh,
		fields 	=> {},
		keys 	=> {},
		debug 	=> 0
	};

	bless $self, $class;

	# use tied hashes to preserve the order of added fields
	tie(%{$self->{fields}}, 'Tie::IxHash');
	tie(%{$self->{keys}}, 'Tie::IxHash');

	return $self;
}

####################################################
# Properties
#

sub UpdateQuery {

	my $self = $_[0];

	my $field_list = "";
	my @args;

	for my $field (keys %{$self->{fields}})
	{
		$field_list .= ", " if $field_list;

		my $value = $self->{fields}->{$field};

		# Temp fix for current_timestamp as a param
		if ($value && $value eq "current_timestamp()") {

			$field_list .= "$field = current_timestamp()";

		} else {

			$field_list .= "$field = ?";

			push @args, $value;
		}
	}

	my ($where, @keys) = $self->WhereClause();

	my $query = "update " . $self->{table} . " set $field_list $where;";

	#warn $query . " : " . join(",", @args, @keys);

	return $query, @args, @keys;

}

sub InsertQuery {

	my $self = $_[0];

	my $field_list = "";
	my $value_list = "";
	my @args;

	for my $field (keys %{$self->{fields}})
	{
		$field_list .= ", " if $field_list;
		$value_list .= ", " if $field_list;

		$field_list .= $field;

		my $value = $self->{fields}->{$field};

		# Temp fix for current_timestamp as a param
		if ($value && $value eq "current_timestamp()") {

			$value_list .= "current_timestamp()";

		} else {

			$value_list .= "?";

			push @args, $value;
		}
	}

	for my $field (keys %{$self->{keys}})
	{
		$field_list .= ", " if $field_list;
		$value_list .= ", " if $field_list;

		$field_list .= $field;
		$value_list .= "?";

		push @args, $self->{keys}->{$field};
	}

	my $query = "insert into " . $self->{table} . " ( $field_list ) values ( $value_list );";

	return $query, @args;
}

sub DeleteQuery {

	my $self = $_[0];

	my ($where, @keys) = $self->WhereClause();

	my $query = "delete from " . $self->{table} . " $where";

	return $query, @keys;
}

sub WhereClause
{
	my $self = $_[0];

	my $where = "";
	my @args;

	for my $field (keys %{$self->{keys}})
	{
		$where .= " and " if $where;

		$where .= "$field = ?";

		push @args, $self->{keys}->{$field};
	}

	$where = "where $where" if $where;

	return $where, @args;
}


####################################################
# Methods
#

sub addKey {

	my ($self, $field, $value) = @_;

	$self->{keys}->{$field} = $value;
}

sub addField {

	my ($self, $field, $value) = @_;

	$value = undef if $value && $value eq ''; # MT - not sure about this!  Maybee remove this line?

	$self->{fields}->{$field} = $value;
}

sub addFields {

	my $self = shift;

	my $fields;

	if (ref($_[0]) eq 'HASH') {

		$fields = $_[0];

	} else {

		$fields = {@_};
	}

	while (my ($field, $value) = each(%$fields)) {

		$value = undef if $value eq '';

		$self->{fields}->{$field} = $value;
	}
}

sub DoInsert {

	my ($self, $dbh) = @_;

	$dbh = $self->{dbh} unless $dbh;

	my ($sql, @args) = $self->InsertQuery();

	my $rows;

	$dbh->do($sql, {}, @args);

	log_query($dbh, $sql, \@args);

	return 0 if $dbh->err;

	my $newid = $dbh->last_insert_id(undef, undef, $self->{table}, undef);

	$log->info("Insert ID: $newid");

	return $newid;
}

sub DoUpdate {

	my ($self, $dbh) = @_;

	$dbh = $self->{dbh} unless $dbh;

	my ($sql, @args) = $self->UpdateQuery();

	unless (keys %{$self->{keys}}) {

		$log->error("Update query with no keys not allowed: $sql (" . join(",", @args) . ")");

		return undef;
	}

	my $rows = $dbh->do($sql, {}, @args);

	log_query($dbh, $sql, \@args);

	return 0 if $dbh->err;

	$log->info("Updated: $rows");

	return($rows);
}

sub DontUpdate {

	# for testing: don't do anything, just show SQL update statement & its args

	my ($self, $dbh) = @_;

	my ($sql, @args) = $self->UpdateQuery();

	warn "UpdateQuery->DoUpdate: $sql  " . join(",", @args);

	return 1;
}

sub DoDelete {

	my ($self, $dbh) = @_;

	$dbh = $self->{dbh} unless $dbh;

	my ($sql, @args) = $self->DeleteQuery();

	my $rows = $dbh->do($sql, {}, @args);

	log_query($dbh, $sql, \@args);

	return 0 if $dbh->err;

	$log->info("Deleted: $rows");

	return $rows;
}


sub log_query
{
	my ($dbh, $sql, $args) = @_;

	# use the 'caller' function name to work out context
	my $caller = ( caller(2) )[3];

	if ($dbh->err) {

		$log->error($dbh->errstr . " - $sql (" . join(",", @$args) . ") called by $caller");

	} else {

		$log->debug("$sql (" . join(",", @$args) . ") called by $caller");
	}
}


####################################################
# End of Package
####################################################

1;

