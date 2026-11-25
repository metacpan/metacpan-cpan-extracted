package Bioconda::Packages::Updater;

use strict;
use warnings;
use Carp qw(croak);
use File::Spec;
use POSIX qw(strftime);

use Bioconda::Packages::DB           ();
use Bioconda::Packages::RecipeParser ();

our $VERSION = '0.01';

=head1 NAME

Bioconda::Packages::Updater - Maintainer tool: (re)build the JSON database from a
bioconda-recipes clone.

=head1 SYNOPSIS

    use Bioconda::Packages::Updater;

    my $up = Bioconda::Packages::Updater->new(
        repo    => 'bioconda-recipes',
        db      => 'share/bioconda-packages.json',
        verbose => 1,
    );

    $up->pull_repo;                 # optional: git pull --ff-only
    my $report = $up->build;        # parse recipes, merge, enrich, write

=head1 DESCRIPTION

This is developer-facing: end users only ever read the shipped database via
L<Bioconda::Packages>. The intended workflow is

    1. pull the bioconda-recipes clone   (pull_repo / git pull)
    2. rebuild the database               (build)
    3. commit the regenerated JSON        (git)

Removed-package handling: any package present in the previous database but no
longer found in the repo is B<kept> and flagged C<is_removed>, with C<removed_at>
stamped once. A package that reappears is un-flagged.

Dependencies: core Perl only. L<HTTP::Tiny> (core since 5.14) is used for the
optional anaconda.org enrichment.

=head1 METHODS

=head2 new

    my $up = Bioconda::Packages::Updater->new(%opts);

Options: C<repo> (path to the bioconda-recipes clone, required for L</build>),
C<db> (output JSON path; defaults to the located bundled db), C<api> (enable
anaconda.org enrichment), C<api_sleep> (seconds between API calls, default 0),
C<limit> (process at most N recipes, for testing), C<force> (bump the version
and rewrite even when the content is unchanged), C<verbose>, and C<log> (a code
ref called with log lines; defaults to printing to STDERR when verbose).

The version only advances, and the database file is only rewritten, when the
semantic package content actually changed (see L</build>). Volatile fields
(timestamps, download counts) are excluded from that comparison.

=cut

sub new {
    my ($class, %opt) = @_;
    my $self = {
        repo      => $opt{repo},
        db        => $opt{db},
        api       => $opt{api}       || 0,
        api_sleep => $opt{api_sleep} || 0,
        limit     => $opt{limit},
        force     => $opt{force}     || 0,
        verbose   => $opt{verbose}   || 0,
        log       => $opt{log},
    };
    return bless $self, $class;
}

sub _log {
    my ($self, @msg) = @_;
    if ($self->{log}) { $self->{log}->(@msg) }
    elsif ($self->{verbose}) { print STDERR @msg, "\n" }
}

=head2 pull_repo

    my $sha = $up->pull_repo;

Runs C<git -C $repo pull --ff-only> and returns the new HEAD sha. Dies if the
repo is not a git checkout or the pull fails.

=cut

sub pull_repo {
    my ($self) = @_;
    my $repo = $self->{repo} or croak "No repo path configured";
    croak "Repo '$repo' is not a directory" unless -d $repo;
    croak "Repo '$repo' is not a git checkout"
        unless -d File::Spec->catdir($repo, '.git');

    $self->_log("Pulling $repo ...");
    my $out = qx(git -C "$repo" pull --ff-only 2>&1);
    croak "git pull failed:\n$out" if $? != 0;
    $self->_log($out) if $self->{verbose};
    return $self->repo_commit;
}

=head2 repo_commit

Returns the repo's current HEAD sha (or undef if unavailable).

=cut

sub repo_commit {
    my ($self) = @_;
    my $repo = $self->{repo} or return undef;
    return undef unless -d File::Spec->catdir($repo, '.git');
    my $sha = qx(git -C "$repo" rev-parse HEAD 2>/dev/null);
    return undef if $? != 0;
    chomp $sha;
    return $sha || undef;
}

=head2 build

    my $report = $up->build;

Parses every recipe, merges with the existing database (preserving removed
state), optionally enriches via anaconda.org, and writes the database atomically.

Returns a report hashref: C<added>, C<updated>, C<removed>, C<reappeared>,
C<parse_warnings>, C<api_ok>, C<api_fail>, C<total>, C<db_path>.

=cut

sub build {
    my ($self) = @_;
    my $repo = $self->{repo} or croak "No repo path configured";
    my $recipes_dir = File::Spec->catdir($repo, 'recipes');
    croak "No recipes directory at '$recipes_dir'" unless -d $recipes_dir;

    my $db_path = Bioconda::Packages::DB->locate_db($self->{db});

    # Load previous db (if any) for removed-flag continuity and to advance the
    # progressive database version.
    my $old = {};
    my ($old_version, $old_sig);
    if (-f $db_path) {
        my $prev = eval { Bioconda::Packages::DB->load($db_path) };
        if ($prev && ref $prev->{packages} eq 'HASH') {
            $old = $prev->{packages};
            $old_version = $prev->{meta}{db_version};
            $old_sig     = $prev->{meta}{content_sha};
        }
    }

    my $now = _now_iso();
    my %new;                         # name => record
    my %recipe_warnings;
    my ($n_recipes, $n_warn) = (0, 0);

    opendir my $dh, $recipes_dir or croak "Cannot read '$recipes_dir': $!";
    my @dirs = sort grep { !/^\./ && -d File::Spec->catdir($recipes_dir, $_) }
                    readdir $dh;
    closedir $dh;

    for my $rname (@dirs) {
        last if defined $self->{limit} && $n_recipes >= $self->{limit};
        my $rdir = File::Spec->catdir($recipes_dir, $rname);
        my ($meta, $recipe_versions) = _find_meta($rdir);
        next unless $meta;
        $n_recipes++;

        my $info = eval { Bioconda::Packages::RecipeParser::parse_file($meta) };
        if ($@) {
            $self->_log("parse failed for $rname: $@");
            next;
        }
        if (@{ $info->{warnings} }) {
            $n_warn++;
            $recipe_warnings{$rname} = $info->{warnings};
        }

        # Build one record per installable package name this recipe provides.
        my @names = @{ $info->{package_names} };
        @names = ($rname) unless @names;    # fallback to dir name
        my $primary = $info->{name} // $names[0];

        for my $pname (@names) {
            my $is_primary = defined $primary && $pname eq $primary;
            my $old_rec = $old->{ lc $pname };
            my $rec = {
                name            => $pname,
                current_version => $info->{version},
                recipe_versions => $recipe_versions,
                published_versions =>
                    ($old_rec && $old_rec->{published_versions}) || [],
                downloads       => ($old_rec && $old_rec->{downloads}),
                build_number    => $info->{build_number},
                noarch          => $info->{noarch},
                summary         => $info->{summary},
                license         => $info->{license},
                license_family  => $info->{license_family},
                home            => $info->{home},
                dev_url         => $info->{dev_url},
                doc_url         => $info->{doc_url},
                identifiers     => $info->{identifiers},
                outputs         => $info->{outputs},
                depends         => $info->{depends},
                recipe_path     => "recipes/$rname",
                is_removed      => JSON_false(),
                removed_at      => undef,
                first_seen      => ($old_rec && $old_rec->{first_seen}) || $now,
                last_seen       => $now,
                is_subpackage   => $is_primary ? JSON_false() : JSON_true(),
            };
            # If an output record duplicates nothing useful, still keep it so the
            # name is discoverable; prefer the primary record on name clashes.
            if (!exists $new{ lc $pname } || $is_primary) {
                $new{ lc $pname } = $rec;
            }
        }
    }

    # Merge: carry over removed packages, detect reappearances.
    my ($added, $updated, $removed, $reappeared) = (0, 0, 0, 0);

    for my $key (keys %new) {
        if (exists $old->{$key}) {
            if ($old->{$key}{is_removed}) { $reappeared++ }
            else                          { $updated++ }
        }
        else { $added++ }
    }

    for my $key (keys %$old) {
        next if exists $new{$key};
        # Package vanished from the repo: retain but flag removed.
        my $rec = { %{ $old->{$key} } };
        $rec->{is_removed} = JSON_true();
        $rec->{removed_at} ||= $now;
        $new{$key} = $rec;
        $removed++;
    }

    # Optional enrichment from anaconda.org.
    my ($api_ok, $api_fail) = (0, 0);
    if ($self->{api}) {
        ($api_ok, $api_fail) = $self->_enrich(\%new);
    }

    my $removed_total = grep { $new{$_}{is_removed} } keys %new;

    # Bump the version only when the semantic content actually changed. The
    # signature deliberately ignores volatile fields (timestamps, download
    # counts) so a no-op rebuild neither bumps the version nor rewrites the file.
    my $sig = _content_signature(\%new);
    my $unchanged = (!$self->{force}
                     && defined $old_sig && $old_sig eq $sig && -f $db_path)
                    ? 1 : 0;
    my $db_version = $unchanged ? $old_version : _next_db_version($old_version);

    my $data = {
        meta => {
            db_version     => $db_version,
            content_sha    => $sig,
            generated_at   => $now,
            generator      => "Bioconda::Packages::Updater $VERSION",
            recipes_commit => $self->repo_commit,
            source         => 'bioconda-recipes',
            package_count  => scalar(keys %new),
            removed_count  => $removed_total,
            api_enriched   => $self->{api} ? JSON_true() : JSON_false(),
        },
        packages => \%new,
    };

    # Skip rewriting an unchanged database so the file (and its git state) stays
    # byte-identical.
    Bioconda::Packages::DB->save($db_path, $data) unless $unchanged;

    my $report = {
        added          => $added,
        updated        => $updated,
        removed        => $removed,
        reappeared     => $reappeared,
        parse_warnings => $n_warn,
        warnings_by_recipe => \%recipe_warnings,
        api_ok         => $api_ok,
        api_fail       => $api_fail,
        total          => scalar(keys %new),
        recipes_seen   => $n_recipes,
        db_path        => $db_path,
        db_version     => $db_version,
        changed        => $unchanged ? 0 : 1,
    };
    if ($unchanged) {
        $self->_log(sprintf
            "No content changes; database stays at version %s (not rewritten).",
            $db_version);
    }
    else {
        $self->_log(sprintf
            "Built %d packages as db version %s (%d added, %d updated, %d newly-removed, %d reappeared, %d parse warnings) -> %s",
            $report->{total}, $db_version, $added, $updated, $removed, $reappeared, $n_warn, $db_path);
    }
    return $report;
}

#-----------------------------------------------------------------------------
# anaconda.org enrichment
#-----------------------------------------------------------------------------

sub _enrich {
    my ($self, $pkgs) = @_;
    require HTTP::Tiny;
    require JSON::PP;
    my $http = HTTP::Tiny->new(
        timeout    => 30,
        agent      => "Bioconda-Packages/$VERSION ",
    );
    my ($ok, $fail) = (0, 0);
    my @names = sort keys %$pkgs;
    my $i = 0;
    for my $key (@names) {
        next if $pkgs->{$key}{is_removed};   # don't hammer the API for gone pkgs
        $i++;
        my $name = $pkgs->{$key}{name};
        my $url  = "https://api.anaconda.org/package/bioconda/$name";
        my $resp = $http->get($url);
        if (!$resp->{success}) {
            $fail++;
            $self->_log("API $name: $resp->{status} $resp->{reason}")
                if $self->{verbose};
            next;
        }
        my $json = eval { JSON::PP->new->utf8->decode($resp->{content}) };
        if ($@ || ref $json ne 'HASH') { $fail++; next; }

        my %vers;
        my $downloads = 0;
        if (ref $json->{files} eq 'ARRAY') {
            for my $f (@{ $json->{files} }) {
                $vers{ $f->{version} } = 1 if defined $f->{version};
                $downloads += $f->{ndownloads} if $f->{ndownloads};
            }
        }
        if (ref $json->{versions} eq 'ARRAY') {
            $vers{$_} = 1 for @{ $json->{versions} };
        }
        $pkgs->{$key}{published_versions} = [ _sort_versions(keys %vers) ];
        $pkgs->{$key}{downloads} = $downloads;
        $ok++;
        select undef, undef, undef, $self->{api_sleep} if $self->{api_sleep};
        $self->_log("API $i/".scalar(@names)." $name ok")
            if $self->{verbose} && $i % 100 == 0;
    }
    return ($ok, $fail);
}

#-----------------------------------------------------------------------------
# Helpers
#-----------------------------------------------------------------------------

# Locate the recipe's meta.yaml and collect any pinned version subdirectories.
# Returns ($meta_path, \@recipe_versions).
sub _find_meta {
    my ($rdir) = @_;
    my $top = File::Spec->catfile($rdir, 'meta.yaml');

    opendir my $dh, $rdir or return (undef, []);
    my @subs = grep { !/^\./ && -d File::Spec->catdir($rdir, $_) } readdir $dh;
    closedir $dh;
    my @versions = grep { /^[0-9]/ } @subs;      # version subdirs start with a digit

    if (-f $top) {
        return ($top, [ _sort_versions(@versions) ]);
    }
    # No top-level meta.yaml: use the highest version subdir, if any.
    if (@versions) {
        my ($highest) = reverse _sort_versions(@versions);
        my $meta = File::Spec->catfile($rdir, $highest, 'meta.yaml');
        return (-f $meta ? $meta : undef, [ _sort_versions(@versions) ]);
    }
    return (undef, []);
}

# Rough version sort: numeric-aware, good enough for display ordering.
sub _sort_versions {
    my @v = @_;
    return sort {
        my @a = split /[._-]/, $a;
        my @b = split /[._-]/, $b;
        for my $k (0 .. $#a) {
            my ($x, $y) = ($a[$k], $b[$k] // 0);
            my $cmp = ($x =~ /^\d+$/ && (defined $y && $y =~ /^\d+$/))
                      ? $x <=> $y : ($x cmp ($y // ''));
            return $cmp if $cmp;
        }
        return @a <=> @b;
    } @v;
}

sub _now_iso { strftime('%Y-%m-%dT%H:%M:%SZ', gmtime) }

# A stable hash of the semantically meaningful package data, used to decide
# whether a rebuild is a real change. Volatile fields (timestamps, download
# counts) are excluded so a no-op rebuild produces the same signature.
sub _content_signature {
    my ($pkgs) = @_;
    require Digest::SHA;
    my @volatile = qw(first_seen last_seen removed_at downloads);
    my %reduced;
    for my $key (keys %$pkgs) {
        my %rec = %{ $pkgs->{$key} };    # shallow copy; nested refs are read-only
        delete @rec{@volatile};
        $reduced{$key} = \%rec;
    }
    my $json = JSON::PP->new->utf8->canonical->encode(\%reduced);
    return Digest::SHA::sha256_hex($json);
}

# CalVer-style database version: YYYY.M.N (a valid 3-part SemVer, so it sorts
# under SemVer/numeric rules). N is a progressive counter that resets each month
# and increments on every rebuild within the same year+month. Uses UTC to match
# generated_at.
sub _next_db_version {
    my ($prev) = @_;
    my @t = gmtime;
    my $year  = $t[5] + 1900;
    my $month = $t[4] + 1;
    my $patch = 1;
    if (defined $prev && $prev =~ /^(\d+)\.(\d+)\.(\d+)$/) {
        $patch = $3 + 1 if "$1.$2" eq "$year.$month";
    }
    return "$year.$month.$patch";
}

# JSON booleans so they round-trip as true/false, not 1/0/"".
sub JSON_true  { JSON::PP::true()  }
sub JSON_false { JSON::PP::false() }

require JSON::PP;

1;
