package Data::AnyXfer::JsonToElasticsearch;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


extends 'Data::AnyXfer';
with 'Data::AnyXfer::From::JSON';
with 'Data::AnyXfer::To::Elasticsearch';

=head1 NAME

Data::AnyXfer::JsonToElasticsearch - transfer from JSON files to Elasticsearch

=head1 DESCRIPTION

This class combines the L<Data::AnyXfer::From::JSON> and
L<Data::AnyXfer::To::Elasticsearch> roles.

=cut

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

