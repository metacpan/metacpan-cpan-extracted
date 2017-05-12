package Catmandu::Store::Lucy;

use Catmandu::Sane;
use Moo;
use Lucy::Plan::Schema;
use Lucy::Plan::StringType;
use Lucy::Plan::FullTextType;
use Lucy::Analysis::PolyAnalyzer;
use Lucy::Index::Indexer;
use Lucy::Search::IndexSearcher;
use Data::MessagePack;
use Catmandu::Store::Lucy::Bag;

with 'Catmandu::Store';

=head1 NAME

Catmandu::Store::Lucy - A searchable store backed by Lucy

=head1 VERSION

Version 0.0101

=cut

our $VERSION = '0.0103';

=head1 SYNOPSIS

    # From the command line

    $ catmandu import JSON to Lucy --path /path/to/index/ < data.json
    $ catmandu export Lucy --path /path/to/index/ to JSON > data.json

    # From perl
    use Catmandu;

    my $store = Catmandu->store('Lucy',path => '/path/to/index/');

    my $book = $store->bag->add({ title => 'Advanced Perl' });

    printf "book stored as %s\n", $book->{_id};

    $store->bag->commit;

    $bag->get($id);

    # all bags are iterators
    $bag->each(sub { ... });
    $bag->take(10)->each(sub { ... });

    my $hits = $bag->search(query => 'perl');

    # hits is an iterator
    $hits->each(sub {
        say $_[0]->{title};
    });

    $bag->delete($id);
    $bag->delete_by_query(query => 'perl');
    $bag->delete_all;
    $bag->commit;

=cut

has path => (is => 'ro', required => 1);

for my $attr (qw(analyzer ft_field_type schema)) {
    has "_$attr" => (is => 'ro', lazy => 1, builder => "_build_$attr");
}

for my $attr (qw(indexer searcher)) {
    has "_$attr" => (is => 'ro', lazy => 1, builder => "_build_$attr", clearer => 1, predicate => 1);
}

sub _messagepack { state $_messagepack = Data::MessagePack->new->utf8 }

sub _build_analyzer {
    Lucy::Analysis::PolyAnalyzer->new(language => 'en');
}

sub _build_ft_field_type {
    my $self = $_[0];
    Lucy::Plan::FullTextType->new(analyzer => $self->_analyzer, stored => 0);
}

sub _build_schema {
    my $self = $_[0];
    my $schema = Lucy::Plan::Schema->new;
    $schema->spec_field(name => '_id',   type => Lucy::Plan::StringType->new(stored => 1, sortable => 1));
    $schema->spec_field(name => '_bag',  type => Lucy::Plan::StringType->new(stored => 0));
    $schema->spec_field(name => '_data', type => Lucy::Plan::BlobType->new(stored => 1));
    $schema;
}

sub _build_indexer {
    my $self = $_[0];
    Lucy::Index::Indexer->new(schema => $self->_schema, index => $self->path, create => 1);
}

sub _build_searcher {
    my $self = $_[0];
    Lucy::Search::IndexSearcher->new(index => $self->path);
}

sub _commit {
    my ($self) = @_;

    if ($self->_has_indexer) {
        $self->_indexer->commit;
        $self->_clear_indexer;
        $self->_clear_searcher;
    }
}

=head1 SEE ALSO

L<Catmandu::Store>

=head1 AUTHOR

Nicolas Steenlant, C<< <nicolas.steenlant at ugent.be> >>

=head1 LICENSE AND COPYRIGHT

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
