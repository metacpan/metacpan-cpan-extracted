package Data::Riak::Result::SingleObject;
{
  $Data::Riak::Result::SingleObject::VERSION = '2.0';
}
# ABSTRACT: Single result containing an object

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result::Object';
with 'Data::Riak::Result::Single';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Result::SingleObject - Single result containing an object

=head1 VERSION

version 2.0

=head1 DESCRIPTION

A result class for Riak requests returning one full object, such as C<GetObject>
and C<StoreObject>.

It is identical to L<Data::Riak::Result::Object>, but also composes
L<Data::Riak::Result::Single> to avoid the results being wrapped in a
L<Data::Riak::ResultSet>, as there will only ever be one result.

=head1 AUTHORS

=over 4

=item *

Andrew Nelson <anelson at cpan.org>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
