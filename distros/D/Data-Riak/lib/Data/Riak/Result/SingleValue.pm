package Data::Riak::Result::SingleValue;
{
  $Data::Riak::Result::SingleValue::VERSION = '2.0';
}
# ABSTRACT: Result class for requests with a single result

use Moose;
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::Single';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Result::SingleValue - Result class for requests with a single result

=head1 VERSION

version 2.0

=head1 SEE ALSO

L<Data::Riak::Result::Single>

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
