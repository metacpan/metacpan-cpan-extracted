package App::Actions::Cache;

use strict;
use warnings;
use Carp qw(croak);
use File::Basename qw(dirname);
use File::Path qw(make_path);
use File::Spec;
use File::Temp ();
use JSON::PP ();

use App::Actions::I18N qw(i18n);
use App::Actions::Schema ();

our $VERSION = '0.001.0';

# The images action-run keeps are a cache: a run records what it pulled, so a
# later command can list the images and say how much disk they take, and
# remove them when they are no longer wanted.  The record holds names only -
# the size is asked of the daemon each time, because an image can be removed
# or replaced behind the tool's back.

my $FORMAT = 1;

# The shape of the JSON document this module prints.  Bump it whenever a key,
# a value type or an enum changes, and update the schema below and the examples
# in t/fixtures/ with it; a CI job asserts the number rather than discovering
# a changed shape at the point where its assertion fails for another reason.
our $JSON_SCHEMA_VERSION = 3;

# The schema of the document cache --json prints, so that the installed
# action-run can hand the contract to a caller instead of leaving it in the
# tests.  A change to the document belongs here, in $JSON_SCHEMA_VERSION and
# in the examples in t/fixtures/, which t/schema.t holds against this and
# fails when a key it names appears in none of them.
my $JSON_SCHEMA = <<'JSON';
{
  "title": "action-run cache --json",
  "description": "The document action-run cache --json prints.  Objects reject keys this file does not name, so a new key is a schema change.",
  "version": 3,
  "type": "object",
  "properties": {
    "schema_version": {
      "description": "The version of this shape; App::Actions::Cache->json_schema_version returns it.",
      "type": "integer",
      "const": 3
    },
    "generated_at": {
      "description": "The epoch second the document was made; an image's age is generated_at minus its last_used.",
      "type": "integer"
    },
    "cache_file": {
      "description": "The record the images were read from, and that --prune changed.",
      "type": "string"
    },
    "docker": {
      "description": "The Docker command and whether it could be reached.",
      "type": "object",
      "properties": {
        "bin": { "type": "string" },
        "reachable": { "type": "boolean" }
      },
      "required": [ "bin", "reachable" ]
    },
    "images": {
      "description": "Every image the command selected, sorted by name; a listing without --older-than selects the whole record.",
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "image": { "type": "string" },
          "pulls": {
            "description": "How many runs pulled and kept the image.",
            "type": "integer"
          },
          "last_used": {
            "description": "When a run last used the image, in epoch seconds, or null in a record written without it.",
            "type": [ "integer", "null" ]
          },
          "age": {
            "description": "The seconds between generated_at and last_used, or null when last_used is unknown; 0 when last_used is later than generated_at.",
            "type": [ "integer", "null" ]
          },
          "size": {
            "description": "The bytes the daemon reports, or null when it could not report one.",
            "type": [ "integer", "null" ]
          },
          "present": {
            "description": "Whether the daemon has the image, or null when the daemon could not be reached.",
            "type": [ "boolean", "null" ]
          }
        },
        "required": [ "image", "pulls", "last_used", "age", "size", "present" ]
      }
    },
    "totals": {
      "description": "The selected images and the disk they take.  The size and the counts are null when the daemon could not be reached.",
      "type": "object",
      "properties": {
        "images": { "type": "integer" },
        "size": { "type": [ "integer", "null" ] },
        "present": { "type": [ "integer", "null" ] },
        "missing": { "type": [ "integer", "null" ] }
      },
      "required": [ "images", "size", "present", "missing" ]
    },
    "prune": {
      "description": "What --prune did to the images --older-than selected, or null when the command only listed the record.",
      "oneOf": [
        { "type": "null" },
        {
          "type": "object",
          "properties": {
            "removed": { "type": "integer" },
            "freed": { "type": "integer" },
            "forgotten": { "type": "integer" },
            "failed": {
              "type": "array",
              "items": { "type": "string" }
            }
          },
          "required": [ "removed", "freed", "forgotten", "failed" ]
        }
      ]
    }
  },
  "required": [
    "schema_version",
    "generated_at",
    "cache_file",
    "docker",
    "images",
    "totals",
    "prune"
  ]
}
JSON

sub json_schema {
    return JSON::PP->new->decode($JSON_SCHEMA);
}

sub json_schema_version { return $JSON_SCHEMA_VERSION }

# The per-user directory action-run keeps its own state in: the image cache
# record and the logs of a run.  XDG_CACHE_HOME is where a Linux or macOS
# desktop puts that, and LOCALAPPDATA where Windows does.
sub base_directory {
    my $base;
    if ($^O eq 'MSWin32') {
        $base = $ENV{LOCALAPPDATA};
        if (!defined $base || !length $base) {
            $base = File::Spec->catdir($ENV{USERPROFILE}, 'AppData', 'Local')
                if defined $ENV{USERPROFILE} && length $ENV{USERPROFILE};
        }
    } else {
        $base = $ENV{XDG_CACHE_HOME};
        $base = File::Spec->catdir($ENV{HOME}, '.cache')
            if !defined $base || !length $base;
    }

    $base = File::Spec->catdir(File::Spec->curdir, '.cache')
        if !defined $base || !length $base;

    return $base;
}

sub default_path {
	my $override = $ENV{ACTION_RUN_CACHE_FILE};

    # An empty variable is the same as an unset one.
    return (defined $override && length $override)
        ? $override
        : File::Spec->catfile(base_directory(), 'action-run', 'cache.json');
}

sub new {
	my ($class, %args) = @_;

	my $file = $args{file};
	$file = default_path() if !defined $file || !length $file;

	return bless { file => $file, data => undef }, $class;
}

sub file { return $_[0]->{file} }

sub load {
	my ($self) = @_;

	return $self->{data} if $self->{data};

    my $images = {};
    my $path   = $self->{file};

    if (-e $path) {
        my $text = '';
        if (open my $handle, '<', $path) {
            binmode $handle;
            $text = do { local $/; <$handle> };
            close $handle;
        }
        $text = '' unless defined $text;

        # A cache that cannot be read is not worth failing a run over: the
        # images are still there, and the next run records them again.
        my $decoded = eval { JSON::PP->new->decode($text) };
        if ($decoded && ref $decoded eq 'HASH' && ref $decoded->{images} eq 'HASH') {
            for my $image (keys %{ $decoded->{images} }) {
                my $entry = $decoded->{images}{$image};
                next unless ref $entry eq 'HASH';
                $images->{$image} = {
                    pulls     => $entry->{pulls} || 0,
                    last_used => $entry->{last_used},
                };
            }
        }
    }

    return $self->{data} = { version => $FORMAT, images => $images };
}

sub save {
    my ($self) = @_;

    my $data = $self->{data} || $self->load;
    my $path = $self->{file};

    # Nothing cached means nothing to remember, so the file goes away rather
    # than staying behind as an empty document.
    if (!keys %{ $data->{images} }) {
        unlink $path if -e $path;
        return 1;
    }

    my $dir = dirname($path);
    make_path($dir) unless -d $dir;

    # The new contents go to a file File::Temp creates exclusively, with a
    # name nobody can predict, and replace the old by rename.  A name made of
    # the PID and rand() can be guessed, and open '>' follows a symbolic link
    # someone placed there, so in a shared directory (ACTION_RUN_CACHE_FILE
    # can point anywhere) the write would land in whatever file it named.
    my $handle = eval {
        File::Temp->new(TEMPLATE => '.cache-XXXXXXXXXX', DIR => $dir, SUFFIX => '.tmp', UNLINK => 0);
    } or croak "cannot write a new cache file in '$dir': " . (length $@ ? $@ =~ s/\s+\z//r : 'unknown error');
    my $temp = $handle->filename;
    binmode $handle;
    print {$handle} JSON::PP->new->canonical->pretty->encode($data);
    close $handle or croak "cannot write '$temp': $!";

    if (!rename $temp, $path) {
        my $error = $!;
        unlink $temp;
        croak "cannot replace '$path': $error";
    }

    return 1;
}

# Record images this run pulled and kept.  Pulling the same image again later
# counts as another use, which is what "last used" reports.
sub remember {
    my ($self, @images) = @_;

    my $data = $self->load;
    my $now  = time;
    my $count = 0;

    for my $image (@images) {
        next unless defined $image && length $image;

        my $entry = $data->{images}{$image} || {};
        $entry->{pulls}     = ($entry->{pulls} || 0) + 1;
        $entry->{last_used} = $now;
        $data->{images}{$image} = $entry;
        $count++;
    }

    $self->save if $count;

    return $count;
}

sub entries {
    my ($self) = @_;

    my $images = $self->load->{images};

    return [
        map {
            {
                image     => $_,
                pulls     => $images->{$_}{pulls} || 0,
                last_used => $images->{$_}{last_used},
            }
        } sort keys %{$images}
    ];
}

# Forget images without touching the daemon: they are no longer there, or the
# user asked for them to be dropped from the record.
sub forget {
    my ($self, @images) = @_;

    my $data = $self->load;
    my $count = 0;

    for my $image (@images) {
        next unless defined $image;
        $count++ if delete $data->{images}{$image};
    }

	$self->save if $count;

	return $count;
}

sub format_size {
	my ($bytes) = @_;

	return '0 B' unless defined $bytes && $bytes > 0;

    my @units = qw(B KB MB GB TB);
    my $value = $bytes;
    my $unit  = 0;
    while ($value >= 1024 && $unit < $#units) {
        $value /= 1024;
        $unit++;
    }

    return sprintf('%d %s', $value, $units[$unit]) unless $unit;
    return sprintf('%.1f %s', $value, $units[$unit]);
}

my %DURATION_SECONDS = (
    s       => 1,
    sec     => 1,
    secs    => 1,
    second  => 1,
    seconds => 1,
    m       => 60,
    min     => 60,
    mins    => 60,
    minute  => 60,
    minutes => 60,
    h       => 60 * 60,
    hr      => 60 * 60,
    hrs     => 60 * 60,
    hour    => 60 * 60,
    hours   => 60 * 60,
    d       => 60 * 60 * 24,
    day     => 60 * 60 * 24,
    days    => 60 * 60 * 24,
    w       => 60 * 60 * 24 * 7,
    week    => 60 * 60 * 24 * 7,
    weeks   => 60 * 60 * 24 * 7,
    mo      => 60 * 60 * 24 * 30,
    month   => 60 * 60 * 24 * 30,
    months  => 60 * 60 * 24 * 30,
    y       => 60 * 60 * 24 * 365,
    yr      => 60 * 60 * 24 * 365,
    yrs     => 60 * 60 * 24 * 365,
    year    => 60 * 60 * 24 * 365,
    years   => 60 * 60 * 24 * 365,
);

# A duration is a number and a unit, with the unit matching the words the age
# column uses: 30s, 15m, 12h, 7d, 2w, 3mo or 1y.  Months and years are the
# 30- and 365-day spans format_age uses, so a threshold and the ages it filters
# cannot disagree about what "2 months" means.
sub parse_duration {
    my ($text) = @_;

    return unless defined $text;
    return unless $text =~ /\A\s*(\d+)\s*([A-Za-z]+)\s*\z/;

    my ($amount, $unit) = ($1, lc $2);
    return unless exists $DURATION_SECONDS{$unit};

    return $amount * $DURATION_SECONDS{$unit};
}

sub format_span {
    my ($seconds) = @_;

    $seconds = 0 unless defined $seconds && $seconds =~ /\A-?\d+\z/;
    $seconds = 0 if $seconds < 0;

    my @units = (
        [ 1,                 'second' ],
        [ 60,                'minute' ],
        [ 60 * 60,           'hour'   ],
        [ 60 * 60 * 24,      'day'    ],
        [ 60 * 60 * 24 * 30, 'month'  ],
        [ 60 * 60 * 24 * 365, 'year'  ],
    );

    # The largest whole unit is used, so 90 minutes is an hour and 40 days is
    # a month, whether the number is an age or a threshold.
    my ($index, $amount) = (0, int($seconds / $units[0][0]));
    for my $next (1 .. $#units) {
        last if $seconds < $units[$next][0];
        $index  = $next;
        $amount = int($seconds / $units[$next][0]);
    }

    # The catalogue holds the singular and plural of each unit, so another
    # language's plural rule decides the form rather than an English "s".
    return __PACKAGE__->i18n("span.$units[$index][1]", { count => $amount });
}

# How old a kept image is, in the words a reader expects rather than a second
# count.
sub format_age {
    my ($seconds) = @_;

    $seconds = 0 unless defined $seconds && $seconds =~ /\A-?\d+\z/;
    $seconds = 0 if $seconds < 0;

    return $seconds < 60 ? 'just now' : format_span($seconds) . ' ago';
}

# The entries a threshold selects.  An image with no recorded last use cannot
# be shown to be old enough, so it is left out rather than guessed at; that
# also keeps it in the record when the listing is a prune.
sub _selected_entries {
    my ($self, %args) = @_;

    my $entries = $self->entries;
    return $entries unless defined $args{older_than};

    my $now = defined $args{now} ? $args{now} : time;
    return [
        grep {
            defined $_->{last_used}
                && $now - $_->{last_used} >= $args{older_than}
        } @$entries
    ];
}

sub _stamp {
    my ($epoch) = @_;

    return '-' unless defined $epoch && $epoch =~ /\A\d+\z/;

    my @time = localtime($epoch);
    return sprintf(
        '%04d-%02d-%02d %02d:%02d',
        $time[5] + 1900, $time[4] + 1, $time[3], $time[2], $time[1],
    );
}

# The listing: one line per recorded image, with the size the daemon reports
# and when a run last pulled it.  When the daemon cannot be reached the names
# are still worth printing, so the sizes are left unknown instead of the
# command failing.
sub report {
    my ($self, %args) = @_;

    my $docker = $args{docker};
    my $now = defined $args{now} ? $args{now} : time;
    my $older_than = $args{older_than};
    my $entries = $self->_selected_entries(
        older_than => $older_than, now => $now,
    );

    my $out = "Cache file: $self->{file}\n";

    if (!@$entries) {
        if (defined $older_than && @{ $self->entries }) {
            return $out . 'No cached images are older than '
                . format_span($older_than) . ".\n";
        }

        return $out . "No images have been cached yet.\n";
    }

    $out .= 'Only images older than ' . format_span($older_than) . ".\n"
        if defined $older_than;

    my $width = 5;
    for my $entry (@$entries) {
        $width = length $entry->{image} if length $entry->{image} > $width;
    }

    my ($total, $sized, $missing) = (0, 0, 0);
    my @lines;

    for my $entry (@$entries) {
        my $size_text = 'unknown';
        if ($docker) {
            my $size = $docker->image_size($entry->{image});
            if (defined $size) {
                $total += $size;
                $sized++;
                $size_text = format_size($size);
            } else {
                $missing++;
                $size_text = 'missing';
            }
        }

        my $age_text = defined $entry->{last_used}
            ? format_age($now - $entry->{last_used})
            : 'unknown';

        push @lines, sprintf(
            '  %-*s  %10s  %-16s  %s',
            $width, $entry->{image}, $size_text, _stamp($entry->{last_used}),
            $age_text,
        );
    }

    $out .= "\n";
    $out .= sprintf(
        "  %-*s  %10s  %-16s  %s\n",
        $width, 'IMAGE', 'SIZE', 'LAST USED', 'AGE',
    );
    $out .= "$_\n" for @lines;

    $out .= "\n" . __PACKAGE__->i18n(
        $sized ? 'cache.summary_sized' : 'cache.summary',
        { count => scalar @$entries, size => format_size($total) },
    ) . "\n";

    if (!$docker) {
        $out .= "The Docker daemon is not reachable, so the sizes are unknown.\n";
    } elsif ($missing) {
        $out .= __PACKAGE__->i18n('cache.missing', { count => $missing }) . "\n";
    }

    $out .= "Remove them with \"action-run cache --prune\".\n" if $sized;

    return $out;
}

# Remove every recorded image.  The daemon is the judge of what is there: an
# image that has already gone is forgotten without an error, and one that
# cannot be removed stays in the record so a later attempt still sees it.
sub prune {
    my ($self, %args) = @_;

    my $docker = $args{docker}
        or croak 'pruning the image cache needs a Docker command';

    my $now = defined $args{now} ? $args{now} : time;
    my $older_than = $args{older_than};
    my $entries = $self->_selected_entries(
        older_than => $older_than, now => $now,
    );

    my $out = "Cache file: $self->{file}\n";
    if (!@$entries) {
        my $data = { removed => 0, freed => 0, forgotten => 0, failed => [] };

        if (defined $older_than && @{ $self->entries }) {
            return (
                $out . 'No cached images are older than '
                    . format_span($older_than) . ".\n",
                0,
                $data,
            );
        }

        return ($out . "No images have been cached yet.\n", 0, $data);
    }

    my ($removed, $freed, $gone) = (0, 0, 0);
    my @failed;
    my @forget;

    for my $entry (@$entries) {
        my $image = $entry->{image};
        my $size  = $docker->image_size($image);

        # A size means the image is there; no size means it is not, or the
        # daemon is gone.  The check that precedes a prune tells the two
        # apart, so a missing image is simply forgotten.
        if (!defined $size) {
            push @forget, $image;
            $gone++;
            next;
        }

        if ($docker->image_remove($image) == 0) {
            push @forget, $image;
            $removed++;
            $freed += $size;
        } else {
            push @failed, $image;
        }
    }

    $self->forget(@forget) if @forget;

    my $data = {
        removed   => $removed,
        freed     => $freed,
        forgotten => $gone,
        failed    => [ @failed ],
    };

    $out .= __PACKAGE__->i18n('cache.removed', { count => $removed, size => format_size($freed) }) . "\n"
        if $removed;
    $out .= __PACKAGE__->i18n('cache.forgot', { count => $gone }) . "\n" if $gone;

    if (@failed) {
        $out .= __PACKAGE__->i18n('cache.remove_failed', { count => scalar @failed }) . "\n";
        $out .= "  $_\n" for @failed;
        return ($out, 1, $data);
    }

    return ($out, 0, $data);
}

# The machine-readable form of the listing, or of a prune that was just run.
# The keys are stable and a value that could not be discovered is null rather
# than absent, so a reader can assert on the shape without a missing key
# meaning something different from an unknown value.
sub document {
    my ($self, %args) = @_;

    my $now   = defined $args{now} ? $args{now} : time;
    my $total = 0;
    my ($present, $missing) = (0, 0);
    my $reachable = $args{reachable} ? 1 : 0;
    my $docker = $args{docker};
    my $entries = $self->_selected_entries(
        older_than => $args{older_than}, now => $now,
    );

    my $bin = $args{docker_bin};
    $bin = $docker->bin
        if (!defined $bin || !length $bin) && $docker;
    $bin = 'docker' unless defined $bin && length $bin;

    my @images;
    for my $entry (@$entries) {
        my ($size, $is_present);

        if ($reachable && $docker) {
            $size = $docker->image_size($entry->{image});
            if (defined $size) {
                $total += $size;
                $present++;
                $is_present = JSON::PP::true();
            } else {
                $missing++;
                $is_present = JSON::PP::false();
            }
        }

        my $age;
        if (defined $entry->{last_used}) {
            $age = $now - $entry->{last_used};
            $age = 0 if $age < 0;
        }

        push @images, {
            image     => $entry->{image},
            pulls     => $entry->{pulls} + 0,
            last_used => $entry->{last_used},
            age       => $age,
            size      => $size,
            present   => $is_present,
        };
    }

    my $document = {
        schema_version => $JSON_SCHEMA_VERSION,
        generated_at   => $now + 0,
        cache_file     => $self->{file},
        docker         => {
            bin       => $bin,
            reachable => $reachable ? JSON::PP::true() : JSON::PP::false(),
        },
        images => \@images,
        totals => {
            images  => scalar @$entries,
            size    => $reachable ? $total : undef,
            present => $reachable ? $present : undef,
            missing => $reachable ? $missing : undef,
        },
        prune => $args{prune},
    };

    App::Actions::Schema::assert_valid(
        $document, $self->json_schema,
        'the action-run cache --json document does not match App::Actions::Cache->json_schema',
    );

    return $document;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Actions::Cache - remember which Docker images action-run downloaded, and remove them

=head1 SYNOPSIS

Record that a run used some images:

    use App::Actions::Cache;

    my $cache = App::Actions::Cache->new;
    $cache->remember('alpine:3.20', 'perl:5.40');

List them with their sizes (this is C<action-run cache>):

    use App::Actions::Docker;

    my $docker = App::Actions::Docker->new;
    print $cache->report(docker => $docker);

Remove the images not used for 30 days (C<action-run cache --prune --older-than 30d>):

    my $seconds = App::Actions::Cache::parse_duration('30d');
    my ($text, $status, $pruned) = $cache->prune(docker => $docker, older_than => $seconds);
    print $text;

Get the listing as data (C<action-run cache --json>):

    my $document = $cache->document(docker => $docker, reachable => 1);

Format sizes and times for people:

    print App::Actions::Cache::format_size(1536);       # 1.5 KB
    print App::Actions::Cache::format_age(3 * 3600);    # 3 hours ago

=head1 DESCRIPTION

When C<action-run> runs a workflow, it downloads (pulls) Docker images and
keeps them, so the next run is faster.  Images can be large, so this module
keeps a record of which images action-run pulled.  Then C<action-run cache>
can list them and C<action-run cache --prune> can remove them.  Images you
pulled yourself are not in the record, so they are never removed.

The record is a small JSON file.  For each image, it holds how many runs
used it and when it was last used.  It does not hold sizes: those are asked
from Docker each time, because an image can be removed or replaced outside
action-run.

The file is:

=over 4

=item * C<ACTION_RUN_CACHE_FILE>, if that environment variable is set and
not empty;

=item * otherwise F<action-run/cache.json> inside your cache directory (see
L</base_directory>).

=back

A missing or broken file counts as empty.  That is safe: the images are
still on the disk, and the next run records them again.

The file is replaced in one step (written to a new temporary file, then
renamed), so a crash never leaves a half-written record.  The new file can
be read only by you.

=head1 METHODS

=head2 base_directory

    my $directory = App::Actions::Cache::base_directory();

Returns your personal cache directory, where action-run keeps its files.

=head3 ARGUMENTS

None.

=head3 RETURNS

On Windows: C<%LOCALAPPDATA%>, or C<%USERPROFILE%\AppData\Local>.
Elsewhere: C<$XDG_CACHE_HOME>, or F<$HOME/.cache>.  If none of these is
set: F<./.cache>.

=head3 SIDE EFFECTS

Reads environment variables.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 default_path

    my $file = App::Actions::Cache::default_path();

Returns the record file described above.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 new

    my $cache = App::Actions::Cache->new(file => $path);

Makes an object for one record file.  The file is not read yet.

=head3 ARGUMENTS

=over 4

=item * C<file> - optional.  Default L</default_path>.

=back

=head3 RETURNS

The new object.

=head3 SIDE EFFECTS

None.

=head3 API SPECIFICATION

=head4 INPUT

    { file => { type => 'string', optional => 1 } }

=head4 OUTPUT

    { type => 'object', isa => 'App::Actions::Cache' }

=head3 MESSAGES

None.

=head2 file

    my $path = $cache->file;

Returns the record file this object uses.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 load

    my $data = $cache->load;

Reads the record file, once.  Later calls return the same data without
reading the file again.

=head3 RETURNS

A hash reference: C<{ version =E<gt> 1, images =E<gt> { NAME =E<gt> { pulls,
last_used } } }>.  A missing or broken file gives no images.

=head3 SIDE EFFECTS

Reads the file the first time.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

None.  A file that cannot be read or parsed is treated as empty.

=head2 save

    $cache->save;

Writes the record file.  If there are no images, the file is deleted
instead.  You rarely need this: L</remember> and L</forget> call it.

=head3 RETURNS

1.

=head3 SIDE EFFECTS

Creates the folder if needed.  Writes a new temporary file (mode 0600) next
to the record and renames it over the record.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', memberof => [ 1 ] }

=head3 MESSAGES

    +-------------------------------------------+---------------------------+----------------------------+
    | Exception (croak)                         | Meaning                   | What to do                 |
    +-------------------------------------------+---------------------------+----------------------------+
    | cannot write a new cache file in 'DIR':   | the folder is not         | fix its permissions, or    |
    | ERR                                       | writable                  | set ACTION_RUN_CACHE_FILE  |
    | cannot write 'TEMP': ERR                  | disk full, or I/O error   | free some space            |
    | cannot replace 'FILE': ERR                | rename failed             | check FILE is not a folder |
    +-------------------------------------------+---------------------------+----------------------------+

=head2 remember

    my $count = $cache->remember(@images);

Records that a run used these images: adds 1 to each one's count and sets
its last use to now.

=head3 ARGUMENTS

=over 4

=item * C<@images> - image names.  C<undef> and empty names are skipped.

=back

=head3 RETURNS

How many images were recorded.

=head3 SIDE EFFECTS

Saves the record file if the count is above 0.

=head3 EXAMPLE

    $cache->remember($_) for @pulled;

=head3 API SPECIFICATION

=head4 INPUT

    { images => { type => 'array', element_type => 'string' } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

As for L</save>.

=head2 entries

    my $entries = $cache->entries;

Lists the recorded images.

=head3 RETURNS

An array reference of hash references, sorted by image name, each with
C<image>, C<pulls> and C<last_used> (seconds since 1970, or C<undef> if not
known).

=head3 SIDE EFFECTS

Reads the record file the first time.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'arrayref' }

=head3 MESSAGES

None.

=head2 forget

    my $count = $cache->forget(@images);

Removes images from the record only.  The images stay in Docker.

=head3 RETURNS

How many of the names were in the record.

=head3 SIDE EFFECTS

Saves the record file (or deletes it, if it is now empty) when the count is
above 0.

=head3 API SPECIFICATION

=head4 INPUT

    { images => { type => 'array', element_type => 'string' } }

=head4 OUTPUT

    { type => 'integer', min => 0 }

=head3 MESSAGES

As for L</save>.

=head2 report

    print $cache->report(%options);

Makes the text C<action-run cache> prints: one row per image with its size,
when it was last used and how long ago, then a total.

=head3 ARGUMENTS

=over 4

=item * C<docker> - optional.  An L<App::Actions::Docker>, to ask for the
sizes.  Without it (for example when Docker is not running), sizes are
C<unknown>.

=item * C<older_than> - optional.  Seconds.  List only images last used at
least this long ago.  An image with no recorded last use is left out.

=item * C<now> - optional.  The current time, for tests.

=back

=head3 RETURNS

The text, ending with a newline.

=head3 SIDE EFFECTS

Asks Docker for each image's size, if C<docker> is given.

=head3 API SPECIFICATION

=head4 INPUT

    {
        docker     => { type => 'object', isa => 'App::Actions::Docker', optional => 1 },
        older_than => { type => 'integer', min => 0, optional => 1 },
        now        => { type => 'integer', optional => 1 },
    }

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

A size of C<missing> means the record names an image that Docker no longer
has.  The text then says how many are missing.

=head2 prune

    my ($text, $status, $pruned) = $cache->prune(docker => $docker, %options);

Removes the selected images from Docker and from the record.

=head3 ARGUMENTS

=over 4

=item * C<docker> - required.  An L<App::Actions::Docker>.

=item * C<older_than> - optional.  Seconds.  Remove only images last used at
least this long ago.  Without it, every recorded image is removed.

=item * C<now> - optional.  The current time, for tests.

=back

=head3 RETURNS

A list of three values: the text to print; the exit status (0, or 1 if an
image could not be removed); and a hash reference for the JSON document with
C<removed>, C<freed> (bytes), C<forgotten> (images Docker no longer had) and
C<failed> (names).

=head3 SIDE EFFECTS

Runs C<docker image rm -f> for each selected image that Docker still has.
Removes those images and the ones Docker no longer has from the record.  An
image that could not be removed stays in the record.

=head3 API SPECIFICATION

=head4 INPUT

    {
        docker     => { type => 'object', isa => 'App::Actions::Docker' },
        older_than => { type => 'integer', min => 0, optional => 1 },
        now        => { type => 'integer', optional => 1 },
    }

=head4 OUTPUT

    { type => 'array', min => 3, max => 3 }    # (string, 0 or 1, hashref)

=head3 MESSAGES

    +--------------------------------------------+--------------------------------+---------------------------+
    | Message                                    | Meaning                        | What to do                |
    +--------------------------------------------+--------------------------------+---------------------------+
    | pruning the image cache needs a Docker     | no "docker" argument (croak)   | pass one                  |
    | command                                    |                                |                           |
    | Removed N images, SIZE freed.              | success                        |                           |
    | Forgot N images no longer on the daemon.   | they were already gone         |                           |
    | Could not remove N images:                 | an image is in use by a        | remove the container, and |
    |   IMAGE                                    | container, for example;        | prune again               |
    |                                            | status 1                       |                           |
    +--------------------------------------------+--------------------------------+---------------------------+

And the messages of L</save>.

=head2 document

    my $document = $cache->document(%options);

Returns the listing as data: the document C<action-run cache --json>
prints.

=head3 ARGUMENTS

=over 4

=item * C<docker> - optional.  An L<App::Actions::Docker>.

=item * C<reachable> - true if Docker answers.  Only then are sizes asked
for.

=item * C<docker_bin> - optional.  The Docker program to name in the
document.  Default: C<docker>'s, or C<docker>.

=item * C<older_than> - optional.  As for L</report>.

=item * C<prune> - optional.  The third value L</prune> returned.

=item * C<now> - optional.  The current time.  It becomes C<generated_at>.

=back

=head3 RETURNS

A hash reference, described in L</JSON OUTPUT>.

=head3 SIDE EFFECTS

Asks Docker for sizes, if reachable.  Checks the document against
L</json_schema>.

=head3 API SPECIFICATION

=head4 INPUT

    {
        docker     => { type => 'object', isa => 'App::Actions::Docker', optional => 1 },
        reachable  => { type => 'boolean', optional => 1 },
        docker_bin => { type => 'string', optional => 1 },
        older_than => { type => 'integer', min => 0, optional => 1 },
        prune      => { type => 'hashref', optional => 1 },
        now        => { type => 'integer', optional => 1 },
    }

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

    +--------------------------------------------+------------------------------+-----------------+
    | Exception                                  | Meaning                      | What to do      |
    +--------------------------------------------+------------------------------+-----------------+
    | App::Actions::Schema::Invalid: the         | a bug: the document does not | report it; exit |
    | action-run cache --json document does not  | match its schema             | status 70       |
    | match App::Actions::Cache->json_schema: ...|                              |                 |
    +--------------------------------------------+------------------------------+-----------------+

=head2 json_schema

    my $schema = App::Actions::Cache->json_schema;

Returns the JSON schema of the C<cache --json> document, as a new hash
reference.  C<action-run schema cache> prints the same schema.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'hashref' }

=head3 MESSAGES

None.

=head2 json_schema_version

    my $version = App::Actions::Cache->json_schema_version;

Returns the version of the document's shape.  The document carries the same
number as C<schema_version>.  It goes up whenever the shape changes.

=head3 API SPECIFICATION

=head4 INPUT

    {}

=head4 OUTPUT

    { type => 'integer', min => 1 }

=head3 MESSAGES

None.

=head2 parse_duration

    my $seconds = App::Actions::Cache::parse_duration('30d');

Turns a length of time, as a person types it, into seconds.

=head3 ARGUMENTS

=over 4

=item * C<$text> - a whole number and a unit, with or without a space:
C<30s>, C<15m>, C<12h>, C<7d>, C<2w>, C<3mo>, C<1y>, or the words (C<2
days>, C<1 hour>).  Case does not matter.  A month is 30 days and a year 365
days, the same as in the age column.

=back

=head3 RETURNS

The number of seconds, or C<undef> if the text is not understood (no unit,
an unknown unit, a negative number or a fraction).

=head3 SIDE EFFECTS

None.

=head3 EXAMPLE

    App::Actions::Cache::parse_duration('2 days');    # 172800
    App::Actions::Cache::parse_duration('2');         # undef: no unit

=head3 API SPECIFICATION

=head4 INPUT

    { text => { type => 'string', optional => 1 } }

=head4 OUTPUT

    { type => 'integer', min => 0, optional => 1 }

=head3 MESSAGES

None.

=head2 format_span

    my $words = App::Actions::Cache::format_span($seconds);

Says a length of time in words, using the largest whole unit: C<2 days>,
C<1 hour>, C<1 year>.  It is used for thresholds (C<older than 2 days>).

=head3 RETURNS

The words, in the language of L<App::Actions::I18N>.  A negative or invalid
number counts as 0 (C<0 seconds>).

=head3 API SPECIFICATION

=head4 INPUT

    { seconds => { type => 'integer', optional => 1 } }

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 format_age

    my $words = App::Actions::Cache::format_age($seconds);

Says an age in words: C<just now> under a minute, otherwise L</format_span>
followed by C<ago>, for example C<3 hours ago>.

=head3 API SPECIFICATION

=head4 INPUT

    { seconds => { type => 'integer', optional => 1 } }

=head4 OUTPUT

    { type => 'string', min => 1 }

=head3 MESSAGES

None.

=head2 format_size

    my $text = App::Actions::Cache::format_size($bytes);

Says a size in bytes in a short form: C<500 B>, C<1.5 KB>, C<2.3 GB>.  One
KB is 1024 bytes.

=head3 RETURNS

The text.  C<undef>, 0 or a negative number gives C<0 B>.

=head3 EXAMPLE

    App::Actions::Cache::format_size(1536);    # 1.5 KB

=head3 API SPECIFICATION

=head4 INPUT

    { bytes => { type => 'integer', optional => 1 } }

=head4 OUTPUT

    { type => 'string', min => 3 }

=head3 MESSAGES

None.

=head1 JSON OUTPUT

L</document> returns one object.  Every key is always there.  A value that
could not be found out is C<null>:

    {
      "schema_version": 3,
      "generated_at": 1792540920,
      "cache_file": "/home/me/.cache/action-run/cache.json",
      "docker": { "bin": "docker", "reachable": true },
      "images": [
        { "image": "alpine:3.20", "pulls": 3, "last_used": 1792540800, "age": 120, "size": 12345678, "present": true },
        { "image": "perl:5.38", "pulls": 1, "last_used": 1792440000, "age": 100920, "size": null, "present": false }
      ],
      "totals": { "images": 2, "size": 12345678, "present": 1, "missing": 1 },
      "prune": null
    }

=over 4

=item * C<generated_at> and C<last_used> are seconds since 1970.

=item * C<age> is C<generated_at> minus C<last_used>: C<null> if the last
use is not known, and 0 (not negative) if it is in the future.

=item * C<size> is the bytes Docker reports; C<present> says whether Docker
still has the image.

=item * When Docker cannot be reached, C<docker.reachable> is false, and
C<size>, C<present> and the totals that count them are C<null>.

=item * With C<older_than>, only the selected images are in C<images> and
counted in C<totals>.

=item * C<prune> is C<null> for a listing.  After a prune, it holds
C<removed>, C<freed>, C<forgotten> and C<failed>.  The document is printed
even when a removal failed, and the exit status is then 1.

=back

C<action-run schema cache> prints the schema.  The examples
F<t/fixtures/cache.json>, F<cache-empty.json>, F<cache-unreachable.json> and
F<cache-prune.json> are checked against it by F<t/schema.t>.

=head1 COMMON PITFALLS

=over 4

=item * B<Only images action-run pulled are listed.>  An image you pulled
with C<docker pull> is not in the record and is never pruned.

=item * B<C<older_than> is in seconds.>  Use L</parse_duration> to turn
C<30d> into seconds.

=item * B<C<prune> and C<report> want an L<App::Actions::Docker> object,
not a program name.>

=item * B<Pruning removes images by force.>  C<docker image rm -f> removes
an image even if a stopped container uses it.  An image that a I<running>
container uses cannot be removed and is reported as failed.

=item * B<A broken record file is silently treated as empty.>  Nothing is
lost (the images stay in Docker), but they are not listed until a run uses
them again.

=item * B<The object reads the file once.>  If another program changes the
file after L</load>, this object does not see the change.  Make a new
object.

=item * B<C<prune> returns a list.>  Write C<my ($text, $status, $data) =
...>.

=item * B<Months are 30 days and years 365 days.>  C<1mo> is not "the same
day last month".

=back

=head1 ENCODING

Image names are ASCII in practice (Docker requires it).  The record file is
JSON written as UTF-8 by L<JSON::PP>.  Its path may contain any characters
your system allows, including non-ASCII and emoji; it is used as bytes.  The
words that L</format_span> returns are in the current language of
L<App::Actions::I18N> and may contain non-ASCII characters (for example in
Chinese); encode them when you print.

=head1 AUTHOR

Nigel Horne, C<njh@nigelhorne.com>

=head1 FORMAL SPECIFICATION

This section describes each routine in the Z notation, a precise
mathematical language for describing programs.  You do not need to read it
to use the module: everything here is also said in plain words in the
sections above.

How to read it: a box names a routine.  The lines above the middle rule
declare the values it works with.  A name ending in C<?> is an input, and a
name ending in C<!> is an output.  C<ΞCache> means the routine changes
nothing; C<ΔCache> means it can change the record.  The lines below the rule
are always true when the routine returns.

    [IMAGE, PATH]
    Entry ≙ [ pulls : ℕ; last_used : optional ℕ ]

    ┌─ Cache ───────────────────────────────────────────
    │ file   : PATH
    │ images : IMAGE ⇸ Entry          the record, once loaded
    │ loaded : 𝔹
    ├───────────────────────────────────────────────────
    │ loaded ⇒ (file ∈ files ∧ parses(file) ⇒ images = parse(file).images)
    └───────────────────────────────────────────────────

    persisted ⇔ (images = ∅ ⇒ file ∉ files') ∧ (images ≠ ∅ ⇒ parse(file') = images)
    selected(older, now) = { i ∈ dom images | older = ⊥ ∨
        (images(i).last_used ≠ ⊥ ∧ now − images(i).last_used ≥ older) }

=head2 base_directory

    ┌─ BaseDirectory ───────────────────────────────────
    │ r! : PATH
    ├───────────────────────────────────────────────────
    │ Windows ⇒ r! = first non-empty of ⟨LOCALAPPDATA, USERPROFILE/AppData/Local, ./.cache⟩
    │ ¬Windows ⇒ r! = first non-empty of ⟨XDG_CACHE_HOME, HOME/.cache, ./.cache⟩
    └───────────────────────────────────────────────────

=head2 default_path

    ┌─ DefaultPath ─────────────────────────────────────
    │ r! : PATH
    ├───────────────────────────────────────────────────
    │ ACTION_RUN_CACHE_FILE ∉ {⊥, ⟨⟩} ⇒ r! = ACTION_RUN_CACHE_FILE
    │ otherwise r! = base_directory/action-run/cache.json
    └───────────────────────────────────────────────────

=head2 new

    ┌─ New ─────────────────────────────────────────────
    │ Cache'
    │ file? : optional PATH
    ├───────────────────────────────────────────────────
    │ file' = if file? ∈ {⊥, ⟨⟩} then default_path else file?
    │ ¬loaded'
    └───────────────────────────────────────────────────

=head2 file

    ┌─ File ────────────────────────────────────────────
    │ ΞCache
    │ r! : PATH
    ├───────────────────────────────────────────────────
    │ r! = file
    └───────────────────────────────────────────────────

=head2 load

    ┌─ Load ────────────────────────────────────────────
    │ ΔCache
    │ r! : DATA
    ├───────────────────────────────────────────────────
    │ loaded ⇒ images' = images
    │ ¬loaded ∧ (file ∉ files ∨ ¬parses(file)) ⇒ images' = ∅
    │ loaded' ∧ r! = { version ↦ 1, images ↦ images' }
    └───────────────────────────────────────────────────

=head2 save

    ┌─ Save ────────────────────────────────────────────
    │ ΞCache
    │ r! : {1}
    ├───────────────────────────────────────────────────
    │ persisted
    │ images ≠ ∅ ⇒ mode(file') = 0600 ∧ file is replaced in one rename
    └───────────────────────────────────────────────────

=head2 remember

    ┌─ Remember ────────────────────────────────────────
    │ ΔCache
    │ images? : seq IMAGE
    │ r!      : ℕ
    ├───────────────────────────────────────────────────
    │ G = { i ∈ ran images? | i ≠ ⊥ ∧ i ≠ ⟨⟩ }
    │ ∀ i ∈ G • images'(i).pulls = (images(i).pulls or 0) + count(i, images?)
    │         ∧ images'(i).last_used = now
    │ ∀ i ∈ dom images \ G • images'(i) = images(i)
    │ r! = #⟨ i in images? | i ∈ G ⟩
    │ r! > 0 ⇒ persisted
    └───────────────────────────────────────────────────

=head2 entries

    ┌─ Entries ─────────────────────────────────────────
    │ ΞCache
    │ r! : seq (IMAGE × Entry)
    ├───────────────────────────────────────────────────
    │ ran r! = images ∧ r! is sorted by IMAGE
    └───────────────────────────────────────────────────

=head2 forget

    ┌─ Forget ──────────────────────────────────────────
    │ ΔCache
    │ images? : seq IMAGE
    │ r!      : ℕ
    ├───────────────────────────────────────────────────
    │ images' = ran images? ⩤ images
    │ r! = #(ran images? ∩ dom images)
    │ r! > 0 ⇒ persisted
    └───────────────────────────────────────────────────

=head2 report

    ┌─ Report ──────────────────────────────────────────
    │ ΞCache
    │ older?, now? : optional ℕ
    │ r!           : TEXT
    ├───────────────────────────────────────────────────
    │ one row in r! for each i ∈ selected(older?, now?)
    └───────────────────────────────────────────────────

=head2 prune

    ┌─ Prune ───────────────────────────────────────────
    │ ΔCache
    │ docker? : Docker
    │ older?  : optional ℕ
    │ r!      : TEXT × {0, 1} × DATA
    ├───────────────────────────────────────────────────
    │ docker? = ⊥ ⇒ raises NeedsDocker
    │ S = selected(older?, now)
    │ gone = { i ∈ S | docker?.image_size(i) = ⊥ }
    │ removed = { i ∈ S \ gone | docker?.image_remove(i) = 0 }
    │ failed = S \ (gone ∪ removed)
    │ images' = (gone ∪ removed) ⩤ images
    │ second(r!) = 0 ⇔ failed = ∅
    └───────────────────────────────────────────────────

=head2 document

    ┌─ Document ────────────────────────────────────────
    │ ΞCache
    │ reachable? : 𝔹
    │ d!         : DATA
    ├───────────────────────────────────────────────────
    │ d!.images lists selected(older?, now?) with age = max(0, now? − last_used)
    │ ¬reachable? ⇒ d!.totals.size = ⊥ ∧ ∀ e ∈ d!.images • e.size = ⊥
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

=head2 parse_duration

    UNIT == { s ↦ 1, m ↦ 60, h ↦ 3600, d ↦ 86400, w ↦ 604800,
              mo ↦ 2592000, y ↦ 31536000 } ∪ spelled-out synonyms

    ┌─ ParseDuration ───────────────────────────────────
    │ text? : optional TEXT
    │ r!    : optional ℕ
    ├───────────────────────────────────────────────────
    │ trim(text?) = n ⁀ spaces ⁀ u ∧ n ∈ DIGITS⁺ ∧ lc(u) ∈ dom UNIT
    │     ⇒ r! = n × UNIT(lc(u))
    │ otherwise r! = ⊥
    └───────────────────────────────────────────────────

=head2 format_span

    ┌─ FormatSpan ──────────────────────────────────────
    │ seconds? : optional ℤ
    │ r!       : TEXT
    ├───────────────────────────────────────────────────
    │ s = max(0, seconds?) (0 if not a whole number)
    │ u = the largest of second, minute, hour, day, month, year with size(u) ≤ s
    │     (second if none)
    │ r! = i18n("span." ⁀ u, count ↦ s div size(u))
    └───────────────────────────────────────────────────

=head2 format_age

    ┌─ FormatAge ───────────────────────────────────────
    │ seconds? : optional ℤ
    │ r!       : TEXT
    ├───────────────────────────────────────────────────
    │ max(0, seconds?) < 60 ⇒ r! = "just now"
    │ otherwise r! = format_span(seconds?) ⁀ " ago"
    └───────────────────────────────────────────────────

=head2 format_size

    ┌─ FormatSize ──────────────────────────────────────
    │ bytes? : optional ℤ
    │ r!     : TEXT
    ├───────────────────────────────────────────────────
    │ bytes? = ⊥ ∨ bytes? ≤ 0 ⇒ r! = "0 B"
    │ k = min(4, max { j | 1024ʲ ≤ bytes? })
    │ k = 0 ⇒ r! = show(bytes?) ⁀ " B"
    │ k > 0 ⇒ r! = show1(bytes? / 1024ᵏ) ⁀ " " ⁀ ⟨KB, MB, GB, TB⟩(k)
    └───────────────────────────────────────────────────

=head1 STATE DIAGRAM

The object has two states (record not yet read, record in memory).  Each
image in the record goes through the states on the right:

    Object:

        new()                 load / entries / remember / forget / report /
    --------> +----------+    prune / document (first call)   +-----------+
              | UNLOADED |----------------------------------->|  LOADED   |
              +----------+   file read; missing or broken     | (in       |
                             file = no images                 |  memory)  |
                                                              +-----------+
                                                                |  ^
                                         remember / forget /    |  | no further
                                         prune change images:   |  | file reads
                                         save() writes the file +--+

    One image in the record:

     run pulls IMAGE          remember(IMAGE): pulls+1, last_used=now
    ----------------> +-------------+ <-----------------------------+
                      |  RECORDED   |-------------------------------+
                      +-------------+
                       |     |     |
     forget(IMAGE)     |     |     | prune: Docker no longer has it
     (Docker keeps it) |     |     v
                       |     |  +-------------+
                       |     |  | FORGOTTEN   |  counted in "forgotten"
                       |     |  +-------------+
                       |     |
                       |     | prune: docker image rm -f
                       |     +-------------------+------------------+
                       |              succeeded  |                  | failed (in use)
                       v                         v                  v
                +-------------+          +-------------+    +----------------+
                | NOT IN      |          | REMOVED     |    | stays RECORDED |
                | RECORD      |          | from Docker |    | listed in      |
                +-------------+          | and record  |    | "failed";      |
                                         +-------------+    | status 1       |
                                                            +----------------+

    prune(older_than => N) only touches images with a last use at least N
    seconds ago; the others stay RECORDED.

=head1 LICENSE AND COPYRIGHT

Copyright 2026 Nigel Horne.

This program is released under the GNU General Public License, version 2.
See the F<LICENSE> file that comes with this distribution.
If you use it, please let me know.

=cut
