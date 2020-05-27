package Data::AnyXfer::Elastic::Cache;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use namespace::autoclean;

use Carp ();

=head1 NAME

Data::AnyXfer::Elastic::Cache

=head1 SYNOPSIS

    my $cache = Data::AnyXfer::Elastic::Cache->new( index_info => IndexInfo->new );

    my $data = $cache->get_or_set(
        id          => 12345,
        callback    =>  sub { { # document } },
    );

=head1 DESCRIPTION

Data::AnyXfer::Elastic::Cache is a way of using Elasticsearch like
memcache.

=head1 ATTRIBUTES

=over

=item index_info

=back

=cut

has index_info => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf['Data::AnyXfer::Elastic::IndexInfo'],
);

has _client => (
    is       => 'ro',
    init_arg => undef,
    isa      => InstanceOf['Data::AnyXfer::Elastic::Index'],
    lazy     => 1,
    default  => sub { $_[0]->index_info->get_index },
);

sub BUILD {
    my $self = $_[0];

    my $index_info = $self->index_info;
    my $dynamic_index_info = Data::AnyXfer::Elastic::IndexInfo->new(
        autocreate_index => 1,
        connect_hint     => $index_info->connect_hint,
        index            => $index_info->alias,
        alias            => $index_info->alias,
        type             => $index_info->type,
        mappings         => $index_info->mappings,
        silo             => $index_info->silo,
        aliases          => {},
    );
}

=head1 METHODS

=head2 get_or_set

A short cut for calling C<get()> and then C<set()> if no value found.

=cut

sub get_or_set {
    my ( $self, %args ) = @_;
    if ( my $data = $self->get( id => $args{id} ) ) { return $data }
    return $self->set(%args);
}

=head2 get

    $cache->get( id => 12345 );

Returns document with id or undef if not found. Accepts the same parameters as
www.elastic.co/guide/en/elasticsearch/reference/current/docs-get.html

=cut

sub get {
    my ( $self, %args ) = @_;
    my $res = $self->_client->get( %args, ignore => 404 );
    return $res->{_source} || undef;
}

=head2 set

    $cache->set(
        id => 12345,
        callback => sub { some_method() }
    );

Creates or replaces a document with the id. Callback function should return
the document body. Accepts additional parameters documented in:
www.elastic.co/guide/en/elasticsearch/reference/current/docs-index_.html

=cut

sub set {
    my ( $self, %args ) = @_;
    my $data = $args{callback}->() and delete $args{callback};

    unless ( defined($data) ) {
        return;
    }

    if ( ref($data) ne 'HASH' ) {
        Carp::croak('callback function must return a hash');
    }

    $self->_client->index( %args, body => $data, );

    return $data;
}

=head2

    $cache->delete( id => 12345 );

Deletes document with id. Note that deletes are not instantaneous. Accepts
additional parameters documented in:
www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete.html

=cut

sub delete {
    my ( $self, %args ) = @_;
    return $self->_client->delete(%args);
}

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

