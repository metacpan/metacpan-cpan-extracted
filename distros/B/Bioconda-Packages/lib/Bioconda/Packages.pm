package Bioconda::Packages;

use strict;
use warnings;
use Carp qw(croak);

use Bioconda::Packages::DB      ();
use Bioconda::Packages::Package ();

our $VERSION = '2026.11.4';

=head1 NAME

Bioconda::Packages - Query a bundled snapshot of Bioconda package metadata.

=head1 SYNOPSIS

    use Bioconda::Packages;

    my $bp = Bioconda::Packages->new;          # loads the bundled database

    if ($bp->exists('samtools')) {
        my $pkg = $bp->get('samtools');
        print $pkg->current_version, "\n";     # 1.25
        print "$_\n" for $pkg->dependency_names('run');
    }

    my @hits = $bp->search('aligner');         # name/summary substring match
    my @users = $bp->reverse_dependencies('zlib');
    my @gone  = $bp->removed;                   # packages dropped from bioconda

=head1 DESCRIPTION

C<Bioconda::Packages> gives offline, read-only access to a snapshot of Bioconda
package metadata: versions, dependencies, licenses, summaries and homepage/URLs.
The snapshot is a JSON database shipped with the distribution and rebuilt by the
maintainer tooling (see L<Bioconda::Packages::Updater> and the C<maintainer/>
scripts). No network access is needed at query time.

Packages that disappear from C<bioconda-recipes> are B<retained> in the database
and flagged as removed (see L</removed> and C<is_removed> on
L<Bioconda::Packages::Package>), so historical lookups keep working.

=head1 METHODS

=head2 new

    my $bp = Bioconda::Packages->new;
    my $bp = Bioconda::Packages->new(db => '/path/to/db.json');

Loads the database. Options:

=over 4

=item C<db>

Explicit path to a JSON database. Defaults to the bundled database (see
L<Bioconda::Packages::DB/locate_db>).

=back

=cut

sub new {
    my ($class, %args) = @_;
    my $path = Bioconda::Packages::DB->locate_db($args{db});
    my $data = Bioconda::Packages::DB->load($path);
    my $self = {
        db_path  => $path,
        data     => $data,
        packages => $data->{packages},
    };
    return bless $self, $class;
}

=head2 db_path

Path to the database file that was loaded.

=head2 meta

The database C<meta> hashref (generation time, commit, counts).

=cut

sub db_path { $_[0]{db_path} }
sub meta    { $_[0]{data}{meta} || {} }

=head2 db_version

The database snapshot version, a CalVer/SemVer string like C<2026.11.1>
(year.month.progressive). Sortable under SemVer rules. Returns C<undef> for a
database built before versions were stamped.

=cut

sub db_version { $_[0]{data}{meta}{db_version} }

=head2 exists

    $bp->exists('samtools');

True if the (case-insensitive) package name is in the database, including removed
packages.

=cut

sub exists {
    my ($self, $name) = @_;
    return 0 unless defined $name;
    return exists $self->{packages}{ _norm($name) } ? 1 : 0;
}

=head2 get

    my $pkg = $bp->get('samtools');

Returns a L<Bioconda::Packages::Package> object, or C<undef> if unknown.

=cut

sub get {
    my ($self, $name) = @_;
    return undef unless defined $name;
    my $rec = $self->{packages}{ _norm($name) } or return undef;
    return Bioconda::Packages::Package->new($rec);
}

=head2 list

    my @names = $bp->list;                       # all current (non-removed)
    my @names = $bp->list(include_removed => 1);  # everything

Returns a sorted list of package names.

=cut

sub list {
    my ($self, %opt) = @_;
    my $inc = $opt{include_removed};
    my @names = sort grep {
        $inc || !$self->{packages}{$_}{is_removed}
    } keys %{ $self->{packages} };
    return @names;
}

=head2 count

    my $n = $bp->count;                          # current packages
    my $n = $bp->count(include_removed => 1);

=cut

sub count {
    my ($self, %opt) = @_;
    return scalar $self->list(%opt);
}

=head2 removed

    my @names = $bp->removed;

Sorted list of packages flagged as removed from bioconda-recipes.

=cut

sub removed {
    my ($self) = @_;
    my @r = sort grep { $self->{packages}{$_}{is_removed} }
                 keys %{ $self->{packages} };
    return @r;
}

=head2 search

    my @names = $bp->search('aligner');
    my @names = $bp->search(qr/align/i);
    my @names = $bp->search('align', fields => ['name']);
    my @names = $bp->search('align', include_removed => 1);

Case-insensitive substring (or regex) search over package name and summary by
default. Returns a sorted list of matching package names.

=cut

sub search {
    my ($self, $query, %opt) = @_;
    croak "search() needs a query" unless defined $query;
    my $re = ref $query eq 'Regexp' ? $query : qr/\Q$query\E/i;
    my @fields = @{ $opt{fields} || ['name', 'summary'] };
    my $inc = $opt{include_removed};

    my @hits;
    for my $name (keys %{ $self->{packages} }) {
        my $rec = $self->{packages}{$name};
        next if $rec->{is_removed} && !$inc;
        for my $f (@fields) {
            my $val = $f eq 'name' ? $name : $rec->{$f};
            next unless defined $val;
            if ($val =~ $re) { push @hits, $name; last }
        }
    }
    @hits = sort @hits;
    return @hits;
}

=head2 reverse_dependencies

    my @users = $bp->reverse_dependencies('zlib');
    my @users = $bp->reverse_dependencies('zlib', kind => 'host');
    my @users = $bp->reverse_dependencies('zlib', kind => 'all');

Returns the sorted names of packages that depend on the given package. C<kind>
is C<run> (default), C<build>, C<host>, or C<all>.

=cut

sub reverse_dependencies {
    my ($self, $dep, %opt) = @_;
    croak "reverse_dependencies() needs a dependency name" unless defined $dep;
    my $kind = $opt{kind} || 'run';
    my $inc  = $opt{include_removed};
    my $target = lc $dep;

    my @hits;
    for my $name (keys %{ $self->{packages} }) {
        my $rec = $self->{packages}{$name};
        next if $rec->{is_removed} && !$inc;
        my @kinds = $kind eq 'all' ? qw(build host run) : ($kind);
        my $found = 0;
        for my $k (@kinds) {
            for my $d (@{ $rec->{depends}{$k} || [] }) {
                if (lc $d->{name} eq $target) { $found = 1; last }
            }
            last if $found;
        }
        push @hits, $name if $found;
    }
    @hits = sort @hits;
    return @hits;
}

=head2 stats

    my %s = $bp->stats;

Returns a hash of summary counts: C<total>, C<current>, C<removed>, C<noarch>,
plus the database C<generated_at> and C<recipes_commit> when present.

=cut

sub stats {
    my ($self) = @_;
    my $total   = scalar keys %{ $self->{packages} };
    my @removed = $self->removed;
    my $removed = scalar @removed;
    my $noarch  = grep { $_->{noarch} } values %{ $self->{packages} };
    return (
        total          => $total,
        current        => $total - $removed,
        removed        => $removed,
        noarch         => $noarch,
        db_version     => $self->meta->{db_version},
        generated_at   => $self->meta->{generated_at},
        recipes_commit => $self->meta->{recipes_commit},
    );
}

# Normalise a package name for lookup (conda names are lower-case).
sub _norm {
    my ($n) = @_;
    $n = lc $n;
    $n =~ s/^\s+|\s+$//g;
    return $n;
}

=head1 SEE ALSO

L<Bioconda::Packages::Package>, L<Bioconda::Packages::Updater>,
L<Bioconda::Packages::RecipeParser>, L<https://bioconda.github.io>.

=head1 AUTHOR

Andrea Telatin

=cut

1;
