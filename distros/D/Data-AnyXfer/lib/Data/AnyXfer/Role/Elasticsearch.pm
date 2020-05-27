package Data::AnyXfer::Role::Elasticsearch;

use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);
use namespace::autoclean;

use Search::Elasticsearch::Bulk;
use Search::Elasticsearch::Client::6_0::Bulk;

use Data::AnyXfer::Elastic;
use Data::AnyXfer::Elastic::Index;
use Data::AnyXfer::Elastic::Role::IndexInfo;

=head1 NAME

Data::AnyXfer::Role::Elasticsearch - provides es support for AnyXfer modules

=head1 DESCRIPTION

This module is for use primarily by L<Data::AnyXfer::To::Elasticsearch>,
but has been provided as a role, for clarity and potential future re-use.

=head1 ATTRIBUTES

=head2 index_info

Required. An instance of L<Data::AnyXfer::Elastic::Role::IndexInfo>.

=head2 es

This is automatically provided.

It holds an instance of L<Data::AnyXfer::Elastic::Index> which can be used to
perform Elasticsearch operations.

=head2 _bulk

This is a shared bulk helper, which acts as the command queue for the majority of
batch operations performed in AnyXfer Elasticsearch modules.

=cut


has index_info => (
    is       => 'rw',
    does     => 'Data::AnyXfer::Elastic::Role::IndexInfo',
    required => 1,
);



has 'es' => (
    is       => 'ro',
    isa      => InstanceOf['Data::AnyXfer::Elastic::Index'],
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        return shift->index_info->get_index;
    },
);

has '_bulk' => (
    is => 'ro',
    isa => AnyOf[
      InstanceOf['Search::Elasticsearch::Bulk'],
      InstanceOf['Search::Elasticsearch::Client::6_0::Bulk']
    ],
    lazy     => 1,
    init_arg => undef,
    default  => sub {
        my ($self) = @_;
        $self->es->bulk_helper();
    },
);




1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

