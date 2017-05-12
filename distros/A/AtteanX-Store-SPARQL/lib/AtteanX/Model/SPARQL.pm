package AtteanX::Model::SPARQL;

use v5.14;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.010';

use Moo;
use Types::Standard qw(InstanceOf);
use namespace::clean;

has 'store'    => (
						 is => 'ro',
						 isa => InstanceOf['AtteanX::Store::SPARQL'],
						 required => 1,
						 handles => { size => 'size' ,
										  get_quads => 'get_triples',
										  count_quads => 'count_triples',
										  get_sparql => 'get_sparql',
										  plans_for_algebra => 'plans_for_algebra'
										}
						);


with 'Attean::API::Model', 'Attean::API::CostPlanner';

sub cost_for_plan {
	my $self = shift;
 	my $plan = shift;
 	my $planner = shift;

	# TODO: check if the store does something
	if ($plan->isa('AtteanX::Plan::SPARQLBGP')) {
		# BGPs should have a cost proportional to the number of triple patterns,
		# but be much more costly if they contain a cartesian product.
		if ($plan->children_are_variable_connected) {
			return 10 * scalar(@{ $plan->children });
		} else {
			return 100 * scalar(@{ $plan->children });
		}
	}
	return;
}

sub get_graphs {
	return Attean::ListIterator->new();
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

AtteanX::Model::SPARQL - Attean SPARQL Model

=head1 SYNOPSIS

  my $store = Attean->get_store('SPARQL')->new(endpoint_url => $url);
  my $model = AtteanX::Model::SPARQL->new( store => $store );

=head1 DESCRIPTION

This model is in practice a thin wrapper around the underlying SPARQL
store, that adds facilities only to allow quering and planning with
quad semantics.

It consumes L<Attean::API::Model> and L<Attean::API::CostPlanner> and
adds no new methods or attributes.

=head1 OTHER DETAILS

For author, copyright and other details, see L<AtteanX::Store::SPARQL>.


=cut

