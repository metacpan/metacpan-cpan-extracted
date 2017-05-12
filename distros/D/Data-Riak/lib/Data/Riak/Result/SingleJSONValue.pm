package Data::Riak::Result::SingleJSONValue;
{
  $Data::Riak::Result::SingleJSONValue::VERSION = '2.0';
}
# ABSTRACT: Single result containing JSON data

use Moose;
use JSON 'decode_json';
use namespace::autoclean;

extends 'Data::Riak::Result';
with 'Data::Riak::Result::JSONValue',
     'Data::Riak::Result::Single';


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Data::Riak::Result::SingleJSONValue - Single result containing JSON data

=head1 VERSION

version 2.0

=head1 DESCRIPTION

This is a result class for requests returning a single result containing JSON
encoded data. It applies L<Data::Riak::Result::JSONValue> and
L<Data::Riak::Result::Single>.

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
