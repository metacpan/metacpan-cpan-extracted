package Data::Transfigure::Tree::Merge 1.03;
use v5.26;
use warnings;

# ABSTRACT: merges marked hashrefs into their parent hash

=head1 NAME

Data::Transfigure::Tree::Merge - merges marked hashrefs into their parent hash

=head1 DESCRIPTION

C<Data::Transfigure::Tree::Merge> allows you to mark a hashref key with a 
trailing C<%> to indicate that you want the HashRef pointed to by that key to be
merged into the HashRef containing it. Common keys are overwritten by the merged
data.

=cut

use Object::Pad;

use Data::Transfigure::Tree;
class Data::Transfigure::Tree::Merge : does(Data::Transfigure::Tree) {

=head1 FIELDS

=head2 I<none>

=cut

  my sub tree_merge($entity) {
    if (ref($entity) eq 'HASH') {
      foreach (grep {/%$/} keys($entity->%*)) {
        next unless (ref($entity->{$_}) eq 'HASH');
        my $h = delete($entity->{$_});
        $entity->{$_} = $h->{$_} foreach (keys($h->%*));
        __SUB__->($entity);
      }
      __SUB__->($entity->{$_}) foreach (keys($entity->%*));
    } elsif (ref($entity) eq 'ARRAY') {
      __SUB__->($_) foreach ($entity->@*);
    }
    return $entity;
  }

  sub BUILDARGS ($class, %args) {
    $class->SUPER::BUILDARGS(
      handler => sub ($entity) {
        return tree_merge($entity);
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

