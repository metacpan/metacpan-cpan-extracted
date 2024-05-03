package Data::Transfigure::HashFilter::Undef 1.03;
use v5.26;
use warnings;

# ABSTRACT: filters out undefined hash values whose keys match a pattern

=head1 NAME

Data::Transfigure::HashFilter::Undef - filters out undefined hash values whose 
keys match a pattern

=head1 DESCRIPTION

C<Data::Transfigure::HashFilter::Undef> removes the key and corresponding value
from the hash in cases where the value is undefined and the key matches a given
regular expression. Matching keys can also be rewritten at the same time.

=cut

use Object::Pad;

use Data::Transfigure::Tree;
class Data::Transfigure::HashFilter::Undef : does(Data::Transfigure::Tree) {

=head1 FIELDS

=head2 key_pattern (optional param)

A compiled regular expression (C<qr/.../>) identifying keys that this 
transfigurator can apply to. If a capture group is included in the regex, the
key is rewritten to its content (additional capture groups are ignored).

Default: C<qr/(.*)\?/>

=cut

  field $key_pattern : param = qr/(.*)\?$/;

  my sub hv_filter_undef($entity, $pat) {
    if (ref($entity) eq 'HASH') {
      foreach (keys($entity->%*)) {
        if ($_ =~ $pat) {
          my $v = delete($entity->{$_});
          $entity->{$1 || $_} = $v if (defined($v));
        }
        __SUB__->($entity->{$_}, $pat) if (exists($entity->{$_}));
      }
    } elsif (ref($entity) eq 'ARRAY') {
      __SUB__->($_, $pat) foreach ($entity->@*);
    }
    return $entity;
  }

  sub BUILDARGS ($class, %args) {
    $class->SUPER::BUILDARGS(
      handler => sub ($entity) {
        return hv_filter_undef($entity, $args{key_pattern} // qr/(.*)\?$/);
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

