package Database::BI;

use Mojo::Base 'Mojolicious', -strict, -signatures;

use Carp	qw(croak);
use File::Spec	();
use Readonly;

use Database::BI::Model::DataSource;

our $VERSION = '0.005.2';

# Default config values used by the Config plugin and referenced explicitly
# in startup() so callers always get a resolved value.
Readonly my $DEFAULT_DATA_DIR => 'data';
Readonly my $DEFAULT_PLATFORM => 'web';
Readonly my $DEFAULT_LANGUAGE => 'en';

# Transport-layer upload size cap (bytes).  Mojolicious enforces this before
# the request body is read into memory, so an oversized upload never reaches
# the controller.  Must match $MAX_UPLOAD_BYTES in Dashboard.pm.
Readonly my $MAX_REQUEST_SIZE  => 50 * 1_048_576;	# 50 MiB
Readonly my $UPLOAD_MAX_AGE_S  => 24 * 3600;		# evict uploads older than 24 h

=head1 NAME

Database::BI - Web-based Business Intelligence viewer for flat data files

=head1 VERSION

0.005.2

=head1 DESCRIPTION

C<Database::BI> is a self-contained L<Mojolicious> web application that reads arbitrary
flat data files (CSV, PSV, SQLite, XML, etc.) via L<Database::Abstraction>
and presents them as styled, sortable, reorderable HTML tables.
It has no persistent database of its own,
it reads arbitrary data files (CSV, PSV, SQLite, XML etc) presents each file as a styled, sortable, exportable HTML table.

Users navigate to pick a file, open the filesystem browser to navigate anywhere on disk, drag-and-drop files to upload, join multiple tables in memory, apply server-side filters, and export results as CSV, SQLite, or JSON.
A D3.js line graph view plots any numeric column.

Key features:

=over 4

=item *

B<File picker> - the home page scans C<data_dir> and shows a card for
every supported file.  Recently opened filesystem files appear in a
"Recently opened" section powered by C<localStorage>.

=item *

B<Filesystem browser> - C</browse> lets the user navigate the entire
filesystem and open any supported data file, not just files in C<data_dir>.

=item *

B<Column sort and reorder> - clicking a header sorts the table; headers
are draggable to reorder.  Both settings are persisted in C<localStorage>
by column name and survive page reloads.

=item *

B<Left join> - the "Merge data / Filter results" panel on any table view
lets the user join one or more additional tables on a shared key.  Every
left row is kept; right-table columns are appended for matching rows.

=item *

B<Result filters> - the same panel lets the user add filter conditions
(column / operator / value) that are applied server-side after all joins.
Operators: C<eq>, C<ne>, C<contains>, C<starts>, C<lt>, C<le>, C<gt>,
C<ge>, C<empty>, C<notempty>.  Active filters are shown as chips in the
toolbar with a one-click "Clear" link.

=item *

B<Drag-and-drop upload> - any supported data file can be dropped directly
onto the application.  On the home page the file is opened immediately;
when the join panel is open the dropped file populates the right-table
path field.

=item *

B<Export> - the toolbar on any view offers an export panel that writes
the current logical view (after joins and filters) to a chosen filesystem
path as CSV (C<.csv>) or SQLite (C<.sql>).

=back

=head1 SYNOPSIS

B<Start the development server (restarts automatically when you edit a file):>

    morbo script/database-bi

B<Start the production server:>

    hypnotoad script/database-bi

B<Use a different data directory:>

    # In database_bi.conf (create this file in the same folder as script/):
    { data_dir => '/home/user/data' }

B<Change the language used for templates:>

    # In database_bi.conf:
    { data_dir => 'data', language => 'fr', platform => 'web' }
    # Then create templates/web/fr/ and put your French .html.tt files there.

B<Run the test suite to verify everything is working:>

    make test

B<Generate the Makefile for the first time or after editing Makefile.PL:>

    perl Makefile.PL

=head1 ROUTES

=over 4

=item C<GET />

Scans C<data_dir>, renders a card grid of available tables.

=item C<GET /view/:table>

Opens the named table from C<data_dir>.  Accepts C<?f=col:op:val>
(repeatable) to pre-filter results.

=item C<GET /browse>

Filesystem navigator.  Accepts C<?path=> to set the starting directory
(defaults to C<$HOME>).

=item C<GET /open>

Opens any supported file by absolute path (C<?path=>).  Accepts C<?f=>
filters.

=item C<GET /join>

Performs one or more left joins and renders the merged table.  Parameters:

  l=<spec>               left table: "table:name" or "path:/abs/path"
  j=<spec>|<lk>|<rk>    join step (repeatable): right-spec, left key, right key
  f=<col>:<op>:<val>     result filter (repeatable)

=item C<GET /api/columns>

Returns C<{ "columns": [...] }> for a table (C<?table=name>) or file
(C<?path=/abs/path>).  Used by the join UI to populate the right-key
dropdown without a page reload.

=item C<GET /export>

Exports the current logical view (same C<l=>, C<j=>, C<f=> parameters as
C</join>) as a file download.  Additional parameter:

  format=csv      (default) - RFC 4180 CSV; UTF-8; CRLF line endings
  format=sqlite   - SQLite 3 database with a single table named "data"

The download filename is derived from the left table label with
non-alphanumeric characters replaced by underscores.

=item C<POST /export>

Writes the current logical view to a chosen filesystem path.
Body params: C<l=>, C<j=>, C<f=> (same as GET), plus
C<dir=> (target directory) and C<filename=> (name including extension;
extension determines format: C<.csv> or C<.sql>).
Returns JSON C<{ saved: "/abs/path" }> or C<{ error: "..." }>.

=item C<GET /api/dirs>

Returns a JSON directory listing (subdirectories only) for the export
panel's inline directory browser.  Accepts C<?path=> (defaults to
C<$HOME>).  Returns C<{ path, parent, dirs: [{name, path}] }>.

=item C<GET /api/stat>

Returns filesystem metadata for a file path (C<?path=>).
Returns C<{ exists, path, mtime, size }>.  If the file does not exist,
C<exists> is C<false> and the remaining fields are absent (HTTP 200).
Returns HTTP 400 when C<path> is missing.

=item C<POST /upload>

Accepts a multipart file upload (field name: C<file>), validates the
extension, saves to a managed C<.uploads/> subdirectory under the app
home, and returns JSON C<{ url, path }>.

=item C<GET /import>

Fetches an HTML table from a public URL (C<?url=>) and renders it as a
data grid.  An optional C<?t=> parameter (zero-based integer) selects
which HTML table on the page to display when the page contains multiple
tables.

=item C<GET /combine>

Stacks rows from two or more tables vertically (UNION ALL) into a unified
view.  All columns from all sources appear as headers; cells are blank
where a source file lacks a column.  Parameters:

  l=<spec>               left table: "table:name" or "path:/abs/path"
  c=<spec>               additional table to stack (repeatable)
  f=<col>:<op>:<val>     result filter applied after combining (repeatable)

=back

=head1 CONFIGURATION

Place a C<database_bi.conf> file in the application root to override
defaults:

    {
        data_dir => 'data',   # directory scanned for data files on the home page
        platform => 'web',    # VWF template dimension
        language => 'en',     # VWF template dimension
    }

=head1 COMMON PITFALLS

=over 4

=item B<The configuration file is optional but must be valid Perl if present>

C<database_bi.conf> is loaded by C<Mojolicious::Plugin::Config>, which
evaluates it as a Perl data structure.  If the file exists but contains a
syntax error, the application will refuse to start.  If the file does not
exist, built-in defaults are used and no error occurs.  The file must return
a hashref:

    # database_bi.conf -- correct
    { data_dir => 'data', platform => 'web', language => 'en' }

    # WRONG -- missing braces
    data_dir => 'data'

=item B<data_dir is relative to the application home directory, not the process cwd>

Setting C<data_dir =E<gt> 'data'> looks for a folder called C<data/> in the
same directory as the C<script/database-bi> launcher, regardless of where you
run the server from.  An absolute path works on any system:

    { data_dir => '/var/db/mydata' }

=item B<The download_dir default is computed once at startup>

When the application starts, it picks the export directory in this order:
C<~/Downloads> (if it exists), then C<$HOME>, then the system temp directory.
This value is fixed for the life of the process.  Renaming or creating
C<~/Downloads> after the server starts has no effect.  To force a different
default, set it before starting:

    { data_dir => 'data' }   # and create ~/Downloads before starting the server

=item B<Adding a new language requires a template directory, not just a config change>

Setting C<language =E<gt> 'de'> in C<database_bi.conf> tells the controller
to look for templates in C<templates/web/de/>.  If that directory does not
exist, the controller automatically falls back to the default language.  To
add German support: (1) create C<templates/web/de/>, (2) copy and translate
the C<.html.tt> files from C<templates/web/en/>, then (3) set the config.

=item B<Supported data file extensions are: csv, db, sql, xml, psv>

The application calls C<Database::Abstraction> which recognises exactly these
five extensions.  A file called C<inventory.sqlite> is B<not> recognised -- it
must be renamed to C<inventory.sql>.  A file called C<data.xlsx> (Excel) is
also not supported; export it as CSV first.

=item B<The open_table helper lowercases the table name>

When the router matches C<GET /view/Sales> or C<GET /view/SALES>, the table
name is lowercased to C<sales> before being passed to the helper.  The data
file on disk must therefore also be lowercase (C<sales.csv>, not
C<Sales.csv>).

=back

=head1 LIMITATIONS

=over 4

=item *

Only read operations on data files are supported.  Write-back (editing
cell values in the browser and saving them to the data file) is not
implemented.

=item *

The left-join engine (C<Dashboard::_left_join>) is an in-memory O(n*m)
hash join.  It is suitable for BI files that fit comfortably in RAM.
For very large files, replace the C<open_table> helper body with a
C<Database::Join> instance (Phase 2) without changing the controller.

=item *

On startup, C<Database::BI> automatically evicts upload subdirectories whose
modification time is older than 24 hours.  Uploads created during the current
or recent server sessions are preserved.  Users may also trigger an immediate
full purge (regardless of age) via the "Clear upload cache" button, which
posts to C<POST /uploads/clear>.

=item *

C<Sub::Protected>/:Protected enforcement relies on the CHECK compilation
phase.  When a module is loaded dynamically at test time (e.g. via
C<Test::Mojo->new(...)>), the CHECK phase has already passed and the
"Too late to run CHECK block" warning is emitted -- the access
restriction is not enforced in that test context.  This does not affect
production (morbo/hypnotoad) deployments where modules are compiled on
startup.  Unlike the former C<Sub::Private> approach, C<Sub::Protected>
does not delete stash entries, so OO dispatch C<< $self->_method() >>
works correctly in production without any special workarounds.

=back

=cut

sub startup ($self) {
	$self->plugin('Config', {
		default => {
			data_dir => $DEFAULT_DATA_DIR,
			platform => $DEFAULT_PLATFORM,
			language => $DEFAULT_LANGUAGE,
		}
	});

	# Cap inbound request body size.  When the limit fires, Mojolicious sets
	# req->is_limit_exceeded and still dispatches to the controller (with partial
	# content in the upload asset).  The controller checks is_limit_exceeded and
	# returns 413 before writing to disk.
	$self->max_request_size($MAX_REQUEST_SIZE);

	# Default export/save directory: ~/Downloads when it exists, else HOME,
	# else system tmpdir.  Resolved once per process and stored as a stash
	# default so every action can read $self->stash('download_dir').
	my $home   = $ENV{HOME} // '';
	my $dl_dir = ($home && -d "$home/Downloads") ? "$home/Downloads"
	           : ($home || File::Spec->tmpdir());
	$self->defaults(download_dir => $dl_dir);

	# Register the TT plugin as 'tt' (not the default 'tt2') so that template
	# files keep the .html.tt extension and handler => 'tt' in render() calls
	# resolves correctly via Template::Provider::Mojo.  TT options must live
	# under the 'template' key; top-level keys are plugin options only.
	$self->plugin('TemplateToolkit', {
		name     => 'tt',
		template => {
			POST_CHOMP => 1,
			TRIM       => 1,
		},
	});

	# Factory helper: opens any named table from the configured data directory.
	# The directory=> option overrides the default so open_file and upload_file
	# can open tables from arbitrary filesystem paths.
	#
	# Phase 2: swap Database::BI::Model::DataSource for Database::Join here;
	# the controller and all templates are untouched.
	my $data_dir = $self->home->child($self->config->{data_dir})->to_string;

	$self->helper(open_table => sub($c, $table, %opts) {
		# URL mode: fetch a remote HTML table directly via Database::Abstraction's
		# URL backend (LWP::UserAgent + HTML::TableExtract).
		if (exists $opts{url}) {
			return Database::BI::Model::DataSource->new(
				url => $opts{url},
				exists $opts{html_table_index}
					? (html_table_index => $opts{html_table_index})
					: (),
			);
		}
		my $dir = exists $opts{directory} ? $opts{directory} : $data_dir;
		Database::BI::Model::DataSource->new(
			directory => $dir,
			table     => $table,
		);
	});

	my $r = $self->routes();
	$r->get('/')->to('Dashboard#index');
	$r->get('/view/:table')->to('Dashboard#view');
	$r->get('/browse')->to('Dashboard#browse');
	$r->get('/open')->to('Dashboard#open_file');
	$r->get('/join')->to('Dashboard#join_tables');
	$r->get('/api/columns')->to('Dashboard#columns_api');
	$r->get('/import')->to('Dashboard#import_url');
	$r->get('/combine')->to('Dashboard#combine_tables');
	$r->get('/export')->to('Dashboard#export_data');
	$r->post('/export')->to('Dashboard#export_write');
	$r->get('/api/dirs')->to('Dashboard#dirs_api');
	$r->get('/api/stat')->to('Dashboard#stat_api');
	$r->post('/upload')->to('Dashboard#upload_file');
	$r->post('/uploads/clear')->to('Dashboard#clear_uploads');
	$r->get('/graph')->to('Dashboard#graph_view');

	# Evict stale upload subdirectories on every startup so the cache cannot
	# grow unboundedly across server restarts.  Only entries whose mtime is
	# older than $UPLOAD_MAX_AGE_S seconds are removed; recent uploads that
	# were made while the previous server process was running are preserved.
	_evict_old_uploads($self->home->child('.uploads'), $UPLOAD_MAX_AGE_S);
}

# _evict_old_uploads( $uploads_dir, $max_age_s ) -> void
#
# Purpose: Remove upload subdirectory trees whose mtime is older than $max_age_s
#          seconds.  Runs at startup and is also called by clear_uploads (via the
#          Dashboard controller) when the user explicitly requests a purge.
# Entry:   $uploads_dir is a Mojo::File.  $max_age_s is a positive integer.
# Exit:    Silent on success.  Individual remove_tree failures are non-fatal.
sub _evict_old_uploads {
	my ($uploads_dir, $max_age_s) = @_;
	return unless -d $uploads_dir;

	my $cutoff = time() - $max_age_s;

	$uploads_dir->list({ dir => 1 })->each(sub {
		my ($entry) = @_;
		my $mtime = (stat $entry)[9] // 0;
		return if $mtime >= $cutoff;	# still fresh — keep it
		if (-d $entry) {
			$entry->remove_tree;
		} elsif (-f $entry) {
			unlink $entry->to_string;
		}
	});
}

=head1 SEE ALSO

=over 4

=item * L<Test Dashboard|https://nigelhorne.github.io/Database-BI/coverage/>

=back

=head1 REPOSITORY

L<https://github.com/nigelhorne/Database-BI>

=head1 SUPPORT

This module is provided as-is without any warranty.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut

1;
