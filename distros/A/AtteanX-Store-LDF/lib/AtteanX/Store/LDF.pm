=head1 NAME

AtteanX::Store::LDF - Linked Data Fragment RDF store

=begin markdown

# STATUS
[![Build Status](https://travis-ci.org/phochste/AtteanX-Store-LDF.svg)](https://travis-ci.org/phochste/AtteanX-Store-LDF)
[![Coverage Status](https://coveralls.io/repos/phochste/AtteanX-Store-LDF/badge.svg)](https://coveralls.io/r/phochste/AtteanX-Store-LDF)
[![Kwalitee Score](http://cpants.cpanauthors.org/dist/AtteanX-Store-LDF.png)](http://cpants.cpanauthors.org/dist/AtteanX-Store-LDF)

=end markdown

=head1 SYNOPSIS

    use v5.14;
    use Attean;
    use Attean::RDF qw(iri blank literal);
    use AtteanX::Store::LDF;

    my $uri   = 'http://fragments.dbpedia.org/2014/en';
    my $store = Attean->get_store('LDF')->new(start_url => $uri);

    my $iter = $store->get_triples(undef,undef,literal("Albert Einstein"));

    while (my $triple = $iter->next) {
     say $triple->subject->ntriples_string .
       " " .
       $triple->predicate->ntriples_string . 
       " " .
       $triple->object->ntriples_string  .
       " .";
    }

=head1 DESCRIPTION

AtteanX::Store::LDF provides a triple-store connected to a Linked Data Fragment server.
For more information on Triple Pattern Fragments consult L<http://linkeddatafragments.org/>

=cut

use v5.14;
use warnings;

package AtteanX::Store::LDF;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION = '0.04';

use Moo;
use Attean;
use Type::Tiny::Role;
use Types::URI -all;
use RDF::LDF;
use namespace::clean;
use Carp;

with 'Attean::API::TripleStore', 'Attean::API::CostPlanner', 'MooX::Log::Any';


=head1 METHODS

Beyond the methods documented below, this class inherits methods from the
L<Attean::API::TripleStore> class.

=over 4

=item new( start_url => $start_url )

Returns a new LDF-backed storage object. The required C<start_url>
argument is a URL pointing at any Linked Data Fragment. The attribure
will be coerced, so it can be a string, a URI object, etc.

=cut

has start_url => (is => 'ro', isa => Uri, coerce => 1, required => 1);
has endpoint_url => (is => 'ro', lazy => 1, builder => '_croak_on_endpoint');
has ldf => (is => 'ro', lazy => 1, builder => '_ldf');

sub _croak_on_endpoint {
	Carp::croak "endpoint_url has been deprecated, use start_url instead";
}

sub _ldf {
    my $self = shift;
    RDF::LDF->new(url => $self->start_url->as_string);
}

sub _term_as_string {
    my ($self,$term) = @_;  
    if (!defined $term) {
        return undef
    }
	 elsif ($term->is_variable) {
		 return undef;
	 }
    elsif ($term->is_literal) {
        return $term->as_string; # includes quotes and any language or datatype
    } 
    else {
        return $term->value; # the raw IRI or blank node identifier value, without other syntax
    }
}

=item count_triples_estimate( $subject, $predicate, $object ) 

Return the count of triples matching the specified subject, predicate and 
objects.

=cut
sub count_triples_estimate {
    my $self    = shift;
    my ($s_pattern,$p_pattern,$o_pattern) = @_;
           
    my $ldf_iter = $self->ldf->get_statements(
        $self->_term_as_string($s_pattern),
        $self->_term_as_string($p_pattern),
        $self->_term_as_string($o_pattern)
    );

    return 0 unless defined $ldf_iter;

    my ($statement,$info) = $ldf_iter->();

    return $info->{'void_triples'};
}

=item get_triples( $subject, $predicate, $object)

Returns a stream object of all statements matching the specified subject,
predicate and objects. Any of the arguments may be undef to match any value.

=cut
sub get_triples {
    my $self    = shift;
    my ($s_pattern,$p_pattern,$o_pattern) = @_;

    my $ldf_iter = $self->ldf->get_statements(
        $self->_term_as_string($s_pattern),
        $self->_term_as_string($p_pattern),
        $self->_term_as_string($o_pattern)
    );

    return Attean::ListIterator->new(values => [] , item_type => 'Attean::API::Triple')
            unless $ldf_iter;

    my $iter = Attean::CodeIterator->new(
        generator => sub {
          my $statement = $ldf_iter->();
          return () unless defined($statement);
          my ($subject,$predicate,$object);

          if ($statement->subject->is_resource) {
                $subject = Attean::IRI->new($statement->subject->value);
          }
          else {
                $subject = Attean::Blank->new($statement->subject->value);
          }

          $predicate = Attean::IRI->new($statement->predicate->value);

          if ($statement->object->is_resource) {
                $object = Attean::IRI->new($statement->object->value);
          }
          elsif ($statement->object->is_literal) {
                $object = Attean::Literal->new($statement->object->value);
          }
          else {
                $object = Attean::Blank->new($statement->object->value);
          }

          my @res = (
            Attean::Triple->new(
                subject   => $subject ,
                predicate => $predicate ,
                object    => $object
            )
          );

          @res;
        },
        item_type => 'Attean::API::Triple',
    );

    return $iter;
}

=item cost_for_plan($plan)

Returns an cost estimation for a single LDF triple based on
estimates. The cost will be in the interval 10-1000 if the supplied
argument is a L<AtteanX::Plan::LDF::Triple>, undef otherwise.

=cut

sub cost_for_plan {
	my $self	= shift;
 	my $plan	= shift;
	if ($plan->isa('AtteanX::Plan::LDF::Triple')) {
		my $totals = $self->count_triples_estimate();
		if ($totals < 1) {
			$self->log->error("Total number of triples in model were $totals, probably an error");
			return 10000; # Probably a plan we don't want
		}
		return 10 + int(990 * $self->count_triples_estimate($plan->values) / $totals)
	}
	return;
}

=item plans_for_algebra($algebra)

Returns an empty plan since access_plans generates the needed plans.

=cut

sub plans_for_algebra {
	return ();
}

1;

__END__

=back

=head1 SEE ALSO

L<Attean> , L<Attean::API::TripleStore>

=head1 BUGS

Please report any bugs or feature requests to through the GitHub web interface
at L<https://github.com/phochste/AtteanX-Store-LDF>.

=head1 AUTHOR

Patrick Hochstenbach  C<< <patrick.hochstenbach@ugent.be> >>
Kjetil Kjernsmo E<lt>kjetilk@cpan.orgE<gt>.

=head1 COPYRIGHT

This software is copyright (c) 2015 by Patrick Hochstenbach.
This software is copyright (c) 2016 by Patrick Hochstenbach and Kjetil Kjernsmo.
This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
