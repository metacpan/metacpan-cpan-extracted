package Data::SearchEngine::Results;
{
  $Data::SearchEngine::Results::VERSION = '0.33';
}
use Moose;
use MooseX::Storage;

# ABSTRACT: Results of a Data::SearchEngine search

with 'MooseX::Storage::Deferred';


has elapsed => (
    is => 'rw',
    isa => 'Num'
);


has items => (
    traits => [ 'Array' ],
    is => 'rw',
    isa => 'ArrayRef[Data::SearchEngine::Item]',
    default => sub { [] },
    handles => {
        count   => 'count',
        get     => 'get',
        add     => 'push',
    }
);


has query => (
    is => 'ro',
    isa => 'Data::SearchEngine::Query',
    required => 1,
);


has pager => (
    is => 'ro',
    isa => 'Data::SearchEngine::Paginator'
);


has raw => (
    is => 'ro',
    isa => 'Any'
);

__PACKAGE__->meta->make_immutable;

1;

__END__
=pod

=head1 NAME

Data::SearchEngine::Results - Results of a Data::SearchEngine search

=head1 VERSION

version 0.33

=head1 SYNOPSIS

    # An example search implementation

    sub search {
        my ($self, $query) = @_;

        # boring, search specific implementation
        
        my $results = Data::SearchEngine::Results->new(
            query       => $query,
            pager       => Data::SearchEngine::Paginator->new # Data::Paginator subclass
        );

        my @sorted_products; # fill with a search or something
        my $scores; # fill with search scores

        my $start = time;
        foreach my $product (@sorted_products) {
            my $item = Data::SearchEngine::Item->new(
                id      => $product->id,            # unique product id
                score   => $scores->{$product->id}  # make your own scores
            );

            $item->set_value('url', 'http://example.com/product/'.$product->id);
            $item->set_value('price', $product->price);

            $results->add($item);
        }
        $results->elapsed(time - $start);

        return $results;
    }

=head1 DESCRIPTION

The Results object holds the list of items found during a query.  They are
usually sorted by a score. This object provides some standard attributes you
are likely to use.

=head1 SERIALIZATION

This module uses L<MooseX::Storage::Deferred> to provide serialization.  You
may serialize it thusly:

  my $json = $results->freeze({ format => 'JSON' });
  # ...
  my $results = Data::SearchEngine::Results->thaw($json, { format => 'JSON' });

=head1 ATTRIBUTES

=head2 elapsed

The time it took to complete this search.

=head2 items

The list of L<Data::SearchEngine::Item>s found for the query.

=head2 query

The L<Data::SearchEngine::Query> that yielded this Results object.

=head2 pager

The L<Data::Page> for this result.

=head2 raw

An attribute that a search backend may fill with the "raw" response it
received.  This is useful for retrieving engine-specific information such
as debugging or tracing information. Type is C<Any>.

=head1 METHODS

=head2 add ($item)

Add an item to this result.

=head2 get ($n)

Get the nth item.

=head1 AUTHOR

Cory G Watson <gphat@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Cold Hard Code, LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

