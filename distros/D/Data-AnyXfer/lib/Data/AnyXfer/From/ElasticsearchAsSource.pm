package Data::AnyXfer::From::ElasticsearchAsSource;

use v5.16.3;

use Carp;
use Moo::Role;
use MooX::Types::MooseLike::Base qw(:all);

with 'Data::AnyXfer::From::Iterator';

use Data::AnyXfer::Elastic::ScrollHelper;

requires 'log';

=head1 NAME

Data::AnyXfer::From::Elasticsearch - Transfer data from Elasticsearch as a datasource

=head1 SYNOPSYS

  use Moo;
use MooX::Types::MooseLike::Base qw(:all);


  extends 'Data::AnyXfer';
  with 'Data::AnyXfer::From::ElasticsearchAsSource';

  use MyIndexInfo ();

  has '+source_index_info' => (
    default => sub { MyIndexInfo->new  }
  );

=head1 DESCRIPTION

This role configures L<Data::AnyXfer> to use a
L<Data::AnyXfer::Elastic::Role::IndexInfo> consumer as a data
source.

=cut

has 'source_index_info' => (
    is      => 'ro',
    isa     => InstanceOf['Data::AnyXfer::Elastic::Role::IndexInfo'],
    lazy    => 1,
    default => sub {
        shift->log->logdie("The index_info attribute was not set");
    },
);

has 'source_index' => (
    is      => 'ro',
    isa     => InstanceOf['Data::AnyXfer::Elastic::Index'],
    lazy    => 1,
    default => sub {
        my $self = shift;

        return $self->source_index_info->get_index(
            direct => $self->source_index_use_direct );
    },
);

has 'source_scroll_size' => (
    is      => 'ro',
    isa     => Int,
    default => 2000,
);

has 'source_index_use_direct' => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);


sub BUILD {
    my $self = $_[0];

    # remove the alias if using the direct index
    # so we don't restore aliases by accident if played later
    if ( $self->source_index_use_direct ) {
        $self->source_index_info->alias(undef);
    }
}


sub get_iterator {

    my $self  = $_[0];
    my $index = $self->source_index;

    # check that the index has some data to iterate over
    # this should catch bad aliases or some other bugs
    if ( $index->count < 1 ) {
        croak sprintf 'ERROR: Alias %s returned a document count of 0',
            $index->alias;
    }

    # create a scroll helper querying all documents under the alias
    my $scroll_helper = $index->scroll_helper(
        size => $self->source_scroll_size,
        body => { query => { match_all => {} } },
    );

    # wrap the scrollhelper to auto-extract document source from results
    return Data::AnyXfer::Elastic::ScrollHelper->new(
        scroll_helper   => $scroll_helper,
        extract_results => 1,
    );
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

