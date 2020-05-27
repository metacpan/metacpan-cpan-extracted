package Data::AnyXfer::Elastic::Cat;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Const::Fast;

extends 'Data::AnyXfer::Elastic';
with 'Data::AnyXfer::Elastic::Role::Wrapper';

=head1 NAME

 Data::AnyXfer::Elastic::Cat - Elasticsearch Cat

=head1 DESCRIPTION

 The cat API in Elasticsearch provides information about your cluster and
 indices in a simple, easy to read text format, intended for human consumption.

 Wraps methods from Search::Elasticsearch::Client::Direct::Cat for 
 purposes.

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Cat;
    my $cat = Data::AnyXfer::Elastic::Cat->new();

    Methods are imported from:

    L<Search::Elasticsearch::Client::Direct::Cat>

=cut

const my @METHODS =>
    qw/ help aliases allocation count health indices master nodes
    pending_tasks recovery shards thread_pool /;

sub BUILD {
    my $self = shift;

    $self->_wrap_methods( $self->elasticsearch->cat(), \@METHODS );

    return $self;
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

