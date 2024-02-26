package Data::Transfigure::Predicate 1.01;
use v5.26;
use warnings;

# ABSTRACT: a transfigurator that filters based on a predicate function

=encoding UTF-8

=head1 NAME

Data::Transfigure::Type - a transfigurator that filters based on a predicate function

=head1 DESCRIPTION

C<Data::Transfigure::Predicate> is a transfigurator that uses a predicate predicate
function to determine whether it applies. This allows extrinsic logic to be 
applied to select appropriate transfigurators.

=cut

use Object::Pad;

class Data::Transfigure::Predicate : does(Data::Transfigure::Node) {
  use Data::Transfigure::Constants;

=head1 FIELDS

=head2 predicate (required param)

The predicate function. Must be a CODE refereence. Receives the node value and
position as parameters and returns a simple true/false value.

=head2 transfigurator (required parameter)

A C<Data::Transfigure> transfigurator conforming to the C<Data::Transfigure::Node> 
role. Weird things will happen if you provide a 
C<Data::Transfigure::Tree> -type transfigurator, so you probably shouldn't do
that.

=cut

  field $predicate : param;
  field $transfigurator : param;

  ADJUST {
    die("predicate must be a CODEREF") unless (ref($predicate) eq 'CODE');
  }

  sub BUILDARGS ($class, %params) {
    $class->SUPER::BUILDARGS(
      predicate      => $params{predicate},
      transfigurator => $params{transfigurator},
      handler        => sub (@args) {
        $params{transfigurator}->transfigure(@args);
      }
    );
  }

=head1 METHODS

=head2 applies_to( %params )

Requires C<$params{value}> and C<$params{position}> to exist

If C<$predicate> returns true when possed the value and position (in that order),
returns C<$MATCH_EXACT>.

Otherwise returns C<$NO_MATCH>.

=cut

  method applies_to (%params) {
    die('value is a required parameter for Data::Transfigure::Predicate->applies_to')    unless (exists($params{value}));
    die('position is a required parameter for Data::Transfigure::Predicate->applies_to') unless (exists($params{position}));
    my $node     = $params{value};
    my $position = $params{value};

    my $cbv = $predicate->($node, $position);

    return $transfigurator->applies_to(%params) if ($cbv);
    return $NO_MATCH;
  }

}

=pod

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2023 Mark Tyrrell

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=cut

1;

__END__
