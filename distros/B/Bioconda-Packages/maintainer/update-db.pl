#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Getopt::Long qw(GetOptions);
use Bioconda::Packages::Updater;

=head1 NAME

update-db.pl - Rebuild the bundled Bioconda::Packages database from a
bioconda-recipes clone.

=head1 SYNOPSIS

    # Standard rebuild: pull the repo and regenerate the shipped database:
    perl maintainer/update-db.pl --repo bioconda-recipes

    # Rebuild without pulling, then enrich with anaconda.org metadata:
    perl maintainer/update-db.pl --repo bioconda-recipes --no-pull --api

    # Throttle API calls to avoid rate-limiting (1 second between requests):
    perl maintainer/update-db.pl --repo bioconda-recipes --api --api-sleep 1

    # Quick smoke-test: process the first 500 recipes into a scratch database:
    perl maintainer/update-db.pl --repo bioconda-recipes --no-pull \
         --limit 500 --db /tmp/test.json

    # Force a version bump even when nothing changed (e.g. after a hotfix):
    perl maintainer/update-db.pl --repo bioconda-recipes --force

=head1 DESCRIPTION

This maintainer-only script rebuilds C<share/bioconda-packages.json.gz>, the
database that ships with the distribution and powers the Bioconda::Packages API
at runtime.

The full workflow:

=over 4

=item 1. B<git pull> the bioconda-recipes clone (unless C<--no-pull>).

=item 2. B<Parse> every C<recipes/E<lt>nameE<gt>/meta.yaml> using
L<Bioconda::Packages::RecipeParser>.

=item 3. B<Merge> with the existing database: new packages are added, changed
packages are updated, and packages that have disappeared from the recipes tree
are flagged as removed (they are kept in the database rather than deleted, so
consumers can distinguish "never existed" from "was removed").

=item 4. B<Enrich> (optional, C<--api>) each package with the latest published
version and total download count fetched from the anaconda.org JSON API.
Requires L<IO::Socket::SSL> and L<Net::SSLeay>.

=item 5. B<Write> the database atomically — but B<only> if the semantic content
changed. Volatile fields (C<first_seen>, C<last_seen>, C<downloads>) are
excluded from the content-hash comparison, so a rebuild that produces identical
metadata keeps the same CalVer and leaves the file untouched. Use C<--force>
to override this behaviour.

=back

The database version follows CalVer (C<YYYY.M.N>); the counter C<N> resets
each month and increments only when the content hash changes (or C<--force> is
given).

After a rebuild that changed the data, B<commit the regenerated JSON> before
cutting a release:

    git add share/bioconda-packages.json.gz
    git commit -m "chore: rebuild database YYYY.M.N"

=head1 OPTIONS

=over 4

=item B<--repo> I<PATH>

Path to a local clone of L<https://github.com/bioconda/bioconda-recipes>.
Defaults to C<./bioconda-recipes>. The directory must already exist; the
script will C<git pull --ff-only> inside it unless C<--no-pull> is set.

=item B<--db> I<PATH>

Output path for the rebuilt database. Defaults to
C<share/bioconda-packages.json.gz> relative to the distribution root. The
file is written atomically (write to a temp file, then rename).

=item B<--pull> / B<--no-pull>

Whether to run C<git pull --ff-only> on the recipes clone before building.
Default: pull. Use C<--no-pull> to build from whatever HEAD is currently
checked out (useful during development or when network is unavailable).

=item B<--api>

After parsing, fetch each package's latest published version and cumulative
download count from the anaconda.org JSON API and store them in the database.
Requires L<IO::Socket::SSL> and L<Net::SSLeay> to be installed. Off by default.

=item B<--api-sleep> I<SEC>

Fractional seconds to sleep between anaconda.org API requests. Default: 0.
Increase (e.g. C<--api-sleep 0.5>) if you hit rate limits during a full
rebuild.

=item B<--limit> I<N>

Stop after processing the first I<N> recipes. Intended for quick smoke-tests
and development; do not use for production database rebuilds.

=item B<--force>

Bump the CalVer and rewrite the database file even when the content hash is
unchanged. Useful after infrastructure changes that do not affect package
metadata.

=item B<--quiet>

Suppress progress messages on STDERR. The final summary is still printed to
STDOUT.

=item B<--help>

Print this documentation and exit.

=back

=head1 DEPENDENCIES

Runtime (all Perl core): L<JSON::PP>, L<IO::Compress::Gzip>,
L<IO::Uncompress::Gunzip>.

Optional (for C<--api>): L<IO::Socket::SSL>, L<Net::SSLeay>.

=head1 AUTHOR

Andrea Telatin, Quadram Institute Bioscience (2026).

=head1 SEE ALSO

L<Bioconda::Packages>, L<Bioconda::Packages::Updater>,
L<Bioconda::Packages::RecipeParser>

=cut

my %opt = (
    repo      => 'bioconda-recipes',
    db        => undef,
    pull      => 1,
    api       => 0,
    api_sleep => 0,
    limit     => undef,
    force     => 0,
    quiet     => 0,
);

GetOptions(
    'repo=s'      => \$opt{repo},
    'db=s'        => \$opt{db},
    'pull!'       => \$opt{pull},
    'api!'        => \$opt{api},
    'api-sleep=f' => \$opt{api_sleep},
    'limit=i'     => \$opt{limit},
    'force'       => \$opt{force},
    'quiet'       => \$opt{quiet},
    'help'        => \$opt{help},
) or die "Error in arguments. Try --help.\n";

if ($opt{help}) {
    exec 'perldoc', $0;
}

# Default db: share/bioconda-packages.json relative to this script's dist root.
my $db = $opt{db} // "$RealBin/../share/bioconda-packages.json.gz";

my $up = Bioconda::Packages::Updater->new(
    repo      => $opt{repo},
    db        => $db,
    api       => $opt{api},
    api_sleep => $opt{api_sleep},
    limit     => $opt{limit},
    force     => $opt{force},
    verbose   => !$opt{quiet},
);

if ($opt{pull}) {
    my $sha = eval { $up->pull_repo };
    if ($@) { warn "WARNING: pull failed, building from current checkout.\n$@"; }
    else    { print STDERR "Repo at $sha\n" unless $opt{quiet}; }
}

my $report = $up->build;

print "\n";
printf "Database:        %s\n", $report->{db_path};
printf "DB version:      %s%s\n", $report->{db_version},
    ($report->{changed} ? '' : '  (unchanged - not rewritten)');
printf "Recipes seen:    %d\n", $report->{recipes_seen};
printf "Total packages:  %d\n", $report->{total};
printf "  added:         %d\n", $report->{added};
printf "  updated:       %d\n", $report->{updated};
printf "  newly removed: %d\n", $report->{removed};
printf "  reappeared:    %d\n", $report->{reappeared};
printf "Parse warnings:  %d recipes\n", $report->{parse_warnings};
if ($opt{api}) {
    printf "API enrichment:  %d ok, %d failed\n",
        $report->{api_ok}, $report->{api_fail};
}
