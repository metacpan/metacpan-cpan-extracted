=pod

=head1 NAME

AtteanX::Plan::LDF::Triple - Plan for evaluation of Linked Data Fragments

=head1 SYNOPSIS

This is typically only constructed by planning hacks deep in the code,
but might look like e.g.:

  use v5.14;
  use AtteanX::Plan::LDF::Triple;
  my $ldf_plan = AtteanX::Plan::LDF::Triple->new(subject => $subject,
                                                        predicate => $predicate,
                                                        object => $object);


=head1 DESCRIPTION

This plan class will aid a query planner that seeks to incorporate
Linked Data Fragments into the query planning.

=cut


package AtteanX::Plan::LDF::Triple;
# Most of the code is shamelessly stolen from Attean::API::Quad, since
# it has very much in common with that module. Unfortunately, this has
# just triple semantics, so it cannot just simply be extended. This
# probably implies that the quad plan should be refactored into some
# roles.

use v5.14;
use warnings;

our $AUTHORITY = 'cpan:KJETILK';
our $VERSION = '0.04';

use Moo;
use Class::Method::Modifiers;
use Attean;
use Carp;
use Scalar::Util qw(blessed reftype);
use namespace::clean;

has 'subject'	=> (is => 'ro', required => 1);
has 'predicate'	=> (is => 'ro', required => 1);
has 'object'	=> (is => 'ro', required => 1);

with 'Attean::API::BindingSubstitutionPlan', 'Attean::API::NullaryQueryTree';
with 'Attean::API::TriplePattern';

around 'BUILDARGS' => sub {
	my $orig		= shift;
	my $class		= shift;
	my $args		= $orig->( $class, @_ );
	if (exists $args->{in_scope_variables}) {
		Carp::confess "in_scope_variables is computed automatically, and must not be specified in the $class constructor";
	}
	
	my %vars;
	foreach my $pos (qw(subject predicate object)) {
		my $term	= $args->{$pos};
		if (blessed($term) and $term->does('Attean::API::Variable')) {
			$vars{$term->value}	= $term;
		}
	}
	
	my @vars	= keys %vars;
	$args->{in_scope_variables}	= [@vars];
	
	return $args;
};

sub plan_as_string {
	my $self	= shift;
	my @nodes	= $self->values;
	my @strings;
	foreach my $t (@nodes) {
		if (ref($t) eq 'ARRAY') {
			my @tstrings	= map { $_->ntriples_string } @$t;
			if (scalar(@tstrings) == 1) {
				push(@strings, @tstrings);
			} else {
				push(@strings, '[' . join(', ', @tstrings) . ']');
			}
		} elsif ($t->does('Attean::API::TermOrVariable')) {
			push(@strings, $t->ntriples_string);
		} else {
			use Data::Dumper;
			die "Unrecognized node in quad pattern: " . Dumper($t);
		}
	}
	return sprintf('LDFTriple { %s }', join(', ', @strings));
}
	
sub substitute_impl {
	my $self	= shift;
	my $model	= shift;
	my $b		= shift;
	my @values	= $self->values;
	foreach my $i (0 .. $#values) {
		my $value	= $values[$i];
		if (reftype($value) eq 'ARRAY') {
			my @values;
			foreach my $value (@{ $value }) {
				my $name	= $value->value;
				if (my $node = $b->value($name)) {
					push(@values, $node);
				} else {
					push(@values, $value);
				}
				$values[$i]	= \@values;
			}
		} elsif ($value->does('Attean::API::Variable')) {
			my $name	= $value->value;
			if (my $node = $b->value($name)) {
				$values[$i]	= $node;
			}
		}
	}
	
	return sub {
		return $model->get_bindings( @values );
	}
}

sub impl {
	my $self	= shift;
	my $model	= shift;
	my @values	= $self->values;
	return sub {
		return $model->get_bindings( @values );
	}
}


1;
