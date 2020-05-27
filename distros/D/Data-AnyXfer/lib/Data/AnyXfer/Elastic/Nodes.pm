package Data::AnyXfer::Elastic::Nodes;

use v5.16.3;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


use Const::Fast;

extends 'Data::AnyXfer::Elastic';
with 'Data::AnyXfer::Elastic::Role::Wrapper';

=head1 NAME

 Data::AnyXfer::Elastic::Nodes - Elasticsearch Nodes

=head1 DESCRIPTION

 This module provides methods to make node-level requests, such as retrieving
 node info and stats.

 Wraps methods from Search::Elasticsearch::Client::Direct::Nodes for 
 purposes.

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::Nodes;
    my $cluster = Data::AnyXfer::Elastic::Nodes->new();

    Methods are imported from:

    See: L<Search::Elasticsearch::Client::Direct::Nodes>

=cut

const my @METHODS => qw/info stats hot_threads/;

sub BUILD {
	my $self = shift;

	$self->_wrap_methods( $self->elasticsearch->nodes(), \@METHODS);

	return $self;
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

