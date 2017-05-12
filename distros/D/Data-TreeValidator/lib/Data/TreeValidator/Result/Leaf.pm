package Data::TreeValidator::Result::Leaf;
{
  $Data::TreeValidator::Result::Leaf::VERSION = '0.04';
}
# ABSTRACT: The result of processing a leaf node
use Moose;

has 'clean' => (
    is => 'ro',
    predicate => 'has_clean_data'
);

sub valid { shift->has_clean_data }

with 'Data::TreeValidator::Result';

1;



__END__
=pod

=encoding utf-8

=head1 NAME

Data::TreeValidator::Result::Leaf - The result of processing a leaf node

=head1 DESCRIPTION

This result object is the result of calling process on a
L<Data::TreeValidator::Leaf>.

=head1 METHODS

=head2 clean

Returns clean data for this field.

=head2 has_clean_data

A predicate to determine if this field has clean data.

=head2 valid

An alias for C<has_clean_data>.

=head1 AUTHOR

Oliver Charles

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Oliver Charles <oliver.g.charles@googlemail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

