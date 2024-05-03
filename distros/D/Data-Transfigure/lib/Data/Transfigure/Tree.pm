package Data::Transfigure::Tree 1.03;
use v5.26;
use warnings;

# ABSTRACT: a transfigurator that is applied to the entire data structure

=head1 NAME

Data::Transfigure::Tree - a transfigurator that is applied to the entire data 
structure, after all "node" transfigurations have been completed

=head1 DESCRIPTION

C<Data::Transfigure::Tree> transfigurators are used to "clean-up" the data
structure after all other transfigurations have been applied. 

=cut

use Object::Pad;

role Data::Transfigure::Tree {
  field $handler : param;

=head1 METHODS

=head2 transfigure( @args )

Executes the handler on the entire data structure. Typically this shouldn't be 
called manually or need to be overridden by subclasses.

=cut

  method transfigure (@args) {
    return $handler->(@args);
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
