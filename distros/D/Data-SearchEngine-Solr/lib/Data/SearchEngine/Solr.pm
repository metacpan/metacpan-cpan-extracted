package Data::SearchEngine::Solr;
use Moose;

use Clone qw(clone);
use Data::SearchEngine::Paginator;
use Data::SearchEngine::Item;
use Data::SearchEngine::Results::Spellcheck::Suggestion;
use Data::SearchEngine::Solr::Results;
use Time::HiRes qw(time);
use WebService::Solr;

with (
    'Data::SearchEngine',
    'Data::SearchEngine::Modifiable'
);

our $VERSION = '0.18';

has options => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {
        wt => 'json',
        fl => '*,score',
    } }
);

has 'url' => (
    is => 'ro',
    isa => 'Str',
    required => 1
);

has '_solr' => (
    is => 'ro',
    isa => 'WebService::Solr',
    lazy_build => 1
);

sub _build__solr {
    my ($self) = @_;

    return WebService::Solr->new($self->url);
}

sub add {
    my ($self, $items, $options) = @_;

    my @docs;
    foreach my $item (@{ $items }) {
        my $doc = WebService::Solr::Document->new;
        $doc->add_fields(id => $item->id);

        foreach my $key ($item->keys) {
            my $val = $item->get_value($key);
            if(ref($val)) {
                foreach my $v (@{ $val }) {
                    $doc->add_fields($key => $v);
                }
            }  else {
                $doc->add_fields($key => $val);
            }
        }
        push(@docs, $doc);
    }

    $self->_solr->add(\@docs, $options);
}

sub optimize {
    my ($self) = @_;

    $self->_solr->optimize;
}

sub present {
    warn 'present is not implemented\n';
    return 0;
}

sub remove {
    my ($self, $query, $id) = @_;

    $self->_solr->delete({ query => $query, id => $id });
}

sub remove_by_id {
	my ($self, $id) = @_;
	
	return $self->_solr->delete_by_id($id);
}

sub find_by_id {
    die "Not implemented!";
}

sub search {
    my ($self, $query) = @_;

    my $options = clone($self->options);

    $options->{rows} = $query->count;

    if($query->has_filters) {
        $options->{fq} = [];
        foreach my $filter (keys %{ $query->filters }) {
            push(@{ $options->{fq} }, $query->get_filter($filter));
        }
    }

    if($query->has_order) {
        $options->{sort} = $query->order;
    }

    if($query->has_debug) {
        $options->{debug} = $query->debug;
    }

    $options->{start} = ($query->page - 1) * $query->count;

    my $start = time;
    my $resp = $self->_solr->search($query->query, $options);

    my $dpager = $resp->pager;
    # The response will have no pager if there were no results, so we handle
    # that here.
    my $pager = Data::SearchEngine::Paginator->new(
        current_page => defined($dpager) ? $dpager->current_page : 0,
        entries_per_page => defined($dpager) ? $dpager->entries_per_page : 0,
        total_entries => defined($dpager) ? $dpager->total_entries : 0
    );

    my $result = Data::SearchEngine::Solr::Results->new(
        query => $query,
        pager => $pager,
        elapsed => time - $start,
        raw => $resp
    );

    my $facets = $resp->facet_counts;
    if(exists($facets->{facet_fields})) {
        foreach my $facet (keys %{ $facets->{facet_fields} }) {
            $result->set_facet($facet, $facets->{facet_fields}->{$facet});
        }
    }
    if(exists($facets->{facet_queries})) {
        foreach my $facet (keys %{ $facets->{facet_queries} }) {
            $result->set_facet($facet, $facets->{facet_queries}->{$facet});
        }
    }

    my $spellcheck = $resp->content->{spellcheck};

    if(defined($spellcheck) && exists($spellcheck->{suggestions})) {
        my $suggs = $spellcheck->{suggestions};
        for(my $i = 0; $i < scalar(@{ $suggs }); $i += 2) {
            my $sword = $suggs->[$i];
            my $data = $suggs->[$i + 1];

            if($sword eq 'collation') {
                $result->spell_collation($data);
                next;
            } elsif($sword eq 'correctlySpelled') {
                $result->spelled_correctly($data ? 1 : 0);
            }

            # Necessary to skip some of the non-hash pieces, like
            # correctlySpelled in the extended results
            next unless ref($data) eq 'HASH';

            if(exists($data->{origFreq})) {
                # Only present in the extended results
                $result->set_spell_frequency($sword, $data->{origFreq});
            }

            my $suggdata = $data->{suggestion};
            if(defined($suggdata) && ref($suggdata) eq 'ARRAY') {
                foreach my $sugg (@{ $suggdata }) {

                    if(ref($sugg) eq 'HASH') {
                        # This handles "extended results" from the spellcheck
                        # component...
                        $result->set_spell_suggestion($sugg->{word},
                            Data::SearchEngine::Results::Spellcheck::Suggestion->new(
                                original_word => $sword,
                                word        => $sugg->{word},
                                frequency   => $sugg->{freq}
                            )
                        );
                    } else {
                        # This handles non-"extended results" from the spellcheck
                        # component...
                        $result->set_spell_suggestion($sugg,
                            Data::SearchEngine::Results::Spellcheck::Suggestion->new(
                                original_word => $sword,
                                word    => $sugg,
                            )
                        );
                    }
                }
            }
        }
    }

    foreach my $doc ($resp->docs) {

        my %values;
        foreach my $fn ($doc->field_names) {
            my @n_values = $doc->values_for($fn);
            if (scalar(@n_values) > 1) {
                @{$values{$fn}} = @n_values;
            } else {
                $values{$fn} = $n_values[0];
            }
        }

        $result->add(Data::SearchEngine::Item->new(
            id      => $doc->value_for('id'),
            values  => \%values,
        ));
    }

    return $result;
}

sub update {
    my $self = shift;

    $self->add(@_);
}

1;



=pod

=head1 NAME

Data::SearchEngine::Solr

=head1 VERSION

version 0.20

=head1 SYNOPSIS

  my $solr = Data::SearchEngine::Solr->new(
    url => 'http://localhost:8983/solr',
    options => {
        fq => 'category:Foo',
        facets => 'true'
    }
  );

  my $query = Data::SearchEngine::Query->new(
    count => 10,
    page => 1,
    query => 'ice cream',
  );

  my $results = $solr->search($query);

  foreach my $item ($results->items) {
    print $item->get_value('name')."\n";
  }

=head1 DESCRIPTION

Data::SearchEngine::Solr is a L<Data::SearchEngine> backend for the Solr
search server.

=head1 NAME

Data::SearchEngine::Solr - Data::SearchEngine backend for Solr

=head1 SOLR FEATURES

=head2 FILTERS

This module uses the values from Data::SearchEngine::Query's C<filters> to
populate the C<fq> parameter.  Before talking to Solr we iterate over the
filters and add the filter's value to C<fq>.

  $query->filters->{'last name watson'} = 'last_name:watson';

Will results in fq=name:watson.  Multiple filters will be appended.

=head2 FACETS

Facets may be enabled thusly:

  $solr->options->{facets} = 'true';
  $solr->options->{facet.field} = 'somefield';

You may also use other C<facet.*> parameters, as defined by Solr.

To access facet data, consult the documentation for
L<Data::SearchEngine::Results> and it's C<facets> method.

=head2 SPELLCHECK

Queries may be spellchecked using Solr's spellcheck component. If you supply
the correct parameters through the URL or to your URI handler then
Data::SearchEngine::Solr will see it in the results and populate the bits from
L<Data::SearchEngine::Results::Spellcheck>.  Note that some of the features
may not work properly unless C<spellcheck.extendedResults> is true in your
query.

=head1 ATTRIBUTES

=head2 options

HashRef that is passed to L<WebService::Solr>.  Please see the above
documentation on filters and facets before using this directly.

=head2 url

The URL at which to contact the Solr instance.

=head1 METHODS

=head2 add (\@items)

Adds a list of L<Data::SearchEngine::Item>s to the Solr index.  The Items
are converted into L<WebService::Solr::Document>s using the follow means:

=over 4

=item C<score> is used as the bonus.

=item C<id> is used as the document's id.

=item Multiple-value fields are broken up into multiple
L<WebService::Solr::Field> objects per L<WebService::Solr>'s convention.  This
is merely a formality, it has no real affect.

=back

=head2 optimize

Calls WebService::Solr's C<optimize> method.

=head2 remove

Deletes an item from the index.  A straight dispatch to L<WebService::Solr>'s
C<delete>.

=head2 remove_by_id

Delete a specific document by it's id.

=head2 search ($query)

Accepts a L<Data::SearchEngine::Query> and returns a
L<Data::SearchEngine::Results> object containing the data from Solr.

=head2 update

Alias for C<add>.

=head1 AUTHOR

Cory G Watson, C<< <gphat at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 - 2011 Cory G Watson.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

