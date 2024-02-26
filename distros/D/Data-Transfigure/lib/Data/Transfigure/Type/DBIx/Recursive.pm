package Data::Transfigure::Type::DBIx::Recursive 1.01;
use v5.26;
use warnings;

# ABSTRACT: transfigures DBIx::Class::Rows into hashrefs, traversing (some) relationships

=head1 NAME

Data::Transfigure::Type::DBIx - transfigures DBIx::Class::Rows into hashrefs, 
traversing (some) relationships

=head1 DESCRIPTION

C<Data::Transfigure::Type::DBIx> is used to transfigure L<DBIx::Class::Row>
instances into JSON-able structures, using C<get_inflated_columns> to get make
a hashref from the object's keys (column names) and values.

This transfigurator traverses to_one-type relationships, inserting the related
object into the resulting hashref with its relationship name as the key, instead
of the foreign key column name.

=cut

use Object::Pad;

use Data::Transfigure::Type;
class Data::Transfigure::Type::DBIx::Recursive : isa(Data::Transfigure::Type) {

=head1 FIELDS

I<none>

=cut

  sub BUILDARGS ($class) {
    $class->SUPER::BUILDARGS(
      type    => q(DBIx::Class::Row),
      handler => sub ($data) {
        my %cols = $data->get_inflated_columns;
        foreach my $rel ($data->result_source->relationships) {
          my $info = $data->result_source->relationship_info($rel);
          if ($info->{attrs}->{accessor} eq 'single') {
            delete(@cols{keys($info->{attrs}->{fk_columns}->%*)});
            $cols{$rel} = $data->$rel;
          }
        }
        return {%cols};
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
