package CGI::Widget::DBI::Search::AbstractDisplay;

use strict;

use base qw/ CGI::Widget::DBI::Search::Base /;

use constant BASE_URI => '';

sub new {
    my ($this, $search) = @_;
    my $class = ref($this) || $this;
    my $self = bless {}, $class;
    $self->{q} = $search->{q} if $search->{q};
    return $self;
}

sub get_option_value {
    my ($self, $option_name, $closure_args, $allowed_option_types) = @_;
    $allowed_option_types ||= { map {$_=>1} qw/CODE HASH ARRAY/ };

    return undef if ! $self->{$option_name} || ! $allowed_option_types->{ ref($self->{$option_name}) };
    return $self->{$option_name}->($self, @$closure_args) if ref $self->{$option_name} eq 'CODE';
    return $self->{$option_name};
}

=head1 NAME

CGI::Widget::DBI::Search::AbstractDisplay - Abstract Display class inherited by default display classes

=head1 SYNOPSIS

  package My::SearchWidget::CustomDisplayClass;

  use base qw/ CGI::Widget::DBI::Search::AbstractDisplay /;

  # ... implement abstract methods


  # then, when instantiating your search widget:
  my $ws = CGI::Widget::DBI::Search->new(q => CGI->new);
  ...
  $ws->{-display_class} = 'My::SearchWidget::CustomDisplayClass';

=head1 DESCRIPTION

This abstract class defines several methods useful to display classes, and is the base
class of all default display classes (shipped with this distribution).

=head1 ABSTRACT METHODS

=over 4

=item render_dataset()

=item display_dataset()

=back

=cut

sub render_dataset { die 'abstract'; }
sub display_dataset { die 'abstract'; }

=head1 METHODS

=over 4

=item display()

This is the top-level method called by L<CGI::Widget::DBI::Search>.  The default
implementation calls the _set_display_defaults() and render_dataset() methods,
then returns the result of the display_dataset() method.

If this method is overridden, it should return the rendering of the search
widget UI from data values stored in the search widget's 'results' object
variable (retrieved from the most recent call to its search() method).

=cut

sub display {
    my ($self) = @_;
    $self->_set_display_defaults();
    $self->render_dataset();
    return $self->display_dataset();
}

=item _set_display_defaults()

Sets object variables for displaying search results.  Called from display() method.

=cut

sub _set_display_defaults {
    my ($self) = @_;
    # read ordered list of table columns
    $self->{'sql_table_display_columns'} = ref $self->{-sql_retrieve_columns} eq 'ARRAY'
      ? [ @{$self->{-sql_retrieve_columns}} ] : [ @{$self->{-sql_table_columns}} ];

    $self->_init_header_columns();

    if ($self->{'-action_uri_js_function'}) {
        $self->{'action_uri_jsfunc'} = $self->{'-action_uri_js_function'};
        if (ref $self->{-href_extra_vars} eq 'HASH') {
            $self->{'json_extra_vars'} = $self->extra_vars_for_json();
        }
        return;
    }

    $self->{'action_uri'} = $self->{-action_uri} || $ENV{SCRIPT_NAME} || '';

    $self->{'href_extra_vars'} = '';
    if (ref $self->{-href_extra_vars} eq 'HASH') {
        $self->{'href_extra_vars'} = $self->extra_vars_for_uri();
    }
    if ($self->{-href_extra_vars_qs}) {
        $self->{'href_extra_vars'} .= '&'.$self->{-href_extra_vars_qs};
    }
    $self->{'href_extra_vars'} = '&'.$self->{'href_extra_vars'}
      if $self->{'href_extra_vars'} && $self->{'href_extra_vars'} !~ m/^&/;
}

=item _init_header_columns()

Initializes list of columns to display in dataset, based on 'sql_table_display_columns'
object variable, and -pre_nondb_columns, -post_nondb_columns, and -display_columns
settings.

=cut

sub _init_header_columns {
    my ($self) = @_;
    $self->{'header_columns'} = [];
    my $init_display_columns = ! (ref $self->{-display_columns} eq 'HASH');
    foreach my $sql_col (@{ $self->{-pre_nondb_columns} || [] },
                         @{ $self->{'sql_table_display_columns'} },
                         @{ $self->{-post_nondb_columns} || [] }) {
        my $col = _column_name($self, $sql_col);
        $self->{-display_columns}->{$col} = $col if $init_display_columns;
        push(@{ $self->{'header_columns'} }, $col) if defined $self->{-display_columns}->{$col};
    }
}

sub _column_name {
    my ($self, $col) = @_;
    $col =~ s/.*[. ](\w+)$/$1/;
    return $col;
}

=item sortby_column_uri($column)

Returns URI for sorting the dataset by the given column.  If the dataset is currently
sorted by $column, then the URI returned will be for reversing the sort.

=cut

sub sortby_column_uri {
    my ($self, $column) = @_;
    if ($self->{'action_uri_jsfunc'}) {
        my $json = _json_sortby_params($self, $column, 1);
        $json .= ', '.$self->{'json_extra_vars'} if $self->{'json_extra_vars'};
        return $self->{'action_uri_jsfunc'}.'({ '.$json.' });';
    }
    return $self->BASE_URI . $self->{'action_uri'} . '?'
      . _query_string_sortby_params($self, $column, 1) . ($self->{'href_extra_vars'} || '');
}

sub _data_for_sortby_params {
    my ($self, $column, $for_sortlink) = @_;
    my $reverse = $self->{'sort_reverse'}->{$column};
    $reverse = ! $reverse if $for_sortlink;
    my $sortby = $self->{'sortby'} && $column eq $self->{'sortby'};
    return ($sortby, $reverse);
}

sub _query_string_sortby_params {
    my ($self, $column, $for_sortlink) = @_;
    my ($sortby, $reverse) = $self->_data_for_sortby_params($column, $for_sortlink);
    return 'sortby=' . $column . ($sortby ? '&sort_reverse='.($reverse ? '1':'0') : '');
}

sub _json_sortby_params {
    my ($self, $column, $for_sortlink) = @_;
    my ($sortby, $reverse) = $self->_data_for_sortby_params($column, $for_sortlink);
    return qq|'sortby': '$column'| . ($sortby ? q|, 'sort_reverse': |.($reverse ? '1':'0') : '');
}

=item next_page_exists()

Returns true if another page of search results exists after the current page.

=cut

sub next_page_exists {
    my ($self) = @_;
    my $maxpagesize = $self->{-max_results_per_page};
    my $searchtotal = $self->{'numresults'};
    return defined $maxpagesize
      && (defined $searchtotal ? ($self->{'page'}||0) != int(($searchtotal-1)/$maxpagesize)
            : scalar( @{$self->{'results'}} ) >= $maxpagesize);
}

=item prev_page_uri()

Returns URI of location to previous page in search results.

=cut

sub prev_page_uri {
    my ($self) = @_;
    $self->{'prevlink'} ||= make_nav_uri($self, $self->{'page'} - 1);
    return $self->{'prevlink'};
}

=item next_page_uri()

Returns URI of location to next page in search results.

=cut

sub next_page_uri {
    my ($self) = @_;
    $self->{'nextlink'} ||= make_nav_uri($self, $self->{'page'} + 1);
    return $self->{'nextlink'};
}

=item first_page_uri()

Returns URI of location to first page in search results.

=cut

sub first_page_uri {
    my ($self) = @_;
    $self->{'firstlink'} ||= make_nav_uri($self, 0);
    return $self->{'firstlink'};
}

=item last_page_uri()

Returns URI of location to last page in search results.

=cut

sub last_page_uri {
    my ($self) = @_;
    $self->{'lastlink'} ||= make_nav_uri($self, $self->{'lastpage'});
    return $self->{'lastlink'};
}

=item make_nav_uri( $page_no )

Generates and returns a URI for a given page number in the search result set.
Pages start at 0, with each page containing at most -max_results_per_page.

=cut

sub make_nav_uri {
    my ($self, $page_no) = @_;
    return make_nav_jsfunc_uri($self, $page_no) if $self->{'action_uri_jsfunc'};

    my $link = $self->BASE_URI.$self->{'action_uri'}.'?search_startat='.$page_no;
    if ($self->{-no_persistent_object} && $self->{'sortby'}) {
        $link .= '&'._query_string_sortby_params($self, $self->{'sortby'});
    }
    $link .= $self->{'href_extra_vars'} || '';
    return $link;
}

sub make_nav_jsfunc_uri {
    my ($self, $page_no) = @_;
    my $json = 'search_startat: '.$page_no;
    if ($self->{-no_persistent_object} && $self->{'sortby'}) {
        $json .= ', '._json_sortby_params($self, $self->{'sortby'});
    }
    $json .= ', '.$self->{'json_extra_vars'} if $self->{'json_extra_vars'};
    return 'javascript:'.$self->{'action_uri_jsfunc'}.'({ '.$json.' });';
}

=item display_pager_links($showtotal, $showpages, $hide_if_singlepage)

Returns an HTML table containing navigation links for first, previous, next,
and last pages of result set, and optionally, number and range of results being
displayed, and/or navigable list of pages in the dataset.

This method is called from display() and should be treated as a protected method.

parameters:
  $showtotal	boolean to toggle whether to show total number
                of results along with range on current page
  $showpages    boolean to toggle whether to show page range links
                for easier navigation in large datasets
                (has no effect unless -show_total_numresults setting is set)
  $hide_if_singlepage  boolean to toggle whether to display nothing
                       if there is only one page of search results

=cut

sub display_pager_links {
    my ($self, $showtotal, $showpages, $hide_if_singlepage) = @_;
    my $startat = $self->{'page'} || 0;
    my $pagetotal = scalar( @{$self->{'results'}} );
    my $maxpagesize = $self->{-max_results_per_page};
    my $searchtotal = $self->{'numresults'};
    my $middle_column = $showtotal || $showpages && $searchtotal;
    my $next_page_exists = $self->next_page_exists();
    my $onclick_js = $self->{-page_nav_link_onclick} ? ' onclick="'.$self->{-page_nav_link_onclick}.'"' : '';

    return '' if $hide_if_singlepage && $startat == 0 && !$next_page_exists;
    return '<table class="searchResultsNavBarTable '.($showpages ? 'bottom' : 'top').'" width="100%"><tr>'
      .'<td class="searchResultPagerLeftTd" align="left" nowrap="1" width="'.($middle_column ? '30%' : '50%').'">'
        .'<span class="searchResultPagerLinks">'
          .($startat > 0
              ? '<b>'.($self->first_page_uri() ? '<a class="firstPageLink" href="'.$self->first_page_uri().'"'.$onclick_js.'><span>|&lt; '.$self->translate('First').'</span></a>&nbsp;&nbsp;&nbsp;' : '')
                .'<a class="prevPageLink" href="'.$self->prev_page_uri().'"'.$onclick_js.'><span>&lt; '.$self->translate('Previous').'</span></a></b>'
              : '<span class="atFirstPageLabel"><span>'.$self->translate('At first page').'</span></span>')
        .'</span></td>'
      .($middle_column
          ? '<td class="searchResultPagerMiddleTd" align="center" nowrap="1" width="40%">'
            .($showtotal
                ? '<span class="numResultsDisplayedLabel"><b>'.$pagetotal.'</b> '.($pagetotal == 1 ? $self->translate('result') : $self->translate('results')).' '.$self->translate('displayed').': </span>'
                  .($searchtotal
                      ? '<span class="resultRangeDisplayed"><b>'.($startat*$maxpagesize + 1).' - '.($startat*$maxpagesize + $pagetotal).'</b> '.$self->translate('of').' <b>'.$searchtotal.'</b></span>'
                      : '').'<br/>'
                : '')
            .($showpages && $searchtotal
                ? '<span class="searchResultPagerLinks"><span class="skipToPageLabel"><span>'.$self->translate('Skip to page').': </span></span>'.$self->display_page_range_links($startat).'</span>'
                : '')
            .'</td>'
          : '')
      .'<td class="searchResultPagerRightTd" align="right" nowrap="1" width="'.($middle_column ? '30%' : '50%').'">'
        .'<span class="searchResultPagerLinks">'
          .($next_page_exists
              ? '<b><a class="nextPageLink" href="'.$self->next_page_uri().'"'.$onclick_js.'><span>'.$self->translate('Next').' &gt;</span></a>'
                .($self->last_page_uri() ? '&nbsp;&nbsp;&nbsp;<a class="lastPageLink" href="'.$self->last_page_uri().'"'.$onclick_js.'><span>'.$self->translate('Last').' &gt;|</span></a>' : '').'</b>'
              : '<span class="atLastPageLabel"><span>'.$self->translate('At last page').'</span></span>')
        .'</span></td>'
      .'</tr></table>';
}

=item display_record($row, $column)

Returns HTML rendering of a single record in the dataset, for column name $column.
The $row parameter is the entire row hash for the row being displayed.

=cut

sub display_record {
    my ($self, $row, $column) = @_;
    return ref $self->{-columndata_closures}->{$column} eq 'CODE' ? $self->{-columndata_closures}->{$column}->($self, $row)
      : $self->{-currency_columns}->{$column} ? sprintf('%.2f', $row->{$column})
      : $self->{-skip_utf8_decode} ? $row->{$column} || ''
      : $self->decode_utf8($row->{$column} || '');
}

=item display_page_range_links()

Returns a chunk of HTML which shows links to the surrounding pages in the search set.
The number of pages shown is determined by the -page_range_nav_limit setting.

=cut

sub display_page_range_links {
    my ($self, $startat) = @_;
    my @page_range;
    my ($pre, $post) = ('', '');
    if ($startat <= $self->{-page_range_nav_limit}
          && $startat + $self->{-page_range_nav_limit} >= $self->{'lastpage'}) {
        @page_range = 0 .. $self->{'lastpage'};
    } elsif ($startat <= $self->{-page_range_nav_limit}) {
        @page_range = 0 .. ($startat + $self->{-page_range_nav_limit});
        $post = ' ...';
    } elsif ($startat + $self->{-page_range_nav_limit} >= $self->{'lastpage'}) {
        @page_range = ($startat - $self->{-page_range_nav_limit}) .. $self->{'lastpage'};
        $pre = '... ';
    } else {
        @page_range = ($startat - $self->{-page_range_nav_limit}) .. ($startat + $self->{-page_range_nav_limit});
        $pre = '... ';
        $post = ' ...';
    }

    my $onclick_js = $self->{-page_nav_link_onclick} ? ' onclick="'.$self->{-page_nav_link_onclick}.'"' : '';
    return $pre.join(' ', map {
        $startat == $_ ? '<b>'.$_.'</b>' : '<a href="'.make_nav_uri($self, $_).'"'.$onclick_js.'>'.$_.'</a>'
    } @page_range).$post;
}


1;
__END__

=back

=head1 SEE ALSO

L<CGI::Widget::DBI::Search::Display::Grid>, L<CGI::Widget::DBI::Search::Display::Table>,

=cut
