package CGI::Widget::DBI::Search;

use strict;

use base qw/ CGI::Widget::DBI::Search::Base /;
use vars qw/ $VERSION /;
$CGI::Widget::DBI::Search::VERSION = '0.31';

use DBI;
use CGI::Widget::DBI::Search::Display::Table;
use CGI::Widget::DBI::Search::Display::Grid;

# --------------------- USER CUSTOMIZABLE VARIABLES ------------------------

# default values - these can be overridden by method parameters
use constant MAX_PER_PAGE => 20;
use constant PAGE_RANGE_NAV_LIMIT => 10;

use constant SQL_DATABASE       => '';

use constant DBI_CONNECT_HOST   => 'localhost';
#use constant DBI_CONNECT_DSN    => 'DBI:mysql:database='.SQL_DATABASE().';host='.DBI_CONNECT_HOST();
use constant DBI_CONNECT_DSN    => '';
use constant DBI_USER           => '';
use constant DBI_PASS           => '';

# --------------------- END USER CUSTOMIZABLE VARIABLES --------------------


# VARS_TO_KEEP and cleanup() method not called anywhere; commented out

# instance variables to keep across http requests
#  NOTE: closure variables should NOT be kept! Storable cannot handle CODE refs
# use constant VARS_TO_KEEP => {# vars beginning with '-' are object config vars, set by programmer
#     -sql_table            => 1, -sql_table_columns    => 1, -sql_retrieve_columns  => 1,
#     -pre_nondb_columns    => 1, -post_nondb_columns   => 1, -action_uri            => 1,
#     -display_columns      => 1, -unsortable_columns   => 1, -sortable_columns      => 1, -default_orderby_columns => 1,
#     -column_align         => 1, -numeric_columns      => 1, -currency_columns      => 1,
#     -optional_header      => 1, -optional_footer      => 1, -href_extra_vars       => 1, -href_extra_vars_qs      => 1,
#     -where_clause         => 1, -bind_params          => 1, -opt_precols_sql       => 1,
#     -max_results_per_page => 1, -page_range_nav_limit => 1, -show_total_numresults => 1,
#     -no_persistent_object => 1, -display_mode         => 1, -display_class         => 1,
#     -grid_columns         => 1, -browse_mode          => 1,
#     # vars not beginning with '-' are instance vars, set by methods in class
#     results     => 1, numresults       => 1, page => 1, lastpage => 1, sortby => 1,
#     page_sortby => 1, reverse_pagesort => 1,
# };

# sub cleanup { 
#     my ($self) = @_;
#     # delete instance variables not set to keep across http requests
#     while (my ($k, $v) = each %$self) {
# 	delete $self->{$k} unless VARS_TO_KEEP->{$k};
#     }
# }

=head1 NAME

CGI::Widget::DBI::Search - Database search widget

=head1 SYNOPSIS

  use CGI;
  use CGI::Widget::DBI::Search;

  my $q = CGI->new;
  my $ws = CGI::Widget::DBI::Search->new(q => $q);

  # database connection info
  $ws->{-dbi_connect_dsn} = 'DBI:Pg:dbname=my_pg_database;host=localhost';
  $ws->{-dbi_user} = 'pguser';
  $ws->{-dbi_pass} = 'pgpass';

  # what table to use in the SQL query FROM clause
  $ws->{-sql_table} = 'table1 t1 inner join table2 t2 using (key_col)';

  # optional WHERE clause
  $ws->{-where_clause} = 't1.filter = ? OR t2.filter != ?';
  # bind params needed for WHERE clause
  $ws->{-bind_params} = [ $filter, $inverse_filter ];

  # what columns to retrieve from query
  $ws->{-sql_retrieve_columns} =
    [ qw/t1.id t1.name t2.long_description/, '(t1.price + t2.price) AS total_price'];
  # what columns to display in search results (with header name)
  $ws->{-display_columns} =
    { id => "ID", name => "Name", long_description => "Description", total_price => "Price" };

  $ws->{-numeric_columns} = { id => 1 };
  $ws->{-currency_columns} = { total_price => 1 };
  $ws->{-column_align} = { name => 'center' };

  #$ws->{-show_total_numresults} = 1; # set by default

  # execute database search
  $ws->search();

  # output search results to browser
  print $q->header;
  print $q->start_html;

  # show search results as HTML
  print $ws->display_results();

  print $q->end_html;

=head1 DESCRIPTION

Encapsulates a DBI search in a Perl class, including all SQL statements
required for performing the search, query results, HTML display methods,
and multi-column, sortable result set displayed page-by-page
(using HTML navigation links).

=head1 CONSTRUCTOR

=over 4

=item new(@config_options)

Creates and initializes a new CGI::Widget::DBI::Search object.
Possible configuration options:

=item Database connection options

  -dbi_connect_dsn      => DBI data source name (full connection string)
  -dbi_user             => database username
  -dbi_pass             => database password
  -dbi_host             => host to connect to database (overridden by -dbi_connect_dsn)
  -sql_database         => database to connect to (overridden by -dbi_connect_dsn)

=item Database retrieval options

  -sql_table            => Database table(s) to query,
  -sql_table_columns    => [ARRAY] List of all columns in sql_table,
  -sql_retrieve_columns => [ARRAY] List of columns for retrieval,
  -sql_search_columns   => [ARRAY] (optional) List of columns to retrieve in
                           initial search, results to be saved to a temporary table.
                           (has no effect without -sql_join_for_dataset)
  -sql_join_for_dataset => (optional) SQL join clause which will be appended -
                           in the FROM clause - to the temporary table generated
                           with columns from -sql_search_columns.
                           (has no effect without -sql_search_columns)
  -opt_precols_sql      => Optional SQL code to insert between 'SELECT' and
                           columns to retrieve (-sql_retrieve_columns).
                           This is commonly something like 'DISTINCT',
  -where_clause         => Literal SQL WHERE clause to use in SELECT state-
                           ment sent to database (may contain placeholders),
  -default_orderby_columns => [ARRAY] Default list of columns to use in ORDER BY
                           clause.  If 'sortby' cgi param is passed (e.g. from
                           user clicking a column sort link), it will always be
                           the first column in the ORDER BY clause, with these
                           coming after it.
  -bind_params          => [ARRAY] If -where_clause used placeholders ("?"),
                           this must be the ordered values to use for them,
  -fetchrow_closure     => (CODE) A code ref to execute upon retrieving a
                           single row of data from database.  First arg to
                           closure will be calling object; subsequent args
                           will be the values of the retrieved row of data.
                           The closure's return value will be push()d onto the
                           object's results array, which is unique to a search.
                           It should be a hash reference with a key for each
                           column returned in the search, and values with the
                           search field values.
  -dry_run              => Do a dry run: just build SQL without actually running
                           it and building 'results' array.  SQL statement that
                           would have been executed is in '_sql' object variable


=item Search result display options

The following settings affect display of search results, but also affect
the search logic (SQL query executed).

  -max_results_per_page   => Maximum number of database records to display on a
                             single page of search result display table
                             (default: 20)
  -show_total_numresults  => Show total number of records found by most recent
                             search, with First/Last page navigation links
                             (default: true)

The following settings only affect display of search results, not the search logic.

  -display_columns        => {HASH} Associative array holding column names as
                             keys, and labels for display table as values,
  -column_titles          => {HASH} Associative array holding column names as keys, and titles
                             (anchor titles, a.k.a mouseovers) for display table as values;
                             has effect only when using -display_mode => 'table
  -column_align           => {HASH} Keyed on column name to specify the table cell
                             html align attribute when using -display_mode => 'table'
  -numeric_columns        => {HASH} Columns of numeric type should have a
                             true value in this hash,
  -currency_columns       => {HASH} Columns of monetary value should have a
                             true value in this hash,
  -unsortable_columns     => {HASH} Columns which the user should not be able
                             to sort by should have a true value in this hash,
  -sortable_columns       => {HASH} Columns which the user should only be able
                             to sort by should have a true value in this hash,
  -pre_nondb_columns      => [ARRAY] Columns to show left of database columns
                             in display table,
  -post_nondb_columns     => [ARRAY] Columns to show right of database columns
                             in display table,
     (Note: Since no data from the database will be present for
      -{pre,post}_nondb_columns columns, you should define
      -columndata_closures for each column you list)

  -optional_header        => Optional HTML header to display just above search
                             result display table,
  -optional_footer        => Optional HTML footer to display just below search
                             result display table,
  -href_extra_vars        => {HASH} Extra CGI params to append to column sorting and
                             navigation links in search result display table.
                             If a key in the HASHREF has an undef value, will take the
                             value from an existing CGI param on request named the
                             same as key.
  -href_extra_vars_qs     => Extra CGI params (in query string form) to append to column sorting.
  -form_extra_vars        => {HASH} Extra CGI params to include in HTML as hidden
                             input fields.  Note that the search widget itself doesn't
                             generate an HTML form, so if the search output is not
                             wrapped in an HTML form, these hidden inputs will be ignored
                             by browsers.  The HASHREF has the same syntax as -href_extra_vars,
                             including the meaning of keys with undef values.
  -action_uri             => HTTP URI of script this is running under
                             (default: SCRIPT_NAME environment variable),
  -action_uri_js_function => Optional javascript function call as action URI syntax. If this
                             is set, it overrides -action_uri and all navigation and sort links
                             become function calls to this function, with a single argument which
                             contains a JSON hash with all active search params.  Note also, when
                             this is set, params -href_extra_vars will be converted to JSON
                             key/values and passed in the function call argument, but
                             -href_extra_vars_qs and -form_extra_vars will be ignored.
  -page_range_nav_limit   => Maximum number of pages to allow user to navigate to
                             before and after the current page in the result set
                             (default: 10)
  -page_nav_link_onclick  => Optional javascript code to call as onclick event when user clicks a
                             page navigation link (e.g. First, Prev, Next, Last, or page number)
  -columndata_closures    => {HASH} of (CODE): Reference to a hash containing a
                             code reference for each column which should be
                             passed through before displaying in result table.
                             Each closure will be passed 3 arguments:
                              $searchdispobj (the -display_class object),
                              $row (the current row from the result set)
                              $color (the current background color of this row)
                             and is (currently) expected to return an HTML table
                             cell (e.g. "<td>blah</td>")
  -skip_utf8_decode       => Boolean to control whether a utf8 decode is done on raw
                             (non- columndata_closure, non-numeric) data before displaying.
                             By default a utf8 decode is done in case there are utf8 chars
                             present, but if you know there will be no utf8 chars, enabling
                             this will increase performance.  Has no effect when
                             -columndata_closures in effect for column.
                             (default: 0)

  -display_mode           => ('table'|'grid') Which of the default display modes
                             to use, table or grid.
                             (default: table)
  -display_class          => Actual class to use to display search results.
                             (default: CGI::Widget::DBI::Search::Display::Table)
  -grid_columns           => Maximum number of columns to render, if displaying
                             as grid
  -browse_mode            => If true, hides sorting and paging options from search
                             result display.  Used by CGI::Widget::DBI::Browse.

=item Universal options

  -no_persistent_object   => Inform object that we are not running under a
                             persistent object framework (eg. Apache::Session):
                             disable all features which enhance performance
                             under a persistence framework, and enable features
                             necessary for smooth operation without persistence
                             (default: true)

=item CSS / Skinning options

Note: these should really be named -html_... instead of -css_..., but leaving as-is for legacy code.

  -css_grid_id           => (default: searchWidgetGridId)
  -css_grid_class        => (default: searchWidgetGridTable)
  -css_grid_cell_class   => (default: searchWidgetGridCell)

  -css_table_id                => (default: searchWidgetTableId)
  -css_table_class             => (default: searchWidgetTableTable)
  -css_table_row_class         => (default: searchWidgetTableRow)
  -css_table_header_row_class  => (default: searchWidgetTableHeaderRow)
  -css_table_cell_class        => (default: searchWidgetTableCell)
  -css_table_header_cell_class => (default: searchWidgetTableHeaderCell)
  -css_table_unsortable_header_cell_class => (default: searchWidgetTableUnsortableHeaderCell)

  -extra_grid_cell_attributes  => {HASH} Static attributes to add to the grid table cell (<TD> element),
                            -OR-  (CODE) Dynamic attributes to add to the grid table cell (<TD> element); the
                                         anonymous sub takes two arguments: the display object and the results row
  -extra_table_cell_attributes        => {HASH} -OR- (CODE) Same as above except for table display_mode instead of grid
  -extra_table_header_cell_attributes => {HASH} -OR- (CODE) Same as above except for table display_mode instead of grid

These can be configured for non-English apps (i18n):

  -i18n_translation_strings => {HASH} English-to-other-language hash used for user-visible words;
                               current strings displayed: Previous, Next, First, Last, At first page, At last page,
                               Skip to page, result, results, of, displayed, Sort by, Sort field,
                               (and if using Browse widget): Top, all results, Show all items in this category

=back

=head1 PRIVATE METHODS

=over 4

=item _set_defaults()

Sets necessary object variables from defaults in package constants, if not already set.
Called from search() method.

=cut

sub _set_defaults {
    my ($self) = @_;

    $self->{-dbi_connect_dsn} ||= DBI_CONNECT_DSN();
    # default to mysql dsn if no other was specified
    $self->{-dbi_connect_dsn} ||=
      'DBI:mysql:database='.($self->{-sql_database}||'').';host='.($self->{-dbi_host}||'');
    $self->{-dbi_user} ||= DBI_USER();
    $self->{-dbi_pass} ||= DBI_PASS();

    $self->{-show_total_numresults} = 1
      unless defined $self->{-show_total_numresults};
    $self->{-no_persistent_object} = 1
      unless defined $self->{-no_persistent_object};
}

sub _find_sql_column_in_sql_columns {
    my ($self, $alias_or_sql_column, $columns) = @_;
    return (grep(
        $_ eq $alias_or_sql_column || m/(?:as\s+|\.)$alias_or_sql_column\Z/i,
        @$columns,
    ))[0];
}

sub _find_sql_column_in_sql_select_columns {
    my ($self, $alias_or_sql_column) = @_;
    return _find_sql_column_in_sql_columns($self, $alias_or_sql_column, [$self->_columns_for_sql()]);
}

sub _find_sql_column_in_sql_retrieve_columns {
    my ($self, $alias_or_sql_column) = @_;
    return _find_sql_column_in_sql_columns($self, $alias_or_sql_column, $self->{-sql_retrieve_columns});
}

sub _find_sql_column_in_sql_search_columns {
    my ($self, $alias_or_sql_column) = @_;
    return _find_sql_column_in_sql_columns($self, $alias_or_sql_column, $self->{-sql_search_columns});
}

sub _check_call_syntax {
    my ($self) = @_;
    # method call syntax checks
    unless ($self->{-sql_table}
            && ref $self->{-sql_retrieve_columns} eq 'ARRAY'
            && (ref $self->{-dbh} && $self->{-dbh}->isa('DBI::db')
                || $self->{-dbi_connect_dsn}
                  && defined $self->{-dbi_user}
                  && defined $self->{-dbi_pass})) {
        $self->log_error(q|instance variables '-sql_table' (SCALAR), '-sql_retrieve_columns' (ARRAY); '-dbh' or '-dbi_connect_dsn' and '-dbi_user' and '-dbi_pass' (SCALARs) are required|);
        return undef;
    }
    return 1;
}

sub _connect_to_db {
    my ($self) = @_;
    return 2 if ref $self->{-dbh} && $self->{-dbh}->isa('DBI::db');
    eval {
        $self->{-dbh} = DBI->connect($self->{-dbi_connect_dsn}, $self->{-dbi_user},
                                     $self->{-dbi_pass}, {'RaiseError' => 1});
    };
    if ($@) {
        $self->log_error($@);
        return undef;
    }
    return 1;
}

=back

=head1 METHODS

=over 4

=item search([ $where_clause, $bind_params, $clobber ])

Perform the search: runs the database query, and stores the matched results in an
object variable: 'results'.

Optional parameters $where_clause and $bind_params will override object
variables -where_clause and -bind_params.  If $clobber is true, search results
from a previous execution will be deleted before running new search.

After this method executes, various internal object variables will be set, to
indicate the state of the search.  Here are some useful ones:

(if -show_total_numresults is true)
  page        => current page in result set (0 indexed)
  lastpage    => last page in result set (0 indexed)

=cut

sub search {
    my ($self, $where_clause, $bind_params, $clobber) = @_;
    my $q = $self->{q};

    $self->_set_defaults();
    return undef unless $self->_check_call_syntax();

    # clobber old search results if desired
    if ($clobber) {
        delete $self->{-where_clause};
        delete $self->{-bind_params};
        delete $self->{'results'};
    }

    # handle paging logic
    my $old_page = $self->{'page'};
    $self->{'page'} = $q->param('search_startat')
      if defined $q->param('search_startat');
    $self->{'page'} ||= 0;

    # return cached results if page has not changed
    if (defined $old_page && $self->{'page'} == $old_page && ref $self->{'results'} eq 'ARRAY') {
        $self->warn('no page change, using cached results');
        return $self;
    }

    # read sortby column from cgi
    $self->{'sortby'} = $q->param('sortby') if $q->param('sortby');
    $self->{'sort_reverse'} ||= {};
    $self->{'sort_reverse'}->{ $self->{'sortby'} } = $q->param('sort_reverse')
      if defined $q->param('sort_reverse');

    $self->{-where_clause} = $where_clause if $where_clause;
    $self->{-where_clause} =~ s/^\s*where//i if $self->{-where_clause};
    $self->{-bind_params} = $bind_params if ref $bind_params eq 'ARRAY';
    $self->{-max_results_per_page} ||= MAX_PER_PAGE;
    $self->{-page_range_nav_limit} ||= PAGE_RANGE_NAV_LIMIT;
    $self->{-limit_clause} =
      ('LIMIT '.($self->{-max_results_per_page}*$self->{'page'}).','.
       $self->{-max_results_per_page});
    $self->{-opt_precols_sql} ||= '';
    my $orig_opt_precols_sql = $self->{-opt_precols_sql};
    $self->{-opt_precols_sql} .= ' SQL_CALC_FOUND_ROWS '
      if $self->{-show_total_numresults} && $self->{-opt_precols_sql} !~ m/SQL_CALC_FOUND_ROWS/i;

    my @orderby;
    if (ref $self->{-default_orderby_columns} eq 'ARRAY') {
        @orderby = @{ $self->{-default_orderby_columns} };
    }
    if ($self->{'sortby'}) {
        if (_find_sql_column_in_sql_select_columns($self, $self->{'sortby'})) {
            @orderby = ($self->{'sortby'}, grep($_ ne $self->{'sortby'}, @orderby));
        }
    }
    $self->{-orderby_clause} =
      'ORDER BY '.join(',', map {$_.($self->{'sort_reverse'}->{$_} ? ' DESC' : '')} @orderby)
        if @orderby;
    # TODO: we should support a custom -orderby_clause and not just clobber it each time


    $self->_build_sql();
    return $self if $self->{-dry_run};

    my $conn_code = $self->_connect_to_db();
    return undef if ! $conn_code;

    my $should_disconnect = $conn_code == 1;

    if ($self->{-sql_search_columns} && $self->{-sql_join_for_dataset}) {
        eval {
            # tmp_search_results may already exist even in production code, due to use of Apache::DBI
            $self->{-dbh}->do('DROP TABLE IF EXISTS tmp_search_results');
            my @search_sql = (<<"SQL1",<<'SQL2',<<"SQL3");
CREATE TEMPORARY TABLE tmp_search_results AS
@{[ $self->{'_sql_no_limit'} ]} LIMIT 0
SQL1
ALTER TABLE tmp_search_results ADD row_index INT AUTO_INCREMENT PRIMARY KEY FIRST
SQL2
INSERT INTO tmp_search_results (
  @{[ join(',', map { $self->extract_alias_from_sql_column($_) } @{ $self->{-sql_search_columns} }) ]}
)
@{[ $self->{'_sql'} ]}
SQL3
            my @bind_params = @{ $self->{-bind_params} || [] };
            $self->warn('SQL search statement: '.join(";\n", @search_sql)
                          ."\nbind params: ".join(', ', @bind_params));
            $self->{-dbh}->do(shift @search_sql, undef, @bind_params);
            $self->{-dbh}->do(shift @search_sql);
            $self->{-dbh}->do(shift @search_sql, undef, @bind_params);
            $self->get_num_results();
        };
        if ($@) {
            $self->log_error($@);
            return undef;
        }
        $self->{-sql_search_columns} = undef;
        $self->{-sql_table} = 'tmp_search_results '.$self->{-sql_join_for_dataset};
        $self->{-where_clause} = undef;
        $self->{-bind_params} = undef;
        $self->{-orderby_clause} = 'ORDER BY row_index';
        $self->{-opt_precols_sql} = $orig_opt_precols_sql;
        $self->{-limit_clause} = undef;
        $self->_build_sql();
    }

    eval {
        my $sth = $self->{-dbh}->prepare_cached( $self->{'_sql'} );

        my @bind_params = @{ $self->{-bind_params} || [] };
        $self->warn("SQL statement: $self->{'_sql'}; bind params: ".join(', ', @bind_params));
        $sth->execute(@bind_params);

        $self->{'results'} = [];
        if (ref $self->{-fetchrow_closure} eq 'CODE') {
            my @row_data;
            $sth->bind_columns
              (map { \$row_data[$_] } 0..$#{$self->{-sql_retrieve_columns}});

            while ($sth->fetchrow_arrayref) {
                push(@{$self->{'results'}}, $self->{-fetchrow_closure}->($self, @row_data));
            }
        } else {
            $self->{'results'} = $sth->fetchall_arrayref({});
        }

        $sth->finish();

        $self->get_num_results();

        $self->{-dbh}->disconnect() if $should_disconnect;
    };
    if ($@) {
        $self->log_error("SQL statement: $self->{'_sql'}; bind params: ".join(', ', @{ $self->{-bind_params} || [] }));
        $self->log_error($@);
        return undef;
    }

    #$self->pagesort_results($self->{'page_sortby'}) if $self->{'page_sortby'};
    return $self;
}

sub _build_sql {
    my ($self) = @_;
    $self->{'_sql_no_limit'} = (
        'SELECT '.$self->{-opt_precols_sql}.' '.join(',', $self->_columns_for_sql()).
        ' FROM '.$self->{-sql_table}.' '.
        ($self->{-where_clause} ? 'WHERE '.$self->{-where_clause} : '').' '.
        ($self->{-orderby_clause}||'')
    );
    $self->{'_sql'} = $self->{'_sql_no_limit'}.' '.($self->{-limit_clause}||'');
}

sub _columns_for_sql {
    my ($self) = @_;
    return $self->{-sql_search_columns} && $self->{-sql_join_for_dataset}
      ? @{ $self->{-sql_search_columns} } : @{ $self->{-sql_retrieve_columns} };
}

=item get_num_results()

Executes a SELECT COUNT() query with the current search parameters and stores result
in object variable: 'numresults'.  Has no effect unless -show_total_numresults object
variable is true.  As a side-effect, this method also sets the 'lastpage' object
variable which, no surprise, is the page number denoting the last page in the search
result set.

This is used for displaying total number of results found, and is
necessary to provide a last-page link to skip to the end of the search results.

=cut

sub get_num_results {
    my ($self) = @_;
    return if ! $self->{-show_total_numresults} || defined $self->{'numresults'};

    # read total number of results in search set (mysql only)
    $self->{'numresults'} = @{ $self->{-dbh}->selectrow_arrayref('SELECT FOUND_ROWS()') || [] }[0];
    $self->{'lastpage'} = int(($self->{'numresults'} - 1) / $self->{-max_results_per_page});
    return $self->{'numresults'};
}

=item pagesort_results($col, $reverse)

Sorts a single page of results by column $col.  Reorders object variable 'results'
based on sort column $col and boolean $reverse parameters.

(note: method currently unused)

=cut

# sub pagesort_results {
#     my ($self, $col, $reverse) = @_;

#     # handle sorting by arbitrary data column
#     if ($self->{'page_sortby'} and $reverse) {
# 	# toggle reverse flag if they clicked the current sort column
# 	$self->{'reverse_pagesort'}->{$self->{'page_sortby'}} =
# 	  $self->{'reverse_pagesort'}->{$self->{'page_sortby'}} ? 0 : 1;
# 	@{$self->{'results'}} = reverse @{$self->{'results'}};
#     } else {
# 	# set new page_sortby column, and sort results array
# 	$self->{'page_sortby'} = $col;
# 	@{$self->{'results'}} = sort {
# 	    ($self->{-numeric_columns}->{$self->{'page_sortby'}} ||
# 	     $self->{-currency_columns}->{$self->{'page_sortby'}}
# 	     ? $a->{$self->{'page_sortby'}} <=> $b->{$self->{'page_sortby'}}
# 	     : uc($a->{$self->{'page_sortby'}}) cmp uc($b->{$self->{'page_sortby'}}))
# 	} @{$self->{'results'}};
# 	@{$self->{'results'}} = reverse @{$self->{'results'}}
# 	  if $self->{'reverse_pagesort'}->{$self->{'page_sortby'}};
#     }
# }

=item append_where_clause($where_sql, [ $op ])

Adds an SQL expression to the current -where_clause, if any.  Optional $op specifies the
SQL operator to attach the expression with (default: AND).

=item append_bind_params(@bind_params)

Appends extra bind params to the end of the current list of -bind_params.

=cut

sub append_where_clause {
    my ($self, $where_sql, $op) = @_;
    return if ! $where_sql;
    $op ||= 'AND';
    $self->{-where_clause} = ($self->{-where_clause} ? '( '.$self->{-where_clause}.' ) '.$op.' ' : '') . '( '.$where_sql.' )';
}

sub append_bind_params {
    my ($self, @bind_params) = @_;
    return if ! @bind_params;
    $self->{-bind_params} ||= [];
    push(@{ $self->{-bind_params} }, @bind_params);
}


=item init_display_class([ $disp_cols ])

Instantiates and initializes the desired display object.  Returns it and sets in 'display' object variable.
This is called by display_results(), and does not normally need to be called directly.

=item display_results([ $disp_cols ])

Displays an HTML table of data values stored in object variable 'results' (retrieved
from the most recent call to search() method).  Optional variable $disp_cols overrides
object variable -display_columns.

=cut

sub init_display_class {
    my ($self, $disp_cols) = @_;
    unless (ref $self->{'results'} eq 'ARRAY' &&
	    (ref $self->{-sql_table_columns} eq 'ARRAY' ||
	     ref $self->{-sql_retrieve_columns} eq 'ARRAY')) {
	$self->log_error(q|instance variables '-sql_table_columns' or '-sql_retrieve_columns', and data resultset 'results' (ARRAYs) are required|);
	return undef;
    }

    $self->{-display_columns} = $disp_cols if ref $disp_cols eq 'HASH';
    $self->{-display_class} ||= ($self->{-display_mode}||'') eq 'grid'
      ? 'CGI::Widget::DBI::Search::Display::Grid'
      : 'CGI::Widget::DBI::Search::Display::Table';

    $self->{display} = $self->{-display_class}->new($self);
    $self->transfer_display_settings();
    return $self->{display};
}

sub display_results {
    my ($self, $disp_cols) = @_;
    return undef if ! $self->init_display_class($disp_cols);
    return $self->{display}->display();
}

=item translate($string)

Translation method: just looks up $string in -i18n_translation_strings hash, and if a hit is found returns it;
otherwise returns $string.

=item transfer_display_settings()

Transfers all display-specific settings from search widget object to the
search display widget object.

=cut

sub transfer_display_settings {
    my ($self) = @_;
    foreach my $var (
        qw/results
           numresults
           page
           lastpage
           sortby
           sort_reverse
          /) {
        $self->{display}->{$var} = $self->{$var} if defined $self->{$var};
    }
    foreach my $var (keys %$self) {
        $self->{display}->{$var} = $self->{$var} if substr($var, 0, 1) eq '-';
    }
}

sub sql_search_column_for_alias {
    my ($self, $alias_or_sql_column) = @_;
    my $sql_col = _find_sql_column_in_sql_search_columns($self, $alias_or_sql_column);
    ($sql_col) = ( $sql_col =~ m/\A(.+)\s+as\s+$alias_or_sql_column\Z/i )
      if $sql_col && $sql_col =~ m/as\s+$alias_or_sql_column\Z/i;
    return $sql_col || $alias_or_sql_column;
}

sub sql_column_for_alias {
    my ($self, $alias_or_sql_column) = @_;
    my $sql_col = _find_sql_column_in_sql_retrieve_columns($self, $alias_or_sql_column);
    ($sql_col) = ( $sql_col =~ m/\A(.+)\s+as\s+$alias_or_sql_column\Z/i )
      if $sql_col && $sql_col =~ m/as\s+$alias_or_sql_column\Z/i;
    return $sql_col || $alias_or_sql_column;
}

sub sql_column_with_tbl_alias_for_alias {
    my ($self, $alias_or_sql_column) = @_;
    my $sql_col = _find_sql_column_in_sql_retrieve_columns($self, $alias_or_sql_column);
    $sql_col =~ s/\s+as\s+$alias_or_sql_column\Z//i if $sql_col;
    return $sql_col || $alias_or_sql_column;
}

sub full_sql_column_for_alias {
    my ($self, $alias_or_sql_column) = @_;
    my $sql_col = _find_sql_column_in_sql_retrieve_columns($self, $alias_or_sql_column);
    return $sql_col || $alias_or_sql_column;
}

sub sql_column_for_full_sql_column_with_alias {
    my ($self, $full_sql_column) = @_;
    my $sql_col = _find_sql_column_in_sql_retrieve_columns($self, $full_sql_column);
    ($sql_col) = ( $sql_col =~ m/\A(.+)\s+as\s+.+\Z/i ) if $sql_col;
    return $sql_col || $full_sql_column;
}

sub extract_alias_from_sql_column {
    my ($self, $full_sql_column) = @_;
    my ($alias) = ( $full_sql_column =~ m/\s+as\s+(.+)\Z/i );
    return $alias || $full_sql_column;
}


1;
__END__

=back

=head1 SEE ALSO

L<CGI::Widget::DBI::Search::Display::Grid>, L<CGI::Widget::DBI::Search::Display::Table>,
L<CGI::Widget::DBI::Search::AbstractDisplay>

=head1 BUGS

Columns listed in -sql_retrieve_columns may not contain newline characters (\n).
You can alias complex SQL functions though, which is exactly where you'd want to
use a newline for readability.

=head1 AUTHOR

Adi Fairbank <adi@adiraj.org>

=head1 COPYRIGHT

Copyright (C) 2004-2014  Adi Fairbank

=head1 COPYLEFT (LICENSE)

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=head1 LAST MODIFIED

Dec 7, 2014

=cut
