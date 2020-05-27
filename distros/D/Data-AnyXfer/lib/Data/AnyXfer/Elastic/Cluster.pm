package Data::AnyXfer::Elastic::Cluster;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Const::Fast;

extends 'Data::AnyXfer::Elastic';
with 'Data::AnyXfer::Elastic::Role::Wrapper';

=head1 NAME

 Data::AnyXfer::Elastic::Cluster - Elasticsearch Cluster

=head1 DESCRIPTION

 This module provides methods to make cluster-level requests, such as getting
 and setting cluster-level settings, manually rerouting shards, and retrieving
 for monitoring purposes.

 Wraps methods from Search::Elasticsearch::Client::Direct::Cluster for 
 purposes.

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Cluster;
    my $cluster = Data::AnyXfer::Elastic::Cluster->new();

    Methods are imported from:

    See: L<Search::Elasticsearch::Client::Direct::Cluster>

=cut

const my @METHODS => qw/ health stats get_settings put_settings state
    pending_tasks reroute /;

sub BUILD {
    my $self = shift;

    $self->_wrap_methods( $self->elasticsearch->cluster(), \@METHODS );

    return $self;
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

