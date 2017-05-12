package CGI::Widget::DBI::Search::Display::Grid;

use strict;

use base qw/ CGI::Widget::DBI::Search::AbstractDisplay /;

=head1 NAME

CGI::Widget::DBI::Search::Display::Grid - Grid display class for Search widget

=head1 SYNOPSIS

  my $ws = CGI::Widget::DBI::Search->new(q => CGI->new);
  ...
  $ws->{-display_class} = 'CGI::Widget::DBI::Search::Display::Grid';

  # or instead, simply:
  $ws->{-display_mode} = 'grid';

=head1 DESCRIPTION

This class displays search results retrieved in the search widget in a grid format
with each row in the dataset inhabiting its own cell.  The dataset can be sorted
via a drop-down menu at the upper-right of the grid, and paging links appear at the
lower right.

=head1 METHODS

=over 4

=item render_dataset()

Builds an HTML table in grid layout for current page in the dataset.

Builds data in object variables:

  dataset_cells_html

=cut

sub render_dataset {
    my ($self) = @_;
    $self->{'dataset_cells_html'} = [];

    # iterate over most recently returned 'results', which should be a
    # (possibly blessed) hashref
    foreach my $row (@{$self->{'results'}}) {
	# build a cell in the grid
	push(@{ $self->{'dataset_cells_html'} }, $self->display_cell($row));
    }
}

=item display_cell( $row )

Returns an HTML table cell rendering for row $row in the dataset.  Called by
render_dataset() for each row in the current page of search results.

=cut

sub display_cell {
    my ($self, $row) = @_;
    my $td_width = sprintf('%.0f%%', 1 / $self->{-grid_columns} * 100);

    my %extra_attributes = %{ $self->get_option_value('-extra_grid_cell_attributes', [$row]) || {} };

    return $self->{q}->td(
        {-class => $self->{-css_grid_cell_class} || 'searchWidgetGridCell',
         -valign => 'top', -width => $td_width, %extra_attributes},
        join '<br/>', map {
            my $hdr = defined $self->{-display_columns}->{$_}
              ? $self->{-display_columns}->{$_} : $_;
            ($self->{-browse_mode} ? '' : $hdr ? $hdr.': ' : '')
              . $self->display_record($row, $_);
        } @{ $self->{'header_columns'} }
    );
}

=item display_dataset()

Returns HTML rendering of current page in search results, along with navigation links.

=cut

sub display_dataset {
    my ($self) = @_;
    my @grid_rows;
    foreach my $i (0 .. $#{ $self->{'dataset_cells_html'} }) {
        if ($i % $self->{-grid_columns} == 0) {
            push(@grid_rows, $self->{'dataset_cells_html'}->[$i]);
        } else {
            $grid_rows[-1] .= $self->{'dataset_cells_html'}->[$i];
        }
    }

    return ($self->{-optional_header}||'')
      . $self->extra_vars_for_form()
      . ($self->{-browse_mode}
           ? $self->display_pager_links(1, 0, 1)
           : '<div align="right">'.$self->translate('Sort by').': '.$self->display_sort_popup.'</div>'.$self->display_pager_links(1, 0))
      . '<table id="'.($self->{-css_grid_id} || 'searchWidgetGridId').'" class="'.($self->{-css_grid_class} || 'searchWidgetGridTable').'">'
        . $self->{q}->Tr([ @grid_rows ])
      . '</table>'
      . ($self->{-browse_mode}
           ? $self->display_pager_links(0, 1, 1)
           : $self->display_pager_links(0, 1))
      . ($self->{-optional_footer}||'');
}

=item display_sort_popup()

Returns an HTML popup with possible columns to sort dataset by, whose values are the
full navigation URIs.  An onChange event causes the URI to be loaded, resorting the
dataset.

=cut

sub display_sort_popup {
    my ($self) = @_;
    my $q = $self->{q};

    my @sortable_cols = ref $self->{-sortable_columns} eq 'HASH'
      ? keys %{$self->{-sortable_columns} || {}}
      : @{$self->{'sql_table_display_columns'}};
    $self->{'sortable_columns'} ||= [
        map { $self->_column_name($_) } grep { ! $self->{-unsortable_columns}->{$_} } @sortable_cols
    ];
    return $q->popup_menu(
        -name => 'sortby_columns_popup',
        -values => [ '', map { $self->sortby_column_uri($_) } @{ $self->{'sortable_columns'} } ],
        -labels => {
            '' => '<'.$self->translate('Sort field').'>',
            map { $self->sortby_column_uri($_) => $self->{-display_columns}->{$_} || $_ }
              @{$self->{'sortable_columns'}}
        },
        -onchange => $self->{'action_uri_jsfunc'} ? 'var code = this.value; eval(code);' : 'if (this.value) window.location=this.value;',
        -default => $q->param('sortby') ? $self->sortby_column_uri($q->param('sortby')) : undef,
    );
}

=item _set_display_defaults()

Sets grid-layout specific default settings in addition to settings in
AbstractDisplay.

=cut

sub _set_display_defaults {
    my ($self) = @_;
    $self->SUPER::_set_display_defaults();
    $self->{-grid_columns} ||= 4;
}


1;
__END__

=back

=head1 SEE ALSO

L<CGI::Widget::DBI::Search::AbstractDisplay>

=cut
