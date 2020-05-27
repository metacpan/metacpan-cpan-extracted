package Data::AnyXfer::IteratorToElasticsearch;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


extends 'Data::AnyXfer';
with 'Data::AnyXfer::From::Iterator';
with 'Data::AnyXfer::To::Elasticsearch';

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

=head1 NAME

Data::AnyXfer::IteratorToElasticsearch - transfer from a generic iterator to Elasticsearch

=head1 DESCRIPTION

This class combines the L<Data::AnyXfer::From::Iterator> and
L<Data::AnyXfer::To::Elasticsearch> roles.

=cut

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

