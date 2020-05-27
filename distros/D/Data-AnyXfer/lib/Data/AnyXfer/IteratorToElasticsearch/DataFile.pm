package Data::AnyXfer::IteratorToElasticsearch::DataFile;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


extends 'Data::AnyXfer';
with 'Data::AnyXfer::From::Iterator';
with 'Data::AnyXfer::To::Elasticsearch::DataFile';



=head1 NAME

Data::AnyXfer::IteratorToElasticsearch::DataFile - transfer from a
generic iterator to an Elasticsearch datafile

=head1 DESCRIPTION

This class combines the L<Data::AnyXfer::From::Iterator> and
L<Data::AnyXfer::To::Elasticsearch::DataFile> roles.

=cut


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

