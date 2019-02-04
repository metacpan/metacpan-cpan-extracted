=head1 NAME

AtteanX::Plan::SPARQLBGP - Plan for efficient evaluation of SPARQL BGPs on remote endpoints

=head1 SYNOPSIS

This is typically only constructed by planning hacks deep in the code,
but might look like:

  use v5.14;
  use AtteanX::Plan::SPARQLBGP;
  my $new_bgp_plan = AtteanX::Plan::SPARQLBGP->new(children => [$some_quads],
                                                            distinct => 0,
                                                            ordered => []);

=head1 DESCRIPTION

This plan class implements compiling basic graph patterns that can be
joined remotely on a SPARQL endpoint.

=head2 Attributes and methods

Consumes L<Attean::API::QueryTree>, L<Attean::API::Plan> and
L<Attean::API::UnionScopeVariablesPlan>, and introduces nothing
new. The most notable attribute is:

=over

=item C<< children >>

which takes an arrayref of L<Attean::Plan::Quad> objects to be
included in the Basic Graph pattern that will be evaluated against the
model.

=back

=head1 OTHER DETAILS

For author, copyright and other details, see L<AtteanX::Store::SPARQL>.

=cut


package AtteanX::Plan::SPARQLBGP;

use v5.14;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION   = '0.012';

use Moo;
use Scalar::Util qw(blessed);

with 'Attean::API::QueryTree',
     'Attean::API::Plan',
     'Attean::API::UnionScopeVariablesPlan',
     'MooX::Log::Any';

sub plan_as_string {
 	my $self = shift;
	return 'SPARQLBGP';
}

sub impl {
	my $self = shift;
	my $model = shift;
	my $sparql = 'SELECT * WHERE {';
	foreach my $child (@{$self->children}) {
		my @terms = $child->values; 
		my $pattern = Attean::TriplePattern->new(@terms[0..2]);
		$sparql .= "\n  " . $pattern->as_sparql . ' . ';
	}
	$sparql .= "\n}\n";
	$self->log->debug("Using query:\n$sparql");
	return sub {
		return $model->get_sparql($sparql)
	}
}

1;
