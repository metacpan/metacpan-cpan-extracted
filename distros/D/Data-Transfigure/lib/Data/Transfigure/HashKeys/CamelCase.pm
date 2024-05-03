package Data::Transfigure::HashKeys::CamelCase 1.03;
use v5.26;
use warnings;

# ABSTRACT: converts hash keys to lowerCamelCase

=head1 NAME

Data::Transfigure::HashKeys::CamelCase - converts hash keys to 
lowerCamelCase

=head1 DESCRIPTION

C<Data::Transfigure::HashKeys::CamelCase> is intended for cases where the
backend policies require C<snake_case> but the frontend (and API) policies 
dictate C<camelCase>. As a post-process transfigurator, adding it rewrites all of 
the structure's hash keys to the proper format in that scenario.

=cut

use Object::Pad;

use Data::Transfigure::Tree;
class Data::Transfigure::HashKeys::CamelCase : does(Data::Transfigure::Tree) {
  use Data::Transfigure       qw(hk_rewrite_cb);
  use String::CamelSnakeKebab qw(lower_camel_case);

=head1 FIELDS

I<none>

=cut

  sub BUILDARGS ($class) {
    $class->SUPER::BUILDARGS(
      handler => sub ($entity) {
        return hk_rewrite_cb($entity, \&lower_camel_case);
      }
    );
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
