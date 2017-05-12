package Catalyst::Model::Search::Plucene::Simple;

use strict;
use warnings;

use Plucene::Analysis::SimpleAnalyzer;
use Plucene::Analysis::WhitespaceAnalyzer;
use Plucene::Document;
use Plucene::Document::DateSerializer;
use Plucene::Document::Field;
use Plucene::Index::Reader;
use Plucene::Index::Writer;
use Plucene::QueryParser;
use Plucene::Search::DateFilter;
use Plucene::Search::HitCollector;
use Plucene::Search::IndexSearcher;

use Carp;
use File::Spec::Functions qw(catfile);

use Catalyst::Model::Search::Results;
use Catalyst::Model::Search::Item;

sub analyzer {
    my ( $self, $analyzer_class ) = @_;
    
    eval "use $analyzer_class";
    my $analyzer = eval "$analyzer_class->new()" unless $@;
    if ( $@ ) {
        Catalyst::Exception->throw(
            message => "Unable to load Plucene analyzer $analyzer_class, $@"
        );
    }
    
    $self->{_analyzer} = $analyzer;
}

sub new {
    my ( $class, $args ) = @_;
    $args->{dir} or croak "No index directory specified";
    $args->{analyzer} ||= 'Plucene::Analysis::SimpleAnalyzer';
    $args->{return_style} ||= 'key';
    bless { 
        _dir          => $args->{dir},
        _analyzer     => $args->{analyzer},
        _return_style => $args->{return_style},
    }, $class;
}

sub _dir { shift->{_dir} }

sub _parsed_query {
    my ( $self, $query, $default ) = @_;
    
    my $parser = Plucene::QueryParser->new( {
        analyzer => $self->{_analyzer},
        default  => $default,
    } );
    $parser->parse( $query );
}

sub _searcher { Plucene::Search::IndexSearcher->new(shift->_dir) }

sub _reader { Plucene::Index::Reader->open(shift->_dir) }

sub search {
    my ($self, $sstring) = @_;
    return () unless $sstring;
    my @docs;
    my $searcher = $self->_searcher;
    my $hc = Plucene::Search::HitCollector->new(
        collect => sub {
            my ( $self, $doc, $score ) = @_;
            my $res = eval { $searcher->doc($doc) };
            push @docs, [ $res, $score ] if $res;
        }
    );

    $searcher->search_hc( $self->_parsed_query( $sstring, '_text' ), $hc );
    
    # return all items, sorted by score
    my @items;
    foreach my $d ( sort { $b->[1] <=> $a->[1] } @docs ) {
        my $item = Catalyst::Model::Search::Item->new( {
            score => $d->[1],
            key   => $d->[0]->get('_key')->string,
        } );
        if ( $self->{_return_style} eq 'full' ) {
            foreach my $field ( $d->[0]->fields ) {
                $item->add_data( { 
                    name  => $field->name,
                    value => $field->string
                } );
            }
        }
        push @items, $item;
    }
    my $results = Catalyst::Model::Search::Results->new( {
        total_hits => scalar @items,
        items      => \@items,
    } );
    return $results;
}

sub _writer {
    my $self = shift;
    
    return Plucene::Index::Writer->new(
        $self->_dir,
        $self->{_analyzer},
        -e catfile($self->_dir, 'segments') ? 0 : 1,
    );
}

sub add {
    my ($self, @data) = @_;
    my $writer = $self->_writer;
    while (my ($id, $terms) = splice @data, 0, 2) {
        my $doc = Plucene::Document->new;
        $doc->add(Plucene::Document::Field->Keyword( _key => $id ));
        if ( ref $terms eq 'HASH' ) {
            foreach my $key ( keys %{$terms} ) {
                if ( $self->{_return_style} eq 'key' ) {
                    $doc->add(
                        Plucene::Document::Field->UnStored( $key => $terms->{$key} )
                    );
                }
                else {
                    $doc->add(
                        Plucene::Document::Field->Text( $key => $terms->{$key} )
                    );
                }
                $terms->{_text} .= ' ' . $terms->{$key} unless $key =~ /^_/;
            }
        }
        else {
            # no metadata specified, just the raw text
            $terms->{_text} = $terms;
        }
        $doc->add(
            Plucene::Document::Field->UnStored( _text => $terms->{_text})
        );
        $writer->add_document($doc);
    }
    undef $writer;
}

sub delete_document {
    my ( $self, $id ) = @_;
    my $reader = $self->_reader;
    $reader->delete_term(
        Plucene::Index::Term->new( { field => '_key', text => $id } )
    );
    $reader->close;
}

sub optimize { shift->_writer->optimize() }

sub indexed {
    my ( $self, $id ) = @_;
    my $term = Plucene::Index::Term->new( { field => '_key', text => $id } );
    return $self->_reader->doc_freq( $term );
}

1;
__END__

=head1 NAME

Catalyst::Model::Search::Plucene::Simple - Plucene interface based heavily
on Plucene::Simple.

=head1 DESCRIPTION

This module should not be used directly, it is part of
Catalyst::Model::Search::Plucene.

=head1 AUTHOR

Andy Grundman, <andy@hybridized.org>

=head1 THANKS

Marc Kerr, <coder@stray-toaster.co.uk>, for Plucene::Simple from which this
module borrows heavily.

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
