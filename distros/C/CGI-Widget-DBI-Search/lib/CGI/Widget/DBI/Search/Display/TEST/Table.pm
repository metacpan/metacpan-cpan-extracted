package CGI::Widget::DBI::Search::Display::TEST::Table;

use strict;
use base qw/ CGI::Widget::DBI::TEST::Search /;


sub test_display_results {}

sub test_search__basic
{
    my $self = shift;
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'At first page', 'At last page' ],
        [ map {("sortby=$_", $_)} qw/widget_no name description size/ ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'At first page', 'At last page' ],
    );
}

sub test_search__display_only_subset_of_columns
{
    my $self = shift;
    $self->{ws}->{-display_columns} = { map {$_ => $_} qw/widget_no name size/ };
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'At first page', 'At last page' ],
        [ map {("sortby=$_", $_)} qw/widget_no name size/ ],
        [ 1, 'clock_widget', 'small' ],
        [ 2, 'calendar_widget', 'medium' ],
        [ 3, 'silly_widget', 'unknown' ],
        [ 4, 'gps_widget', 'medium' ],
        [ 'At first page', 'At last page' ],
    );
    $self->assert_display_does_not_contain( [ 'description' ] );
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
        [ 'At first page', 'At last page' ],
        [ 'my_header1', (map {("sortby=$_", $_)} qw/widget_no name description size/), qw/my_header2 my_header3/ ],
        [ 'Widget #1', 1, 'clock_widget', 'A time keeper widget', 'small', 'Widget Size: small', '">\*\*\*</', ],
        [ 'Widget #2', 2, 'calendar_widget', 'A date tracker widget', 'medium', 'Widget Size: medium', '">\*\*\*</', ],
        [ 'Widget #3', 3, 'silly_widget', 'A goofball widget', 'unknown', 'Widget Size: unknown', '">\*\*\*</', ],
        [ 'Widget #4', 4, 'gps_widget', 'A GPS widget', 'medium', 'Widget Size: medium', '">\*\*\*</', ],
        [ 'At first page', 'At last page' ],
    );
}

sub test_search__display_with_custom_column_align
{
    my $self = shift;
    $self->{ws}->{-column_align} = { widget_no => 'right', name => 'center' };
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'At first page', 'At last page' ],
        [ 'align="right', 'sortby=widget_no', 'widget_no' ],
        [ 'align="center', 'sortby=name', 'name' ],
        [ 'sortby=description', 'description' ],
        [ 'sortby=size', 'size' ],

        [ 'align="right', 1, 'align="center', 'clock_widget',    'align="left', 'A time keeper widget',  'align="left', 'small'   ],
        [ 'align="right', 2, 'align="center', 'calendar_widget', 'align="left', 'A date tracker widget', 'align="left', 'medium'  ],
        [ 'align="right', 3, 'align="center', 'silly_widget',    'align="left', 'A goofball widget',     'align="left', 'unknown' ],
        [ 'align="right', 4, 'align="center', 'gps_widget',      'align="left', 'A GPS widget',          'align="left', 'medium'  ],

        [ 'At first page', 'At last page' ],
    );

}

sub test_search__with_a_join
{
    my $self = shift;
    $self->SUPER::test_search__with_a_join;

    $self->assert_display_contains(
        [ 'At first page', 'At last page' ],
        [ map {("sortby=$_", $_)} qw/widget_no name description size tool_no tool_name type/ ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small', 2, 'wrench', 'hand' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small', 1, 'hammer', 'hand' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium', 5, 'emacs', 'software' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium', 6, 'apache', 'software' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown', 4, 'rm', 'unix' ],
        [ 'At first page', 'At last page' ],
    );
}

sub test_search__with_a_filter
{
    my $self = shift;
    $self->SUPER::test_search__with_a_filter;

    # only displays most recent filter
    $self->assert_display_contains(
        [ 'At first page', 'At last page' ],
        [ map {("sortby=$_", $_)} qw/widget_no name description size/ ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'At first page', 'At last page' ],
    );
}

sub test_search__paging
{
    my $self = shift;
    $self->SUPER::test_search__paging;

    # only displays most recent page of search
    $self->assert_display_contains(
        [ 'search_startat=0','First', 'search_startat=1', 'Previous',
          '1', 'result displayed', '5 - 5', 'of', '5', 'At last page' ],
        [ map {("sortby=$_", $_)} qw/widget_no name description size tool_no tool_name type/ ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown', 4, 'rm', 'unix' ],
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
        [ 'At first page', 'At last page' ],
        [ "sortby=widget_no&sort_reverse=0", "widget_no", (map {("sortby=$_", $_)} qw/name description size/) ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'At first page', 'At last page' ],
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
        [ 'At first page', 'At last page' ],
        [ "sortby=widget_no&href_testvar=foo", "widget_no", (map {("sortby=$_", $_)} qw/name description size/) ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'At first page', 'At last page' ],
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
        [ 'At first page', 'At last page' ],
        [ map { ("\QmyCustomFunc({ 'sortby': '$_', 'href_testvar': 'foo' });\E.*", $_) } qw/widget_no name description size/ ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'At first page', 'At last page' ],
    );
}

sub test_search__paging_and_sorting_together
{
    my $self = shift;
    $self->SUPER::test_search__paging_and_sorting_together;

    # only displays most recent page of search
    $self->assert_display_contains(
        [ 'search_startat=0', 'sortby=tool_name', 'sort_reverse=0','First',
          'search_startat=1', 'sortby=tool_name', 'sort_reverse=0', 'Previous',
          '1', 'result displayed', '5 - 5', 'of', '5', 'At last page' ],
        [ (map {("sortby=$_", $_)} qw/widget_no name description size tool_no/),
          'sortby=tool_name', 'sort_reverse=1', 'tool_name' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small', 2, 'wrench', 'hand' ],
        [ 'search_startat=0', 'sortby=tool_name', 'sort_reverse=0', 'First',
          'search_startat=1', 'sortby=tool_name', 'sort_reverse=0', 'Previous',
          'Skip to page', '0', '1', '2',  'At last page' ],
    );

    # reset search
    $self->init_test_object();
    $self->_setup_test_search__paging();

    $self->{ws}->{q}->param('sortby', 'tool_name');
    $self->{ws}->{q}->param('search_startat', 1);
    $self->{ws}->search();

    $self->assert_display_contains(
        [ 'search_startat=0', 'sortby=tool_name', 'sort_reverse=0', 'First',
          'search_startat=0', 'sortby=tool_name', 'sort_reverse=0', 'Previous',
          '2', 'results displayed', '3 - 4', 'of', '5',
          'search_startat=2', 'sortby=tool_name', 'sort_reverse=0', 'Next',
          'search_startat=2', 'sortby=tool_name', 'sort_reverse=0', 'Last',
        ],
        [ (map {("sortby=$_", $_)} qw/widget_no name description size tool_no/),
          'sortby=tool_name', 'sort_reverse=1', 'tool_name' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small', 1, 'hammer', 'hand' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown', 4, 'rm', 'unix' ],
        [ 'search_startat=0', 'sortby=tool_name', 'sort_reverse=0', 'First',
          'search_startat=0', 'sortby=tool_name', 'sort_reverse=0', 'Previous',
          'Skip to page', '0', '1', '2',
          'search_startat=2', 'sortby=tool_name', 'sort_reverse=0', 'Next',
          'search_startat=2', 'sortby=tool_name', 'sort_reverse=0', 'Last',
         ],
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
        [ "sortby=widget_no&sort_reverse=1", "widget_no", (map {("sortby=$_", $_)} qw/name description/) ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
    );
    $self->assert_display_does_not_contain([ 'sortby=size' ]);

    # reset and search again
    $self->init_test_object();
    $self->_setup_test_search__sorting();
    $ws = $self->{ws};
    $ws->{q}->param('sortby', 'widget_no');
    $ws->{q}->param('sort_reverse', 1);

    $ws->{-sortable_columns} = {widget_no => 1, name => 1};
    $ws->search();

    $self->assert_display_contains(
        [ "sortby=widget_no&sort_reverse=0", "widget_no", "sortby=name" ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
    );
    $self->assert_display_does_not_contain([ 'sortby=description' ]);
    $self->assert_display_does_not_contain([ 'sortby=size' ]);
}

sub test_search__default_orderby_and_sorting
{
    my $self = shift;
    $self->SUPER::test_search__default_orderby_and_sorting;

    # only displays most recent sorting
    $self->assert_display_contains(
        [ 'At first page', 'At last page' ],
        [ (map {("sortby=$_", $_)} qw/widget_no name description/), "sortby=size&sort_reverse=1", "size" ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'At first page', 'At last page' ],
    );
}

sub test_search__css_options
{
    my $self = shift;
    $self->{ws}->{-css_table_class} = 'TestTableClass';
    $self->{ws}->{-css_table_row_class} = 'TestTableRowClass';
    $self->{ws}->{-css_table_header_row_class} = 'TestTableHeaderRowClass';
    $self->{ws}->{-css_table_cell_class} = 'TestTableCellClass';
    $self->{ws}->{-css_table_header_cell_class} = 'TestTableHeaderCellClass';

    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'At first page', 'At last page' ],
        [ 'table [^<>]*class="TestTableClass' ],
        [ 'thead', 'tr [^<>]*class="TestTableHeaderRowClass', 'th [^<>]*class="TestTableHeaderCellClass' ],
        [ map {("sortby=$_", $_)} qw/widget_no name description size/ ],
        [ 'th', 'tr', 'thead' ],
        [ 'tbody', 'tr [^<>]*class="TestTableRowClass', 'td [^<>]*class="TestTableCellClass' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'td', 'tr', 'tr [^<>]*class="TestTableRowClass', 'td [^<>]*class="TestTableCellClass' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr [^<>]*class="TestTableRowClass', 'td [^<>]*class="TestTableCellClass' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td', 'tr', 'tr [^<>]*class="TestTableRowClass', 'td [^<>]*class="TestTableCellClass' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr', 'tbody', 'table' ],
        [ 'At first page', 'At last page' ],
    );
}

sub test_search__extra_attributes
{
    my $self = shift;
    $self->{ws}->{-extra_table_cell_attributes} = { test_attr1 => 'foo', test_attr2 => 'bar' };
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'table' ],
        [ map {("sortby=$_", $_)} qw/widget_no name description size/ ],
        [ 'tr', 'td [^<>]*test-attr2="bar" [^<>]*test-attr1="foo' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*test-attr2="bar" [^<>]*test-attr1="foo' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*test-attr2="bar" [^<>]*test-attr1="foo' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*test-attr2="bar" [^<>]*test-attr1="foo' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}

sub test_search__extra_attributes_closure
{
    my $self = shift;
    $self->{ws}->{-extra_table_cell_attributes} = sub {
        my ($obj, $row) = @_;
        my $col1 = $obj->{'header_columns'}->[0];
        my $col2 = $obj->{'header_columns'}->[1];
        return { "attr_$col1" => $row->{$col1}, "attr_$col2" => $row->{$col2} };
    };
    $self->SUPER::test_search__basic;

    $self->assert_display_contains(
        [ 'table' ],
        [ map {("sortby=$_", $_)} qw/widget_no name description size/ ],
        [ 'tr', 'td [^<>]*attr-widget-no="1" [^<>]*attr-name="clock_widget' ],
        [ 1, 'clock_widget', 'A time keeper widget', 'small' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*attr-widget-no="2" [^<>]*attr-name="calendar_widget' ],
        [ 2, 'calendar_widget', 'A date tracker widget', 'medium' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*attr-widget-no="3" [^<>]*attr-name="silly_widget' ],
        [ 3, 'silly_widget', 'A goofball widget', 'unknown' ],
        [ 'td', 'tr', 'tr', 'td [^<>]*attr-widget-no="4" [^<>]*attr-name="gps_widget' ],
        [ 4, 'gps_widget', 'A GPS widget', 'medium' ],
        [ 'td', 'tr' ],
    );
}


1;
