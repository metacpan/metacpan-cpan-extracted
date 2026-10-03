## Name

App::Access2CSV - Export the tables of a Microsoft Access database to CSV files

## Version

Version 0.001.1

## Synopsis

```
    # Export every table to the current directory
    access2csv shop.accdb

    # See what would be written, with row counts, without writing anything
    access2csv --dry-run --show-counts shop.accdb

    # Export only two tables, into a directory called "exports"
    access2csv --output-dir exports --table Customers --table Orders shop.mdb

    # Make files that Excel opens correctly, replace old files, no log file
    access2csv --encoding utf8-bom --overwrite --no-log shop.accdb

    # Read the database from standard input ("-"), e.g. from a download
    curl -s https://example.com/shop.accdb | access2csv --output-dir exports -

    # Nightly job: quiet, with a log in a fixed place, and stop on failure
    access2csv --no-progress --log /var/log/access2csv.log \
            --output-dir /srv/exports --overwrite shop.accdb || exit 1
```

## Description

Microsoft Access keeps its data in `.mdb` or `.accdb` files.
`access2csv` reads one of these files and writes one CSV file
(comma-separated values, a plain-text table) for each table in it.

It does not read the Access file itself.  It runs three small programs
from the free **mdbtools** package:

- `mdb-tables` - to get the list of tables
- `mdb-export` - to get the data of each table as CSV
- `mdb-count` - to count rows (only when you use **--show-counts**)

These programs must be installed and must be in your `PATH`.

Access also keeps its own internal tables in the file.  Their names start
with `MSys`, `USys` or `~`.  They are skipped.

### How the CSV Files Are Named

Each file has the name of its table plus `.csv`, for example
`Orders.csv`.  Some characters are not allowed in file names on some
computers (`< > : " / \ | ? *` and control characters).  They are
changed to `_`, and so are invisible text-direction controls (such as
U+202E, "right-to-left override"), which could make a file name look
like something else.  Bytes that are not valid UTF-8 (only a damaged
database has them, and macOS cannot store them in a file name) are also
changed to `_`.  Spaces and dots at the end, and spaces at the start,
are removed.  A name such as `CON` or `NUL` (reserved on Windows) gets a
`_` in front.  An empty name becomes `unnamed`.

Access names are at most 64 characters, so a longer name can only come
from a damaged database.  It is shortened to 64 characters (and to 240
bytes, to fit the file name limit of most systems), without cutting a
character in half.

If two tables would get the same file name, the second one gets `_2`,
the third `_3`, and so on.  Upper and lower case count as the same here,
because Windows and macOS treat `Orders.csv` and `ORDERS.csv` as one file.

### Reading the Database From Standard Input

If the database name is `-`, the database is read from standard input
instead of a file, so it can be piped in.  mdbtools can only read a real
file, so the data is first copied to a private temporary file (readable
by you only) in the temporary directory (`TMPDIR`, or `/tmp`), and that
copy is deleted when the program ends - whether it succeeds, fails or is
interrupted.

`-` is refused if standard input is a terminal (there is nothing to
read but the keyboard), and a directory or empty input is an error.  To use
a file that is really called `-`, write `./-`.

### How Files Are Written

Each file is first written to a hidden temporary file (its name starts
with `.access2csv-`) in the output directory.  Only when it is complete
is it renamed to its real name.  So if something goes wrong, you never
get a half-written CSV file, and an old file is only replaced by a
complete new one.

## Requirements

The mdbtools programs `mdb-tables` and `mdb-export` must be installed
and in your `PATH`; `mdb-count` is needed only for **--show-counts**.
They are not Perl modules, so the CPAN installer cannot install them for
you.  Install them with your system's package manager, for example:

```
    sudo apt install mdbtools       # Debian, Ubuntu
    sudo dnf install mdbtools       # Fedora
    brew install mdbtools           # macOS (Homebrew)
    pacman -S mingw-w64-x86_64-mdbtools   # Windows (MSYS2)
```

Without them the program stops with "Required program not found in
PATH".  Project home: [https://github.com/mdbtools/mdbtools](https://github.com/mdbtools/mdbtools).

## Using From Perl

The program is a very thin wrapper.  You can call the same code from Perl:

```perl
    use App::Access2CSV;

    my $status = App::Access2CSV->run('--no-log', '--output-dir', 'out', 'shop.accdb');
```

For more control, use [App::Access2CSV::Exporter](https://metacpan.org/pod/App%3A%3AAccess2CSV%3A%3AExporter) directly.

## Options

- **--output-dir** _DIR_

    The directory to write the CSV files to.  It is created if it does not exist.
    Default: the directory.

- **--table** _NAME_

    Export only this table.  You can use this option more than once.
    Names must match exactly, including upper and lower case.  A name that is
    not in the database gives a warning.

- **--overwrite**

    Replace CSV files that already exist.  Without this option, a table whose
    CSV file already exists is not exported, and it counts as a failure.

- **--verbose**

    Write more detail to the log (where each mdbtools program was found).
    Also show the Perl file and line number in fatal error messages.

- **--dry-run**

    Only print a list of the tables and the file names they would get.
    Nothing is written.  The output directory is not created.

- **--show-counts**

    Show the number of rows of each table: in the dry-run list, and in the
    log.  This needs `mdb-count`.  Without it you get a warning, and the
    export goes on without counts.

- **--no-progress**

    Do not print the `[1/5] Customers` progress lines.  (These lines go to
    standard error, not standard output.)

- **--encoding** _utf8|utf8-bom|cp1252_

    The character encoding of the CSV files.  See ["ENCODING"](#encoding).
    Default: `utf8`.

- **--log** _FILE_

    Add log messages to the end of _FILE_.  Default: `access2csv.log` in
    the directory.  An empty name (`--log ''`) means no log.  _FILE_
    must not be a symbolic link (see ["SECURITY"](#security)).

- **--no-log**

    Do not write a log file.

- **--help**, **-h**

    Print the synopsis and the options, then stop.

- **--man**

    Print this whole manual, then stop.

- **--version**

    Print the version ("access2csv version 0.001.1"), then stop.

## Exit Status

The program ends with one of these numbers.  Scripts can test it.

```
    0  Every selected table was exported.  Also used for --dry-run,
       --help, --man and --version.
    1  At least one table was not exported.  The other tables were.
    2  The command line was wrong, for example an unknown option, an
       invalid value (--encoding latin1), no database name, or "-" while
       standard input is a terminal.  Nothing has been done.
    3  A fatal error happened before any table was exported, for example
       the database does not exist or mdbtools is not installed.
```

## Encoding

### The Data in the CSV Files

mdbtools gives the table data as UTF-8, the encoding that can hold every
character, including accented letters, Chinese and Japanese text, and
emoji.

- `utf8` (the default) - the data is copied exactly as mdbtools
gives it.  Every character, including emoji, is kept.
- `utf8-bom` - the same, plus three bytes at the very start of each
file (a "byte order mark").  These bytes tell Microsoft Excel that the file
is UTF-8.  Without them, Excel may show accented letters wrongly.  Some
other programs show the mark as strange characters in the first column
name.
- `cp1252` - Windows-1252, an old Western European encoding.  It has
only 256 characters: English letters, most Western European accented
letters, and a few symbols such as the Euro sign.  It has no Greek,
Cyrillic, Chinese, Japanese or emoji.  If a table contains a character
that Windows-1252 cannot hold, that table is **not** exported, and the
error message gives the line number.  Nothing is silently replaced.

### Names on the Command Line

Database paths, directory names, log file names and table names are used
exactly as the operating system gives them to the program (as bytes).
On Linux and macOS, where the terminal uses UTF-8, names with accented
letters, non-Latin scripts and emoji work.  On Windows, the command line
uses the system code page, so names outside that code page may not work.

### Messages

All messages that the program prints and logs are in plain ASCII English.

## Environment

- `PATH`

    Used to find `mdb-tables`, `mdb-export` and `mdb-count`.  Only
    absolute directories in `PATH` are used: relative entries such as `.` are
    ignored, so a program planted in the directory is never run.

- `LANGUAGE`, `LC_ALL`, `LC_MESSAGES`, `LANG`

    Choose the language of messages (see [App::Access2CSV::I18N](https://metacpan.org/pod/App%3A%3AAccess2CSV%3A%3AI18N)).  Only the
    language code at the start is used; any other value means English.

- `TMPDIR`

    Where a database read from standard input (`-`) is copied while it is
    exported.  Default: `/tmp`.

- `MDB_ICONV`

    Not read by this program, but by mdbtools: it sets the character set
    mdbtools converts to.  Leave it unset, so that the output is UTF-8.

## Security

The program treats the database as untrusted: an Access file received
from someone else may contain table names and data designed to cause
harm.

- **No shell, no option injection.**  Programs are run directly
(never through a shell), and table and file names are passed after a
`--` marker, so names containing `` ; | $( ) ` `` or starting with `-`
are only ever names.
- **No planted programs.**  Relative `PATH` entries are ignored
(see ["ENVIRONMENT"](#environment)).  The mdbtools programs are started with a cleaned
environment: `PATH` holds only absolute directories, and `IFS`, `CDPATH`,
`ENV` and `BASH_ENV` are removed.
- **Taint mode.**  The program runs under Perl's taint mode
(`perl -T`).  Every outside value - the database path, table names,
`--output-dir`, `--log` and the program paths found in `PATH` - is
checked first and only then marked as safe.  Under `-T`, Perl also
refuses to start mdbtools while `PATH` contains a directory other users can
write to; the program then stops with "Insecure directory in
$ENV{PATH}".
- **Private copies of piped input.**  A database read from standard
input is copied with [File::Temp](https://metacpan.org/pod/File%3A%3ATemp) (a new, unpredictable name, readable
by you only) and deleted when the program ends, also after an error or
an interruption.
- **Safe file names.**  Table names cannot place a file outside the
output directory, and control characters - including invisible
text-direction controls and C1 controls - are replaced by `_`.
- **Safe terminal and log output.**  Table names and mdbtools error
text are printed with control characters shown as escapes such as
`\x1B`.  So a table name cannot retitle or clear your terminal, hide
text, or forge lines in the log.
- **No writing through symbolic links.**  If the log file is a
symbolic link (for example one planted in a shared directory such as
`/tmp`), the program stops instead of writing to the file it points at.
Existing CSV files that are links are replaced, never written through.
- **Spreadsheet formulas are NOT neutralised.**  A value such as
`=cmd|' /C calc'!A0` is copied into the CSV exactly as it is in the
database, because changing data would corrupt genuine values.  Some
spreadsheet programs run such formulas when a CSV is opened.  Do not open
CSV files exported from an untrusted database in a spreadsheet without
checking them, or import them as text.

## Common Pitfalls

- **A log file appears in the directory directory.**  By default the log is
`access2csv.log` in the directory you run the program from.  Use **--log** to
choose another place, or **--no-log**.
- **The second run fails.**  If the CSV files already exist, each table
fails (exit status 1) unless you give **--overwrite**.
- **--table does not find my table.**  Table names are case-sensitive:
`--table orders` does not match `Orders`.  Use **--dry-run** to see the
exact names.
- **A file is called Orders\_2.csv.**  Two tables had names that give
the same file name (for example `Orders` and `ORDERS`, or `A/B` and
`A:B`).
- **Progress lines appear even though I redirected the output.**
Progress lines go to standard error.  Use **--no-progress**, or redirect
standard error too (`2>/dev/null`).
- **run() does not end the program.**  When calling from Perl,
`App::Access2CSV->run(...)` returns the exit status.  It does not
call `exit`.  Write `exit App::Access2CSV->run(@ARGV)` if you want
the program to end.
- **Pass a list, not an array reference.**  Write
`App::Access2CSV->run(@args)`, not `App::Access2CSV->run(\@args)`.
- **A file called "-".**  `-` means standard input, even after
`--`.  Write `./-` for a file with that name.
- **Piped databases need temporary space.**  The whole database is
copied to the temporary directory first; if that directory is small, set
`TMPDIR` to one with room.

## Methods

### Run

#### Purpose

This is the whole `access2csv` program.  It reads the command-line
options, opens the log, and runs an [App::Access2CSV::Exporter](https://metacpan.org/pod/App%3A%3AAccess2CSV%3A%3AExporter).

#### Arguments

The command-line arguments, as a list of strings (normally `@ARGV`).
Your array is copied first, so it is not changed.

#### Returns

A number from 0 to 3, as described in ["EXIT STATUS"](#exit-status).
`run` never calls `exit` itself.

#### Side Effects

- Everything that ["run" in App::Access2CSV::Exporter](https://metacpan.org/pod/App%3A%3AAccess2CSV%3A%3AExporter#run) does: it creates
the output directory, writes CSV files, and prints progress to standard error.
- It prints help or usage text (help to standard output, usage errors
to standard error).
- It prints a fatal error, if there is one, to standard error as one
line that starts with `access2csv:`.
- It creates or adds to the log file, unless logging is off.
- It leaves your `$@`, `$!`, `$_` and any pending `alarm` as
they were.

#### Usage

```
    exit App::Access2CSV->run(@ARGV);
```

#### Example

```perl
    use App::Access2CSV;

    # Export to ./out without a log file, then check what happened
    my $status = App::Access2CSV->run('--output-dir', 'out', '--no-log', 'shop.accdb');

    if($status == 0) {
            print "All tables were exported\n";
    } elsif($status == 1) {
            print "Some tables could not be exported\n";
    } elsif($status == 2) {
            print "The arguments were wrong\n";
    } else {
            print "Nothing was exported\n";
    }
```

#### Api Specification

##### Input

```perl
    {
            argv => {
                    type         => 'arrayref',
                    optional     => 1,
                    element_type => 'string',
                    description  => 'Command-line arguments, passed as a list',
            },
    }
```

Valid and invalid values (tested in `t/domain.t`):

```
    database names  exactly 1; 0 or 2 or more give exit status 2.
                    "-" means standard input (exit 2 if it is a
                    terminal, 3 if it is empty or unreadable)
    --encoding      utf8, utf8-bom or cp1252; anything else gives exit 2
    --table         0 times (all tables), once, or many times; names
                    may be non-ASCII
    --log           a file name; '' means no log, like --no-log
```

##### Output

```perl
    {
            type => 'integer',
            min  => 0,
            max  => 3,
    }
```

#### Messages

```
    +-------------------------------------+-------------------------------+------------------------------+
    | Message                             | Meaning                       | What to do                   |
    +-------------------------------------+-------------------------------+------------------------------+
    | Unknown option: X (exit 2)          | X is not an option of this    | See --help                   |
    |                                     | program                       |                              |
    | Option X requires an argument       | An option such as --log was   | Give a value after it        |
    |  (exit 2)                           | the last word                 |                              |
    | Invalid setting: REASON (exit 2)    | An option value is not        | Use a documented value (see  |
    |                                     | allowed, e.g. --encoding      | OPTIONS)                     |
    |                                     | latin1; REASON says which     |                              |
    | Missing database filename (exit 2)  | No database name was given,   | Give exactly one database    |
    |                                     | it was empty, or more than    |                              |
    |                                     | one was given                 |                              |
    | Standard input is a terminal: pipe  | "-" was given, but nothing is | Pipe the database in, or     |
    |  the database in, or give its file  | piped in                      | give its file name           |
    |  name (exit 2)                      |                               |                              |
    | access2csv: Standard input is empty:| "-" was given, but the pipe   | Check the command that       |
    |  no database was piped in (exit 3)  | delivered nothing             | produces the database        |
    | access2csv: Cannot read standard    | Reading the pipe failed; E is | See E                        |
    |  input: E (exit 3)                  | the reason ("Is a directory"  |                              |
    |                                     | if a directory was given)        |                              |
    | access2csv: Interrupted by SIGx     | Stopped (Ctrl-C, kill) while  | Run again                    |
    |  while reading the database from    | waiting for piped input; the  |                              |
    |  standard input (exit 3)            | partial copy was deleted      |                              |
    | access2csv: Cannot open log file F: | The log file cannot be        | Use --log with another file, |
    |  E (exit 3)                         | written; E is the reason from | or --no-log                  |
    |                                     | the operating system, "no     |                              |
    |                                     | logger was created", or "it   |                              |
    |                                     | is a symbolic link"           |                              |
    | access2csv: MESSAGE (exit 3)        | Any fatal error from the      | See MESSAGES in              |
    |                                     | exporter                      | App::Access2CSV::Exporter    |
    +-------------------------------------+-------------------------------+------------------------------+
```

#### Pseudocode

```
    options := default settings
    read the command line into options
    if the command line is wrong: print usage, return 2
    if --help or --man: print the documentation, return 0
    if there is not exactly one database name: print usage, return 2
    try:
            open the log, unless logging is off
            status := new Exporter(options).run(database)
    if that failed:
            print "access2csv: <reason>" to standard error
            status := 3
    return status
```

## Limitations

- The real work is done by the external mdbtools programs.  Their
bugs, and their CSV style (quoting, date format, binary columns), are
passed on unchanged.  No maintained CPAN module can read `.accdb` files,
so there is no pure-Perl alternative today.
- The reason inside "Invalid setting: ..." comes from
[Params::Validate::Strict](https://metacpan.org/pod/Params%3A%3AValidate%3A%3AStrict), and messages from [Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) and
[autodie](https://metacpan.org/pod/autodie) come from those modules; none of them is translated.
- **Windows.**  The code handles Windows (its `PATH` separator, the
absence of Unix permission bits and of signals), and the core export
tests (`t/exporter.t`, `t/app.t`) run there.  Most other test files
use Unix-only facilities (signals, symbolic links, `/proc`, taint-mode
child processes, terminals) and are skipped on Windows, so those
features are tested on Unix only.
- The default log file is created in the directory, which may
surprise users.
- Settings come from the command line only.  `%DEFAULTS` is laid out
so that [Object::Configure](https://metacpan.org/pod/Object%3A%3AConfigure) could read them from a configuration file,
but this is not connected yet.

## Testing With Real Databases

Most tests use stand-in mdbtools programs.  `t/real-mdbtools.t` checks
the program against the real mdbtools and real Access files: every CSV
must be byte for byte what `mdb-export` prints.  No database ships with
this distribution; point `ACCESS2CSV_TEST_DATA` at a directory of
`.mdb`/`.accdb` files, for example the mdbtools project's test data:

```
    git clone --depth 1 https://github.com/mdbtools/mdbtestdata
    ACCESS2CSV_TEST_DATA=mdbtestdata/data prove -l t/real-mdbtools.t
```

The continuous-integration workflow does this on Linux.

## See Also

[App::Access2CSV::Exporter](https://metacpan.org/pod/App%3A%3AAccess2CSV%3A%3AExporter), [App::Access2CSV::I18N](https://metacpan.org/pod/App%3A%3AAccess2CSV%3A%3AI18N), [Log::Abstraction](https://metacpan.org/pod/Log%3A%3AAbstraction),
[https://github.com/mdbtools/mdbtools](https://github.com/mdbtools/mdbtools)

- [Test Dashboard](https://nigelhorne.github.io/App-access2csv/coverage/)

## Formal Specification

These schemas use the Z notation.  `?` marks an input and `!` an output.
You do not need to read this section to use the program.

### Run

```
    ┌─ Run ──────────────────────────────────────────────────────
    │ argv? : seq STRING ; status! : 0 ‥ 3
    │ opts : OPTION ⇸ VALUE ; rest : seq STRING
    ├────────────────────────────────────────────────────────────
    │ (opts, rest) = getopt(DEFAULTS, argv?)
    │ ¬ parsed(argv?) ⇒ status! = 2
    │ parsed(argv?) ∧ help ∈ dom opts ⇒ status! = 0
    │ parsed(argv?) ∧ help ∉ dom opts ∧ #rest ≠ 1 ⇒ status! = 2
    │ parsed(argv?) ∧ help ∉ dom opts ∧ #rest = 1 ∧ head rest = "-" ∧
    │   isTerminal(stdin) ⇒ status! = 2
    │ ¬ valid(opts) ⇒ status! = 2 ∧ files' = files   -- checked first: no copy, no log
    │ db = (if head rest = "-" then copy(stdin) else head rest)
    │ parsed(argv?) ∧ help ∉ dom opts ∧ #rest = 1 ∧
    │   ¬ (head rest = "-" ∧ isTerminal(stdin)) ⇒
    │   (fatal(Exporter.Run(db)) ⇒ status! = 3) ∧
    │   (¬ fatal(Exporter.Run(db)) ⇒ status! = Exporter.Run(db).status!)
    │ files'(copy(stdin)) undefined          -- the copy never outlives the run
    └────────────────────────────────────────────────────────────
```

### Printable Output

Every message shown on the terminal or written to the log first passes
through this filter.  `CTRL` is the set of control characters: C0
except tab, DEL, C1 and the text-direction controls.

```
    ┌─ Printable ────────────────────────────────────────────────
    │ text? : seq CHAR ; shown! : seq CHAR
    ├────────────────────────────────────────────────────────────
    │ shown! = ⁀/ ⟨ c : text? • (if c ∈ CTRL then escape(c) else ⟨c⟩) ⟩
    │ ran shown! ∩ CTRL = ∅
    └────────────────────────────────────────────────────────────
```

## State Diagram

One call of `run`, from start to exit status.  Each box is a state.
Each arrow shows what moves the program to the next state, and what
happens on the way.

```
                      run(@argv)
                          |
                          v
                  +---------------+
                  |    PARSING    |  read options into the settings
                  +---------------+
                   |      |      |
     bad option,   |      |      | --help / --man / --version
     missing value,|      |      | action: print it to STDOUT
     not exactly   |      |      v
     one database, |      |   +--------+
     or "-" while  |      |   |  HELP  |---> return 0
     standard input|      |   +--------+
     is a terminal |      |
                   |      | options parsed, one database
                   |      v
                   |   +--------------------+
                   |   | CHECKING SETTINGS  |
                   |   +--------------------+
                   |      |               |
                   |<-----+ invalid value | valid
                   |        (e.g.         |
                   |        --encoding    |
     action: print |        latin1)       v
     the reason    |              +--------------------+  empty, unreadable,
     and usage to  |              |   READING STDIN    |  or interrupted
     STDERR        v              | (only for "-")     |  (croak) ------------+
          +-------------+         +--------------------+                      |
          | USAGE ERROR |           | action: copy standard input to a        |
          +-------------+           |   private temporary file                |
              |                     v                                         |
     return 2 <           +--------------------+  log cannot be opened        |
                          |    OPENING LOG     |  (croak)                     |
                          | (not with --no-log)|------------------------------+
                          +--------------------+                              |
                            | log is writable                                 |
                            v                                                 |
                  +--------------------+                                      |
                  | EXPORTING          |  fatal error (croak)                 |
                  | (Exporter->run,    |--------------------------------------+
                  |  see its STATE     |                                      |
                  |  DIAGRAM)          |                                      v
                  +--------------------+                           +------------------+
                     |              |                              |      FATAL       |
       all tables OK,|              | some table                   +------------------+
       or dry run    |              | failed                       action: print
                     v              v                              "access2csv: <reason>"
                 return 0       return 1                           to STDERR; return 3
```

Whichever way the run ends, a copy made of standard input is deleted.

## Author

Nigel Horne, `<njh at nigelhorne.com>`

## License and Copyright

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.
