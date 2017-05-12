package CGI::Widget::DBI::Browse;

use strict;

use base qw/ CGI::Widget::DBI::Search::Base /;
use vars qw/ $VERSION /;
$CGI::Widget::DBI::Browse::VERSION = '0.17';

use DBI;
use CGI::Widget::DBI::Search 0.31;
use URI::Escape qw/uri_escape uri_escape_utf8/;
use Scalar::Util qw/blessed/;

#use constant DEFAULT_CACHE_EXPIRATION => '30 days'; # SQL interval format

=head1 NAME

CGI::Widget::DBI::Browse - Database browsing widget

=head1 SYNOPSIS

  use CGI;
  use CGI::Widget::DBI::Browse;

  my $q = CGI->new;
  my $wb = CGI::Widget::DBI::Browse->new(
    q => $q,
    # database connection info
    -dbi_connect_dsn => 'DBI:Pg:dbname=my_pg_database;host=localhost',
    -dbi_user => 'pguser',
    -dbi_pass => 'pgpass',
    # database schema info
    -sql_table => 'table1 t1 inner join table2 t2 using (key_col)',
    -sql_retrieve_columns => [ qw/t1.name t1.description t2.extra_information/ ],
  );
  # or if you already have a search widget, you can use the settings from it
  # my $wb = CGI::Widget::DBI::Browse->new(ws => $search_widget_obj);

  # list of category columns (how to represent data as a tree)
  $wb->{-category_columns} = [ qw/main_category sub_category1 sub_category2/ ];

  # output to browser
  print $q->header;
  print $q->start_html;

  # show current page in tree
  #  (default is a list of distinct values in the first category_column)
  print $wb->display_results();

  print $q->end_html;


=head1 DESCRIPTION

Implements user-interface for browsing a database table or joined tables.
Just provide a list of hierarchical categories for your data, and it allows
the user to walk down the category tree to find the database records they
want.

Specifically, this module simply makes successive calls to the search widget
module (L<CGI::Widget::DBI::Search>) filtering results by the category of
records the user is currently viewing (node in a tree representation of
your data).

=head1 CONSTRUCTOR

=over 4

=item new(@config_options)

Creates and initializes a new CGI::Widget::DBI::Browse object.

=head2 Possible configuration options:

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

  ... Also accepts all the options that CGI::Widget::DBI::Search does;
      they are simply passed through ...

=item Schema description configuration

  -category_columns     => [ARRAY] List of columns to be used as "categories,"
                           or internal nodes, allowing hierarchical navigation of
                           a tree-based representation of your data
  -category_sql_retrieve_columns
                        => {HASH} Extra columns to be retrieved for a given category
                           column.  Keys should be a subset of -category_columns, and
                           values should be an arrayref containing the extra columns
                           (or column aliases) to retrieve for that category column.
                           Typically used in conjunction with -category_column_closures.
  -category_column_closures
                        => {HASH} of (CODE): Reference to a hash containing a code
                           reference for each category column which should be passed 
                           through before displaying.  Similar to the -columndata_closures
                           option of CGI::Widget::DBI::Search.

=item Search result display options

  -max_category_results_per_page
                        => Maximum number of database records to display
                           on a page while navigating by category (default: 100)
  -skip_to_results      => If true, skips directly to display of database records
                           while in category browsing mode
  -auto_skip_to_results => If set, skips directly to results if in category browsing mode
                           but there are no category members at the current level, or if
                           there is exactly one category member with value '' (empty string).
                           Note: this will have no effect if the search widget ('ws' object)
                           is not set to -show_total_numresults.
  -post_auto_skip_callback
                        => (CODE): If set along with -auto_skip_to_results, and auto-skip
                           mode is in effect, this callback routine will be called before
                           the actual search and displaying results are executed.  Useful
                           when behavior of the widget is dependent on whether we are
                           browsing or not. (i.e. the return value of is_browsing())

=item Performance options

  -cache_categories     => Turn on automatic caching of categories.  Creates a table
                           called browse_widget_category_cache which stores records
                           for each internal node in the browse tree.
                           BEWARE: currently there is no cache expiration mechanism;
                           also, the the cache table is a hard-coded name, so be careful
                           if you use more than one browse widget in the same database.

=back

=cut

sub initialize {
    my ($self) = @_;
    if (blessed($self->{ws}) && $self->{ws}->isa('CGI::Widget::DBI::Search')) {
        $self->{q} = $self->{ws}->{q};
    } else {
        $self->{ws} = CGI::Widget::DBI::Search->new($self);
        # search results shown in grid format by default, when using browse widget
        $self->{ws}->{-display_mode} ||= 'grid';
    }
}

sub _break_circular_references {
    my ($self) = @_;
    delete $self->{old_ws}->{display}->{b};
    delete $self->{ws}->{display}->{b};
}

=head1 METHODS

=over 4

=item is_browsing()

Returns true if the widget is in browse mode, viewing navigable categories (branch nodes)
rather than viewing actual results (leaf nodes).  Returns the actual category column name
currently browsing on.

=item parent_category_column()

Returns the previous category column in -category_columns relative to the node currently
being viewed.  If we are at the top-level category (root node in the browse tree), then
this method returns undef.

=item ancestor_category_columns()

Returns a list of all previous category columns in -category_columns relative to the
current node.  If we are the root node, an empty list is returned.

=item display_results()

Displays results from CGI::Widget::DBI::Search (in grid display mode) of data values
specified by -category_columns and current state of query object in object variable 'q'.

=cut

sub is_browsing {
    my ($self) = @_;
    $self->_set_category_index() if ! defined $self->{_category_idx};
    return $self->{-category_columns}->[ $self->{_category_idx} ] if $self->_is_browsing();
    return undef;
}

sub _is_browsing {
    my ($self) = @_;
    return defined($self->{_category_idx}) && ! $self->{-skip_to_results} && ! $self->{q}->param('_browse_skip_to_results_');
}

sub parent_category_column {
    my ($self) = @_;
    $self->_set_category_index() if ! defined $self->{_category_idx};
    return $self->{-category_columns}->[ -1 ] if ! $self->_is_browsing() && ! $self->{'auto_skip_in_effect'};
    return undef if $self->{_category_idx} == 0;
    return $self->{-category_columns}->[ $self->{_category_idx} - 1 ];
}

sub ancestor_category_columns {
    my ($self) = @_;
    $self->_set_category_index() if ! defined $self->{_category_idx};
    my $end_idx = $self->_is_browsing() || $self->{'auto_skip_in_effect'}
      ? $self->{_category_idx} - 1 : $#{ $self->{-category_columns} };
    return @{ $self->{-category_columns} }[0 .. $end_idx];
}

sub _set_category_index {
    my ($self) = @_;
    my $q = $self->{q};

    my @categories = @{ $self->{-category_columns} };
    foreach my $i (0 .. $#categories) {
        if (! $q->param($categories[$i])) {
            $self->{_category_idx} = $i;
            last;
        }
    }
}

sub configure_search_for_category_browse {
    my ($self) = @_;
    my $ws = $self->{ws};
    my $category_column = $self->is_browsing();

    # first, save search widget object in case we need it back, if -auto_skip_to_results is on
    $self->{old_ws} = $self->{ws}->new( $self->{ws} ) if $self->{-auto_skip_to_results};

    $ws->{-display_class} = undef; # need to clear in case it was manually set
    $ws->{-display_mode} = 'grid';

    # display a list of (sub)categories/branch nodes instead of items/leaf nodes
    $ws->{-opt_precols_sql} = 'DISTINCT';

    my @extra_category_retr_cols = map { $ws->full_sql_column_for_alias($_) }
      @{ $self->{-category_sql_retrieve_columns}->{$category_column} || [] };
    $ws->{-sql_search_columns} = undef;
    $ws->{-sql_retrieve_columns} = [
        $ws->full_sql_column_for_alias($category_column), @extra_category_retr_cols,
    ];
    $ws->{-where_clause} .= ($ws->{-where_clause} ? ' AND ' : '')
      . $ws->sql_column_with_tbl_alias_for_alias($category_column) . ' IS NOT NULL';
    $ws->{-display_columns} = {
        $category_column => $ws->{-display_columns}->{$category_column} || $category_column
    };
    $ws->{-columndata_closures} = {
        $category_column => _category_columndata_closure($self, $category_column)
    };
    $ws->{-default_orderby_columns} = [ $ws->sql_column_with_tbl_alias_for_alias($category_column) ];
    $ws->{-max_results_per_page} = $self->{-max_category_results_per_page} || 100;
    $ws->{-browse_mode} = 1;
}

=back

=head1 CACHING METHODS

=over 4

=item category_value_is_cached($category, $value)

Returns true if cache entries exist in the category cache table for the key/value
pair $category/$value.

=item cache_results_for_category_value($category, $value)

Executes a category search as normal, using CGI::Widget::DBI::Search in -dry_run
mode to just generate the SQL, and stores the results in category cache table.

=cut

sub _create_category_cache_table {
    my ($self) = @_;
    $self->{ws}->{-dbh}->do(<<'END_SQL');
CREATE TABLE IF NOT EXISTS browse_widget_category_cache (
  category_column    VARCHAR(32),
  category_value     VARCHAR(96),
  child_value        VARCHAR(96),
  last_modified      TIMESTAMP,
  UNIQUE INDEX unq_all (category_column, category_value, child_value),
  INDEX idx_category_value (category_column, category_value)
) ENGINE = MyISAM
END_SQL
}

sub _where_clause_for_category_value {
    my ($self, $category, $value) = @_;
    return 'category_column '.(defined $category ? '=?' : 'IS NULL')
      .' AND category_value '.(defined $value ? '=?' : 'IS NULL');
}

sub _bind_params_for_category_value {
    my ($self, $category, $value) = @_;
    return (defined $category ? $category : (), defined $value ? $value : ());
}

sub category_value_is_cached {
    my ($self, $category, $value) = @_;
    my $sth = $self->{ws}->{-dbh}->prepare_cached(
        'SELECT count(1) FROM browse_widget_category_cache WHERE '
          . $self->_where_clause_for_category_value($category, $value)
    );
    $sth->execute($self->_bind_params_for_category_value($category, $value));
    my $cnt = $sth->fetchrow_arrayref()->[0];
    $sth->finish();
    return $cnt;
}

sub cache_results_for_category_value {
    my ($self, $category, $value) = @_;
    my $ws = $self->{ws};
    my $category_column = $self->is_browsing();

    local $ws->{-dry_run} = 1;
    local $ws->{-show_total_numresults} = 0;

    $ws->search();

    my $sth = $ws->{-dbh}->prepare_cached(qq{
        INSERT INTO browse_widget_category_cache (category_column, category_value, child_value)
        SELECT DISTINCT ? AS category_column, ? AS category_value, search.$category_column AS child_value
        FROM ( @{[ $ws->{'_sql'} ]} ) search
    });
    $sth->execute($category, $value, @{ $ws->{-bind_params} });
    $sth->finish();
}

=back

=head1 DISPLAY METHODS

=over 4

=item display_results()

Main rendering method of the database browse.  Typically this is the only method that actually *needs*
to be called from the delegating class, after configuration, since this calls all other methods as necessary.

=item display_cached_category_results()

Displays a node in the browse tree, identically to how display_results() would, only by using the cache table.
Specifically, it configures the search widget by directly injecting data retrieved from the cache table
and calling the search widget's display_results() method, skipping the call to its search() method.
Also, if there is no cache entry for the current node in the browse tree, this calls cache_results_for_category_value()
first to cache the results.

Note: this method is called automatically by display_results() if -cache_categories is true.

=item add_breadcrumbs_to_header()

Appends breadcrumb navigation HTML to the -optional_header of the enclosed search widget object
based on the current state of the browse widget.  Also sets the 'category_title' object of this
browse widget object to a string representation of the current location in the browse tree.

Note: this method is called automatically by display_results().

=item link_for_category_column($category_col, $row)

Emits an href link to the requested $category_col in the browse tree for the category data from
$row.  This is typically used as a callback from a column's -columndata_closures rendering.  E.g.

  $wb->{ws}->{-columndata_closures}->{'state_or_province'} = sub {
      my ($obj, $row) = @_;
      return $obj->{b}->link_for_category_column('state_or_province', $row);
  };

For it to work as expected, all columns listed in -category_columns must also be in the select
results, i.e. present in -sql_retrieve_columns.

=cut

sub display_results {
    my ($self) = @_;
    my $q = $self->{q};
    my $ws = $self->{ws};

    die 'Required configuration setting -category_columns not set.'
      if ref $self->{-category_columns} ne 'ARRAY';

    # set category filter condition
    $self->{'filter_columns'} = [ grep($q->param($_), @{ $self->{-category_columns} }) ];
    if (@{ $self->{'filter_columns'} }) {
        $ws->{-where_clause} = ($ws->{-where_clause} ? '('.$ws->{-where_clause}.') AND ' : '').join(
            ' AND ', map {$_.' = ?'} map { $ws->sql_column_with_tbl_alias_for_alias($_) } @{ $self->{'filter_columns'} }
        );
        $ws->{-bind_params} = [ @{ $ws->{-bind_params} || [] }, map { $q->param($_) } @{ $self->{'filter_columns'} } ];

        map {
            $ws->{-href_extra_vars}->{$_} = undef;
            $ws->{-form_extra_vars}->{$_} = undef;
        } @{ $self->{'filter_columns'} };
    }

    my $category_column = $self->is_browsing();
    if ($category_column) {
        $self->configure_search_for_category_browse();
        return $self->display_cached_category_results() if $self->{-cache_categories};
    }

    $ws->{-href_extra_vars}->{'_browse_skip_to_results_'} = undef;
    $ws->{-form_extra_vars}->{'_browse_skip_to_results_'} = undef;

    $self->add_breadcrumbs_to_header();

    $self->build_results();

    my $html;
    eval {
        if ($self->{ws}->init_display_class()) {
            $self->{ws}->{display}->{b} = $self; # circular ref, must break with _break_circular_references()
            $html = $self->{ws}->{display}->display();
        }
    };
    $self->_break_circular_references(); # must always break ref to avoid memory leak, even if error occurred
    if ($@) { die $@; }
    return $html;
}

sub build_results {
    my ($self) = @_;
    $self->{ws}->search();
    $self->auto_skip_to_results();
}

sub auto_skip_to_results {
    my ($self) = @_;
    my $ws = $self->{ws};
    my $category_column = $self->is_browsing();

    if ($self->{-auto_skip_to_results} && $category_column && $ws->{-show_total_numresults} && $ws->{'numresults'} <= 1) {
        # skip to results if we are browsing but we reach a category which has just 0 or 1 members
        $self->{ws} = $self->{old_ws};
        $self->{-skip_to_results} = $self->{'auto_skip_in_effect'} = 1;
        $self->{'_added_breadcrumbs'} = 0;
        $self->add_breadcrumbs_to_header();
        $self->{-post_auto_skip_callback}->($self)
          if ref $self->{-post_auto_skip_callback} eq 'CODE';
        $self->{ws}->search();
    }
}

sub display_cached_category_results {
    my ($self) = @_;
    my $ws = $self->{ws};
    my $category_column = $self->is_browsing();

    $self->_create_category_cache_table();

    my $parent_category = $self->parent_category_column();
    my $parent_value = $self->decode_utf8($self->{q}->param($parent_category));

    if (! $self->category_value_is_cached($parent_category, $parent_value)) {
        $self->cache_results_for_category_value($parent_category, $parent_value);
    }

    my $sth = $ws->{-dbh}->prepare_cached(qq|
        SELECT child_value AS $category_column
        FROM browse_widget_category_cache
        WHERE @{[ $self->_where_clause_for_category_value($parent_category, $parent_value) ]}
        ORDER BY $category_column
    |);
    $sth->execute($self->_bind_params_for_category_value($parent_category, $parent_value));

    $ws->{'results'} = [];
    while (my $row = $sth->fetchrow_hashref()) {
        push(@{ $ws->{'results'} }, $row);
    }
    $sth->finish();

    # extra cost to using -cache_categories with -category_sql_retrieve_columns
    #  - presumably this extra query would be faster than not caching categories at all
    if (my $extra_cols = $self->{-category_sql_retrieve_columns}->{$category_column}) {
        $sth = $ws->{-dbh}->prepare_cached(qq|
            SELECT DISTINCT @{[ join ',', map { $ws->full_sql_column_for_alias($_) } ($category_column, @$extra_cols) ]}
            FROM @{[ $ws->{-sql_table} ]}
            WHERE @{[ $ws->full_sql_column_for_alias($category_column) ]}
              IN ( @{[ join ',', map {'?'} @{ $ws->{'results'} } ]} )
            ORDER BY $category_column
        |);
        $sth->execute(map { $_->{$category_column} } @{ $ws->{'results'} });
        my $i = 0;
        while (my $row = $sth->fetchrow_hashref()) {
            $ws->{'results'}->[$i] = { %{ $ws->{'results'}->[$i] || {} }, %$row };
            $i++;
        }
        $sth->finish();
    }

    $self->add_breadcrumbs_to_header();

    return $ws->display_results();
}

sub category_title { return shift->{'category_title'} || '' }

sub add_breadcrumbs_to_header {
    my ($self) = @_;
    return if $self->{'_added_breadcrumbs'};
    my $q = $self->{q};
    my $ws = $self->{ws};

    # add breadcrumbs in search header
    my @cume_category_filters;

    my $extra_vars = $ws->extra_vars_for_uri([
        @{ $self->{'filter_columns'} }, '_browse_skip_to_results_', @{ $self->{-exclude_vars_from_breadcrumbs}||[] },
    ]);
    $self->{'category_title'} = '';
    $self->{'breadcrumbs'} = ['Top'];
    $self->{'breadcrumb_links'} = [ '<a href="?'.$extra_vars.'" class="breadcrumbNavLink">'.$ws->translate('Top').'</a>' ];

    foreach (@{ $self->{'filter_columns'} }) {
        my $breadcrumb_name = $self->decode_utf8($q->param($_));
        $self->{'category_title'} = join(' > ', $self->{'category_title'} || (), $breadcrumb_name || ());
        push(@cume_category_filters, _uri_param_pair($_, $breadcrumb_name));
        push(@{ $self->{'breadcrumbs'} }, $breadcrumb_name);
        push(@{ $self->{'breadcrumb_links'} },
             '<a href="?'.join('&', @cume_category_filters, $extra_vars||()).'" class="breadcrumbNavLink">'.$breadcrumb_name.'</a>');
    }

    my $skip_to_results = '';
    if ($self->is_browsing() && ! $self->{-skip_to_results}) {
        $skip_to_results = '&nbsp;&nbsp;&nbsp;&nbsp;<i> &rarr; <a href="?'.join(
            '&', @cume_category_filters, '_browse_skip_to_results_=1', $extra_vars||(),
        ).'" id="skipToResultsLink"><span>'.$ws->translate('Show all items in this category').'</span></a></i>';
    } elsif ($q->param('_browse_skip_to_results_')) {
        $self->{'category_title'} .= ' ('.$ws->translate('all results').')';
    } elsif (! $self->{-skip_to_results}) {
        # -skip_to_results typically used for searching, so don't add anything to the title
        $self->{'category_title'} .= ' ('.$ws->translate('results').')';
    }

    $ws->{-optional_header} .= '<div id="breadcrumbNavDiv">'.join('&nbsp;&gt;&nbsp;', @{ $self->{'breadcrumb_links'} }).$skip_to_results.'</div>'
      . '<div class="categoryContentDiv" id="categoryContentDiv-'.join('__', @{ $self->{'breadcrumbs'} }).'"></div>'; # available for CSS-configured content

    $self->{'_added_breadcrumbs'} = 1;
}

sub _uri_param_pair {
    my ($key, $val) = @_;
    return uri_escape($key).'='.uri_escape_utf8($val||'');
}

sub link_for_category_column {
    my ($self, $category_col, $row, @exclude_params) = @_;
    my (@cols, $col_found);
    foreach (@{ $self->{-category_columns} }) {
        push(@cols, $_);
        if ($_ eq $category_col) {
            $col_found = 1;
            last;
        }
    }
    my $extra_vars = $self->{ws}->extra_vars_for_uri([ @{ $self->{'filter_columns'} }, '_browse_skip_to_results_', @exclude_params ]);
    my $category_decoded = $self->decode_utf8($row->{$category_col});
    return $col_found
      ? '<a href="?'.join('&', (map { _uri_param_pair($_, $self->decode_utf8($row->{$_})) } @cols), $extra_vars || ()).'" id="jumpToCategoryLink">'
        .$category_decoded.'</a>'
      : $category_decoded;
}

sub _category_columndata_closure {
    my ($self, $category_col) = @_;
    my $existing_category_filters =
      join('&', map { _uri_param_pair($_, $self->decode_utf8($self->{q}->param($_))) } @{ $self->{'filter_columns'} });
    return sub {
        my ($sd, $row) = @_;
        my $category_decoded = $self->decode_utf8($row->{$category_col});
        my $category_display_value =
          ref $self->{-category_column_closures}->{$category_col} eq 'CODE'
            ? $self->{-category_column_closures}->{$category_col}->($sd, $row)
            : $category_decoded;
        my $extra_vars = $sd->extra_vars_for_uri([ @{ $self->{'filter_columns'} }, '_browse_skip_to_results_' ]);
        return '<a href="?'.join(
            '&', $existing_category_filters || (),
            _uri_param_pair($category_col, $category_decoded),
            $extra_vars || (),
        ).'" id="categoryNavLink-'.CGI::escapeHTML($category_decoded).'">'.$category_display_value.'</a>'; # TODO: HTML::Escape is faster than CGI
    };
}


1;
__END__

=back

=head1 AUTHOR

Adi Fairbank <adi@adiraj.org>

=head1 COPYRIGHT

Copyright (C) 2008-2014  Adi Fairbank

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
