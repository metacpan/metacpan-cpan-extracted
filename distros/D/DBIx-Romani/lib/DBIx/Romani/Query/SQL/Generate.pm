
package DBIx::Romani::Query::SQL::Generate;

use DBIx::Romani::Query::Comparison;
use strict;

use Data::Dumper;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $driver;
	my $values;

	if ( ref($args) eq 'HASH' )
	{
		$driver = $args->{driver};
		$values = $args->{values};
	}
	else
	{
		$driver = $args;
	}

	if ( not defined $driver )
	{
		die "no driver.";
	}

	my $self = {
		driver => $driver,
		values => $values || { },
	};

	bless  $self, $class;
	return $self;
}

sub get_driver { return shift->{driver}; }

sub visit_select
{
	my ($self, $select) = @_;

	# check to see that we have a valid select query
	if ( scalar @{$select->get_from()} == 0 )
	{
		die "Select query must one or more tables";
	}
	if ( scalar @{$select->get_result()} == 0 )
	{
		die "Select query must have a result";
	}
	
	my $SQL = "SELECT ";
	
	# add distinct if necessary
	if ( $select->get_distinct() )
	{
		$SQL .= "DISTINCT ";
	}

	# add the result list
	my @results;
	foreach my $result ( @{$select->get_result()} )
	{
		my $s = $result->get_value()->visit( $self );
		if ( $result->get_name() )
		{
			$s .= " AS " . $result->get_name();
		}
		push @results, $s;
	}
	$SQL .= join ', ', @results;

	# add the tables
	$SQL .= ' FROM ' . join( ', ', @{$select->get_from()} );

	# add the join section
	my $join = $select->get_join();
	if ( $join )
	{
		$SQL .= " " . sprintf "%s JOIN %s ON %s", 
			uc($join->get_type()), $join->get_table(), $join->get_on()->visit($self);
	}

	# add the where statement
	if ( $select->get_where() )
	{
		my $where = $select->get_where()->visit($self);
		if ( $where )
		{
			$SQL .= " WHERE " . $select->get_where()->visit($self);
		}
	}

	# add the group by
	if ( scalar @{$select->get_group_by()} > 0 )
	{
		$SQL .= " GROUP BY " . join( ', ', map { $_->visit($self) } @{$select->get_group_by()} );
	}

	# add the order by
	if ( scalar @{$select->get_order_by()} > 0 )
	{

		my @temp;
		foreach my $order_by ( @{$select->get_order_by()} )
		{
			push @temp, sprintf( "%s %s", $order_by->get_value()->visit($self), uc($order_by->get_dir()) );
		}

		$SQL .= " ORDER BY " . join( ', ', @temp );
	}

	# limit
	$SQL = $self->get_driver()->apply_limit( $SQL, $select->get_offset(), $select->get_limit() );

	return $SQL;
}

sub visit_insert
{
	my ($self, $insert) = @_;

	return sprintf "INSERT INTO %s (%s) VALUES (%s)",
		$insert->get_into(),
		join( ', ', map { $_->{column} } @{$insert->get_values()} ),
		join( ', ', map { $_->{value}->visit($self) } @{$insert->get_values()} );
}

sub visit_update
{
	my ($self, $update) = @_;

	my $SQL = sprintf "UPDATE %s SET ", $update->get_table();

	$SQL .= join ", ", map { sprintf("%s = %s", $_->{column}, $_->{value}->visit($self)) } @{$update->get_values()};

	if ( $update->get_where() )
	{
		my $where = $update->get_where()->visit($self);
		if ( $where )
		{
			$SQL .= " WHERE $where";
		}
	}

	return $SQL;
}

sub visit_delete
{
	my ($self, $delete) = @_;

	my $SQL = sprintf "DELETE FROM %s", $delete->get_from();
	
	if ( $delete->get_where() )
	{
		my $where = $delete->get_where()->visit($self);
		if ( $where )
		{
			$SQL .= " WHERE $where";
		}
	}

	return $SQL;
}

sub visit_sql_column
{
	my ($self, $column) = @_;

	my $name = "";
	if ( $column->get_table() )
	{
		$name .= $column->get_table() . '.';
	}
	$name .= $column->get_name();

	# TODO: Column should be escaped, if necessary or possible!

	return $name;
}

sub visit_sql_literal
{
	my ($self, $literal) = @_;
	# TODO: we don't always have to escape this!  Gahwah!
	return sprintf "'%s'", $self->{driver}->escape_string( $literal->get_value() );
}

sub visit_variable
{
	my ($self, $variable) = @_;

	my $name  = $variable->get_name();
	my $value = $self->{values}->{$name};

	if ( not defined $value )
	{
		die "No value for variable named \"$name\"";
	}

	return $value->visit($self);
}

sub visit_null
{
	my ($self, $null) = @_;
	return 'NULL';
}

sub visit_comparison
{
	my ($self, $comp) = @_;

	my $lstr = $comp->get_lvalue()->visit( $self );
	my $type = $comp->get_type();
	my $rstr;

	if ( $type eq $DBIx::Romani::Query::Comparison::IS_NULL or
	     $type eq $DBIx::Romani::Query::Comparison::IS_NOT_NULL )
	{
		# there is not nothing
	}
	elsif ( $type eq $DBIx::Romani::Query::Comparison::BETWEEN )
	{
		my $rval = $comp->get_rvalue();
		my $val1 = $rval->[0]->visit( $self );
		my $val2 = $rval->[1]->visit( $self );

		$rstr = "$val1 AND $val2";
	}
	elsif ( $type eq $DBIx::Romani::Query::Comparison::IN or
	        $type eq $DBIx::Romani::Query::Comparison::NOT_IN )
	{
		$rstr = sprintf( "(%s)", join( ',', map { $_->visit($self) } @{$comp->get_rvalue()} ) );
	}
	else
	{
		$rstr = $comp->get_rvalue()->visit( $self );
	}

	# build the return string
	my $ret = "$lstr $type";
	if ( $rstr )
	{
		$ret .= " " . $rstr;
	}

	return $ret;
}

sub visit_operator
{
	my ($self, $operator) = @_;

	my $op_str = $operator->get_type();
	my $s = join( " $op_str ", map { $_->visit($self) } @{$operator->get_values()} );

	return "($s)";
}

sub visit_where
{
	my ($self, $where) = @_;

	my $op = $where->get_type();

	my @result;
	foreach my $value ( @{$where->get_values()} )
	{
		my $str = $value->visit( $self );

		if ( $value->isa( 'DBIx::Romani::Query::Where' ) )
		{
			$str = "($str)";
		}

		push @result, $str;
	}

	return join " $op ", @result;
}

sub visit_ttt_function
{
	my ($self, $ttt) = @_;

	my $s = sprintf "%s(", $ttt->get_name();
	$s .= join ", ", map { $_->visit($self) } @{$ttt->get_arguments()};
	$s .= ")";

	return $s;
}

sub visit_ttt_operator
{
	my ($self, $ttt) = @_;

	my $op = $ttt->get_operator();
	my $s  = join( " $op ", map { $_->visit($self) } @{$ttt->get_values()} );

	return "($s)";
}

sub visit_ttt_keyword
{
	my ($self, $ttt) = @_;

	# the bare keyword
	return $ttt->get_keyword();
}

sub visit_ttt_join
{
	my ($self, $ttt) = @_;

	# join values by a whitespace
	return join( " ", map { $_->visit($self) } @{$ttt->get_values()} );
}

sub visit_function_count
{
	my ($self, $func) = @_;

	if ( scalar @{$func->get_arguments()} == 0 )
	{
		die "Count function must have one value";
	}

	my $s = $func->get_arguments()->[0]->visit( $self );
	if ( $func->get_distinct() )
	{
		$s = "DISTINCT $s";
	}
	return "COUNT($s)";
}

sub visit_function_now
{
	my ($self, $func) = @_;

	return "NOW()";
}

1;

