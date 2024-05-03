package Data::Transfigure::Value 1.03;
use v5.26;
use warnings;

# ABSTRACT: a transfigurator that filters by node value

=encoding UTF-8

=head1 NAME

Data::Transfigure::Value - a transfigurator that filters by node value

=head1 DESCRIPTION

C<Data::Transfigure::Value> is a transfigurator that applies to one or more node
values. It can either match exactly if the node value and the supplied value are
equal, or it can match loosely if the supplied value is a compiled regular
expression, or a callback CODEREF.

=cut

use Object::Pad;

class Data::Transfigure::Value : does(Data::Transfigure::Node) {
  use Data::Transfigure::Constants;

=head1 FIELDS

=head2 value (required param)

C<value> is required and can either be a simple scalar value, or a CODE 
reference, or a compiled regular expression.

=cut

  field $value : param;

  ADJUST {
    die(ref($value) . ' is not acceptable for Data::Transfigure::Value(value)')
      if (ref($value) && ref($value) ne 'CODE' && ref($value) ne 'Regexp');
  }

=head1 METHODS

=head2 applies_to( %params )

Requires C<$params{value}> to exist

Returns C<$MATCH_EXACT_VALUE> if neither C<$params{value}> nor C<value> are 
defined, or if C<$params{value}> is not a reference and C<$params{value}> equals
C<value>.

Returns C<$MATCH_LIKE_VALUE> if C<value> is a regular expression and it matches
C<$params{value}> or if C<value> is a CODE reference and returns a truth-y value
when given C<$params{value}>.

Returns C<$NO_MATCH> otherwise.

=cut

  method applies_to (%params) {
    die('value is a required parameter for Data::Transfigure::Value->applies_to') unless (exists($params{value}));
    my $node = $params{value};

    return $MATCH_EXACT_VALUE if (!defined($node) && !defined($value));
    return $NO_MATCH          if (!defined($node) || !defined($value));
    return $MATCH_EXACT_VALUE if (!ref($value)            && $node eq $value);
    return $MATCH_LIKE_VALUE  if (ref($value) eq 'Regexp' && $node =~ /$value/);
    return $MATCH_LIKE_VALUE  if (ref($value) eq 'CODE'   && $value->($node));
    return $NO_MATCH;
  }

}

=pod

=head1 AUTHOR

Mark Tyrrell C<< <mark@tyrrminal.dev> >>

=head1 LICENSE

Copyright (c) 2024 Mark Tyrrell

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
