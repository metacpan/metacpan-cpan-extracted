package Data::SearchEngine::ElasticSearch;
{
  $Data::SearchEngine::ElasticSearch::VERSION = '0.21';
}
use Moose;

# ABSTRACT: ElasticSearch support for Data::SearchEngine

use Clone qw(clone);
use ElasticSearch;
use Time::HiRes;
use Try::Tiny;

with (
    'Data::SearchEngine',
    'Data::SearchEngine::Modifiable'
);

use Data::SearchEngine::Item;
use Data::SearchEngine::Paginator;
use Data::SearchEngine::ElasticSearch::Results;


has '_es' => (
    is => 'ro',
    isa => 'ElasticSearch',
    lazy => 1,
    default => sub {
        my $self = shift;
        return ElasticSearch->new(
            servers => $self->servers,
            transport => $self->transport,
            trace_calls => $self->debug
        )
    }
);


has 'servers' => (
    is => 'ro',
    isa => 'Str|ArrayRef',
    default => '127.0.0.1:9200'
);


has 'transport' => (
    is => 'ro',
    isa => 'Str',
    default => 'http'
);


sub add {
    my ($self, $items, $options) = @_;

    my @docs;
    foreach my $item (@{ $items }) {

        my %data = %{ $item->values };

        my %doc = (
            index => delete($data{index}),
            type => delete($data{type}),
            id => $item->id,
            data => \%data
        );
        # Check for a version
        if(exists($data{'_version'})) {
            $doc{version} = delete($data{'_version'});
        }
        push(@docs, \%doc);
    }
    $self->_es->bulk_index(\@docs);
}


sub engine {
    my ($self) = @_;
    
    return $self->_es;
}


sub present {
    my ($self, $item) = @_;

    my $data = $item->values;

    try {
        my $result = $self->_es->get(
            index => delete($data->{index}),
            type => delete($data->{type}),
            id => $item->id
        );
    } catch {
        # ElasticSearch throws an exception if the document isn't there.
        return 0;
    }

    return 1;
}

sub remove {
    die("not implemented");
}


sub remove_by_id {
    my ($self, $item) = @_;

    my $data = $item->values;

    $self->_es->delete(
        index => $data->{index},
        type => $data->{type},
        id => $item->id
    );
}

sub update {
    my $self = shift;

    $self->add(@_);
}



sub search {
    my ($self, $query, $filter_combine) = @_;

    unless(defined($filter_combine)) {
        $filter_combine = 'and';
    }

    my $options;
    if($query->has_query) {
        die "Queries must have a type." unless $query->has_type;
        $options->{query} = { $query->type => $query->query };
    }

    $options->{index} = $query->index;

    if($query->has_debug) {
        # Turn on explain
        $options->{explain} = 1;
    }

    my @facet_cache = ();
    if($query->has_filters) {
        foreach my $filter ($query->filter_names) {
            push(@facet_cache, $query->get_filter($filter));
        }
        $options->{filter}->{$filter_combine} = \@facet_cache;
    }

    if($query->has_facets) {
        # Copy filters used in the overall query into each facet, thereby
        # limiting the facets to only counting against the filtered bits.
        # This is really to replicate my expecations and the way facets are
        # usually used.
        my %facets = %{ $query->facets };
        $options->{facets} = $query->facets;

        if($query->has_filters) {
            foreach my $f (keys %facets) {
                $facets{$f}->{facet_filter}->{$filter_combine} = \@facet_cache;
            }
        }

        # Shlep the facets into the final query, even if we didn't do anything
        # with the filters above.
        $options->{facets} = \%facets;
    }

    if($query->has_order) {
        $options->{sort} = $query->order;
    }

    if($query->has_fields) {
        $options->{fields} = $query->fields;
    }

    $options->{from} = ($query->page - 1) * $query->count;
    $options->{size} = $query->count;

    my $start = Time::HiRes::time;
    my $resp = $self->_es->search($options);

    my $page = $query->page;
    my $count = $query->count;
    my $hit_count = $resp->{hits}->{total};
    my $max_page = $hit_count / $count;
    if($max_page != int($max_page)) {
        # If trying to calculate how many pages we _could_ have gives us a
        # non integer, add one to the page after inting it so we get the right
        # integer.
        $max_page = int($max_page) + 1;
    }
    if($page > $max_page) {
        $page = $max_page;
    }

    my $pager = Data::SearchEngine::Paginator->new(
        current_page => $page || 1,
        entries_per_page => $count,
        total_entries => $hit_count
    );

    my $result = Data::SearchEngine::ElasticSearch::Results->new(
        query => $query,
        pager => $pager,
        elapsed => time - $start,
        raw => $resp
    );

    if(exists($resp->{facets})) {
        foreach my $facet (keys %{ $resp->{facets} }) {
            my $href = $resp->{facets}->{$facet};
            if(exists($href->{terms})) {
                my @vals = ();
                foreach my $term (@{ $href->{terms} }) {
                    push(@vals, { count => $term->{count}, value => $term->{term} });
                }
                $result->set_facet($facet, \@vals);
            }
        }
    }
    foreach my $doc (@{ $resp->{hits}->{hits} }) {
        my $values = $doc->{_source};
        $values->{_index} = $doc->{_index};
        $values->{_version} = $doc->{_version};
        $result->add($self->_doc_to_item($doc));
    }

    return $result;
}

sub _doc_to_item {
    my ($self, $doc) = @_;

    my $values = $doc->{_source} || $doc->{fields};
    $values->{_index} = $doc->{_index};
    $values->{_version} = $doc->{_version};
    return Data::SearchEngine::Item->new(
        id      => $doc->{_id},
        score   => $doc->{_score} || 0,
        values  => $values,
    );
}

sub find_by_id {
    my ($self, $index, $type, $id) = @_;

    my $doc = $self->_es->get(
        index => $index,
        type => $type,
        id => $id
    );

    return $self->_doc_to_item($doc);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Data::SearchEngine::ElasticSearch - ElasticSearch support for Data::SearchEngine

=head1 VERSION

version 0.21

=head1 SYNOPSIS

    use Data::SearchEngine::Query;
    use Data::SearchEngine::ElasticSearch;

    my $dse = Data::SearchEngine::ElasticSearch->new(
        servers => [ '127.0.0.1:9200' ]
    );

    my $query = Data::SearchEngine::Query->new(
        index => 'tweets',
        page => 1,
        count => 10,
        order => { _score => { order => 'asc' } },
        type => 'query_string',
        facets => {
            etype => { terms => { field => 'etype' } },
            author_organization_literal => { terms => { field => 'author_organization_literal' } },
            author_literal => { terms => { field => 'author_literal' } },
            source_literal => { terms => { field => 'source_literal' } },
        }
    );

    my $results = $dse->search($query);

=head1 DESCRIPTION

Data::SearchEngine::ElasticSearch is a backend for Data::SearchEngine.  It
aims to generalize the features of L<ElasticSearch> so that application
authors are insulated from I<some> of the differences betwene search modules.

=head1 IMPLEMENTATION NOTES

This module is opinionated. ElasticSearch's query language and features are
powerful and difficult to reign in.  Therefore this module has taken some
steps to bring things toward a more central feature set.

=head2 Incomplete

ElasticSearch's query DSL is large and complex.  It is not well suited to
abstraction by a library like this one.  As such you will almost likely find
this abstraction lacking.  Expect it to improve as the author uses more of
ElasticSearch's features in applications.

=head2 Resultes

The C<_index> and C<_version> keys will both be populated in the returned
L<Data::SearchEngine::Item>.

=head2 Explanations

Setting C<debug> to a true value will cause <explain> to be set when the query
is sent to ElasticSearch.  You can find the explanation by examining the
C<raw> attribute of the L<Data::SearchEngine::Results> object.

=head2 Queries

It is expected that if your L<Data::SearchEngine::Query> object has B<any>
C<query> set then it must also have a C<type>.

The query is then passed on to L<ElasticSearch> thusly:

    $es->search(
        # ...
        query => { $query->type => $query->query }
        # ...
    );

So if you want to do a query_string query, you would set up your query like
this:

    my $query = Data::SearchEngine::Query->new(
        # ...
        type => 'query_string',
        query => { query => 'some query text' }
        # ...
    );

See the documents for
L<ElasticSearch's DLS|http://www.elasticsearch.org/guide/reference/query-dsl/>
for more details.

=head2 Indexing

ElasticSearch wants an C<index> and C<type> for each Item that is indexed. It
is expected that you will populate these values in the item thusly:

  my $item = Data::SearchEngine::Item->new(
    id => $something,
    values => {
        index => 'twitter',
        type => 'tweet',
        # and whatever else
    }
  );
  $dse->add($item);

=head2 Filters

If you set multiple filters they will be ANDed together.  If you want to change
this behavior then you can supply an additional argument to the C<query> method:

  $dse->search($query, 'or');

This defaults to 'and'.

=head2 Facets & Filters

If you use facets then any filters will be copied into the facet's
C<facet_filter> so that the facets are limited similarly to the results.

=head1 ATTRIBUTES

=head2 servers

The servers to which we'll be connecting.

=head2 transport

The transport to use.  Refer to L<ElasticSearch> for more information.

=head1 METHODS

=head2 add ([ $items ])

Add items to the index.  Keep in mind that the L<Data::SearchEngine::Item>
should have values set for L<index> and L<type>.

=head2 engine

Returns the underlying ElasticSearch implementation.

=head2 present ($item)

Returns true if the L<Data::SearchEngine::Item> is present.  Uses the item's
C<id>.

=head2 remove_by_id ($item)

Remove the specified item from the index.  Uses the item's C<id>.

=head2 search ($query)

Search!

=head2 find_by_id ($index, $type, $id)

Find a document by it's unique id.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

