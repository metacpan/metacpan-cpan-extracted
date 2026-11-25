#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";
use Getopt::Long qw(GetOptions);
use Bioconda::Packages::Updater;

=head1 NAME

update-db.pl - Maintainer utility to (re)build the bundled Bioconda::Packages
database from a bioconda-recipes clone.

=head1 SYNOPSIS

    # Pull the repo, rebuild the shipped database (recipes only):
    perl maintainer/update-db.pl --repo bioconda-recipes

    # Rebuild without pulling, enrich from anaconda.org:
    perl maintainer/update-db.pl --repo bioconda-recipes --no-pull --api

    # Quick test over the first 500 recipes into a scratch db:
    perl maintainer/update-db.pl --repo bioconda-recipes --no-pull \
         --limit 500 --db /tmp/test.json

=head1 OPTIONS

    --repo PATH      Path to the bioconda-recipes clone (default: ./bioconda-recipes)
    --db PATH        Output JSON database (default: share/bioconda-packages.json)
    --pull / --no-pull   git pull --ff-only before building (default: pull)
    --api            Enrich with published versions & downloads from anaconda.org
    --api-sleep SEC  Pause between API calls (default: 0)
    --limit N        Process at most N recipes (for testing)
    --force          Bump the version and rewrite even if nothing changed
    --quiet          Suppress progress output
    --help           This message

The full workflow this implements:

    1. git pull the recipes clone        (unless --no-pull)
    2. parse every recipes/<name>/meta.yaml
    3. merge with the existing database, flagging vanished packages as removed
    4. (optional) enrich from anaconda.org
    5. write the database atomically - but ONLY if the semantic content changed;
       an unchanged rebuild keeps the same version and leaves the file untouched
       (use --force to override).

After a rebuild that changed the data, commit the regenerated JSON before
releasing.

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
