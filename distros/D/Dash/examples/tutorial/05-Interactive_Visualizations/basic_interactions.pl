#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Dependencies'     => 'deps';

use JSON;

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

my $app = Dash->new( app_name             => 'Dash Tutorial - 3 Basic Callbacks',
                     external_stylesheets => $external_stylesheets );

my %styles = (
               pre => { border    => 'thin lightgrey solid',
                        overflowX => 'scroll'
               }
);

$app->layout(
    html->Div(
        [
           dcc->Graph( id     => 'basic-interactions',
                       figure => {
                                   data => [
                                             { x          => [ 1, 2, 3, 4 ],
                                               y          => [ 4, 1, 3, 5 ],
                                               text       => [qw(a b c d)],
                                               customdata => [qw(c.a c.b c.c c.d)],
                                               name       => 'Trace 1',
                                               mode       => 'markers',
                                               marker     => { size => 12 }
                                             },
                                             { x          => [ 1, 2, 3, 4 ],
                                               y          => [ 9, 4, 1, 4 ],
                                               text       => [qw(w x y z)],
                                               customdata => [qw(c.w c.x c.y c.z)],
                                               name       => 'Trace 2',
                                               mode       => 'markers',
                                               marker     => { size => 12 }
                                             }
                                   ],
                                   layout => { clickmode => 'event+select' }
                       }
           ),
           html->Div(
               className => 'row',
               children  => [
                   html->Div(
                       [
                          dcc->Markdown( '
                                **Hover Data**

                                Mouse over values in the graph.
                                ' ),
                          html->Pre( id => 'hover-data', style => $styles{pre} )

                       ],
                       className => 'three columns'
                   ),
                   html->Div(
                       [
                          dcc->Markdown( "
                               **Selection Data**

                               Choose the lasso or rectangle tool in the graph's menu
                               bar and then select points in the graph.

                               Note that if `layout.clickmode = 'event+select'`, selection data also 
                               accumulates (or un-accumulates) selected data if you hold down the shift
                               button while clicking.    
                                " ),
                          html->Pre( id => 'selected-data', style => $styles{pre} )
                       ],
                       className => 'three columns'
                   ),
                   html->Div(
                       [
                          dcc->Markdown( "
                                **Zoom and Relayout Data**

                                Click and drag on the graph to zoom or click on the zoom
                                buttons in the graph's menu bar.
                                Clicking on legend items will also fire
                                this event.                                
                                " ),
                          html->Pre( id => 'relayout-data', style => $styles{pre} )
                       ],
                       className => 'three columns'
                   ),

               ]
           )
        ]
    )
);

$app->callback(
    deps->Output( 'hover-data', 'children' ),
    [ deps->Input( 'basic-interactions', 'hoverData' ), ],
    sub {
        return to_json( shift, { pretty => 1, canonical => 1 } );
    }
);

$app->callback(
    deps->Output( 'click-data', 'children' ),
    [ deps->Input( 'basic-interactions', 'clickData' ), ],
    sub {
        return to_json( shift, { pretty => 1, canonical => 1 } );
    }
);

$app->callback(
    deps->Output( 'selected-data', 'children' ),
    [ deps->Input( 'basic-interactions', 'selectedData' ), ],
    sub {
        return to_json( shift, { pretty => 1, canonical => 1 } );
    }
);

$app->callback(
    deps->Output( 'relayout-data', 'children' ),
    [ deps->Input( 'basic-interactions', 'relayoutData' ), ],
    sub {
        return to_json( shift, { pretty => 1, canonical => 1 } );
    }
);

$app->run_server();
