package Data::AnyXfer::Elastic::Snapshot;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Const::Fast;

extends 'Data::AnyXfer::Elastic';
with 'Data::AnyXfer::Elastic::Role::Wrapper';

=head1 NAME

 Data::AnyXfer::Elastic::Cluster - Elasticsearch Cluster

=head1 DESCRIPTION

 This module provides methods to manage snapshot/restore, or backups. It can
 create, get and delete configured backup repositories, and create, get, delete
 and restore snapshots of your cluster or indices.

 Wraps methods from Search::Elasticsearch::Client::Direct::Snapshot for 
 purposes.

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Snapshot;
    my $snapshot = Data::AnyXfer::Elastic::Snapshot->new();

    Methods are imported from:

    See: L<Search::Elasticsearch::Client::Direct::Snapshot>

=cut

const my @METHODS => (

    #REPOSITORY METHODS
    'create_repository',
    'verify_repository',

    'get_repository',
    'delete_repository',

    #SNAPSHOT METHODS
    'create',
    'get',
    'delete',
    'restore',
    'status',
);

sub BUILD {
    my $self = shift;

    $self->_wrap_methods( $self->elasticsearch->snapshot(), \@METHODS );

    return $self;
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

