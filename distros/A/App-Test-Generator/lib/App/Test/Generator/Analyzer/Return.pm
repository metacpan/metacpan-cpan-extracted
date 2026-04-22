package App::Test::Generator::Analyzer::Return;

use strict;
use warnings;
use Carp    qw(croak);
use Readonly;

# --------------------------------------------------
# Evidence weights for each detected return pattern.
# Higher weights indicate stronger signals that the
# detected pattern is the primary return behaviour.
# --------------------------------------------------
Readonly my $WEIGHT_RETURNS_PROPERTY => 20;
Readonly my $WEIGHT_RETURNS_SELF     => 15;
Readonly my $WEIGHT_RETURNS_CONSTANT => 10;

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Analyses the source code of a method and adds evidence to a
L<App::Test::Generator::Model::Method> object describing what kind of
value the method returns. Evidence is used downstream by
L<App::Test::Generator::Model::Method/resolve_return_type> to determine
the most likely return type.

=head2 new

Construct a new Return analyser.

    my $analyser = App::Test::Generator::Analyzer::Return->new;

=head3 Arguments

None.

=head3 Returns

A blessed hashref.

=head3 API specification

=head4 input

    {}

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Analyzer::Return',
    }

=cut

sub new {
	my $class = $_[0];
	return bless {}, $class;
}

=head2 analyze

Scan the source code of a method for return patterns and add weighted
evidence to the method object. Detects three patterns: returning a
property from C<$self>, returning C<$self> itself, and returning a
constant literal value.

    my $analyser = App::Test::Generator::Analyzer::Return->new;
    $analyser->analyze($method);

    my $type = $method->resolve_return_type;

=head3 Arguments

=over 4

=item * C<$method>

An L<App::Test::Generator::Model::Method> object. Evidence is added
to this object in place via C<add_evidence>.

=back

=head3 Returns

Nothing (undef). All results are communicated via side effects on the
C<$method> object.

=head3 Notes

The interface of this analyser differs from
L<App::Test::Generator::Analyzer::ReturnMeta>, which operates on a raw
schema hashref. This analyser operates on a C<Model::Method> object
directly.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT, isa => 'App::Test::Generator::Analyzer::Return' },
        method => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' },
    }

=head4 output

    { type => UNDEF }

=cut

sub analyze {
	my ($self, $method) = @_;

	# Accept either a Model::Method object or a raw hashref,
	# since callers in SchemaExtractor pass raw hashrefs
	my $source = ref($method) && $method->can('source')
		? $method->source()
		: ($method->{source} // $method->{body} // '');

	# --------------------------------------------------
	# Detect: return $self->{property}
	# Negative lookahead ensures this does not also match
	# plain return $self (handled separately below)
	# --------------------------------------------------
	if($source =~ /return\s+\$self->\{(\w+)\}/) {
		$method->add_evidence(
			category => 'return',
			signal   => 'returns_property',
			value    => $1,
			weight   => $WEIGHT_RETURNS_PROPERTY,
		);
	}

	# --------------------------------------------------
	# Detect: return $self
	# Use negative lookahead to avoid matching
	# return $self->{...} which is a property return
	# --------------------------------------------------
	if($source =~ /return\s+\$self(?!->)/) {
		$method->add_evidence(
			category => 'return',
			signal   => 'returns_self',
			weight   => $WEIGHT_RETURNS_SELF,
		);
	}

	# --------------------------------------------------
	# Detect: return of a constant literal — quoted string,
	# numeric literal, or undef. All indicate the method
	# returns a fixed value rather than computed state.
	# --------------------------------------------------
	if($source =~ /return\s+(?:['"\d]|undef\b)/) {
		$method->add_evidence(
			category => 'return',
			signal   => 'returns_constant',
			weight   => $WEIGHT_RETURNS_CONSTANT,
		);
	}

	return;
}

1;
