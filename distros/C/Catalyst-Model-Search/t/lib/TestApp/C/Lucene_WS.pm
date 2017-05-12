package TestApp::C::Lucene_WS;

use strict;
use base 'Catalyst::Base';

my $lucene = 'TestApp::M::Search::LuceneWebService';

sub add : Local {
    my ( $self, $c, $key ) = @_;
    
    my $data = {
        $key => {},
    };
    foreach my $param ( $c->req->param ) {
        $data->{$key}->{$param} = $c->req->params->{$param};
    }
    
    $c->res->output( ($lucene->add( $data )) ? 'ok' : 'not ok' );
}

sub query_total_hits : Local {
    my ( $self, $c ) = @_;
    
    my $results = $lucene->query( $c->req->params->{q} );
    my $total_hits = $results->get_total_hits;
    $c->res->output( $total_hits );
}

sub query_items : Local {
    my ( $self, $c ) = @_;
    
    my $results = $lucene->query( $c->req->params->{q} );
    if ( !$results ) {
        $c->res->output( $lucene->error );
    }
    
    my @items = $results->get_items;
    my $output;
    foreach my $item ( @items ) {
        $output .= 'score=' . $item->get_score . ' ';
        $output .= 'key='   . $item->get_key   . ' ';
    }
    $c->res->output( $output );
}

sub query_data : Local {
    my ( $self, $c ) = @_;
    
    my $results = $lucene->query( $c->req->params->{q} );
    return unless $results;
    my @items = $results->get_items;
    my $output;
    foreach my $item ( @items ) {
        foreach my $field ( $item->get_fields ) {
            $output .= $field . '=' . $item->get($field) . ' ';
        }
    }
    $c->res->output( $output );
}

sub remove : Local {
    my ( $self, $c, $key ) = @_;
    
    if ( $lucene->remove( $key ) ) {
        $c->res->output( 'ok' );
    }
    else {
        $c->res->output( $lucene->error );
    }
}

sub is_indexed : Local {
    my ( $self, $c, $key ) = @_;
   
    $c->res->output( $lucene->is_indexed( $key ) || 'no results' );
}

sub optimize : Local {
    my ( $self, $c ) = @_;
    
    $lucene->optimize;
    $c->res->output( 'ok' );
}

1;
