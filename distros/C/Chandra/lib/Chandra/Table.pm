package Chandra::Table;

use strict;
use warnings;
use Object::Proto;
use Cpanel::JSON::XS ();
use Chandra::Component;
use Chandra::Element;

our $VERSION = '0.25';

BEGIN {
    Object::Proto::define('Chandra::Table',
        extends => 'Chandra::Component',
        'columns:ArrayRef:required',
        'data:ArrayRef:default([])',
        'page_size:Int:default(25)',
        'selectable:Str:default(0)',
        'striped:Bool:default(1)',
        'on_row_click:CodeRef',
        'on_sort:CodeRef',
        'on_selection:CodeRef',
        'empty_message:Str:default(No data)',
        'loading:Bool:default(0)',
        '_current_page:Int:default(1)',
        '_sort_key:Str',
        '_sort_dir:Str:default(asc)',
        '_filters:HashRef:default({})',
        '_selected:HashRef:default({})',
    );
    Object::Proto::import_accessors('Chandra::Table', 'tbl_');
}

# ── Data access ────────────────────────────────────────────

sub set_data {
    my ($self, $data) = @_;
    tbl_data $self, $data;
    tbl__current_page $self, 1;
    tbl__selected $self, {};
    $self->update if $self->_mounted;
    return $self;
}

sub selected_rows {
    my ($self) = @_;
    my $sel = tbl__selected $self;
    my $data = $self->_visible_data;
    return grep { $sel->{$_} } (0 .. $#$data);
}

# ── Filtering ──────────────────────────────────────────────

sub _filtered_data {
    my ($self) = @_;
    my $data = tbl_data $self;
    my $filters = tbl__filters $self;
    return $data unless keys %$filters;

    my @result;
    for my $row (@$data) {
        my $match = 1;
        for my $key (keys %$filters) {
            my $val = $filters->{$key};
            next unless defined $val && length $val;
            my $cell = $row->{$key} // '';
            if (index(lc($cell), lc($val)) < 0) {
                $match = 0;
                last;
            }
        }
        push @result, $row if $match;
    }
    return \@result;
}

# ── Sorting ────────────────────────────────────────────────

sub _sorted_data {
    my ($self) = @_;
    my $data = $self->_filtered_data;
    my $key = tbl__sort_key $self;
    return $data unless defined $key && length $key;

    my $dir = tbl__sort_dir $self;
    my @sorted = sort {
        my $va = $a->{$key} // '';
        my $vb = $b->{$key} // '';
        my $cmp = ($va =~ /^-?\d+\.?\d*$/ && $vb =~ /^-?\d+\.?\d*$/)
            ? ($va <=> $vb)
            : (lc($va) cmp lc($vb));
        $dir eq 'desc' ? -$cmp : $cmp;
    } @$data;
    return \@sorted;
}

# ── Pagination ─────────────────────────────────────────────

sub _visible_data {
    my ($self) = @_;
    my $data = $self->_sorted_data;
    my $page_size = tbl_page_size $self;
    return $data if $page_size <= 0;

    my $page = tbl__current_page $self;
    my $start = ($page - 1) * $page_size;
    my $end = $start + $page_size - 1;
    $end = $#$data if $end > $#$data;
    return [] if $start > $#$data;
    return [@$data[$start .. $end]];
}

sub _total_pages {
    my ($self) = @_;
    my $data = $self->_filtered_data;
    my $page_size = tbl_page_size $self;
    return 1 if $page_size <= 0;
    use POSIX qw(ceil);
    return ceil(scalar(@$data) / $page_size) || 1;
}

# ── Actions ────────────────────────────────────────────────

sub _update_body {
    my ($self) = @_;
    my $cid = $self->_cid;
    $self->update_part("${cid}_body", $self->_render_tbody->render);
    $self->update_part("${cid}_pag",  $self->_render_pagination->render);
    $self->update_part("${cid}_head", $self->_render_thead->render);
}

sub on_sort_column {
    my ($self, $key) = @_;
    my $current = tbl__sort_key $self;
    if (defined $current && $current eq $key) {
        tbl__sort_dir $self, (tbl__sort_dir($self) eq 'asc' ? 'desc' : 'asc');
    } else {
        tbl__sort_key $self, $key;
        tbl__sort_dir $self, 'asc';
    }
    my $cb = tbl_on_sort $self;
    $cb->($key, tbl__sort_dir $self) if $cb;
    tbl__current_page $self, 1;
    $self->_update_body;
}

sub on_filter {
    my ($self, $key, $value) = @_;
    my $filters = tbl__filters $self;
    if (defined $value && length $value) {
        $filters->{$key} = $value;
    } else {
        delete $filters->{$key};
    }
    tbl__filters $self, $filters;
    tbl__current_page $self, 1;
    $self->_update_body;
}

sub on_page {
    my ($self, $page) = @_;
    $page = int($page);
    my $total = $self->_total_pages;
    $page = 1 if $page < 1;
    $page = $total if $page > $total;
    tbl__current_page $self, $page;
    $self->_update_body;
}

sub on_select_row {
    my ($self, $index) = @_;
    my $sel = tbl__selected $self;
    my $mode = tbl_selectable $self;
    return unless $mode;
    if ($mode eq 'single') {
        $sel = { $index => 1 };
    } else {
        if ($sel->{$index}) { delete $sel->{$index} }
        else { $sel->{$index} = 1 }
    }
    tbl__selected $self, $sel;
    my $cb = tbl_on_selection $self;
    $cb->(keys %$sel) if $cb;
    $self->_update_body;
}

sub on_click_row {
    my ($self, $index) = @_;
    my $cb = tbl_on_row_click $self;
    if ($cb) {
        my $visible = $self->_visible_data;
        $cb->($visible->[$index]) if $index >= 0 && $index <= $#$visible;
    }
}

sub on_select_all {
    my ($self) = @_;
    my $visible = $self->_visible_data;
    my $sel = tbl__selected $self;
    if (keys(%$sel) == scalar(@$visible)) {
        tbl__selected $self, {};
    } else {
        my %new_sel;
        $new_sel{$_} = 1 for 0 .. $#$visible;
        tbl__selected $self, \%new_sel;
    }
    $self->_update_body;
}

# ── CSV Export ─────────────────────────────────────────────

sub to_csv {
    my ($self) = @_;
    my $columns = tbl_columns $self;
    my $data = $self->_sorted_data;
    my @lines;
    push @lines, join(',', map { _csv_escape($_->{label} // $_->{key}) } @$columns);
    for my $row (@$data) {
        push @lines, join(',', map { _csv_escape($row->{$_->{key}} // '') } @$columns);
    }
    return join("\n", @lines) . "\n";
}

sub _csv_escape {
    my ($val) = @_;
    if ($val =~ /[",\n\r]/) {
        $val =~ s/"/""/g;
        return qq{"$val"};
    }
    return $val;
}

# ── Render sub-parts (each with stable ID for partial updates) ──

sub _render_thead {
    my ($self) = @_;
    my $cid       = $self->_cid;
    my $columns   = tbl_columns $self;
    my $selectable = tbl_selectable $self;
    my $visible   = $self->_visible_data;
    my $sel       = tbl__selected $self;
    my $sort_key  = tbl__sort_key $self;
    my $sort_dir  = tbl__sort_dir $self;

    my $thead = Chandra::Element->new({ tag => 'thead', id => "${cid}_head" });
    my $hrow = Chandra::Element->new({ tag => 'tr' });

    if ($selectable eq 'multi') {
        my $th = Chandra::Element->new({ tag => 'th', class => 'chandra-table-select' });
        my $cb = Chandra::Element->new({ tag => 'input', 'data-action' => 'select_all' });
        $cb->attribute('type', 'checkbox');
        $cb->attribute('checked', 'checked') if @$visible && keys(%$sel) == scalar(@$visible);
        $th->add_child($cb);
        $hrow->add_child($th);
    } elsif ($selectable) {
        $hrow->add_child(Chandra::Element->new({ tag => 'th', class => 'chandra-table-select' }));
    }

    for my $col (@$columns) {
        my $label = $col->{label} // $col->{key};
        my %th_args = (tag => 'th');
        $th_args{style} = { width => "$col->{width}px" } if $col->{width};
        if ($col->{sortable}) {
            my $arrow = '';
            if (defined $sort_key && $sort_key eq $col->{key}) {
                $arrow = $sort_dir eq 'asc' ? " \x{25B2}" : " \x{25BC}";
            }
            $th_args{class} = 'chandra-table-sortable';
            $th_args{'data-action'} = "sort_column:$col->{key}";
            $th_args{data} = "$label$arrow";
        } else {
            $th_args{data} = $label;
        }
        $hrow->add_child(Chandra::Element->new(\%th_args));
    }
    $thead->add_child($hrow);
    return $thead;
}

sub _render_tbody {
    my ($self) = @_;
    my $cid        = $self->_cid;
    my $columns    = tbl_columns $self;
    my $visible    = $self->_visible_data;
    my $selectable = tbl_selectable $self;
    my $striped    = tbl_striped $self;
    my $sel        = tbl__selected $self;
    my $loading    = tbl_loading $self;

    my $tbody = Chandra::Element->new({ tag => 'tbody', id => "${cid}_body" });
    my $colspan = scalar(@$columns) + ($selectable ? 1 : 0);

    if ($loading) {
        my $tr = Chandra::Element->new({ tag => 'tr' });
        my $td = Chandra::Element->new({ tag => 'td', class => 'chandra-table-loading', data => 'Loading...' });
        $td->attribute('colspan', $colspan);
        $tr->add_child($td);
        $tbody->add_child($tr);
    } elsif (!@$visible) {
        my $tr = Chandra::Element->new({ tag => 'tr' });
        my $td = Chandra::Element->new({ tag => 'td', class => 'chandra-table-empty', data => tbl_empty_message($self) });
        $td->attribute('colspan', $colspan);
        $tr->add_child($td);
        $tbody->add_child($tr);
    } else {
        for my $i (0 .. $#$visible) {
            my $row = $visible->[$i];
            my $class = '';
            $class .= 'chandra-table-stripe' if $striped && $i % 2;
            $class .= ($class ? ' ' : '') . 'chandra-table-selected' if $sel->{$i};
            my %tr_args = (tag => 'tr', 'data-action' => "click_row:$i");
            $tr_args{class} = $class if $class;
            my $tr = Chandra::Element->new(\%tr_args);

            if ($selectable) {
                my $td = Chandra::Element->new({ tag => 'td', class => 'chandra-table-select' });
                my $cb = Chandra::Element->new({ tag => 'input', 'data-action' => "select_row:$i" });
                $cb->attribute('type', 'checkbox');
                $cb->attribute('checked', 'checked') if $sel->{$i};
                $td->add_child($cb);
                $tr->add_child($td);
            }

            for my $col (@$columns) {
                my $val = $row->{$col->{key}} // '';
                if ($col->{type} && $col->{type} eq 'boolean') {
                    $val = $val ? "\x{2713}" : '';
                }
                $val = $col->{render}->($val, $row) if $col->{render};
                $tr->add_child(Chandra::Element->new({ tag => 'td', data => $val }));
            }
            $tbody->add_child($tr);
        }
    }
    return $tbody;
}

sub _render_pagination {
    my ($self) = @_;
    my $cid          = $self->_cid;
    my $total_pages  = $self->_total_pages;
    my $current_page = tbl__current_page $self;

    my $pag = Chandra::Element->new({ tag => 'div', id => "${cid}_pag", class => 'chandra-table-pagination' });

    if ($total_pages <= 1) {
        return $pag;  # empty div placeholder
    }

    my $filtered = $self->_filtered_data;
    $pag->add_child(Chandra::Element->new({
        tag => 'span', class => 'chandra-table-info',
        data => scalar(@$filtered) . ' rows, page ' . $current_page . ' of ' . $total_pages,
    }));

    if ($current_page > 1) {
        $pag->add_child(Chandra::Element->new({
            tag => 'button', class => 'chandra-table-page-btn',
            'data-action' => 'page:1', raw => '&laquo;',
        }));
        $pag->add_child(Chandra::Element->new({
            tag => 'button', class => 'chandra-table-page-btn',
            'data-action' => 'page:' . ($current_page - 1), raw => '&lsaquo;',
        }));
    }

    my $start_p = $current_page - 2;
    $start_p = 1 if $start_p < 1;
    my $end_p = $start_p + 4;
    $end_p = $total_pages if $end_p > $total_pages;
    for my $p ($start_p .. $end_p) {
        my $cls = 'chandra-table-page-btn';
        $cls .= ' chandra-table-page-active' if $p == $current_page;
        $pag->add_child(Chandra::Element->new({
            tag => 'button', class => $cls,
            'data-action' => "page:$p", data => $p,
        }));
    }

    if ($current_page < $total_pages) {
        $pag->add_child(Chandra::Element->new({
            tag => 'button', class => 'chandra-table-page-btn',
            'data-action' => 'page:' . ($current_page + 1), raw => '&rsaquo;',
        }));
        $pag->add_child(Chandra::Element->new({
            tag => 'button', class => 'chandra-table-page-btn',
            'data-action' => "page:$total_pages", raw => '&raquo;',
        }));
    }

    return $pag;
}

# ── Full render (using Chandra::Element) ──────────────────

sub render {
    my ($self) = @_;
    my $cid     = $self->_cid;
    my $columns = tbl_columns $self;
    my $filters = tbl__filters $self;

    my $wrap = Chandra::Element->new({ tag => 'div', class => 'chandra-table-wrap' });

    # ── Filter row (never re-rendered by _update_body) ────
    my $has_filters = grep { $_->{filterable} } @$columns;
    if ($has_filters) {
        my $filter_div = Chandra::Element->new({ tag => 'div', class => 'chandra-table-filters' });
        for my $col (@$columns) {
            next unless $col->{filterable};
            my $key = $col->{key};
            my $current = $filters->{$key} // '';
            if ($col->{filter_options}) {
                my $select = Chandra::Element->new({
                    tag => 'select', class => 'chandra-table-filter',
                    'data-action' => "filter:$key",
                });
                $select->add_child(Chandra::Element->new({
                    tag => 'option', data => "All $col->{label}",
                })->attribute('value', ''));
                for my $opt (@{$col->{filter_options}}) {
                    my $option = Chandra::Element->new({ tag => 'option', data => $opt });
                    $option->attribute('value', $opt);
                    $option->attribute('selected', 'selected') if $current eq $opt;
                    $select->add_child($option);
                }
                $filter_div->add_child($select);
            } else {
                my $input = Chandra::Element->new({
                    tag => 'input', class => 'chandra-table-filter',
                    'data-action' => "filter:$key",
                });
                $input->attribute('type', 'text');
                $input->attribute('placeholder', "Filter $col->{label}...");
                $input->attribute('value', $current);
                $filter_div->add_child($input);
            }
        }
        $wrap->add_child($filter_div);
    }

    # ── Table with thead + tbody ──────────────────────────
    my $table = Chandra::Element->new({ tag => 'table', class => 'chandra-table' });
    $table->add_child($self->_render_thead);
    $table->add_child($self->_render_tbody);
    $wrap->add_child($table);

    # ── Pagination ────────────────────────────────────────
    $wrap->add_child($self->_render_pagination);

    return $wrap->render;
}

# ── CSS ────────────────────────────────────────────────────

sub css {
    return <<'CSS';
.chandra-table-wrap { font-family: system-ui, -apple-system, sans-serif; }
.chandra-table { width: 100%; border-collapse: collapse; }
.chandra-table th, .chandra-table td { padding: 8px 12px; text-align: left; border-bottom: 1px solid #e0e0e0; }
.chandra-table th { background: #f5f5f5; font-weight: 600; user-select: none; }
.chandra-table-sortable { cursor: pointer; }
.chandra-table-sortable:hover { background: #e8e8e8; }
.chandra-table-stripe { background: #fafafa; }
.chandra-table-selected { background: #e3f2fd !important; }
.chandra-table-select { width: 40px; text-align: center; }
.chandra-table-empty, .chandra-table-loading { text-align: center; padding: 24px; color: #999; }
.chandra-table-filters { padding: 8px 0; display: flex; gap: 8px; flex-wrap: wrap; }
.chandra-table-filter { padding: 4px 8px; border: 1px solid #ddd; border-radius: 4px; font-size: 13px; }
.chandra-table-pagination { display: flex; align-items: center; justify-content: center; gap: 4px; padding: 12px 0; }
.chandra-table-page-btn { padding: 4px 10px; border: 1px solid #ddd; border-radius: 4px; background: #fff; cursor: pointer; font-size: 13px; }
.chandra-table-page-btn:hover { background: #f0f0f0; }
.chandra-table-page-active { background: #2196F3 !important; color: #fff; border-color: #2196F3; }
.chandra-table-info { margin-right: 12px; font-size: 13px; color: #666; }
CSS
}

1;

__END__

=head1 NAME

Chandra::Table - Sortable, filterable, paginated data grid component

=head1 SYNOPSIS

    use Chandra::Table;

    my $table = Chandra::Table->new(
        columns => [
            { key => 'name',  label => 'Name',  sortable => 1 },
            { key => 'email', label => 'Email', sortable => 1 },
            { key => 'role',  label => 'Role',  filterable => 1,
              filter_options => [qw(admin user guest)] },
        ],
        data      => \@users,
        page_size => 10,
        selectable => 'multi',
        on_row_click => sub { my ($row) = @_; print $row->{name} },
    );

    $app->css(Chandra::Table->css);
    $table->mount($app, '#content');

=head1 DESCRIPTION

C<Chandra::Table> is a L<Chandra::Component> subclass providing a
data grid. Renders using L<Chandra::Element> for proper event wiring.

=head1 SEE ALSO

L<Chandra::Component>, L<Chandra::Element>, L<Chandra::App>

=cut
