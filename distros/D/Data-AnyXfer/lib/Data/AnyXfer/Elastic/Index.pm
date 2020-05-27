package Data::AnyXfer::Elastic::Index;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);




use Const::Fast;

extends 'Data::AnyXfer::Elastic';
with 'Data::AnyXfer::Elastic::Role::Wrapper';

=head1 NAME

 Data::AnyXfer::Elastic::Index - Elasticsearch Index Object

=head1 DESCRIPTION

 This module is intended to act as a instance of a index. It wraps the most common
 methods for index CRUD and search operations. Each of these methods have the
 index name and document type injected into them, thus a instance of this object
 can only connect to a particular index. Any methods required that are not currently
 wrapped should be added when required.

=head1 SYNOSPSIS

    my $index = Data::AnyXfer::Elastic::Index->new(
        index_name  => 'properties',     # required
        index_type  => 'property'        # required
    );

=cut

const my @METHODS => (

    # DOCUMENT CRUD METHODS
    'index',  'get',    'get_source',
    'exists', 'delete', 'update',

    # BULK DOCUMENT CRUD METHODS
    'bulk', 'bulk_helper', 'mget', 'delete_by_query',

    # SEARCH METHODS
    'search', 'count', 'scroll', 'clear_scroll', 'scroll_helper', 'msearch',
    'explain',
);

=head1 ATTRIBUTES

=head2 C<index_name>

 Sets the name of the elasticsearch index - on test environments this is
 prepeneded with executing hostname.

=cut

has index_name => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 C<index_type>

 Sets the type of document.

=cut

has index_type => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

=head2 C<is_inject_index_and_type>

This overrides the attribute in L<Data::AnyXfer::Elastic>. It forces
any method called to be injected with the index name and type - fetched from the
attributes C<index_name> and C<index_type>.

=cut

has '+is_inject_index_and_type' => ( default => 1, );



=head1 METHODS

    Methods are imported from:

    See: L<Search::Elasticsearch::Client::Direct>

=cut

sub BUILD {
    my $self = shift;

    $self->_wrap_methods( $self->elasticsearch, \@METHODS );

    return $self;
}


=head1 IMPLEMENTS METHODS

=head2 suggest

    $index->suggest( body => {} );

This method was removed in later versions of Elasticsearch,
so we provide a replacement for compatibility.

=cut

sub suggest {
    my ( $self, %args ) = @_;

    # perform the suggestions search as part of a
    # normal search now that the suggest endpoint has been removed
    my $results = $self->search(    #
        %args, body => { suggest => $args{body} }
    );

    return $results->{suggest};
}

use namespace::autoclean;
1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

