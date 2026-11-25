package Bioconda::Packages::DB;

use strict;
use warnings;
use Carp qw(croak);
use File::Spec;
use File::Basename qw(dirname);
use JSON::PP ();

our $VERSION = '0.01';

=head1 NAME

Bioconda::Packages::DB - Locate, load and save the bundled JSON package database.

=head1 DESCRIPTION

A tiny storage layer shared by the read-only API (L<Bioconda::Packages>) and the
maintainer tooling (L<Bioconda::Packages::Updater>). The on-disk format is a
single JSON file; keeping all I/O here means a different backend (e.g. SQLite)
could be slotted in later without touching callers.

=head1 DATABASE FORMAT

    {
      "meta": {
        "generated_at": "2026-11-24T10:00:00Z",
        "generator":    "Bioconda::Packages::Updater 0.01",
        "recipes_commit": "<git sha or null>",
        "package_count": 11500,
        "removed_count": 3
      },
      "packages": {
        "samtools": {
          "name": "samtools",
          "current_version": "1.25",
          "recipe_versions": ["0.1.18", "...", "1.25"],
          "published_versions": [...],   # from anaconda.org (optional)
          "downloads": 123456,           # from anaconda.org (optional)
          "build_number": 0,
          "noarch": null,
          "summary": "...",
          "license": "MIT",
          "license_family": null,
          "home": "...",
          "dev_url": "...",
          "doc_url": "...",
          "identifiers": ["biotools:samtools"],
          "outputs": ["samtools"],
          "depends": { "build": [...], "host": [...], "run": [...] },
          "recipe_path": "recipes/samtools",
          "is_removed": false,
          "removed_at": null,
          "first_seen": "2026-11-24T10:00:00Z",
          "last_seen":  "2026-11-24T10:00:00Z"
        }
      }
    }

=cut

# Default filenames shipped in the distribution's share/ directory. The gzipped
# form is preferred (it is ~1.4MB vs ~16MB) and loaded transparently.
our $DB_BASENAME    = 'bioconda-packages.json.gz';
our @DB_CANDIDATES  = ('bioconda-packages.json.gz', 'bioconda-packages.json');

=head2 locate_db

    my $path = Bioconda::Packages::DB->locate_db;
    my $path = Bioconda::Packages::DB->locate_db($explicit_path);

Returns the path to the database, searching in order:

=over 4

=item 1. an explicit path argument (if given);

=item 2. the C<BIOCONDA_PACKAGES_DB> environment variable;

=item 3. L<File::ShareDir> (when the dist is installed and that module is present);

=item 4. the C<share/> directory relative to this module (running from the source tree).

=back

Dies if nothing can be found.

=cut

sub locate_db {
    my ($class, $explicit) = @_;

    return $explicit if defined $explicit && length $explicit;
    return $ENV{BIOCONDA_PACKAGES_DB}
        if defined $ENV{BIOCONDA_PACKAGES_DB} && length $ENV{BIOCONDA_PACKAGES_DB};

    # Installed location via File::ShareDir, if available.
    for my $base (@DB_CANDIDATES) {
        my $shared = eval {
            require File::ShareDir;
            File::ShareDir::dist_file('Bioconda-Packages', $base);
        };
        return $shared if defined $shared && -f $shared;
    }

    # Source-tree fallback: <dist>/share/<basename>, relative to this file.
    my $here = $INC{'Bioconda/Packages/DB.pm'};
    if (defined $here) {
        my $libdir  = dirname(dirname(dirname($here)));   # .../lib
        my $distdir = dirname($libdir);                   # dist root
        for my $base (@DB_CANDIDATES) {
            my $cand = File::Spec->catfile($distdir, 'share', $base);
            return $cand if -f $cand;
            # Also allow a db sitting next to the modules.
            my $cand2 = File::Spec->catfile(dirname($here), $base);
            return $cand2 if -f $cand2;
        }
    }

    croak "Could not locate the Bioconda::Packages database. Set the "
        . "BIOCONDA_PACKAGES_DB environment variable or pass db => \$path.";
}

=head2 load

    my $data = Bioconda::Packages::DB->load($path);

Reads and decodes the JSON database. Dies on failure.

=cut

sub load {
    my ($class, $path) = @_;
    croak "No database path given" unless defined $path;

    my $json;
    if (_is_gzip($path)) {
        require IO::Uncompress::Gunzip;
        IO::Uncompress::Gunzip::gunzip($path => \$json)
            or croak "Cannot gunzip database '$path': "
                   . $IO::Uncompress::Gunzip::GunzipError;
    }
    else {
        open my $fh, '<:raw', $path or croak "Cannot read database '$path': $!";
        local $/;
        $json = <$fh>;
        close $fh;
    }

    my $data = eval { JSON::PP->new->utf8->decode($json) };
    croak "Database '$path' is not valid JSON: $@" if $@;
    croak "Database '$path' has no 'packages' section"
        unless ref $data eq 'HASH' && ref $data->{packages} eq 'HASH';
    return $data;
}

=head2 save

    Bioconda::Packages::DB->save($path, $data);

Encodes C<$data> as canonical JSON and writes it atomically (temp file + rename).
If C<$path> ends in C<.gz> the output is gzip-compressed and written compact
(it is ~1.4MB that way); otherwise it is pretty-printed for human readability.

=cut

sub save {
    my ($class, $path, $data) = @_;
    croak "No database path given" unless defined $path;
    my $gz = $path =~ /\.gz$/;

    # Compact + canonical for the shipped gzip; pretty for a plain .json.
    my $encoder = JSON::PP->new->utf8->canonical;
    $encoder->pretty unless $gz;
    my $json = $encoder->encode($data);

    my $tmp = "$path.tmp.$$";
    if ($gz) {
        require IO::Compress::Gzip;
        IO::Compress::Gzip::gzip(\$json => $tmp, Level => 9)
            or croak "Cannot gzip '$tmp': $IO::Compress::Gzip::GzipError";
    }
    else {
        open my $fh, '>:raw', $tmp or croak "Cannot write '$tmp': $!";
        print {$fh} $json or croak "Error writing '$tmp': $!";
        close $fh or croak "Error closing '$tmp': $!";
    }
    rename $tmp, $path or croak "Cannot rename '$tmp' -> '$path': $!";
    return $path;
}

# Detect a gzip file by extension or magic bytes (1f 8b).
sub _is_gzip {
    my ($path) = @_;
    return 1 if $path =~ /\.gz$/;
    open my $fh, '<:raw', $path or return 0;
    read $fh, my $magic, 2;
    close $fh;
    return (defined $magic && $magic eq "\x1f\x8b") ? 1 : 0;
}

1;
