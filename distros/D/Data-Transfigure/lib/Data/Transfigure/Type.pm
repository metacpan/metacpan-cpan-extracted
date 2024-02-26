package Data::Transfigure::Type 1.01;
use v5.26;
use warnings;

# ABSTRACT: a transfigurator that filters by reference type

=encoding UTF-8

=head1 NAME

Data::Transfigure::Type - a transfigurator that filters by reference type

=head1 DESCRIPTION

C<Data::Transfigure::Type> is a transfigurator that applies to one or more value
types. It detects both exact type matches and inherited type matches (including
role-implementing), giving priority to the former.

=cut

use Object::Pad;

class Data::Transfigure::Type : does(Data::Transfigure::Node) {
  use Data::Transfigure::Constants;

  use Scalar::Util qw(blessed);

=head1 FIELDS

=head2 type (required param)

The type to check against. To check for multiple types, provide an arrayref of
the type names.

=cut

  field $type : param;

  ADJUST {
    foreach my $t (grep {defined} $self->types()) {
      die("$t cannot be used with Data::Transfigure::Type - use Data::Transfigure::Schema")
        if ($t eq 'ARRAY' || $t eq 'HASH');
    }
  }

=head1 METHODS

=head2 types()

Returns a list of the types to be checked against

=cut

  method types() {
    return ref($type) eq 'ARRAY' ? $type->@* : $type;
  }

=head2 applies_to( %params )

Requires C<$params{value}> to exist

If C<$params{value}>'s type is exactly any of C<types()>, returns 
C<$MATCH_EXACT_TYPE>.

Otherwise, if the value's type is a subclass of any of C<types()>, returns
C<$MATCH_INHERITED_TYPE>.

Otherwise returns C<$NO_MATCH>.

=cut

  method applies_to (%params) {
    die('value is a required parameter for Data::Transfigure::Type->applies_to') unless (exists($params{value}));
    my $node = $params{value};

    my $rv = $NO_MATCH;
    if (my $r = ref($node)) {
      foreach ($self->types()) {
        return $MATCH_EXACT_TYPE    if ($r eq $_);
        $rv = $MATCH_INHERITED_TYPE if (blessed($node) && ($node->isa($_) || $node->DOES($_)));
      }
    }
    return $rv;
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
