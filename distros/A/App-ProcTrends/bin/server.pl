#!/usr/bin/env perl  

use strict;
use warnings;  
use Mojolicious::Lite;
use App::ProcTrends::Config;
use App::ProcTrends::RRD;
use Data::Dumper;
use RRDs;
use File::Temp qw/tempfile/;
use File::Slurp;

my $cfg = App::ProcTrends::Config->new();

get '/' => sub {
    my $self = shift;
    my $params = override_params( $self, $cfg );
    my $dir = $params->{ rrd_dir };
    my $rrd = App::ProcTrends::RRD->new( $params );
    
    for my $metric ( 'cpu', 'rss' ) {
        my $path = $dir . "/$metric";
        my $rrds = $rrd->find_rrds( $path );
        my @processes = sort keys %{ $rrds };
        my $img = $rrd->gen_group_image( $metric, \@processes );
        $self->render_data( $img, format=> lc( $params->{ imgformat } ) ) if ( $img );
    }
};

get '/img/:metric/:process' => sub {
    my $self = shift;
    my $metric = $self->param('metric');
    my $process = $self->param('process');
    
    my $params = override_params( $self, $cfg );
    my $rrd = App::ProcTrends::RRD->new( $params );
    my $graph = $rrd->gen_image( $metric, $process );
    $self->render_data( $graph, format => lc( $params->{ imgformat } ) ) if ( $graph );
};

get '/list' => sub {
    my $self = shift;
    
    my $params = override_params( $self, $cfg );
    my $dir = $params->{ rrd_dir };
    my $rrd = App::ProcTrends::RRD->new();
    my $result = {};
    
    for my $metric ( 'cpu', 'rss' ) {
        $result->{ $metric } = $rrd->find_rrds( $dir );
    }
    $self->render( json => $result );
};

app->start;

# each route can perform overrides from the defaults with this method.
sub override_params {
    my ( $self, $cfg ) = @_;
    
    my $params = {};
    $params->{ rrd_dir }   = $self->param('rrd_dir')   || $cfg->RRD_DIR();
    $params->{ start }     = $self->param('start')     || $cfg->RRD_START();
    $params->{ end }       = $self->param('end')       || $cfg->RRD_END();
    $params->{ line }      = $self->param('line')      || $cfg->RRD_LINE();
    $params->{ stack }     = $self->param('stack')     || $cfg->RRD_STACK();
    $params->{ imgformat } = $self->param('imgformat') || $cfg->RRD_IMGFORMAT();
    $params->{ title }     = $self->param('title')     || $cfg->RRD_TITLE();
    $params->{ width }     = $self->param('width')     || $cfg->RRD_WIDTH();
    $params->{ height }    = $self->param('height')    || $cfg->RRD_HEIGHT();
    
    return $params;
}
