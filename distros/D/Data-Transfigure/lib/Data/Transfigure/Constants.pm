package Data::Transfigure::Constants 1.03;
use v5.26;
use warnings;

# ABSTRACT: defines constants used by Data::Transfigure and its transfigurators

=head1 NAME

Data::Transfigure::Constants;

=head1 DESCRIPTION

Defines the following constants, in ascending value order:

=over

=item $NO_MATCH

=item $MATCH_DEFAULT

=item $MATCH_INHERITED_TYPE

=item $MATCH_EXACT_TYPE

=item $MATCH_LIKE_VALUE

=item $MATCH_EXACT_VALUE

=item $MATCH_WILDCARD_POSITION

=item $MATCH_EXACT_POSITION

=item $MATCH_EXACT

=back

=cut

use Exporter qw(import);
use Readonly;

our @EXPORT = qw(
  $NO_MATCH
  $MATCH_DEFAULT
  $MATCH_INHERITED_TYPE
  $MATCH_EXACT_TYPE
  $MATCH_LIKE_VALUE
  $MATCH_EXACT_VALUE
  $MATCH_WILDCARD_POSITION
  $MATCH_EXACT_POSITION
  $MATCH_EXACT
);

Readonly::Scalar our $NO_MATCH                => -1;
Readonly::Scalar our $MATCH_DEFAULT           => 0b00000001;
Readonly::Scalar our $MATCH_INHERITED_TYPE    => 0b00000010;
Readonly::Scalar our $MATCH_EXACT_TYPE        => 0b00000100;
Readonly::Scalar our $MATCH_LIKE_VALUE        => 0b00001000;
Readonly::Scalar our $MATCH_EXACT_VALUE       => 0b00010000;
Readonly::Scalar our $MATCH_WILDCARD_POSITION => 0b00100000;
Readonly::Scalar our $MATCH_EXACT_POSITION    => 0b01000000;
Readonly::Scalar our $MATCH_EXACT             => 0b10000000;

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
