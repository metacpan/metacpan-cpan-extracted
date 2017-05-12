
package DBIx::Romani::Query::Function;

=begin xmldoc

<name> DBIx::Romani::Query::Function </name>

<synopsis>
	# Don't use directy, create a sub-class!
	use DBIx::Romani::Query::Function;
	my $func = DBIx::Romani::Query::Function->new();
	$func->add( DBIx::Romani::Query::SQL::Column->new('column_name') );
</synopsis>

<description>
	The parent class of all query functions.  A query function is something
	like COUNT() in SQL, but can include control flow functions that are 
	executed in the query engine and not in SQL.  This class is abstract and
	can't be used directly.
</description>

=cut

use strict;

=begin xmldoc

<sub type="constructor">
	<name> new() </name>
	<purpose> Constructs a new query object </purpose>
	<arguments> none </arguments>
</sub>

=cut
sub new
{
	my $class = shift;
	my $args  = shift;

	my $self = {
		arguments => [ ]
	};

	bless  $self, $class;
	return $self;
}

=begin xmldoc

<sub type="method">
	<name> get_arguments() </name>
	<purpose> Gets the argument list. </purpose>
	<returns> A list reference. </returns>
	<arguments> none </arguments>
</sub>

=cut
sub get_arguments { return shift->{arguments}; }

=begin xmldoc

<sub type="method">
	<name> add() </name>
	<purpose> Add an object to the argument list </purpose>
	<arguments> object </arguments>
</sub>

=cut
sub add
{
	my ($self, $arg) = @_;
	push @{$self->{arguments}}, $arg;
}

=begin xmldoc

<sub type="method">
	<name> visit() </name>
	<purpose> Abstract method to "execute" the function </purpose>
	<arguments> visitor </arguments>
	<returns> The result of the function </returns>
</sub>

=cut
sub visit
{
	die "Abstract.";
}

sub copy_arguments
{
	my ($self, $other) = @_;

	foreach my $arg ( @{$other->get_arguments()} )
	{
		$self->add_arguments( $arg->clone() );
	}
}

sub clone
{
	my $self = shift;
	my $class = ref($self);

	my $clone;
	$clone = $class->new();
	$clone->copy_arguments( $self );

	return $clone;
}

1;

