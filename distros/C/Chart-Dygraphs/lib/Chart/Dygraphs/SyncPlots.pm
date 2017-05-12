package Chart::Dygraphs::SyncPlots;

use strict;
use warnings;
use utf8;

use Moose;
use Chart::Dygraphs;
use Chart::Dygraphs::Plot;

our $VERSION = '0.007';    # VERSION

# ABSTRACT: Collection of plots synced

has 'plots' => ( traits  => ['Array'],
                 is      => 'rw',
                 isa     => 'ArrayRef[Chart::Dygraphs::Plot]',
                 default => sub { [] },
                 handles => { add_plot    => 'push',
                              get_plot    => 'get',
                              insert_plot => 'insert',
                              delete_plot => 'delete'
                 }
);

sub show {
    my $self                    = shift;
    my $synced_plots            = $self->plots;
    my @data_to_plot            = @$synced_plots;
    my $number_of_plots_to_sync = scalar @data_to_plot;
    my $rendered_cells          = "";
    my $numeric_id              = 0;
    my $first_plot              = 1;
    my $pre_graph_html          = "<script>var blockRedraw = false; var grupo = []</script>";
    for my $data (@data_to_plot) {

        if ( ref $data eq 'Chart::Dygraphs::Plot' ) {
            my $javascript_object_name = 'g' . $numeric_id;
            $rendered_cells .= Chart::Dygraphs::_render_cell(
                Chart::Dygraphs::_process_data_and_options( $data->data, $data->options ),
                {  dygraphs_div_id                 => 'graphdiv' . $numeric_id,
                   dygraphs_javascript_object_name => $javascript_object_name,
                   ( $first_plot-- ? ( pre_graph_html => $pre_graph_html ) : () ),
                   post_graph_html => "<script>
													$javascript_object_name.updateOptions({drawCallback: function(me, initial) {
                if (blockRedraw || initial) return;
                blockRedraw = true;
                var range = me.xAxisRange();
                //var yrange = me.yAxisRange();
                for (var j = 0; j < $number_of_plots_to_sync; j++) {
				  if (j < grupo.length) {
                  if (grupo[j] == me) continue;
                  grupo[j].updateOptions( {
                    dateWindow: range,
                    //valueRange: yrange
                  } );
				  }
                }
                blockRedraw = false;
            }});
													grupo.push($javascript_object_name)</script>"
                },
                'chart_' . $numeric_id++
            );

        } else {
            $rendered_cells .= Chart::Dygraphs::_render_cell(
                                        Chart::Dygraphs::_process_data_and_options( $data, { showRangeSelector => 1 } ),
                                        { dygraphs_div_id                 => 'graphdiv' . $numeric_id,
                                          dygraphs_javascript_object_name => 'g' . $numeric_id
                                        },
                                        'chart_' . $numeric_id++
            );
        }
    }
    my $plots = Chart::Dygraphs::_render_html_wrap($rendered_cells);
    HTML::Show::show($plots);

}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Chart::Dygraphs::SyncPlots - Collection of plots synced 

=head1 VERSION

version 0.007

=head1 METHODS

=head2 show

Show the sync plots.

This method is subject to change

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Pablo Rodríguez González.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
