package Data::AnyXfer::ElasticsearchToDataFile;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Data::AnyXfer::Elastic ();

extends 'Data::AnyXfer';

with 'Data::AnyXfer::From::Elasticsearch';
with 'Data::AnyXfer::To::Elasticsearch::DataFile';


=head1 NAME

Data::AnyXfer::ElasticsearchToDataFile - transfer from a
elasticsearch index (defined using a
L<Data::AnyXfer::Elastic::Role::IndexInfo> consumer) to an
Elasticsearch datafile.

=head1 DESCRIPTION

This class combines the L<Data::AnyXfer::From::Elasticsearch> and
L<Data::AnyXfer::To::Elasticsearch::DataFile> roles.

=cut


has '+dir' => (
    lazy    => 1,
    default => sub {
        Data::AnyXfer::Elastic
            ->datafile_dir
            ->subdir( $_[0]->index_info->alias );
    }
);


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

