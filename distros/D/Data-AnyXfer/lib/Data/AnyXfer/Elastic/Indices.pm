package Data::AnyXfer::Elastic::Indices;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Const::Fast;

extends 'Data::AnyXfer::Elastic';
with 'Data::AnyXfer::Elastic::Role::Wrapper';

=head1 NAME

 Data::AnyXfer::Elastic::Indices - Elasticsearch Indices

=head1 DESCRIPTION

 This module provides methods to make index-level requests, such as creating and
 deleting indices, managing type mappings, index settings, warmers, index
 templates and aliases.

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Indices;
    my $indices = Data::AnyXfer::Elastic::Indices->new();

    Methods are imported from:

    See: L<Search::Elasticsearch::Client::Direct::Indices>

=cut

const my @METHODS => (

    #INDEX METHODS
    'get',
    'create',
    'exists',
    'delete',
    'close',
    'open',
    'clear_cache',
    'refresh',
    'flush',

    #MAPPING METHODS
    'put_mapping',
    'get_mapping',
    'get_field_mapping',
    'exists_type',

    #ALIAS METHODS
    'update_aliases',
    'put_alias',
    'get_alias',
    'exists_alias',
    'delete_alias',

    #SETTINGS METHODS
    'put_settings',
    'get_settings',

    #TEMPLATE METHODS
    'put_template',
    'get_template',
    'exists_template',
    'delete_template',

    # QUERY AND ANALYSIS METHODS
    'analyze',
    'validate_query',

);

sub BUILD {
    my $self = shift;

    $self->_wrap_methods( $self->elasticsearch->indices(), \@METHODS );

    return $self;
}

=head1 IMPLEMENTS METHODS

=head2 update_aliases

    $indices->get_aliases;

This method was removed in later versions of Elasticsearch,
so we provide a replacement for compatibility.

=cut

sub get_aliases {
    shift->get_alias( name => '*' );
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

