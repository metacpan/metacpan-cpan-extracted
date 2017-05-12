package CGI::Widget::DBI::Search::Display::TEST::Grid;

use strict;
use base qw/ CGI::Widget::DBI::TEST::Search /;


sub init_test_object
{
    my $self = shift;
    $self->SUPER::init_test_object();
    $self->{ws}->{-display_mode} = 'grid';
    $self->{ws}->{-grid_columns} = 2;
}

sub test_display_results {}

sub test_search__basic
{
    my $self = shift;
    # TODO: move these superclass calls into set_up method
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__display_only_subset_of_columns
{
    my $self = shift;
    $self->{ws}->{-display_columns} = { map {$_ => $_} qw/widget_no name size/ };
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 1, 'clock_widget', 'small' ],
        [ 2, 'calendar_widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 3, 'silly_widget', 'unknown' ],
        [ 4, 'gps_widget', 'medium' ],
        [ 'td', 'tr' ],
    );
    $self->assert_display_does_not_contain( [ 'A time keeper widget', ] );
    $self->assert_display_does_not_contain( [ 'A date tracker widget', ] );
    $self->assert_display_does_not_contain( [ 'A goofball widget', ] );
}

sub test_search__display_nondb_columns_and_columndata_closures
{
    my $self = shift;
    $self->{ws}->{-pre_nondb_columns} = [qw/my_header1/];
    $self->{ws}->{-post_nondb_columns} = [qw/my_header2 my_header3/];
    $self->{ws}->{-columndata_closures} = {
        my_header1 => sub { my ($self, $row) = @_; return "Widget #".$row->{widget_no}; },
        my_header2 => sub { my ($self, $row) = @_; return "Widget Size: ".$row->{size}; },
        my_header3 => sub { return "***"; },
    };
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 'Widget #1', 1, 'clock_widget', 'A time keeper widget', 'small', 'Widget Size: small', 'my_header3: \*\*\*</', ],
        [ 'Widget #2', 2, 'calendar_widget', 'A date tracker widget', 'medium', 'Widget Size: medium', 'my_header3: \*\*\*</', ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 'Widget #3', 3, 'silly_widget', 'A goofball widget', 'unknown', 'Widget Size: unknown', 'my_header3: \*\*\*</', ],
        [ 'td', 'tr' ],
    );
}

sub test_search__with_a_join
{
    my $self = shift;
    $self->SUPER::test_search__with_a_join;

    $self->assert_display_contains(
        [ 'div', 'align', 'right', 'Sort by', 'sortby_columns_popup', 'Sort field',
          'sortby=widget_no', 'widget_no', 'sortby=name', 'name',
          'sortby=description', 'description', 'sortby=size', 'size',
          'sortby=tool_no', 'tool_no', 'sortby=tool_name', 'tool_name',
          'sortby=type', 'type', ],
        [ 'tr', 'td' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small', 2, 'wrench', 'hand' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small', 1, 'hammer', 'hand' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium', 5, 'emacs', 'software' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium', 6, 'apache', 'software' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown', 4, 'rm', 'unix' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__with_a_filter
{
    my $self = shift;
    $self->SUPER::test_search__with_a_filter;

    # only displays most recent filter
    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__paging
{
    my $self = shift;
    $self->SUPER::test_search__paging;

    # only displays most recent page of search
    $self->assert_display_contains(
        [ 'search_startat=0', 'First', 'search_startat=1', 'Previous',
          '1', 'result displayed', '5 - 5', 'of', '5', 'At last page' ],
        [ 'tr', 'td' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown', 4, 'rm', 'unix' ],
        [ 'td', 'tr' ],
        [ 'search_startat=0', 'First', 'search_startat=1', 'Previous',
          'Skip to page', '0', '1', '2',  'At last page' ],
    );
}

sub test_search__sorting
{
    my $self = shift;
    $self->SUPER::test_search__sorting;

    # only displays most recent sorting
    $self->assert_display_contains(
        [ 'div', 'align', 'right', 'Sort by', 'sortby_columns_popup',
          'sortby=widget_no', 'widget_no', 'sortby=name', 'name',
          'sortby=description', 'description', 'sortby=size', 'size' ],
        [ 'tr', 'td' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__sorting__supports_href_and_form_extra_vars
{
    my $self = shift;
    my $ws = $self->{ws};

    $self->_setup_test_search__sorting();
    $ws->{q}->param('href_testvar', 'foo');
    $ws->{q}->param('form_hiddenvar', 'bar');
    $ws->{-href_extra_vars} = { href_testvar => undef };
    $ws->{-form_extra_vars} = { form_hiddenvar => undef };
    $ws->search();

    # only displays most recent sorting
    $self->assert_display_contains(
        [ 'input type="hidden" name="form_hiddenvar" value="bar' ],
        [ 'div', 'align', 'right', 'Sort by', 'sortby_columns_popup',
          'sortby=widget_no&amp;href_testvar=foo', 'widget_no', 'sortby=name&amp;href_testvar=foo', 'name',
          'sortby=description&amp;href_testvar=foo', 'description', 'sortby=size&amp;href_testvar=foo', 'size' ],
        [ 'tr', 'td' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__sorting_in_action_uri_js_function_mode__supports_href_and_form_extra_vars
{
    my $self = shift;
    my $ws = $self->{ws};

    $self->_setup_test_search__sorting();
    $ws->{q}->param('href_testvar', 'foo');
    $ws->{q}->param('form_hiddenvar', 'bar');
    $ws->{-href_extra_vars} = { href_testvar => undef };
    $ws->{-form_extra_vars} = { form_hiddenvar => undef };
    $ws->{-action_uri_js_function} = 'myCustomFunc';
    $ws->search();

    # only displays most recent sorting
    $self->assert_display_contains(
        [ 'input type="hidden" name="form_hiddenvar" value="bar' ],
        [ 'div', 'align', 'right', 'Sort by', 'sortby_columns_popup', ],
        [ map { ("\QmyCustomFunc({ &#39;sortby&#39;: &#39;$_&#39;, &#39;href_testvar&#39;: &#39;foo&#39\E", $_) } qw/widget_no name description size/ ],
        [ 'tr', 'td' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__only_allows_sorting_by_specified_columns
{
    my $self = shift;
    my $ws = $self->{ws};

    $self->_setup_test_search__sorting();
    $ws->{q}->param('sortby', 'widget_no');

    $ws->{-unsortable_columns} = {size => 1};
    $ws->search();

    $self->assert_display_contains(
        [ 'div', 'align', 'right', 'Sort by', 'sortby_columns_popup',
          'sortby=widget_no', 'widget_no', 'sortby=name', 'name',
          'sortby=description', 'description' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
    $self->assert_display_does_not_contain([ 'sortby=size', 'size' ]);

    # reset and search again
    $self->init_test_object();
    $self->_setup_test_search__sorting();
    $ws = $self->{ws};
    $ws->{q}->param('sortby', 'widget_no');
    $ws->{q}->param('sort_reverse', 1);

    $ws->{-sortable_columns} = {widget_no => 1, name => 1};
    $ws->search();

    $self->assert_display_contains(
        [ 'div', 'align', 'right', 'Sort by', 'sortby_columns_popup',
          'sortby=widget_no', 'widget_no', 'sortby=name', 'name' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'td', 'tr' ],
    );
    $self->assert_display_does_not_contain([ 'sortby=description', 'description' ]);
    $self->assert_display_does_not_contain([ 'sortby=size', 'size' ]);
}

sub test_search__default_orderby_and_sorting
{
    my $self = shift;
    $self->SUPER::test_search__default_orderby_and_sorting;

    # only displays most recent sorting
    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__css_options
{
    my $self = shift;
    $self->{ws}->{-css_grid_class} = 'TestGridClass';
    $self->{ws}->{-css_grid_cell_class} = 'TestGridCellClass';
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'table [^<>]*class="TestGridClass' ],
        [ 'tr', 'td [^<>]*class="TestGridCellClass' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'td [^<>]*class="TestGridCellClass' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*class="TestGridCellClass' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td [^<>]*class="TestGridCellClass' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__extra_attributes
{
    my $self = shift;
    $self->{ws}->{-extra_grid_cell_attributes} = { test_attr1 => 'foo', test_attr2 => 'bar' };
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'table' ],
        [ 'tr', 'td [^<>]*test-attr2="bar" [^<>]*test-attr1="foo".*' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'td [^<>]*test-attr2="bar" [^<>]*test-attr1="foo".*' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*test-attr2="bar" [^<>]*test-attr1="foo".*' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td [^<>]*test-attr2="bar" [^<>]*test-attr1="foo".*' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__extra_attributes_closure
{
    my $self = shift;
    $self->{ws}->{-extra_grid_cell_attributes} = sub {
        my ($obj, $row) = @_;
        my $col1 = $obj->{'header_columns'}->[0];
        my $col2 = $obj->{'header_columns'}->[1];
        return { "attr_$col1" => $row->{$col1}, "attr_$col2" => $row->{$col2} };
    };
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'table' ],
        [ 'tr', 'td [^<>]*attr-widget-no="1" [^<>]*attr-name="clock_widget".*' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'td [^<>]*attr-widget-no="2" [^<>]*attr-name="calendar_widget".*' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*attr-widget-no="3" [^<>]*attr-name="silly_widget".*' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td [^<>]*attr-widget-no="4" [^<>]*attr-name="gps_widget".*' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}

sub test_browse_mode
{
    my $self = shift;
    $self->{ws}->{-browse_mode} = 1;
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'tr', 'td' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td', 'tr' ],
    );
    $self->assert_display_does_not_contain([ 'At first page', 'At last page' ]);
    $self->assert_display_does_not_contain([ 'Sort by', 'sortby_columns_popup' ]);
    $self->assert_display_does_not_contain([ 'Sort field' ]);
    $self->assert_display_does_not_contain([ 'sortby=widget_no', 'widget_no' ]);
    $self->assert_display_does_not_contain([ 'sortby=name', 'name', ]);
}

sub test_browse_mode_with_paging
{
    my $self = shift;
    my $ws = $self->{ws};
    $ws->{-browse_mode} = 1;
    $ws->{-max_results_per_page} = 2;
    $ws->{-sql_table} = 'widgets';
    $ws->{-sql_retrieve_columns} = [qw/widget_no name description size/];

    $ws->search();

    $self->assert_display_contains(
        [ 'At first page', '2', 'results displayed', '1 - 2', 'of', '4', 'Next &gt', 'Last &gt' ],
        [ 'tr', 'td' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr' ],
        [ 'At first page', 'Next &gt', 'Last &gt' ],
    );
    $self->assert_display_does_not_contain([ 'Sort by', 'sortby_columns_popup' ]);
    $self->assert_display_does_not_contain([ 'Sort field' ]);
    $self->assert_display_does_not_contain([ 'sortby=widget_no', 'widget_no' ]);
    $self->assert_display_does_not_contain([ 'sortby=name', 'name', ]);


    # reset search
    $self->init_test_object();
    $ws = $self->{ws};
    $ws->{-browse_mode} = 1;
    $ws->{-max_results_per_page} = 2;
    $ws->{-sql_table} = 'widgets';
    $ws->{-sql_retrieve_columns} = [qw/widget_no name description size/];

    $ws->{q}->param('search_startat', 1);
    $ws->search();

    $self->assert_display_contains(
        [ 'lt; First', 'lt; Previous', '2', 'results displayed', '3 - 4', 'of', '4', 'At last page' ],
        [ 'tr', 'td' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
        [ 'lt; First', 'lt; Previous', 'At last page' ],
    );
}


1;
