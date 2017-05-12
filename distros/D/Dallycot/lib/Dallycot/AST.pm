package Dallycot::AST;
our $AUTHORITY = 'cpan:JSMITH';

# ABSTRACT: Abstract type representing a syntax node

use strict;
use warnings;

use utf8;
use experimental qw(switch);

use Carp qw(croak);
use Promises qw(deferred);
use Scalar::Util qw(blessed);

use Module::Pluggable
  require     => 1,
  sub_name    => '_node_types',
  search_path => 'Dallycot::AST';

use Dallycot::Value;

=head1 DESCRIPTION

Dallycot::AST is an abstract class inherited by all of the AST classes:

=over 4

=item L<Apply|Dallycot::AST::Apply>

=item L<Assign|Dallycot::AST::Assign>

=item L<BuildFilter|Dallycot::AST::BuildFilter>

=item L<BuildList|Dallycot::AST::BuildList>

=item L<BuildMap|Dallycot::AST::BuildMap>

=item L<BuildRange|Dallycot::AST::BuildRange>

=item L<BuildVector|Dallycot::AST::BuildVector>

=item L<Compose|Dallycot::AST::Compose>

=item L<Defined|Dallycot::AST::Defined>

=item L<Expr|Dallycot::AST::Expr>

=item L<Fetch|Dallycot::AST::Fetch>

=item L<ForwardWalk|Dallycot::AST::ForwardWalk>

=item L<Head|Dallycot::AST::Head>

=item L<Identity|Dallycot::AST::Identity>

=item L<Index|Dallycot::AST::Index>

=item L<Invert|Dallycot::AST::Invert>

=item L<Lambda|Dallycot::AST::Lambda>

=item L<LibraryFunction|Dallycot::AST::LibraryFunction>

=item L<Modulus|Dallycot::AST::Modulus>

=item L<Negation|Dallycot::AST::Negation>

=item L<Placeholder|Dallycot::AST::Placeholder>

=item L<Product|Dallycot::AST::Product>

=item L<PropertyLit|Dallycot::AST::PropertyLit>

=item L<Reciprocal|Dallycot::AST::Reciprocal>

=item L<Reduce|Dallycot::AST::Reduce>

=item L<Sequence|Dallycot::AST::Sequence>

=item L<Sum|Dallycot::AST::Sum>

=item L<Tail|Dallycot::AST::Tail>

=item L<TypePromotion|Dallycot::AST::TypePromotion>

=item L<Unique|Dallycot::AST::Unique>

=item L<Zip|Dallycot::AST::Zip>

=back

Additional base classes inherit from this abstract class as well:

=over 4

=item L<ComparisonBase|Dallycot::AST::ComparisonBase>

The base for the various comparison operations.

=over 4

=item L<Decreasing|Dallycot::AST::Decreasing>

=item L<Equality|Dallycot::AST::Equality>

=item L<Increasing|Dallycot::AST::Increasing>

=item L<StrictlyDecreasing|Dallycot::AST::StrictlyDecreasing>

=item L<StrictlyIncreasing|Dallycot::AST::StrictlyIncreasing>

=back

=item L<LoopBase|Dallycot::AST::LoopBase>

The base for operations that loop through a series of options.

=over 4

=item L<All|Dallycot::AST::All>

=item L<Any|Dallycot::AST::Any>

=item L<Condition|Dallycot::AST::Condition>

=item L<PropWalk|Dallycot::AST::PropWalk>

=back

=back

=cut

# use overload '""' => sub {
#   shift->to_string
# };

our @NODE_TYPES;

=func node_types

Returns a list of Perl packages that provide AST nodes.

=cut

sub is_declarative {return}

sub node_types {
  return @NODE_TYPES if @NODE_TYPES;
  (@NODE_TYPES) = shift->_node_types;
  return @NODE_TYPES;
}

__PACKAGE__->node_types;

sub new {
  my ($class) = @_;

  $class = ref $class || $class;

  return bless [] => $class;
}

=method simplify

Simplifies the node and any child nodes.

=cut

sub simplify {
  my ($self) = @_;
  return $self;
}

=method check_for_common_mistakes

Checks for any odd expressions given their context.

Returns a list of warnings.

=cut

sub check_for_common_mistakes {
  my ($self) = @_;

  return map { $_->check_for_common_mistakes } $self->child_nodes;
}

=method to_json

Returns a Perl Hash containing the JSON-LD representation of the node and
any child nodes.

=cut

sub to_json {
  my ($self) = @_;

  croak "to_json not defined for " . ( blessed($self) || $self );
}

=method to_string

Returns a Perl string containing a pseudo-code representation of the node
and any child nodes. This string may not parse. It's intended for debugging
purposes.

=cut

sub to_string {
  my ($self) = @_;

  croak "to_string not defined for " . ( blessed($self) || $self );
}

=method execute($engine)

Executes the node using the provided engine. Returns a promise.

=cut

sub execute {
  my ( $self, $engine ) = @_;

  my $d = deferred;

  $d->reject( ( blessed($self) || $self ) . " is not a valid operation" );

  return $d->promise;
}

=method identifiers

Returns a list of identifiers referenced in the current environment by this node.

=cut

sub identifiers { return () }

=method child_nodes

Returns a list of child nodes.

=cut

sub child_nodes {
  my ($self) = @_;

  return grep { blessed($_) && $_->isa(__PACKAGE__) } @{$self};
}

1;
