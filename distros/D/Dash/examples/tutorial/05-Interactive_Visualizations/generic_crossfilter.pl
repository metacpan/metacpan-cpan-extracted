#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Dash;
use aliased 'Dash::Core::Components' => 'dcc';
use aliased 'Dash::Html::Components' => 'html';
use aliased 'Dash::Dependencies'     => 'deps';

use Alt::Data::Frame::ButMore;
use Data::Frame;
use PDL;
use PDL::Primitive;

my $external_stylesheets = ['https://codepen.io/chriddyp/pen/bWLwgP.css'];

srand(0);
my $df    = Data::Frame->new( columns => [ map { ( "Col $_" => random(30) ) } 1 .. 6 ] );
my $index = $df->row_names;

my $app = Dash->new( app_name             => 'Dash Tutorial - 3 Basic Callbacks',
                     external_stylesheets => $external_stylesheets );

$app->layout(
              html->Div(
                         [
                           html->Div( dcc->Graph( id => 'g1', config => { displayModeBar => JSON::false } ),
                                      className => 'four columns'
                           ),
                           html->Div( dcc->Graph( id => 'g2', config => { displayModeBar => JSON::false } ),
                                      className => 'four columns'
                           ),
                           html->Div( dcc->Graph( id => 'g3', config => { displayModeBar => JSON::false } ),
                                      className => 'four columns'
                           ),
                         ],
                         className => 'row'
              )
);

sub get_figure {
    my ( $df, $x_col, $y_col, $selectedpoints, $selectedpoints_local ) = @_;
    my $selection_bounds;
    if ( $selectedpoints_local && ref($selectedpoints_local) eq 'HASH' && defined $selectedpoints_local->{range} ) {
        my $ranges = $selectedpoints_local->{range};
        $selection_bounds = { x0 => $ranges->{x}[0],
                              x1 => $ranges->{x}[1],
                              y0 => $ranges->{y}[0],
                              y1 => $ranges->{y}[1],
        };
    } else {
        $selection_bounds = { x0 => $df->at($x_col)->min,
                              x1 => $df->at($x_col)->max,
                              y0 => $df->at($y_col)->min,
                              y1 => $df->at($y_col)->max,
        };
    }
    return {
             data => [
                       { x              => $df->at($x_col)->unpdl,
                         y              => $df->at($y_col)->unpdl,
                         mode           => 'lines+markers',
                         textposition   => 'top',
                         selectedpoints => $selectedpoints->unpdl,
                         customdata     => $index->unpdl,
                         text           => $index->unpdl,
                         type           => 'scatter',
                         mode           => 'markers+text',
                         marker         => { color => 'rgba(0, 116, 217, 0.7)', size => 12 },
                         unselected     => {
                                         marker   => { opacity => 0.3 },
                                         textfont => { color   => 'rgba(0, 0, 0, 0)' }
                         }
                       }
             ],
             layout => { margin    => { l => 20, b => 15, r => 0, t => 5 },
                         dragmode  => 'select',
                         hovermode => JSON::false,
                         shapes    => {
                                     type => 'rect',
                                     line => { width => 1, dash => 'dot', color => 'darkgrey' },
                                     %{$selection_bounds}
                         }
             }
    };
}

$app->callback(
    [ deps->Output( 'g1', 'figure' ), deps->Output( 'g2', 'figure' ), deps->Output( 'g3', 'figure' ), ],
    [ deps->Input( 'g1', 'selectedData' ), deps->Input( 'g2', 'selectedData' ), deps->Input( 'g3', 'selectedData' ), ],
    sub {
        my ( $selection1, $selection2, $selection3 ) = @_;
        my $selectedpoints = $index->copy;
        for my $selected_data ( $selection1, $selection2, $selection3 ) {
            if ( $selected_data && defined $selected_data->{points} ) {
                $selectedpoints =
                  intersect( $selectedpoints, pdl( [ map { $_->{customdata} } @{ $selected_data->{points} } ] ) );
            }
        }
        return get_figure( $df, "Col 1", "Col 2", $selectedpoints, $selection1 ),
          get_figure( $df, "Col 3", "Col 4", $selectedpoints, $selection2 ),
          get_figure( $df, "Col 5", "Col 6", $selectedpoints, $selection3 ),
          ;
    }
);

$app->run_server();
