# NAME

Database::BI - Web-based Business Intelligence viewer for flat data files

# VERSION

0.005.2

# DESCRIPTION

`Database::BI` is a self-contained [Mojolicious](https://metacpan.org/pod/Mojolicious) web application that reads arbitrary
flat data files (CSV, PSV, SQLite, XML, etc.) via [Database::Abstraction](https://metacpan.org/pod/Database%3A%3AAbstraction)
and presents them as styled, sortable, reorderable HTML tables.
It has no persistent database of its own,
it reads arbitrary data files (CSV, PSV, SQLite, XML etc) presents each file as a styled, sortable, exportable HTML table.

Users navigate to pick a file, open the filesystem browser to navigate anywhere on disk, drag-and-drop files to upload, join multiple tables in memory, apply server-side filters, and export results as CSV, SQLite, or JSON.
A D3.js line graph view plots any numeric column.

Key features:

- **File picker** - the home page scans `data_dir` and shows a card for
every supported file.  Recently opened filesystem files appear in a
"Recently opened" section powered by `localStorage`.
- **Filesystem browser** - `/browse` lets the user navigate the entire
filesystem and open any supported data file, not just files in `data_dir`.
- **Column sort and reorder** - clicking a header sorts the table; headers
are draggable to reorder.  Both settings are persisted in `localStorage`
by column name and survive page reloads.
- **Left join** - the "Merge data / Filter results" panel on any table view
lets the user join one or more additional tables on a shared key.  Every
left row is kept; right-table columns are appended for matching rows.
- **Result filters** - the same panel lets the user add filter conditions
(column / operator / value) that are applied server-side after all joins.
Operators: `eq`, `ne`, `contains`, `starts`, `lt`, `le`, `gt`,
`ge`, `empty`, `notempty`.  Active filters are shown as chips in the
toolbar with a one-click "Clear" link.
- **Drag-and-drop upload** - any supported data file can be dropped directly
onto the application.  On the home page the file is opened immediately;
when the join panel is open the dropped file populates the right-table
path field.
- **Export** - the toolbar on any view offers an export panel that writes
the current logical view (after joins and filters) to a chosen filesystem
path as CSV (`.csv`) or SQLite (`.sql`).

# SYNOPSIS

**Start the development server (restarts automatically when you edit a file):**

    morbo script/database-bi

**Start the production server:**

    hypnotoad script/database-bi

**Use a different data directory:**

    # In database_bi.conf (create this file in the same folder as script/):
    { data_dir => '/home/user/data' }

**Change the language used for templates:**

    # In database_bi.conf:
    { data_dir => 'data', language => 'fr', platform => 'web' }
    # Then create templates/web/fr/ and put your French .html.tt files there.

**Run the test suite to verify everything is working:**

    make test

**Generate the Makefile for the first time or after editing Makefile.PL:**

    perl Makefile.PL

# ROUTES

- `GET /`

    Scans `data_dir`, renders a card grid of available tables.

- `GET /view/:table`

    Opens the named table from `data_dir`.  Accepts `?f=col:op:val`
    (repeatable) to pre-filter results.

- `GET /browse`

    Filesystem navigator.  Accepts `?path=` to set the starting directory
    (defaults to `$HOME`).

- `GET /open`

    Opens any supported file by absolute path (`?path=`).  Accepts `?f=`
    filters.

- `GET /join`

    Performs one or more left joins and renders the merged table.  Parameters:

        l=<spec>               left table: "table:name" or "path:/abs/path"
        j=<spec>|<lk>|<rk>    join step (repeatable): right-spec, left key, right key
        f=<col>:<op>:<val>     result filter (repeatable)

- `GET /api/columns`

    Returns `{ "columns": [...] }` for a table (`?table=name`) or file
    (`?path=/abs/path`).  Used by the join UI to populate the right-key
    dropdown without a page reload.

- `GET /export`

    Exports the current logical view (same `l=`, `j=`, `f=` parameters as
    `/join`) as a file download.  Additional parameter:

        format=csv      (default) - RFC 4180 CSV; UTF-8; CRLF line endings
        format=sqlite   - SQLite 3 database with a single table named "data"

    The download filename is derived from the left table label with
    non-alphanumeric characters replaced by underscores.

- `POST /export`

    Writes the current logical view to a chosen filesystem path.
    Body params: `l=`, `j=`, `f=` (same as GET), plus
    `dir=` (target directory) and `filename=` (name including extension;
    extension determines format: `.csv` or `.sql`).
    Returns JSON `{ saved: "/abs/path" }` or `{ error: "..." }`.

- `GET /api/dirs`

    Returns a JSON directory listing (subdirectories only) for the export
    panel's inline directory browser.  Accepts `?path=` (defaults to
    `$HOME`).  Returns `{ path, parent, dirs: [{name, path}] }`.

- `GET /api/stat`

    Returns filesystem metadata for a file path (`?path=`).
    Returns `{ exists, path, mtime, size }`.  If the file does not exist,
    `exists` is `false` and the remaining fields are absent (HTTP 200).
    Returns HTTP 400 when `path` is missing.

- `POST /upload`

    Accepts a multipart file upload (field name: `file`), validates the
    extension, saves to a managed `.uploads/` subdirectory under the app
    home, and returns JSON `{ url, path }`.

- `GET /import`

    Fetches an HTML table from a public URL (`?url=`) and renders it as a
    data grid.  An optional `?t=` parameter (zero-based integer) selects
    which HTML table on the page to display when the page contains multiple
    tables.

- `GET /combine`

    Stacks rows from two or more tables vertically (UNION ALL) into a unified
    view.  All columns from all sources appear as headers; cells are blank
    where a source file lacks a column.  Parameters:

        l=<spec>               left table: "table:name" or "path:/abs/path"
        c=<spec>               additional table to stack (repeatable)
        f=<col>:<op>:<val>     result filter applied after combining (repeatable)

# CONFIGURATION

Place a `database_bi.conf` file in the application root to override
defaults:

    {
        data_dir => 'data',   # directory scanned for data files on the home page
        platform => 'web',    # VWF template dimension
        language => 'en',     # VWF template dimension
    }

# COMMON PITFALLS

- **The configuration file is optional but must be valid Perl if present**

    `database_bi.conf` is loaded by `Mojolicious::Plugin::Config`, which
    evaluates it as a Perl data structure.  If the file exists but contains a
    syntax error, the application will refuse to start.  If the file does not
    exist, built-in defaults are used and no error occurs.  The file must return
    a hashref:

        # database_bi.conf -- correct
        { data_dir => 'data', platform => 'web', language => 'en' }

        # WRONG -- missing braces
        data_dir => 'data'

- **data\_dir is relative to the application home directory, not the process cwd**

    Setting `data_dir => 'data'` looks for a folder called `data/` in the
    same directory as the `script/database-bi` launcher, regardless of where you
    run the server from.  An absolute path works on any system:

        { data_dir => '/var/db/mydata' }

- **The download\_dir default is computed once at startup**

    When the application starts, it picks the export directory in this order:
    `~/Downloads` (if it exists), then `$HOME`, then the system temp directory.
    This value is fixed for the life of the process.  Renaming or creating
    `~/Downloads` after the server starts has no effect.  To force a different
    default, set it before starting:

        { data_dir => 'data' }   # and create ~/Downloads before starting the server

- **Adding a new language requires a template directory, not just a config change**

    Setting `language => 'de'` in `database_bi.conf` tells the controller
    to look for templates in `templates/web/de/`.  If that directory does not
    exist, the controller automatically falls back to the default language.  To
    add German support: (1) create `templates/web/de/`, (2) copy and translate
    the `.html.tt` files from `templates/web/en/`, then (3) set the config.

- **Supported data file extensions are: csv, db, sql, xml, psv**

    The application calls `Database::Abstraction` which recognises exactly these
    five extensions.  A file called `inventory.sqlite` is **not** recognised -- it
    must be renamed to `inventory.sql`.  A file called `data.xlsx` (Excel) is
    also not supported; export it as CSV first.

- **The open\_table helper lowercases the table name**

    When the router matches `GET /view/Sales` or `GET /view/SALES`, the table
    name is lowercased to `sales` before being passed to the helper.  The data
    file on disk must therefore also be lowercase (`sales.csv`, not
    `Sales.csv`).

# LIMITATIONS

- Only read operations on data files are supported.  Write-back (editing
cell values in the browser and saving them to the data file) is not
implemented.
- The left-join engine (`Dashboard::_left_join`) is an in-memory O(n\*m)
hash join.  It is suitable for BI files that fit comfortably in RAM.
For very large files, replace the `open_table` helper body with a
`Database::Join` instance (Phase 2) without changing the controller.
- On startup, `Database::BI` automatically evicts upload subdirectories whose
modification time is older than 24 hours.  Uploads created during the current
or recent server sessions are preserved.  Users may also trigger an immediate
full purge (regardless of age) via the "Clear upload cache" button, which
posts to `POST /uploads/clear`.
- `Sub::Protected`/:Protected enforcement relies on the CHECK compilation
phase.  When a module is loaded dynamically at test time (e.g. via
`Test::Mojo-`new(...)>), the CHECK phase has already passed and the
"Too late to run CHECK block" warning is emitted -- the access
restriction is not enforced in that test context.  This does not affect
production (morbo/hypnotoad) deployments where modules are compiled on
startup.  Unlike the former `Sub::Private` approach, `Sub::Protected`
does not delete stash entries, so OO dispatch `$self->_method()`
works correctly in production without any special workarounds.

# SEE ALSO

- [Test Dashboard](https://nigelhorne.github.io/Database-BI/coverage/)

# REPOSITORY

[https://github.com/nigelhorne/Database-BI](https://github.com/nigelhorne/Database-BI)

# SUPPORT

This module is provided as-is without any warranty.

# AUTHOR

Nigel Horne `<njh@nigelhorne.com>`

# LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
