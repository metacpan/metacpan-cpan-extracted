
package DBIx::Romani::Query::Select;

use DBIx::Romani::Query::Select::Result;
use DBIx::Romani::Query::Select::Join;
use DBIx::Romani::Query::Select::OrderBy;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;
	
	my $self = {
		from     => [],
		result   => [],
		where    => undef,
		join     => undef,
		group_by => [],
		order_by => [],
		limit    => undef,
		offset   => undef,
		distinct => 0,
	};

	bless $self, $class;
	return $self;
}

sub get_from     { return shift->{from}; }
sub get_result   { return shift->{result}; }
sub get_where    { return shift->{where}; }
sub get_group_by { return shift->{group_by}; }
sub get_order_by { return shift->{order_by}; }
sub get_join     { return shift->{join}; }
sub get_limit    { return shift->{limit}; }
sub get_offset   { return shift->{offset}; }
sub get_distinct { return shift->{distinct}; }

sub clear_from     { shift->{from}     = [ ]; }
sub clear_result   { shift->{result}   = [ ]; }
sub clear_where    { shift->{where}    = undef; }
sub clear_group_by { shift->{group_by} = [ ]; }
sub clear_order_by { shift->{order_by} = [ ]; }

sub clear_limit
{
	my $self = shift;

	# must clear both for sanity
	$self->{limit}  = undef; 
	$self->{offset} = undef;
}

sub add_from
{
	my ($self, $table_name) = @_;
	
	foreach my $other ( @{$self->get_from()} )
	{
		if ( $table_name eq $other )
		{
			# don't add it twice!!
			return;
		}
	}

	push @{$self->{from}}, $table_name;
}

sub add_result
{
	my $self = shift;

	my $result = DBIx::Romani::Query::Select::Result->new( @_ );
	
	my $name = $result->get_name();
	if ( defined $name )
	{
		my @temp = grep { $_->get_name() eq $name } @{$self->{result}};
		if ( scalar @temp > 0 )
		{
			die "Cannot add two results with the same name";
		}
	}

	push @{$self->{result}}, $result;
}

sub add_group_by
{
	my ($self, $result) = @_;
	push @{$self->{group_by}}, $result;
}

sub add_order_by
{
	my $self = shift;
	my $order_by = DBIx::Romani::Query::Select::OrderBy->new( @_ );
	push @{$self->{order_by}}, $order_by;
}

sub set_where
{
	my ($self, $where) = @_;
	$self->{where} = $where;
}

sub set_join
{
	my $self = shift;
	my $join = DBIx::Romani::Query::Select::Join->new( @_ );
	$self->{join} = $join;
}

sub set_limit
{
	my ($self, $limit, $offset) = @_;
	$self->{limit}  = $limit;
	$self->{offset} = $offset;
}

sub set_distinct
{
	my ($self, $distinct) = @_;
	$self->{distinct} = $distinct;
}

sub visit
{
	my ($self, $visitor) = @_;
	return $visitor->visit_select( $self );
}

sub clone
{
	my $self = shift;

	my $query = DBIx::Romani::Query::Select->new();

	# from
	foreach my $from ( @{$self->get_from()} )
	{
		$query->add_from( $from );
	}

	# result
	foreach my $result ( @{$self->get_result()} )
	{
		# A little non-standard
		push @{$query->{result}}, $result->clone();
	}

	# where 
	if ( defined $query->get_where() )
	{
		$query->set_where( $query->get_where()->clone() );
	}

	# join
	if ( defined $query->get_join() )
	{
		$query->set_join( $query->get_join()->clone() );
	}

	# group by
	foreach my $group_by ( @{$self->get_group_by()} )
	{
		$query->add_group_by( $group_by );
	}

	# order by
	foreach my $order_by ( @{$self->get_order_by()} )
	{
		$query->add_order_by( $order_by );
	}

	return $query;
}

1;

