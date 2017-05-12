package Catalyst::Model::Search::LuceneWebService;

use strict;
use warnings;
use NEXT;
use base qw/Catalyst::Model::Search/;
use Net::LuceneWS;

__PACKAGE__->mk_classdata( '_lucene' );

sub new { 
    my ( $self, $c ) = @_;

    $self = $self->NEXT::new( $c );
    
    $self->config->{host}          ||= 'localhost';
    $self->config->{port}          ||= 8080;
    $self->config->{context}       ||= 'lucene';
    $self->config->{index}         ||= 'catalyst'; 
    $self->config->{max_hits}      ||= 25;
    $self->config->{default_field} ||= '_text';
    $self->config->{debug}         ||= 0;
    $self->config->{analyzer}      ||= 'WithStopAnalyzer';
    
    return $self->init();
}

sub init {
    my $self = shift;
    
    $self->_lucene( Net::LuceneWS->new( %{ $self->config } ) );
    
    return $self;
}

sub analyzer {
    my ( $self, $analyzer_class ) = @_;
    
    $self->config->{analyzer} = $analyzer_class;
    
    return $self->init();
}

sub add {
    my ( $self, $docs ) = @_;
    
    # adjust input format from $key => $data to an arrayref
    my @add_docs;
    foreach my $key ( keys %{$docs} ) {
        # _text is a special metadata field containing all data values
        my $text;
        foreach my $field ( keys %{ $docs->{$key} } ) {
            $text .= ' ' . $docs->{$key}->{$field} unless $field =~ /^_/;
        }
        
        push @add_docs, {
            _key  => $key,
            _text => $text,
            %{ $docs->{$key} },
        };
    }
    
    $self->_lucene->AddDocuments( 
        \@add_docs,
        analyzer => $self->config->{analyzer}
    );
    
    return ($self->_lucene->GetError) ? undef : 1;
}

sub update {
    my ( $self, $docs ) = @_;
    
    my $update = [];
    foreach my $key ( %{$docs} ) {
        push @{$update}, {
            default_field => '_key',
            query         => $key,
            document      => {
                _key => $key,
                %{ $docs->{$key} },
            },
        };
    }
    
    $self->_lucene->UpdateDocuments( $update );
    
    return ($self->_lucene->GetError) ? undef : 1;
}

sub remove {
    my ( $self, $key ) = @_;
    
    my $remove = [];
    push @{$remove}, {
        default_field => '_key',
        query         => $key,
    };

    $self->_lucene->DeleteDocuments( $remove );
    
    return ($self->_lucene->GetError) ? undef : 1;
}

sub query {
    my ( $self, $query, $args ) = @_;

    my $ret = $self->_lucene->Search(
        $query,
        %{ $args }
    );
    
    return undef if ( $self->_lucene->GetError);
    
    my @items;
    foreach my $hit ( $ret->GetHits() ) {
        my $item = Catalyst::Model::Search::Item->new( {
            score => $hit->GetScore(),
            key   => $hit->GetField( '_key' ),
        } );
        foreach my $field ( $hit->GetFields() ) {
            # ignore our custom metadata fields
            next if $field =~ /^(_key|_text)$/xms;
            $item->add_data( { 
                name  => $field,
                value => $hit->GetField( $field ),
            } );
        }
        push @items, $item;
    }
    
    my $results = Catalyst::Model::Search::Results->new( {
        total_hits => $ret->GetNumHitsTotal(),
        items => \@items,
    } );
    return ($self->_lucene->GetError) ? undef : $results;
}

sub is_indexed {
    my ( $self, $key ) = @_;
    
    if ( $self->query( '_key:' . $key ) ) {
        return 1;
    }
    return;
}

sub optimize {
    my $self = shift;
    
    $self->_lucene->Optimize();
    return ($self->_lucene->GetError) ? undef : 1;
}

sub error {
    my $self = shift;
    
    return $self->_lucene->GetError();
}

1;
__END__
