package Data::AnyXfer::DbicToElasticsearch;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


extends 'Data::AnyXfer';
with 'Data::AnyXfer::From::DBIC';
with 'Data::AnyXfer::To::Elasticsearch';

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;

=head1 NAME

Data::AnyXfer::DbicToElasticsearch - transfer from DBIC to Elasticsearch

=head1 DESCRIPTION

This class combines the L<Data::AnyXfer::From::DBIC> and
L<Data::AnyXfer::To::Elasticsearch> roles.

=cut

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

