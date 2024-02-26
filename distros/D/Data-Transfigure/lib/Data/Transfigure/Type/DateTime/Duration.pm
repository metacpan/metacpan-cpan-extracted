package Data::Transfigure::Type::DateTime::Duration 1.01;
use v5.26;
use warnings;

# ABSTRACT: transfigures DateTime::Duration objects to ISO8601 format

=head1 NAME

Data::Transfigure::Type::DateTime::Duration - transfigures DateTime::Duration 
objects to ISO8601 format

=head1 DESCRIPTION

C<Data::Transfigure::Type::DateTime::Duration> transfigures L<DateTime::Duration> 
objects to  L<ISO8601|https://en.wikipedia.org/wiki/ISO_8601#Durations> 
(duration!) format.

=cut

use Object::Pad;

use Data::Transfigure::Type;
class Data::Transfigure::Type::DateTime::Duration : isa(Data::Transfigure::Type) {
  use DateTime::Format::Duration::ISO8601;

=head1 FIELDS

I<none>

=cut

  sub BUILDARGS ($class) {
    $class->SUPER::BUILDARGS(
      type    => q(DateTime::Duration),
      handler => sub ($data) {
        return DateTime::Format::Duration::ISO8601->format_duration($data);
      }
    );
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
