package TestApp::C::Plucene;

use strict;
use base 'Catalyst::Base';

my $plucene = 'TestApp::M::Search::Plucene';

sub add : Local {
    my ( $self, $c, $key ) = @_;
    
    my $data = {
        $key => {},
    };
    foreach my $param ( $c->req->param ) {
        $data->{$key}->{$param} = $c->req->params->{$param};
    }
    
    $plucene->add( $data );
    
    $c->res->output( 'ok' );
}

sub query_total_hits : Local {
    my ( $self, $c ) = @_;
    
    my $results = $plucene->query( $c->req->params->{q} );
    my $total_hits = $results->get_total_hits;
    $c->res->output( $total_hits );
}

sub query_items : Local {
    my ( $self, $c ) = @_;
    
    my $results = $plucene->query( $c->req->params->{q} );
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
    
    my $results = $plucene->query( $c->req->params->{q} );
    my @items = $results->get_items;
    my $output;
    foreach my $item ( @items ) {
        foreach my $field ( $item->get_fields ) {
            $output .= $field . '=' . $item->get($field) . ' ';
        }
    }
    $c->res->output( $output );
}

sub is_indexed : Local {
    my ( $self, $c, $key ) = @_;
   
    $c->res->output( $plucene->is_indexed( $key ) || 'no results' );
}

sub optimize : Local {
    my ( $self, $c ) = @_;
    
    $plucene->optimize;
    $c->res->output( 'ok' );
}

1;
