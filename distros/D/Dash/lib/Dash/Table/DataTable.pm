# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Table::DataTable;

use Moo;
use strictures 2;
use Dash::TableAssets;
use namespace::clean;

extends 'Dash::BaseComponent';

has 'active_cell'                       => ( is => 'rw' );
has 'columns'                           => ( is => 'rw' );
has 'include_headers_on_copy_paste'     => ( is => 'rw' );
has 'locale_format'                     => ( is => 'rw' );
has 'css'                               => ( is => 'rw' );
has 'data'                              => ( is => 'rw' );
has 'data_previous'                     => ( is => 'rw' );
has 'data_timestamp'                    => ( is => 'rw' );
has 'editable'                          => ( is => 'rw' );
has 'end_cell'                          => ( is => 'rw' );
has 'export_columns'                    => ( is => 'rw' );
has 'export_format'                     => ( is => 'rw' );
has 'export_headers'                    => ( is => 'rw' );
has 'fill_width'                        => ( is => 'rw' );
has 'hidden_columns'                    => ( is => 'rw' );
has 'id'                                => ( is => 'rw' );
has 'is_focused'                        => ( is => 'rw' );
has 'merge_duplicate_headers'           => ( is => 'rw' );
has 'fixed_columns'                     => ( is => 'rw' );
has 'fixed_rows'                        => ( is => 'rw' );
has 'column_selectable'                 => ( is => 'rw' );
has 'row_deletable'                     => ( is => 'rw' );
has 'row_selectable'                    => ( is => 'rw' );
has 'selected_cells'                    => ( is => 'rw' );
has 'selected_rows'                     => ( is => 'rw' );
has 'selected_columns'                  => ( is => 'rw' );
has 'selected_row_ids'                  => ( is => 'rw' );
has 'start_cell'                        => ( is => 'rw' );
has 'style_as_list_view'                => ( is => 'rw' );
has 'page_action'                       => ( is => 'rw' );
has 'page_current'                      => ( is => 'rw' );
has 'page_count'                        => ( is => 'rw' );
has 'page_size'                         => ( is => 'rw' );
has 'dropdown'                          => ( is => 'rw' );
has 'dropdown_conditional'              => ( is => 'rw' );
has 'dropdown_data'                     => ( is => 'rw' );
has 'tooltip'                           => ( is => 'rw' );
has 'tooltip_conditional'               => ( is => 'rw' );
has 'tooltip_data'                      => ( is => 'rw' );
has 'tooltip_delay'                     => ( is => 'rw' );
has 'tooltip_duration'                  => ( is => 'rw' );
has 'filter_query'                      => ( is => 'rw' );
has 'filter_action'                     => ( is => 'rw' );
has 'sort_action'                       => ( is => 'rw' );
has 'sort_mode'                         => ( is => 'rw' );
has 'sort_by'                           => ( is => 'rw' );
has 'sort_as_null'                      => ( is => 'rw' );
has 'style_table'                       => ( is => 'rw' );
has 'style_cell'                        => ( is => 'rw' );
has 'style_data'                        => ( is => 'rw' );
has 'style_filter'                      => ( is => 'rw' );
has 'style_header'                      => ( is => 'rw' );
has 'style_cell_conditional'            => ( is => 'rw' );
has 'style_data_conditional'            => ( is => 'rw' );
has 'style_filter_conditional'          => ( is => 'rw' );
has 'style_header_conditional'          => ( is => 'rw' );
has 'virtualization'                    => ( is => 'rw' );
has 'derived_filter_query_structure'    => ( is => 'rw' );
has 'derived_viewport_data'             => ( is => 'rw' );
has 'derived_viewport_indices'          => ( is => 'rw' );
has 'derived_viewport_row_ids'          => ( is => 'rw' );
has 'derived_viewport_selected_columns' => ( is => 'rw' );
has 'derived_viewport_selected_rows'    => ( is => 'rw' );
has 'derived_viewport_selected_row_ids' => ( is => 'rw' );
has 'derived_virtual_data'              => ( is => 'rw' );
has 'derived_virtual_indices'           => ( is => 'rw' );
has 'derived_virtual_row_ids'           => ( is => 'rw' );
has 'derived_virtual_selected_rows'     => ( is => 'rw' );
has 'derived_virtual_selected_row_ids'  => ( is => 'rw' );
has 'loading_state'                     => ( is => 'rw' );
has 'persistence'                       => ( is => 'rw' );
has 'persisted_props'                   => ( is => 'rw' );
has 'persistence_type'                  => ( is => 'rw' );
my $dash_namespace = 'dash_table';

sub DashNamespace {
    return $dash_namespace;
}

sub _js_dist {
    return Dash::TableAssets::_js_dist;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Table::DataTable

=head1 VERSION

version 0.10

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
