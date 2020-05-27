package Search::Elasticsearch::CxnPool::Sticky;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);


with 'Search::Elasticsearch::Role::CxnPool::Static',
    'Search::Elasticsearch::Role::Is_Sync';
use Search::Elasticsearch::Util qw(throw);
use namespace::clean;

#===================================
sub next_cxn {
    #===================================
    my ($self) = @_;

    my $cxns  = $self->cxns;
    my $total = @$cxns;

    my $now = time();
    my @skipped;

    while ( $total-- ) {
        my $current = $self->current_cxn_num;
        my $cxn     = $cxns->[ $self->next_cxn_num ];

        if ( $cxn->is_live ) {
            $self->_set_current_cxn_num($current);
            return $cxn;
        }

        if ( $cxn->pings_ok ) {
            $self->_set_current_cxn_num($current);
            return $cxn;
        }
    }

    throw( "NoNodes", "No nodes are available: [" . $self->cxns_str . ']' );
}

1;

=pod

=encoding UTF-8

=head1 NAME

Search::Elasticsearch::CxnPool::Sticky - A CxnPool for connecting to a remote cluster with a static list of nodes.

=head1 VERSION

version 5.01

=head1 SYNOPSIS

    $e = Search::Elasticsearch->new(
        cxn_pool => 'Sticky',
        nodes    => [
            'search1:9200',
            'search2:9200'
        ],
    );

=head1 DESCRIPTION

Like the L<Static|Search::Elasticsearch::CxnPool::Static> connection pool,
except does not round robin nodes unless there has been a connection failure.

=cut

__END__

# ABSTRACT: A CxnPool for connecting to a remote cluster with a static list of nodes.

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

