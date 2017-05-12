package Catalyst::Model::Search::Plucene;

our $VERSION = '0.03';

use strict;
use warnings;
use NEXT;
use base qw/Catalyst::Model::Search/;
use Catalyst::Model::Search::Plucene::Simple;

__PACKAGE__->mk_classdata( '_plucene' );

sub new { 
    my ( $self, $c ) = @_;

    $self = $self->NEXT::new( $c );
    
    $self->config->{index}        ||= $c->config->{home} . '/plucene';
    $self->config->{analyzer}     ||= 'Plucene::Analysis::SimpleAnalyzer';
    $self->config->{return_style} ||= 'key';
    
    return $self->init();
}

sub init {
    my $self = shift;
    
    my $plucene 
        = Catalyst::Model::Search::Plucene::Simple->new( {
            dir          => $self->config->{index},
            analyzer     => $self->config->{analyzer},
            return_style => $self->config->{return_style},
        } );
                   
    $self->_plucene( $plucene );
    
    $self->optimize;
    
    return $self;
}

sub analyzer {
    my ( $self, $analyzer_class ) = @_;
    
    $self->config->{analyzer} = $analyzer_class;
    
    return $self->init();
}

sub add {
    my ( $self, $data ) = @_;
    
    $self->_plucene->add( %{ $data } );
}

sub update {
    my ( $self, $data ) = @_;
    
    foreach my $key ( keys %{ $data } ) {
        $self->remove( $key );
    }
    $self->add( $data );
}

sub remove {
    my ( $self, $key ) = @_;

    if ( $self->is_indexed( $key ) ) {
        $self->_plucene->delete_document( $key );
    }
}

sub query {
    my ( $self, $query ) = @_;
    
    my $results = $self->_plucene->search( $query );
    return (wantarray) ? $results->get_items : $results;
}

sub is_indexed {
    my ( $self, $key ) = @_;
    
    return $self->_plucene->indexed( $key );
}

sub optimize {
    my $self = shift;
    
    $self->_plucene->optimize;
}

1;
__END__

=head1 NAME

Catalyst::Model::Search::Plucene - Index and search using Plucene

=head1 SYNOPSIS

    package MyApp::M::Search;

    use strict;
    use base qw/Catalyst::Model::Search::Plucene/;
    
    __PACKAGE__->config(
        index        => MyApp->config->{home} . '/plucene',
        analyzer     => 'Plucene::Plugin::Analyzer::SnowballAnalyzer',
        return_style => 'full',
    );
    
    1;
    
    # meanwhile, in a controller...
    
    my $search = 'MyApp::M::Search';
    
    $search->add( {
        $key => {
            stuff => 'that',
            you   => 'want',
            to    => 'index',
        },
    } );
    
    my $results = $search->query( 'want' );
    # Hits: $results->total_hits
    foreach my $result ( $results->hits ) {
        # Score: $result->score
        # Key:   $result->key
        # Data:  $result->get('you') # returns 'want'
    }

=head1 DESCRIPTION

This model implements the standard Catalyst::Model::Search interface to a
Plucene index.

=head1 CONFIGURATION OPTIONS

    index

Plucene uses a single directory to store index files.  This value defaults to
a 'plucene' directory in your application's home directory.

    analyzer

The analyzer filters your input data before indexing it.  You may specify
a different analyzer if the default one is not to your liking.

    return_style

This value controls the amount of data stored and returned from a search
query.  The default value is 'key', where only the key value is stored in the
index.  If set to 'full', all of your input data is stored in the index and
returned to you when performing a search query.  See the query method for more
details.

=head1 METHODS

=head2 add( $hashref )

Add one or more items to the search index.  

    $search->add( {
        'page1' => {
            author  => 'jdoe',
            date    => '2005-10-01',
            text    => 'some text on the page',
            _hidden => 'foo', 
        },
        'page2' => 'some more text on this page',
    } );
    
Every item must be indexed with a unique key and may optionally contain
other metadata.  See the query method for examples of retrieving this data.

If you do not need to store additional metadata, you may simply pass in any
text to be indexed.

=head2 update( $hashref )

The update method is the same as add, except that every key is removed from
the index first and then re-added.

=head2 remove( $key )

The remove method removes a single key from the index.

=head2 query( $query_string )

Perform a search query.  If metadata was specified during add(), you may
perform searches on the metadata keys.  For example,

    'author:jdoe'               # page1
    '2005-10-01'                # page1
    'foo'                       # no results
    '_hidden:foo'               # page1
    'page'                      # page1, page2
    
An unqualified search such as '2005-10-01' will search the default field.  The
default field is a special field made up of all pieces of text except for text
associated with keys that begin with an underscore.

query returns a L<Catalyst::Model::Search::Results> object.  This object
contains two methods, total_hits, and hits.

    my $results = $search->query( 'some' );
    $results->get_total_hits;   # 2
    
Loop through the search hits, returns L<Catalyst::Model::Search::Item>
objects.  The results are sorted by highest score.

    foreach my $item ( $results->get_items ) {
        $item;                  # stringifies to 'page1'
        $item->get_score;       # 0.50000
        $item->get_key;         # 'page1'
        $item->get_fields;      # array of available fields
        $item->get('author')    # 'jdoe'
    }

Note that the $item->get() method only returns data if return_style is set to
'full'.

=head2 is_indexed( $key )

Returns true if the specified key exists in the index.

=head2 optimize()

Optimizes the entire index.

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>
Marcus Ramberg, <mramberg@cpan.org>

=head1 THANKS

Marc Kerr, <coder@stray-toaster.co.uk>, for Plucene::Simple from which this
module borrows heavily.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
