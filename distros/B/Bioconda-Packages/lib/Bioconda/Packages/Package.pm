package Bioconda::Packages::Package;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Bioconda::Packages::Package - A single Bioconda package record.

=head1 SYNOPSIS

    my $pkg = $bp->get('samtools');
    print $pkg->name, ' ', $pkg->current_version, "\n";
    print "removed!\n" if $pkg->is_removed;
    my @run = $pkg->dependencies('run');

=head1 DESCRIPTION

A thin, read-only wrapper around the hashref stored in the database. It exists so
callers get stable accessor methods instead of reaching into hash keys. The
underlying data is available via L</data> if you need a field without an
accessor.

=cut

sub new {
    my ($class, $data) = @_;
    return bless { data => $data || {} }, $class;
}

=head2 data

Returns the raw underlying hashref.

=cut

sub data { $_[0]{data} }

# Simple scalar accessors generated from the record keys.
for my $field (qw(
    name current_version build_number noarch
    summary license license_family home dev_url doc_url
    downloads recipe_path removed_at first_seen last_seen
)) {
    no strict 'refs';
    *{$field} = sub { $_[0]{data}{$field} };
}

=head2 is_removed

True if the package is no longer present in bioconda-recipes but retained in the
database.

=cut

sub is_removed { $_[0]{data}{is_removed} ? 1 : 0 }

=head2 recipe_versions

List of recipe versions found in the repo (current plus any pinned version
subdirectories).

=head2 published_versions

List of versions actually published on anaconda.org (only populated when the
database was built with API enrichment).

=head2 identifiers

List of external identifiers (e.g. C<biotools:samtools>, C<doi:...>).

=head2 outputs

List of package names this recipe produces (for multi-output recipes).

=cut

sub recipe_versions    { @{ $_[0]{data}{recipe_versions}    || [] } }
sub published_versions { @{ $_[0]{data}{published_versions} || [] } }
sub identifiers        { @{ $_[0]{data}{identifiers}        || [] } }
sub outputs            { @{ $_[0]{data}{outputs}            || [] } }

=head2 versions

The best available list of versions: published versions when known, otherwise
recipe versions.

=cut

sub versions {
    my ($self) = @_;
    my @pub = $self->published_versions;
    return @pub if @pub;
    return $self->recipe_versions;
}

=head2 dependencies

    my @run   = $pkg->dependencies('run');     # default is 'run'
    my @host  = $pkg->dependencies('host');
    my @build = $pkg->dependencies('build');
    my @all   = $pkg->dependencies('all');

In list context returns dependency hashrefs
(C<< { name, constraint, platform } >>). In scalar context returns the count.

=cut

sub dependencies {
    my ($self, $kind) = @_;
    $kind ||= 'run';
    my $deps = $self->{data}{depends} || {};
    my @list;
    if ($kind eq 'all') {
        push @list, @{ $deps->{$_} || [] } for qw(build host run);
    }
    else {
        @list = @{ $deps->{$kind} || [] };
    }
    return @list;
}

=head2 dependency_names

As L</dependencies> but returns just the names.

=cut

sub dependency_names {
    my ($self, $kind) = @_;
    return map { $_->{name} } $self->dependencies($kind);
}

1;
