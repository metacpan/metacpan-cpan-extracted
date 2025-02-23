package Astro::ADS::Search;
# ABSTRACT: Queries the ADS Search endpoint and collects the results
$Astro::ADS::Search::VERSION = '1.90';
use Moo;
extends 'Astro::ADS';
with 'Astro::ADS::Role::ResultMapper';

use Carp;
use Data::Dumper::Concise;
use Mojo::Base -strict; # do we want -signatures
use Mojo::DOM;
use Mojo::File qw( path );
use Mojo::URL;
use Mojo::Util qw( quote );
use PerlX::Maybe;
use Types::Standard qw( Int Str ArrayRef HashRef ); # InstanceOf ConsumerOf

no warnings 'experimental'; # suppress warning for native perl 5.36 try/catch

has [qw/q fq fl sort/] => (
    is       => 'rw',
);
has [qw/start rows/] => (
    is       => 'rw',
    isa      => Int->where( '$_ >= 0' ),
);
# TODO: add year and other fields
has [qw/authors objects bibcode/] => (
    is       => 'rw',
    isa      => ArrayRef[Str],
    default  => sub { return [] },
);
has [qw/author_logic object_logic/] => (
    is       => 'rw',
    isa      => HashRef[],
    default  => sub { return {} },
);

before sort => sub {
    my $orig = shift;
    my $self = shift;
    my ($field, $direction) = @_;

    return unless $field;

    my $sort_field_re = qr/(?:id|author_count|bibcode|citation_count|citation_count_norm|classic_factor|first_author|date|entry_date|read_count|score)/;
    if ($field =~ /^$sort_field_re\+(?:asc|desc)$/) {
        $orig->($self, $field);
    }
    if ($field !~ /^$sort_field_re$/) {
        carp 'Invalid sort field: ', $field;
        return;
    }
    if ($direction eq 'asc' || $direction eq 'desc') {
        carp 'Invalid sort direction: ', $direction;
        return;
    }
    $orig->($self, join('+', $field, $direction) );
};

sub query {
    my ($self, $terms) = @_;
    my $url = $self->base_url->clone->path('search/query');
    my $search_terms = $self->gather_search_terms( $terms ) or return;

    $url->query( $search_terms );
    my $response = $self->get_response( $url );
    if ( $response->is_error ) {
        carp $response->message;
        return Astro::ADS::Result->new( {error => $response->message} );
    }

    my $json = $response->json;
    return $self->parse_response( $json );
}

sub query_tree {
    my ($self, $terms) = @_;
    carp "Not implemented yet"; return;

    my $url = $self->base_url->path('search/qtree');
    $url->query( { q => $self->q, fl => $self->fl } );
    return $self->get_result( $url );
}

sub bigquery {
    my ($self, $terms) = @_;
    carp "Not implemented yet"; return;

    my $url = $self->base_url->path('search/bigquery');
    $url->query( { q => $self->q, fl => $self->fl } );
    #return $self->post_result( $url );
}

sub gather_search_terms {
    my ($self, $terms) = @_;

    my @query = ();
    if ( $terms && $terms->{q} ) {
        push @query, delete $terms->{q};
    }
    else {
        push @query, $self->q if $self->q;
        push @query, delete $terms->{'+q'} if exists $terms->{'+q'};

        if ( @{$self->authors} ) {
            my $tag = 'author:';
            substr($tag, 0, 0) = '=' if $self->author_logic->{exact};
            if ( @{$self->authors} > 1 ) {
                my $logic = $self->author_logic->{OR} ? q{ OR } : q{ };
                push @query, "$tag(" . join( $logic, map { quote $_ } @{$self->authors}) . ')';
            }
            else {
                push @query, $tag . quote $self->authors->[0];
            }
        }

        if ( @{$self->objects} ) {
            my $tag = 'object:';
            if ( @{$self->objects} > 1 ) {
                my $logic = $self->object_logic->{OR} ? q{ OR } : q{ };
                push @query, "$tag(" . join( $logic, map { quote $_ } @{$self->objects}) . ')';
            }
            else {
                push @query, $tag . quote $self->objects->[0];
            }
        }

        # need to remember which attributes take multiple values
        push @query, @{$self->bibcode} if @{$self->bibcode};
    }
                
    unless ( @query ) {
        carp 'No search terms provided for query';
        return;
    }

    my $search_terms = {
        q => join(q{ }, @query),
        maybe fq => $self->fq,
        maybe fl => $self->fl,
        maybe start => $self->start,
        maybe rows  => $self->rows,
        maybe sort  => $self->sort,
        %$terms
    };

    return $search_terms;
}

sub add_authors {
    my ($self, @authors) = @_;
    push @{$self->authors}, @authors;
}

sub add_objects {
    my ($self, @objects) = @_;
    push @{$self->objects}, @objects;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Astro::ADS::Search - Queries the ADS Search endpoint and collects the results

=head1 VERSION

version 1.90

=head1 SYNOPSIS

    my $search = Astro::ADS::Search->new({
        q  => '...', # initial search query
        fl => '...', # return list of attributes
    });

    my $result = $search->query();
    my @papers = $result->papers();

    while ( my $t = $result->next_query() ) {
        $result = $search->query( $t );
        push @papers, $result->get_papers();
    }

    while ( my $t = $result->next_query() ) {
        push @papers, $result->more_papers( $t );
    }

    while ( push @papers, $result->next_query()->more_papers() ) {
    }

=head1 DESCRIPTION

Search for papers in the Harvard ADS 

You can put base terms in the creation of the object and use the
query method to add new terms to that query only

=head1 Methods

=head2 query

Adding a field key C<+q> to the query method B<adds> the query
term to the existing query terms,
whereas specifying a value for C<q> in the query method
overwrites the query terms and neglects gathering other search attributes,
such as authors or objects.

=head2 add_authors

Add a list of authors to a search query. Authors added here will not be
deleted if the query attribute is updated.

=head2 add_objects

Add a list of objects to a search query. Objects added here will not be
deleted if the query attribute is updated.

=head2 query_tree

B<Not implemented yet>

Will return the L<Abstract Syntax Tree|https://ui.adsabs.harvard.edu/help/api/api-docs.html#get-/search/qtree> for the query.

=head2 bigquery

B<Not implemented yet>

Accepts a L<list of many IDs|https://ui.adsabs.harvard.edu/help/api/api-docs.html#post-/search/bigquery> and supports paging.

=head2 Notes

From the ADS API, the "=" sign turns off the synonym expansion feature
available with the author and title fields

=head1 See Also

=over 4

=item *L<Astro::ADS>

=item *L<Astro::ADS::Result>

=item *L<ADS API|https://ui.adsabs.harvard.edu/help/api/>

=item *L<Search Syntax|https://ui.adsabs.harvard.edu/help/search/search-syntax>

=back

=head1 AUTHOR

Boyd Duffee <duffee@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Boyd Duffee.

This is free software, licensed under:

  The MIT (X11) License

=cut
