package CGI::Widget::DBI::TEST::Search;

use strict;
use base qw/ CGI::Widget::DBI::TEST::TestCase /;

sub test_search__basic
{
    my $self = shift;
    my $ws = $self->{ws};

    $ws->{-sql_table} = 'widgets';
    $ws->{-sql_retrieve_columns} = [qw/widget_no name description size/];

    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small',   },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',  },
        { widget_no => 3, name => 'silly_widget',    description => "A goofball widget",     size => 'unknown', },
        { widget_no => 4, name => 'gps_widget',      description => "A GPS widget",          size => 'medium',  },
    ], $ws->{'results'});
    $self->assert_equals(4, $ws->{'numresults'});
}

sub test_search__with_a_join
{
    my $self = shift;
    my $ws = $self->{ws};

    $ws->{-sql_table} =
      'widgets w inner join widget_tools wt using (widget_no) inner join tools t using (tool_no)';
    $ws->{-sql_retrieve_columns} =
      [qw/w.widget_no w.name w.description w.size t.tool_no/, 't.name as tool_name', 't.type'];

    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 1, name => 'clock_widget', description => "A time keeper widget", size => 'small',
          tool_no => 2, tool_name => 'wrench', type => 'hand', },
        { widget_no => 1, name => 'clock_widget', description => "A time keeper widget", size => 'small',
          tool_no => 1, tool_name => 'hammer', type => 'hand', },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',
          tool_no => 5, tool_name => 'emacs', type => 'software', },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',
          tool_no => 6, tool_name => 'apache', type => 'software', },
        { widget_no => 3, name => 'silly_widget', description => "A goofball widget", size => 'unknown',
          tool_no => 4, tool_name => 'rm', type => 'unix', },
    ], $ws->{'results'});
    $self->assert_equals(5, $ws->{'numresults'});
}

sub test_search__with_a_filter
{
    my $self = shift;
    my $ws = $self->{ws};

    $ws->{-sql_table} = 'widgets';
    $ws->{-sql_retrieve_columns} = [qw/widget_no name description size/];

    $ws->{-where_clause} = 'name LIKE ?';
    $ws->{-bind_params} = ['c%']; # name begins with 'c'

    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small',  },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium', },
    ], $ws->{'results'});
    $self->assert_equals(2, $ws->{'numresults'});

    # try a different filter
    delete $ws->{'results'}; # need to clear old results or it will just return cached copy
    delete $ws->{'numresults'}; # need to clear old numresults, too or it will just return cached copy
    $ws->{-where_clause} = 'name LIKE ? AND size = ?';
    $ws->{-bind_params} = ['c%', 'medium']; # name begins with 'c' and size is medium

    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium', },
    ], $ws->{'results'});
    $self->assert_equals(1, $ws->{'numresults'});
}

sub test_search__with_join_for_dataset_and_filter
{
    my $self = shift;
    my $ws = $self->{ws};

    my $setup = sub {
        my $ws = shift;
        $ws->{-sql_table} = 'widgets';
        $ws->{-sql_search_columns} = [qw/widget_no/, 'COALESCE(description, name) AS my_description'];
        $ws->{-sql_join_for_dataset} = 'inner join widgets w using (widget_no)';
        $ws->{-sql_retrieve_columns} = [qw/w.widget_no w.name w.description w.size/];

        $ws->{-where_clause} = 'size != ?';
        $ws->{-bind_params} = ['unknown'];

        $ws->{-max_results_per_page} = 2;
    };
    $setup->($ws);

    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small'  },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium' },
    ], $ws->{'results'});
    $self->assert_equals(3, $ws->{'numresults'});
    # TODO: what happens with an -sql_join_for_dataset that increases the row count?? test this

    # reset search
    $self->init_test_object();
    $ws = $self->{ws};
    $setup->($ws);

    $ws->{q}->param('search_startat', 1); # next page
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 4, name => 'gps_widget', description => "A GPS widget", size => 'medium' },
    ], $ws->{'results'});
    $self->assert_equals(3, $ws->{'numresults'});
}

sub _setup_test_search__paging
{
    my $self = shift;
    my $ws = $self->{ws};
    $ws->{-sql_table} =
      'widgets w inner join widget_tools wt using (widget_no) inner join tools t using (tool_no)';
    $ws->{-sql_retrieve_columns} =
      [qw/w.widget_no w.name w.description w.size t.tool_no/, 't.name as tool_name', 't.type'];
    $ws->{-max_results_per_page} = 2;
}

sub test_search__paging
{
    my $self = shift;
    my $ws = $self->{ws};

    $self->_setup_test_search__paging();
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 1, name => 'clock_widget', description => "A time keeper widget", size => 'small',
          tool_no => 2, tool_name => 'wrench', type => 'hand', },
        { widget_no => 1, name => 'clock_widget', description => "A time keeper widget", size => 'small',
          tool_no => 1, tool_name => 'hammer', type => 'hand', },
    ], $ws->{'results'});
    $self->assert_equals(5, $ws->{'numresults'});

    # reset search
    $self->init_test_object();
    $self->_setup_test_search__paging();
    $ws = $self->{ws};

    $ws->{q}->param('search_startat', 1);
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',
          tool_no => 5, tool_name => 'emacs', type => 'software', },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',
          tool_no => 6, tool_name => 'apache', type => 'software', },
    ], $ws->{'results'});
    $self->assert_equals(5, $ws->{'numresults'});

    # reset search without re-initializing object (test for running in persistent object environments)
    delete $ws->{'results'};

    $ws->{q}->param('search_startat', 2);
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 3, name => 'silly_widget', description => "A goofball widget", size => 'unknown',
          tool_no => 4, tool_name => 'rm', type => 'unix', },
    ], $ws->{'results'});
    $self->assert_equals(5, $ws->{'numresults'});
    $self->assert_does_not_match(qr/sql_calc_found_rows sql_calc_found_rows/i, $ws->{'_sql'});
}

sub _setup_test_search__sorting
{
    my $self = shift;
    my $ws = $self->{ws};

    $ws->{-sql_table} = 'widgets';
    $ws->{-sql_retrieve_columns} = [qw/widget_no name description size/];
}

sub test_search__sorting
{
    my $self = shift;
    my $ws = $self->{ws};

    $self->_setup_test_search__sorting();
    $ws->{q}->param('sortby', 'description');
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',  },
        { widget_no => 3, name => 'silly_widget',    description => "A goofball widget",     size => 'unknown', },
        { widget_no => 4, name => 'gps_widget',      description => "A GPS widget",          size => 'medium',  },
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small',   },
    ], $ws->{'results'});
    $self->assert_equals(4, $ws->{'numresults'});

    # reset search
    $self->init_test_object();
    $self->_setup_test_search__sorting();
    $ws->{q}->param('sortby', 'description');
    $ws = $self->{ws};

    $ws->{q}->param('sortby', 'widget_no');
    $ws->{q}->param('sort_reverse', 1);
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 4, name => 'gps_widget',      description => "A GPS widget",          size => 'medium',  },
        { widget_no => 3, name => 'silly_widget',    description => "A goofball widget",     size => 'unknown', },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',  },
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small',   },
    ], $ws->{'results'});
    $self->assert_equals(4, $ws->{'numresults'});
}

sub test_search__paging_and_sorting_together
{
    my $self = shift;
    my $ws = $self->{ws};

    $self->_setup_test_search__paging();
    $ws->{q}->param('sortby', 'tool_name');
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',
          tool_no => 6, tool_name => 'apache', type => 'software', },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',
          tool_no => 5, tool_name => 'emacs', type => 'software', },
    ], $ws->{'results'});
    $self->assert_equals(5, $ws->{'numresults'});

    # reset search
    $self->init_test_object();
    $self->_setup_test_search__paging();
    $ws = $self->{ws};

    $ws->{q}->param('sortby', 'tool_name');
    $ws->{q}->param('search_startat', 1);
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 1, name => 'clock_widget', description => "A time keeper widget", size => 'small',
          tool_no => 1, tool_name => 'hammer', type => 'hand', },
        { widget_no => 3, name => 'silly_widget', description => "A goofball widget", size => 'unknown',
          tool_no => 4, tool_name => 'rm', type => 'unix', },
    ], $ws->{'results'});
    $self->assert_equals(5, $ws->{'numresults'});

    # reset search without re-initializing object (test for running in persistent object environments)
    delete $ws->{'results'};

    $ws->{q}->param('sortby', 'tool_name');
    $ws->{q}->param('search_startat', 2);
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 1, name => 'clock_widget', description => "A time keeper widget", size => 'small',
          tool_no => 2, tool_name => 'wrench', type => 'hand', },
    ], $ws->{'results'});
    $self->assert_equals(5, $ws->{'numresults'});
    $self->assert_does_not_match(qr/sql_calc_found_rows sql_calc_found_rows/i, $ws->{'_sql'});
}

sub _setup_test_search__default_orderby_and_sorting
{
    my $self = shift;
    my $ws = $self->{ws};

    $ws->{-sql_table} = 'widgets';
    $ws->{-sql_retrieve_columns} = [qw/widget_no name description size/];
    $ws->{-default_orderby_columns} = [qw/name widget_no/];
}

sub test_search__default_orderby_and_sorting
{
    my $self = shift;
    my $ws = $self->{ws};

    $self->_setup_test_search__default_orderby_and_sorting();
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',  },
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small',   },
        { widget_no => 4, name => 'gps_widget',      description => "A GPS widget",          size => 'medium',  },
        { widget_no => 3, name => 'silly_widget',    description => "A goofball widget",     size => 'unknown', },
    ], $ws->{'results'});
    $self->assert_equals(4, $ws->{'numresults'});

    # reset search
    $self->init_test_object();
    $self->_setup_test_search__default_orderby_and_sorting();
    $ws = $self->{ws};

    $ws->{q}->param('sortby', 'widget_no');
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small',   },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',  },
        { widget_no => 3, name => 'silly_widget',    description => "A goofball widget",     size => 'unknown', },
        { widget_no => 4, name => 'gps_widget',      description => "A GPS widget",          size => 'medium',  },
    ], $ws->{'results'});
    $self->assert_equals(4, $ws->{'numresults'});

    # reset search
    $self->init_test_object();
    $self->_setup_test_search__default_orderby_and_sorting();
    $ws = $self->{ws};

    $ws->{q}->param('sortby', 'size');
    $ws->{q}->param('sort_reverse', 1);
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 3, name => 'silly_widget',    description => "A goofball widget",     size => 'unknown', },
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small',   },
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',  },
        { widget_no => 4, name => 'gps_widget',      description => "A GPS widget",          size => 'medium',  },
    ], $ws->{'results'});
    $self->assert_equals(4, $ws->{'numresults'});

    # reset search
    $self->init_test_object();
    $self->_setup_test_search__default_orderby_and_sorting();
    $ws = $self->{ws};

    $ws->{q}->param('sortby', 'size');
    $ws->{q}->param('sort_reverse', 0);
    $ws->search();

    $self->assert_deep_equals([
        { widget_no => 2, name => 'calendar_widget', description => "A date tracker widget", size => 'medium',  },
        { widget_no => 4, name => 'gps_widget',      description => "A GPS widget",          size => 'medium',  },
        { widget_no => 1, name => 'clock_widget',    description => "A time keeper widget",  size => 'small',   },
        { widget_no => 3, name => 'silly_widget',    description => "A goofball widget",     size => 'unknown', },
    ], $ws->{'results'});
    $self->assert_equals(4, $ws->{'numresults'});
}

sub test_display_results
{
    my $self = shift;
    my $ws = $self->{ws};
    $ws->{-display_columns} =
      { widget_no => 'ID', name => 'Name', description => 'Description', size => '' };
    $ws->{-sql_table} = 'widgets';
    $ws->{-sql_retrieve_columns} = [qw/widget_no name description size/];
    $ws->search();

    $self->assert_display_contains(
        [ 'ID', 'Name',            'Description'            ],
        [    1, 'clock_widget',    'A time keeper widget',  'small'   ],
        [    2, 'calendar_widget', 'A date tracker widget', 'medium'  ],
        [    3, 'silly_widget',    'A goofball widget',     'unknown' ],
    );

    # reset search, set default ordering, and hide 'size' column
    $self->init_test_object();
    $ws = $self->{ws};
    $ws->{-default_orderby_columns} = [qw/name widget_no/];
    $ws->{-display_columns} =
      { widget_no => 'ID', name => 'Name', description => 'Description', size => undef };
    $ws->{-sql_table} = 'widgets';
    $ws->{-sql_retrieve_columns} = [qw/widget_no name description size/];
    $ws->search();

    $self->assert_display_contains(
        [ 'ID', 'Name',            'Description'           ],
        [    2, 'calendar_widget', 'A date tracker widget' ],
        [    1, 'clock_widget',    'A time keeper widget'  ],
        [    3, 'silly_widget',    'A goofball widget'     ],
    );
    $self->assert_display_does_not_contain([ 'medium' ]);
    $self->assert_display_does_not_contain([ 'small' ]);
    $self->assert_display_does_not_contain([ 'unknown' ]);
}


1;
