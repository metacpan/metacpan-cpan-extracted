#!/usr/bin/env perl

use strict;
use warnings;
use CGI qw(:standard);
use App::ProcTrends::RRD;

exit(main());

sub main {  
    my $ref = {};

    my $q = CGI->new();
    $ref->{ rrd_dir }   = $q->param('rrd_dir');
    $ref->{ start }     = $q->param('start');
    $ref->{ end }       = $q->param('end');
    $ref->{ line }      = $q->param('line');
    $ref->{ stack }     = $q->param('stack');
    $ref->{ imgformat } = $q->param('imgformat');
    $ref->{ title }     = $q->param('title');
    $ref->{ width }     = $q->param('width');
    $ref->{ height }    = $q->param('height');
    my $process         = $q->param('process');
    my $metric          = $q->param('metric');
    
    my $rrd = App::ProcTrends::RRD->new( $ref );
    $rrd->gen_image( '/home/satoshi/test.png', 'cpu', 'firefox' );
}