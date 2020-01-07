# AUTO GENERATED FILE - DO NOT EDIT

package Dash::Table::DataTable;

use Dash::Table;
use Mojo::Base 'Dash::BaseComponent';

has 'active_cell';
has 'columns';
has 'include_headers_on_copy_paste';
has 'locale_format';
has 'css';
has 'data';
has 'data_previous';
has 'data_timestamp';
has 'editable';
has 'end_cell';
has 'export_columns';
has 'export_format';
has 'export_headers';
has 'fill_width';
has 'hidden_columns';
has 'id';
has 'is_focused';
has 'merge_duplicate_headers';
has 'fixed_columns';
has 'fixed_rows';
has 'column_selectable';
has 'row_deletable';
has 'row_selectable';
has 'selected_cells';
has 'selected_rows';
has 'selected_columns';
has 'selected_row_ids';
has 'start_cell';
has 'style_as_list_view';
has 'page_action';
has 'page_current';
has 'page_count';
has 'page_size';
has 'dropdown';
has 'dropdown_conditional';
has 'dropdown_data';
has 'tooltip';
has 'tooltip_conditional';
has 'tooltip_data';
has 'tooltip_delay';
has 'tooltip_duration';
has 'filter_query';
has 'filter_action';
has 'sort_action';
has 'sort_mode';
has 'sort_by';
has 'sort_as_null';
has 'style_table';
has 'style_cell';
has 'style_data';
has 'style_filter';
has 'style_header';
has 'style_cell_conditional';
has 'style_data_conditional';
has 'style_filter_conditional';
has 'style_header_conditional';
has 'virtualization';
has 'derived_filter_query_structure';
has 'derived_viewport_data';
has 'derived_viewport_indices';
has 'derived_viewport_row_ids';
has 'derived_viewport_selected_columns';
has 'derived_viewport_selected_rows';
has 'derived_viewport_selected_row_ids';
has 'derived_virtual_data';
has 'derived_virtual_indices';
has 'derived_virtual_row_ids';
has 'derived_virtual_selected_rows';
has 'derived_virtual_selected_row_ids';
has 'loading_state';
has 'persistence';
has 'persisted_props';
has 'persistence_type';
my $dash_namespace = 'dash_table';

sub DashNamespace {
    return $dash_namespace;
}

sub _js_dist {
    return Dash::Table::_js_dist;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Table::DataTable

=head1 VERSION

version 0.05

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
