package App::Actions::Logs;

use strict;
use warnings;
use Carp qw(croak);
use File::Spec;
use JSON::PP ();
use Readonly;

use App::Actions::Cache ();
use App::Actions::I18N qw(i18n);
use App::Actions::Schema ();

our $VERSION = '0.002.1';

# A parallel run copies each job's log out of its temporary directory before
# that is removed, into a directory named after the run.  They are kept so a
# failure can be read after the containers are gone, but nothing used to
# remove them; this module lists what is there and removes it when asked.
#
# The run directories are named by this tool, so a prune only touches a
# directory that matches that name and only deletes files that are job logs.
# A log directory shared with anything else - ACTION_RUN_LOG_DIR can point
# anywhere - is left alone.

# Each pattern is anchored itself and used as it is: wrapping it again, as
# /\A$RUN_DIRECTORY\z/, anchored it twice and built a new pattern from it.
Readonly::Scalar my $RUN_DIRECTORY => qr/\A\d{8}-\d{6}-[0-9a-fA-F]+\z/;    # 20261021-222955-6ad9752153c1
Readonly::Scalar my $LOG_FILE => qr/\Ajob-\d+(?:-[A-Za-z0-9_.-]+)?\.log\z/;  # job-2-test_n_bad.log

# The shape of the JSON document this module prints.  Bump it whenever a key,
# a value type or an enum changes, and update the schema below and the examples
# in t/fixtures/ with it; t/schema.t asserts the number rather than discovering
# a changed shape where its assertion fails for another reason.
our $JSON_SCHEMA_VERSION = 3;

# The schema of the document logs --json prints, so that the installed
# action-run can hand the contract to a caller.  A change to the document
# belongs here, in $JSON_SCHEMA_VERSION and in the examples in t/fixtures/,
# which t/schema.t holds against this and fails when a key it names appears in
# none of them.
my $JSON_SCHEMA = <<'JSON';
{
  "title": "action-run logs --json",
  "description": "The document action-run logs --json prints.  Objects reject keys this file does not name, so a new key is a schema change.",
  "version": 3,
  "type": "object",
  "properties": {
    "schema_version": {
      "description": "The version of this shape; App::Actions::Logs->json_schema_version returns it.",
      "type": "integer",
      "const": 3
    },
    "generated_at": {
      "description": "The epoch second the document was made; age is measured from this clock.",
      "type": "integer"
    },
    "logs_directory": {
      "description": "The directory the kept logs were read from, and that --prune changed.",
      "type": "string"
    },
    "logs": {
      "description": "Every kept log, sorted by run and then by file name.",
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "run": {
            "description": "The run directory the log belongs to, as action-run named it.",
            "type": "string"
          },
          "name": {
            "description": "The log file's name within the run directory.",
            "type": "string"
          },
          "path": {
            "description": "The path the log can be read from.",
            "type": "string"
          },
          "size": {
            "description": "The bytes the log takes.",
            "type": "integer"
          },
          "mtime": {
            "description": "When the log was last written, in epoch seconds.",
            "type": "integer"
          },
          "age": {
            "description": "How many seconds before generated_at the log was last written; 0 when mtime is later than generated_at, as the text report shows it.",
            "type": "integer"
          }
        },
        "required": [ "run", "name", "path", "size", "mtime", "age" ]
      }
    },
    "totals": {
      "description": "The runs, logs and disk the listing found.",
      "type": "object",
      "properties": {
        "runs": { "type": "integer" },
        "logs": { "type": "integer" },
        "size": { "type": "integer" }
      },
      "required": [ "runs", "logs", "size" ]
    },
    "prune": {
      "description": "What --prune did, or null when the command only listed the logs.",
      "oneOf": [
        { "type": "null" },
        {
          "type": "object",
          "properties": {
            "removed": { "type": "integer" },
            "freed": { "type": "integer" },
            "failed": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "run": { "type": "string" },
                  "error": { "type": "string" }
                },
                "required": [ "run", "error" ]
              }
            }
          },
          "required": [ "removed", "freed", "failed" ]
        }
      ]
    }
  },
  "required": [
    "schema_version",
    "generated_at",
    "logs_directory",
    "logs",
    "totals",
    "prune"
  ]
}
JSON

sub json_schema {
    return JSON::PP->new->decode($JSON_SCHEMA);
}

sub json_schema_version { return $JSON_SCHEMA_VERSION }

# The directory a run keeps its per-job logs in: ACTION_RUN_LOG_DIR, then the
# per-user cache directory under action-run/logs.  It is the default a Runner
# uses too, so the command and the runs cannot disagree about where the logs
# are.
sub default_directory {
    my $override = $ENV{ACTION_RUN_LOG_DIR};

    # An empty variable is the same as an unset one.
    return (defined $override && length $override)
        ? $override
        : File::Spec->catdir(App::Actions::Cache::base_directory(), 'action-run', 'logs');
}

sub new {
    my ($class, %args) = @_;

    my $directory = $args{directory};
    $directory = default_directory()
        if !defined $directory || !length $directory;

    return bless { directory => $directory }, $class;
}

sub directory { return $_[0]->{directory} }

# Every run directory that holds at least one job log, newest first.  Only the
# names this tool writes are considered, so a stray file in a shared log
# directory is neither listed nor removed.  A symlink is skipped: following
# one would report, and a prune would delete, something outside the directory.
sub entries {
    my ($self) = @_;

    my $root = $self->{directory};
    return [] unless -d $root;

    opendir my $handle, $root
        or croak "cannot read the log directory '$root': $!";

    my @runs;
    for my $name (sort { $b cmp $a } grep { $_ =~ $RUN_DIRECTORY } readdir $handle) {
        my $run = File::Spec->catdir($root, $name);
        next if -l $run || !-d $run;

        opendir my $logs, $run or next;
        my @files;
        for my $file (sort grep { $_ =~ $LOG_FILE } readdir $logs) {
            my $path = File::Spec->catfile($run, $file);
            next if -l $path || !-f $path;

            my @stat = stat $path;
            next unless @stat;

            push @files, {
                name  => $file,
                path  => $path,
                size  => $stat[7],
                mtime => $stat[9],
            };
        }
        closedir $logs;

        next unless @files;
        push @runs, {
            name      => $name,
            directory => $run,
            logs      => \@files,
        };
    }
    closedir $handle;

    return \@runs;
}

# The logs a threshold selects, grouped by the run they belong to.  A log is
# always stamped with its own modification time, so unlike an image it has no
# unknown age; the comparison still leaves a clock that is ahead out of a
# positive threshold rather than guessing that it is old.  A run with no
# selected log is left out, so a prune never touches a run it was not asked
# about.
sub _selected_runs {
    my ($self, %args) = @_;

    my $runs = $self->entries;
    return $runs unless defined $args{older_than};

    my $now = defined $args{now} ? $args{now} : time;
    my @selected;

    for my $run (@$runs) {
        my @logs = grep {
            $now - $_->{mtime} >= $args{older_than}
        } @{ $run->{logs} };

        next unless @logs;
        push @selected, { %$run, logs => \@logs };
    }

    return \@selected;
}

# The words are shared with the cache listing, which reports an image's age
# the same way.  The largest whole unit is used, so 90 minutes is an hour ago
# and 23 hours is still hours rather than a day.
sub format_age {
    return App::Actions::Cache::format_age($_[0]);
}

# Purpose:     the first line of a listing or a prune, naming the directory.
# Entry:       $self - a Logs.
# Exit:        the line, with its newline.
# Side effects: none.
sub _heading_line {
    my ($self) = @_;

    return __PACKAGE__->i18n('logs.directory', { directory => $self->{directory} }) . "\n";
}

# Purpose:     what a listing or a prune says when it selected nothing: that
#              no log is old enough when there are logs, or that none has
#              been kept at all.
# Entry:       $self - a Logs; $older_than - seconds, or undef.
# Exit:        the sentence, with its newline.
# Side effects: none.
sub _nothing_selected {
    my ($self, $older_than) = @_;

    my $text = (defined $older_than && @{ $self->entries })
        ? __PACKAGE__->i18n('logs.none_older', {
            span => App::Actions::Cache::format_span($older_than),
        })
        : __PACKAGE__->i18n('logs.empty');

    return "$text\n";
}

# The listing: one line per kept job log, with the size it takes and how long
# ago the run wrote it.  Everything is read from the files themselves, so a
# log removed outside the tool simply stops being listed.
sub report {
    my ($self, %args) = @_;

    my $now = defined $args{now} ? $args{now} : time;
    my $older_than = $args{older_than};
    my $runs = $self->_selected_runs(
        older_than => $older_than, now => $now,
    );

    my $out = $self->_heading_line;

    my @rows;
    for my $run (@$runs) {
        for my $log (@{ $run->{logs} }) {
            push @rows, [ $run->{name}, $log->{name}, $log->{size},
                format_age($now - $log->{mtime}) ];
        }
    }

    unless (@rows) {
        return $out . $self->_nothing_selected($older_than);
    }

    $out .= __PACKAGE__->i18n('logs.only_older', {
        span => App::Actions::Cache::format_span($older_than),
    }) . "\n" if defined $older_than;

    # Each column is as wide as its widest entry or its heading, whichever
    # is longer, so a translated heading still lines up.
    my %heading = map { $_ => __PACKAGE__->i18n("logs.heading.$_") }
        qw(run log size age);
    my ($run_width, $log_width) = (length $heading{run}, length $heading{log});
    for my $row (@rows) {
        $run_width = length $row->[0] if length $row->[0] > $run_width;
        $log_width = length $row->[1] if length $row->[1] > $log_width;
    }

    my $total = 0;
    $total += $_->[2] for @rows;

    $out .= "\n";
    $out .= sprintf(
        "  %-*s  %-*s  %10s  %s\n",
        $run_width, $heading{run}, $log_width, $heading{log},
        $heading{size}, $heading{age},
    );
    for my $row (@rows) {
        $out .= sprintf(
            "  %-*s  %-*s  %10s  %s\n",
            $run_width, $row->[0], $log_width, $row->[1],
            App::Actions::Cache::format_size($row->[2]), $row->[3],
        );
    }

    $out .= "\n" . __PACKAGE__->i18n('logs.summary', {
        count => scalar @rows, size => App::Actions::Cache::format_size($total),
    }) . "\n";
    $out .= __PACKAGE__->i18n('logs.prune_hint') . "\n";

    return $out;
}

# Remove every selected log, and the run directory once that is empty.  Only a
# file that matched the listing is unlinked, so a note left in a run directory
# survives, and a newer log keeps its run directory even when the older logs
# beside it went.  A directory named another way is never touched.  A removal
# that fails is reported and leaves the rest of the prune to carry on, with
# exit 1.
sub prune {
    my ($self, %args) = @_;

    my $now = defined $args{now} ? $args{now} : time;
    my $older_than = $args{older_than};
    my $runs = $self->_selected_runs(
        older_than => $older_than, now => $now,
    );
    my $out = $self->_heading_line;

    unless (@$runs) {
        my $data = { removed => 0, freed => 0, failed => [] };
        return ($out . $self->_nothing_selected($older_than), 0, $data);
    }

    my ($removed, $freed) = (0, 0);
    my @failed;

    for my $run (@$runs) {
        # Each log is counted as it goes, so one that was removed before
        # another in the same run failed is still reported as removed.
        my $error;
        for my $log (@{ $run->{logs} }) {
            if ($self->_unlink($log->{path})) {
                $removed++;
                $freed += $log->{size};
                next;
            }
            $error = "cannot remove '$log->{path}': $!";
            last;
        }

        if (defined $error) {
            push @failed, { run => $run->{name}, error => $error };
            next;
        }

        # A directory holding something else is left in place; its logs are
        # gone, so the next listing has nothing to say about it.
        rmdir $run->{directory};
    }

    $out .= __PACKAGE__->i18n('logs.removed', {
        count => $removed, size => App::Actions::Cache::format_size($freed),
    }) . "\n" if $removed;

    my $data = { removed => $removed, freed => $freed, failed => \@failed };

    if (@failed) {
        $out .= __PACKAGE__->i18n('logs.remove_failed', { count => scalar @failed }) . "\n";
        $out .= "  $_->{run}: $_->{error}\n" for @failed;
        return ($out, 1, $data);
    }

    return ($out, 0, $data);
}

# The machine-readable form of the listing, or of a prune that was just run.
# A listing is a flat array like the cache document's images, because a caller
# asserting on it wants the logs rather than the directory tree.  Every key is
# always present and the totals count what the array holds, so an empty
# directory is three zeroes rather than missing keys.  The document is checked
# against the schema this module ships before it is returned.
sub document {
    my ($self, %args) = @_;

    my $now = defined $args{now} ? $args{now} : time;
    my $runs = $self->_selected_runs(
        older_than => $args{older_than}, now => $now,
    );
    my @logs;
    my ($count, $size) = (0, 0);

    for my $run (@$runs) {
        for my $log (@{ $run->{logs} }) {
            my $age = $now - $log->{mtime};
            $age = 0 if $age < 0;

            push @logs, {
                run   => $run->{name},
                name  => $log->{name},
                path  => $log->{path},
                size  => $log->{size} + 0,
                mtime => $log->{mtime} + 0,
                age   => $age + 0,
            };
            $count++;
            $size += $log->{size};
        }
    }

    my $document = {
        schema_version => $JSON_SCHEMA_VERSION,
        generated_at   => $now + 0,
        logs_directory => $self->{directory},
        logs           => \@logs,
        totals         => {
            runs  => scalar @$runs,
            logs  => $count,
            size  => $size,
        },
        prune => $args{prune},
    };

    App::Actions::Schema::assert_valid(
        $document, $self->json_schema,
        'the action-run logs --json document does not match App::Actions::Logs->json_schema',
    );

    return $document;
}

# The one place a log file is removed, so a test can make the filesystem say
# no without changing permissions that mean different things on another host.
sub _unlink {
    my (undef, $path) = @_;
    return unlink $path;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Logs - list and remove the job logs that action-run keeps

=head1 SYNOPSIS

List the kept logs (this is C<action-run logs>):

    use App::Actions::Logs;

    my $logs = App::Actions::Logs->new;
    print $logs->report;

Remove every kept log (C<action-run logs --prune>):

    my ($text, $status, $pruned) = $logs->prune;
    print $text;
    exit $status;

Remove only logs older than two days:

    my ($text, $status) = $logs->prune(older_than => 2 * 24 * 60 * 60);

Get the listing as data for a program (C<action-run logs --json>):

    use JSON::PP;

    my $document = $logs->document;
    print JSON::PP->new->canonical->encode($document), "\n";

Use another directory:

    my $logs = App::Actions::Logs->new(directory => '/var/tmp/my-logs');

=head1 DESCRIPTION

When C<action-run> runs several jobs at the same time, each job writes its
output to its own log file.  After the run, these files are copied to a
I<log directory>, one folder per run, so you can read a failure (or attach
it to a bug report) after the containers are gone.  This module lists those
files and removes them when you ask.

The log directory is:

=over 4

=item * C<ACTION_RUN_LOG_DIR>, if that environment variable is set and not
empty;

=item * otherwise C<action-run/logs> inside your cache directory:
C<$XDG_CACHE_HOME>, or F<~/.cache> on Unix, or C<%LOCALAPPDATA%> on
Windows.

=back

B<Only names that action-run writes are touched.>  A run folder must be named
like C<20261021-121355-6ad8e4c30f83> (date, time, hexadecimal number), and a
log like C<job-2-test.log>.  Symbolic links are skipped.  So if the log
directory is shared with other files, they are never listed or removed.

=head1 METHODS

=head2 default_directory

    my $directory = App::Actions::Logs::default_directory();

Returns the log directory described above.  The runner uses the same
function, so the runs and this module always agree.

=head3 ARGUMENTS

None.

=head3 RETURNS

A path.  It may not exist yet.

=head3 SIDE EFFECTS

Reads C<ACTION_RUN_LOG_DIR> and the cache directory variables.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 new

    my $logs = App::Actions::Logs->new(directory => $path);

Makes an object for one log directory.  Nothing is read yet.

=head3 ARGUMENTS

=over 4

=item * C<directory> - optional.  Default L</default_directory>.

=back

=head3 RETURNS

The new object.

=head3 SIDE EFFECTS

None.

=head3 API SPECIFICATION

=head4 INPUT

    { directory => { type => 'string', optional => 1 } }

=head4 OUTPUT

    { type => 'object', isa => 'App::Actions::Logs' }

=head3 MESSAGES

None.

=head2 directory

    my $path = $logs->directory;

Returns the log directory this object reads.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 entries

    my $runs = $logs->entries;

Reads the log directory.

=head3 ARGUMENTS

None.

=head3 RETURNS

An array reference of runs, newest first.  Each run is a hash reference:
C<name> (the folder name), C<directory> (its full path) and C<logs>.  C<logs>
is an array reference of hash references, sorted by name, each with C<name>,
C<path>, C<size> (bytes) and C<mtime> (when it was last written, in seconds
since 1970).  A run with no logs is not listed.  If the log directory does
not exist, the list is empty.

=head3 SIDE EFFECTS

Reads the file system.

=head3 EXAMPLE

    for my $run (@{ $logs->entries }) {
        printf "%s: %d logs\n", $run->{name}, scalar @{ $run->{logs} };
    }

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'arrayref' }

=head3 MESSAGES

    +--------------------------------------------+-------------------------+----------------------+
    | Exception (croak)                          | Meaning                 | What to do           |
    +--------------------------------------------+-------------------------+----------------------+
    | cannot read the log directory 'DIR': ERR   | the folder exists but   | fix its permissions  |
    |                                            | cannot be read          |                      |
    +--------------------------------------------+-------------------------+----------------------+

=head2 report

    print $logs->report(%options);

Makes the text that C<action-run logs> prints: one row per log (run, file,
size and age), then the number of logs and the space they take.

=head3 ARGUMENTS

=over 4

=item * C<older_than> - optional.  Seconds.  List only logs at least this
old.

=item * C<now> - optional.  The current time, in seconds since 1970.  For
tests.

=back

=head3 RETURNS

The text, ending with a newline.

=head3 SIDE EFFECTS

Reads the file system.

=head3 EXAMPLE

    print $logs->report(older_than => 7 * 24 * 60 * 60);    # logs older than a week

=head3 API SPECIFICATION

=head4 INPUT

    {
        older_than => { type => 'integer', min => 0, optional => 1 },
        now        => { type => 'integer', optional => 1 },
    }

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

As for L</entries>.  The text says C<No job logs have been kept yet.> or
C<No job logs are older than ...> when there is nothing to list.

=head2 prune

    my ($text, $status, $pruned) = $logs->prune(%options);

Removes the selected logs.  A run folder is removed too when it becomes
empty.

=head3 ARGUMENTS

=over 4

=item * C<older_than> - optional.  Seconds.  Remove only logs at least this
old.  Without it, every log is removed.

=item * C<now> - optional.  The current time, for tests.

=back

=head3 RETURNS

A list of three values:

=over 4

=item 1. the text to print;

=item 2. the exit status: 0 if every selected log was removed, 1 if one
could not be (the others are still removed);

=item 3. a hash reference for the JSON document: C<removed> (how many logs),
C<freed> (bytes) and C<failed> (an array of C<{ run, error }>).

=back

=head3 SIDE EFFECTS

Deletes files and empty folders.  A folder that still holds other files
stays.

=head3 EXAMPLE

    my ($text, $status, $pruned) = $logs->prune(older_than => 86_400);
    my $document = $logs->document(prune => $pruned);

=head3 API SPECIFICATION

=head4 INPUT

    {
        older_than => { type => 'integer', min => 0, optional => 1 },
        now        => { type => 'integer', optional => 1 },
    }

=head4 OUTPUT

    { type => 'array', min => 3, max => 3 }    # (string, 0 or 1, hashref)

=head3 MESSAGES

    +----------------------------------------------+------------------------------+---------------------+
    | Text                                         | Meaning                      | What to do          |
    +----------------------------------------------+------------------------------+---------------------+
    | Removed N logs, SIZE freed.                  | success                      |                     |
    | Could not remove N runs:                     | a file could not be deleted; | fix permissions and |
    |   RUN: cannot remove 'PATH': ERR             | status 1                     | prune again         |
    +----------------------------------------------+------------------------------+---------------------+

=head2 document

    my $document = $logs->document(%options);

Returns the listing as data: the document C<action-run logs --json> prints.

=head3 ARGUMENTS

=over 4

=item * C<older_than> - optional.  As for L</report>.

=item * C<prune> - optional.  The third value L</prune> returned, to
describe a prune that just happened.

=item * C<now> - optional.  The current time.  It becomes C<generated_at>.

=back

=head3 RETURNS

A hash reference, described in L</JSON OUTPUT>.

=head3 SIDE EFFECTS

Reads the file system.  Checks the document against L</json_schema>.

=head3 API SPECIFICATION

=head4 INPUT

    {
        older_than => { type => 'integer', min => 0, optional => 1 },
        prune      => { type => 'hashref', optional => 1 },
        now        => { type => 'integer', optional => 1 },
    }

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

    +-------------------------------------------+------------------------------+------------------+
    | Exception                                 | Meaning                      | What to do       |
    +-------------------------------------------+------------------------------+------------------+
    | App::Actions::Schema::Invalid: the        | a bug: the document does not | report it; exit  |
    | action-run logs --json document does not  | match its schema             | status 70        |
    | match App::Actions::Logs->json_schema: ...|                              |                  |
    +-------------------------------------------+------------------------------+------------------+

And the messages of L</entries>.

=head2 json_schema

    my $schema = App::Actions::Logs->json_schema;

Returns the JSON schema of the C<logs --json> document, as a new hash
reference.  C<action-run schema logs> prints the same schema.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

None.

=head2 json_schema_version

    my $version = App::Actions::Logs->json_schema_version;

Returns the version of the document's shape, which the document also
carries as C<schema_version>.  It goes up whenever the shape changes.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', min => 1 }

=head3 MESSAGES

None.

=head2 format_age

    my $words = App::Actions::Logs::format_age($seconds);

Says how old something is, in words: C<just now>, C<3 minutes ago>, C<2
hours ago>, C<5 days ago>, C<2 months ago> or C<1 year ago>.  It uses the
largest whole unit, so 90 minutes is C<1 hour ago>.  These are the
English words; another language of L<App::Actions::I18N> says it its own way.

=head3 ARGUMENTS

=over 4

=item * C<$seconds> - the age.  A negative age (a clock ahead) is C<just
now>.

=back

=head3 RETURNS

The words.

=head3 SIDE EFFECTS

None.

=head3 API SPECIFICATION

=head4 INPUT

    { seconds => { type => 'integer' } }

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head1 JSON OUTPUT

L</document> returns one object.  Every key is always there:

    {
      "schema_version": 3,
      "generated_at": 1792540920,
      "logs_directory": "/home/me/.cache/action-run/logs",
      "logs": [
        { "run": "20261021-121355-6ad8e4c30f83", "name": "job-1-test_n_one.log",
          "path": "/home/me/.cache/action-run/logs/20261021-121355-6ad8e4c30f83/job-1-test_n_one.log",
          "size": 1229, "mtime": 1792540800, "age": 120 }
      ],
      "totals": { "runs": 1, "logs": 1, "size": 1229 },
      "prune": null
    }

=over 4

=item * C<generated_at> and C<mtime> are seconds since 1970.

=item * C<age> is C<generated_at> minus C<mtime>, in seconds, so you do not
need your own clock.  It is 0 (not negative) if the log's time is in the
future.

=item * C<size> is in bytes.

=item * C<logs> lists the newest run first, and each run's logs by name.

=item * C<totals> counts the runs, logs and bytes in C<logs>.  With
C<older_than>, only the selected logs are counted.

=item * C<prune> is C<null> for a listing.  After a prune it is an object
with C<removed>, C<freed> and C<failed>; each failed run has C<run> and
C<error>.  The document is printed even when a removal failed, and the exit
status is then 1.

=back

C<action-run schema logs> prints the schema.  The examples in
F<t/fixtures/logs.json>, F<logs-empty.json>, F<logs-prune.json> and
F<logs-prune-failed.json> are checked against it by F<t/schema.t>.

=head1 COMMON PITFALLS

=over 4

=item * B<Only parallel runs keep logs.>  A run of one job at a time prints
to the terminal and keeps nothing here.

=item * B<C<older_than> is in seconds.>  Two days is C<2 * 24 * 60 * 60>,
not C<2>.

=item * B<C<prune> returns a list.>  C<my $text = $logs-E<gt>prune> gives the
I<last> value (the hash), not the text.  Write C<my ($text, $status, $data)
= ...>.

=item * B<Renamed files are invisible.>  If you rename a log or a run
folder, it no longer matches the names this module looks for, so it is
neither listed nor removed.

=item * B<Pruning does not ask.>  Without C<older_than>, it removes every
log.  Call L</report> first to see what will go.

=item * B<A failed removal does not stop the prune.>  Check the status: 1
means some logs are still there.

=back

=head1 ENCODING

Run and log names are ASCII by construction (job names are made safe before
they are used in file names).  The log directory path may contain any
characters your system allows, including non-ASCII and emoji; it is used and
reported as bytes.  The log files themselves are read only for their size
and time, never for their content.  The text that L</report> and L</prune>
return, and the words of L</format_age>, are in the current language of
L<App::Actions::I18N> and may contain non-ASCII characters; encode them
when you print.  The JSON document is never translated.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞFileSystem> means the routine changes
no file.  The lines below the rule are always true when the routine
returns.

    [PATH, NAME]
    RUNNAME == { n : NAME | n matches \d{8}-\d{6}-[0-9a-fA-F]+ }
    LOGNAME == { n : NAME | n matches job-\d+(-[A-Za-z0-9_.-]+)?\.log }
    Log ≙ [ name : LOGNAME; path : PATH; size, mtime : ℕ ]
    Run ≙ [ name : RUNNAME; directory : PATH; logs : seq₁ Log ]

    ┌─ Logs ────────────────────────────────────────────
    │ directory : PATH
    └───────────────────────────────────────────────────

    selected(older, now) = { r : entries • r with logs restricted to
        { l | older = ⊥ ∨ now − l.mtime ≥ older } } \ { runs with no logs }

=head2 default_directory

    ┌─ DefaultDirectory ────────────────────────────────
    │ r! : PATH
    ├───────────────────────────────────────────────────
    │ ENV.ACTION_RUN_LOG_DIR ∉ {⊥, ⟨⟩} ⇒ r! = ENV.ACTION_RUN_LOG_DIR
    │ otherwise r! = cacheBase ⁀ "/action-run/logs"
    └───────────────────────────────────────────────────

=head2 new

    ┌─ New ─────────────────────────────────────────────
    │ Logs'
    │ directory? : optional PATH
    ├───────────────────────────────────────────────────
    │ directory' = if directory? ∈ {⊥, ⟨⟩} then default_directory else directory?
    └───────────────────────────────────────────────────

=head2 directory

    ┌─ Directory ───────────────────────────────────────
    │ ΞLogs
    │ r! : PATH
    ├───────────────────────────────────────────────────
    │ r! = directory
    └───────────────────────────────────────────────────

=head2 entries

    ┌─ Entries ─────────────────────────────────────────
    │ ΞLogs ∧ ΞFileSystem
    │ r! : seq Run
    ├───────────────────────────────────────────────────
    │ directory ∉ DIRS ⇒ r! = ⟨⟩
    │ ∀ r ∈ ran r! • r.name ∈ RUNNAME ∧ r.directory is a real directory
    │     ∧ ∀ l ∈ ran r.logs • l.name ∈ LOGNAME ∧ l.path is a real file
    │ r! is sorted by name, descending; each r.logs by name, ascending
    │ unreadable directory ⇒ raises CannotRead(directory)
    └───────────────────────────────────────────────────

=head2 report

    ┌─ Report ──────────────────────────────────────────
    │ ΞLogs ∧ ΞFileSystem
    │ older? : optional ℕ
    │ now?   : optional ℕ
    │ r!     : TEXT
    ├───────────────────────────────────────────────────
    │ one row in r! for each log of selected(older?, now?)
    │ selected = ⟨⟩ ⇒ r! says that nothing is kept or nothing is old enough
    └───────────────────────────────────────────────────

=head2 prune

    ┌─ Prune ───────────────────────────────────────────
    │ ΔFileSystem
    │ older? : optional ℕ
    │ r!     : TEXT × {0, 1} × DATA
    ├───────────────────────────────────────────────────
    │ S = selected(older?, now)
    │ ∀ r ∈ S • (∀ l ∈ ran r.logs • l.path ∉ files') ∨ r ∈ failed
    │ ∀ r ∈ S • r.directory empty after removal ⇒ r.directory ∉ dirs'
    │ files not in S are unchanged
    │ second(r!) = 0 ⇔ failed = ∅
    │ gone = { l | r ∈ S ∧ l ∈ ran r.logs ∧ l.path ∉ files' }
    │ third(r!).removed = #gone
    │ third(r!).freed = Σ { l.size | l ∈ gone }
    └───────────────────────────────────────────────────

=head2 document

    ┌─ Document ────────────────────────────────────────
    │ ΞLogs ∧ ΞFileSystem
    │ older?, now? : optional ℕ
    │ prune?       : optional DATA
    │ d!           : DATA
    ├───────────────────────────────────────────────────
    │ d!.generated_at = now?
    │ d!.logs = ⟨ l with run, age = max(0, now? − l.mtime) |
    │             l ∈ logs of selected(older?, now?) ⟩
    │ d!.totals = (#selected, #d!.logs, Σ size)
    │ d!.prune = prune?
    │ matches(d!, json_schema) ∨ raises Invalid
    └───────────────────────────────────────────────────

=head2 json_schema

    ┌─ JsonSchema ──────────────────────────────────────
    │ r! : SCHEMA
    ├───────────────────────────────────────────────────
    │ r! = decode(JSON_SCHEMA) ∧ r! is a new object
    └───────────────────────────────────────────────────

=head2 json_schema_version

    ┌─ JsonSchemaVersion ───────────────────────────────
    │ r! : ℕ₁
    ├───────────────────────────────────────────────────
    │ r! = JSON_SCHEMA_VERSION
    └───────────────────────────────────────────────────

=head2 format_age

    ┌─ FormatAge ───────────────────────────────────────
    │ seconds? : ℤ
    │ r!       : TEXT
    ├───────────────────────────────────────────────────
    │ r! = App::Actions::Cache::format_age(seconds?)
    └───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The object holds only a directory name.  The states below are the states of
one kept log file, from the run that writes it to the prune that removes
it:

     parallel run of action-run
              |
              | job writes its output; the run copies it to
              | LOGDIR/<date>-<time>-<hex>/job-N-<name>.log
              v
     +------------------+   entries / report / document   +------------------+
     |      KEPT        |-------------------------------->|  LISTED          |
     | (on disk)        |<--------------------------------|  (nothing        |
     +------------------+          (no change)             |   changes)       |
         |         |                                       +------------------+
         |         | prune(older_than => N) and the log is newer than N
         |         +----------------------------------------> stays KEPT
         |
         | prune(), or prune(older_than => N) and the log is at least N old
         v
     +------------------+   unlink fails     +-------------------------------+
     |   REMOVING       |------------------->| FAILED: stays on disk; its run |
     +------------------+                    | is in "failed"; status 1       |
         |                                   +-------------------------------+
         | unlink succeeds
         v
     +------------------+   run folder now empty    +------------------+
     |   REMOVED        |-------------------------->| run folder       |
     |   (counted in    |                           | removed too      |
     |    removed/freed)|   folder holds other files+------------------+
     +------------------+-------------------------->  folder stays

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
