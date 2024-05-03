package Data::Transfigure::Default 1.03;
use v5.26;
use warnings;

# ABSTRACT: a transfigurator class that matches anything at very low priority

=encoding UTF-8
 
=head1 NAME
 
Data::Transfigure::Default - a transfigurator class that matches anything at very low 
priority

=head1 DESCRIPTION

C<Data::Transfigure::Default> provides the facility for transfiguring values that
no other registered transfigurator applies to 

=cut

use Object::Pad;

class Data::Transfigure::Default : does(Data::Transfigure::Node) {
  use Data::Transfigure::Constants;

=head1 METHODS

=head2 applies_to( %params )

Always returns C<$MATCH_DEFAULT> regardless of parameters

=cut

  method applies_to (%params) {
    return $NO_MATCH if (ref($params{value}) eq 'HASH' || ref($params{value}) eq 'ARRAY');
    return $MATCH_DEFAULT;
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
