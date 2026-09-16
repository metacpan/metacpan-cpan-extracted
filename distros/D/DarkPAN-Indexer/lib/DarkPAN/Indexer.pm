#!/usr/bin/env perl

package DarkPAN::Indexer;

use strict;
use warnings;

use Carp;
use CLI::Simple::Constants qw(:booleans);
use CLI::Simple::Utils qw(slurp_json);
use Data::Dumper;
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use Scalar::Util qw(openhandle);

use Module::Load ();  # runtime require by name (or Module::Runtime::use_module)

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(
  qw(
    storage
    format
    config
    config_file
    profile
  )
);

use parent qw(Class::Accessor::Fast);

caller or exit __PACKAGE__->main();

our $VERSION = '1.0.2';

# The config entry this indexer operates on. Selected by name (--profile /
# a bucket key) from the multi-DarkPAN config, or the whole file if it is a
# single flat entry. Kept generic so the storage/format keys drive behavior.

########################################################################
sub new {
########################################################################
  my ( $class, @args ) = @_;

  my $options = ref $args[0] ? $args[0] : {@args};

  my $self = $class->SUPER::new($options);

  $self->_load_config;

  $self->_init_storage;

  $self->_init_format;

  return $self;
}

########################################################################
# Resolve a bare backend name to its class, honoring the '+' verbatim
# escape hatch, load it, and assert it consumed the expected role.
########################################################################
sub _load_engine {
########################################################################
  my ( $self, $name, $family, $role ) = @_;

  croak "ERROR: no $family engine specified in config\n"
    if !defined $name || $name eq q{};

  my $class = $name =~ s/^[+]//xsm ? $name : "DarkPAN::Indexer::${family}::${name}";

  local $EVAL_ERROR;
  eval { Module::Load::load($class); 1 }
    or croak "ERROR: could not load $family engine '$class': $EVAL_ERROR";

  croak "ERROR: $class does not consume $role\n"
    if !$class->DOES($role);

  return $class;
}

########################################################################
sub _init_storage {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  # config->{storage}{type} selects the backend; legacy configs with only
  # an AWS block default to S3 (the only backend the old configs meant).
  my $type = $config->{storage} ? $config->{storage}->{type} : undef;
  $type //= 'S3' if $config->{AWS};

  my $class = $self->_load_engine( $type, 'Storage', 'DarkPAN::Indexer::Storage' );

  # S3->new (and every engine) takes the whole config entry and reads its
  # own slice; nothing storage-specific is threaded from here.
  $self->set_storage( $class->new($config) );

  return $self;
}

########################################################################
sub _init_format {
########################################################################
  my ($self) = @_;

  my $config = $self->get_config;

  my $type = $config->{format} ? $config->{format}->{type} : 'SQLite';

  my $class = $self->_load_engine( $type, 'Format', 'DarkPAN::Indexer::Format' );

  $self->set_format( $class->new( $config->{format} // {} ) );

  return $self;
}

########################################################################
# Where the version index lives in the storage container. From config
# (packages_version_index), e.g. 'orepan2/modules/packages.db.gz'. The
# .gz suffix drives compression in retrieve_index/publish_index.
########################################################################
sub _index_key {
########################################################################
  my ($self) = @_;

  my $key = $self->get_config->{packages_version_index};

  croak "ERROR: packages_version_index not set in config\n"
    if !defined $key || $key eq q{};

  return $key;
}

########################################################################
# create_index: build a fresh index from every distribution in storage.
#   list_distributions -> format->create_index(fh) -> load_index(create)
#   -> publish_index. Full rebuild; authoritative.
########################################################################
sub create_index {
########################################################################
  my ($self) = @_;

  my $storage = $self->get_storage;
  my $format  = $self->get_format;
  my $index   = $self->_index_key;

  my $guard = $storage->lock($index)
    or croak "ERROR: could not acquire lock on $index\n";

  # format writes the neutral TSV interchange for all distributions...
  my ( $tsv_fh, $tsv_file ) = File::Temp::tempfile( DIR => '/tmp', UNLINK => 1 );

  my $stats = $format->create_index(
    output        => $tsv_fh,
    distributions => [ $storage->list_distributions ],
    fetch         => sub { $self->_fetch_dist_to_tmp( $_[0] ) }
  );

  close $tsv_fh;

  # ...then loads that interchange into a fresh database, which we publish.
  my ( undef, $db_file ) = File::Temp::tempfile( DIR => '/tmp', UNLINK => 1, SUFFIX => '.db' );

  $format->load_index(
    input    => $tsv_file,
    database => $db_file,
    create   => $TRUE,
  );

  $storage->publish_index( $db_file, $index );

  return $stats;
}

########################################################################
# update_index: incrementally re-index ONE distribution.
#   retrieve current index -> open it -> format->update_index(that dist)
#   -> publish. Locked for the whole read-modify-write.
########################################################################
sub update_index {
########################################################################
  my ( $self, %args ) = @_;

  my $distribution = $args{distribution}
    or croak "ERROR: update_index requires a distribution\n";

  my $storage = $self->get_storage;
  my $format  = $self->get_format;
  my $index   = $self->_index_key;

  my $guard = $storage->lock($index)
    or croak "ERROR: could not acquire lock on $index\n";

  # bring the current index down to a local, writable db file
  my $db_file = $storage->retrieve_index( $index, '.db' );

  # delete-then-insert for this distribution happens inside update_index;
  # the format opens $db_file, mutates, and (via load) commits.
  $format->update_index(
    distribution => $distribution,
    database     => $db_file,
    fetch        => sub { $self->_fetch_dist_to_tmp( $_[0] ) }

  );

  $storage->publish_index( $db_file, $index );

  unlink $db_file;  # we received ownership from retrieve_index

  return $self;
}

########################################################################
# delete_from_index: remove one distribution's rows from the index.
#   retrieve -> update_index(delete_only) -> publish. Same locked round
#   trip, no re-insert.
########################################################################
sub delete_from_index {
########################################################################
  my ( $self, %args ) = @_;

  my $distribution = $args{distribution}
    or croak "ERROR: delete_from_index requires a distribution\n";

  my $storage = $self->get_storage;
  my $format  = $self->get_format;
  my $index   = $self->_index_key;

  my $guard = $storage->lock($index)
    or croak "ERROR: could not acquire lock on $index\n";

  my $db_file = $storage->retrieve_index( $index, '.db' );

  $format->update_index(
    distribution => $distribution,
    database     => $db_file,
    delete_only  => $TRUE,
    fetch        => sub { $self->_fetch_dist_to_tmp( $_[0] ) }
  );

  $storage->publish_index( $db_file, $index );

  unlink $db_file;

  return $self;
}

########################################################################
sub _load_config {
########################################################################
  my ($self) = @_;

  return $self
    if $self->get_config && ref $self->get_config;

  my $config_file = $self->get_config_file // $ENV{OREPAN2_S3_CONFIG};

  croak "ERROR: no config_file\n"
    if !$config_file;

  my $config = eval {
    return slurp_json($config_file)
      if openhandle($config_file) || $config_file =~ /[.]json$/xsm;

    croak "config file format unsupported\n"
      if $config_file !~ /[.]ya?ml$/xsm;

    require YAML::Tiny;

    return YAML::Tiny->read($config_file);
  };

  croak "ERROR: $EVAL_ERROR"
    if !$config || $EVAL_ERROR;

  $self->set_config($config);

  return $self;
}

########################################################################
sub _fetch_dist_to_tmp {
########################################################################
  my ( $self, $key ) = @_;

  # reap the previous distribution's tempfile before fetching the next,
  # so a full rebuild never materializes more than one tarball on disk.
  if ( my $prev = $self->{_dist_tmp} ) {
    unlink $prev if -e $prev;
  }

  my $bytes = $self->get_storage->fetch_object($key);
  croak "ERROR: could not fetch $key\n" if !defined $bytes;

  my ( $fh, $path ) = File::Temp::tempfile( DIR => '/tmp', UNLINK => 0, SUFFIX => '.tar.gz' );
  binmode $fh;
  print {$fh} $bytes;
  close $fh;

  $self->{_dist_tmp} = $path;  # remember so the NEXT call (or cleanup) reaps it
  return $path;
}

# call after create_index finishes, to reap the last one:
########################################################################
sub _reap_dist_tmp {
########################################################################
  my ($self) = @_;
  my $prev = delete $self->{_dist_tmp} or return;
  unlink $prev if -e $prev;
  return;
}

########################################################################
sub main {
########################################################################
  local $ENV{OREPAN2_S3_CONFIG} = sprintf '%s/.orepan2-s3.json', $ENV{HOME};

  my $indexer = __PACKAGE__->new;

  print {*STDERR} Dumper( [ config => $indexer->get_config ] );

  return 0;
}

1;

=pod

=head1 NAME

DarkPAN::Indexer - build and maintain a multi-version index of a DarkPAN

=head1 SYNOPSIS

  use DarkPAN::Indexer;

  my $indexer = DarkPAN::Indexer->new( config_file => '/path/to/darkpan.json' );

  # full build from every distribution in the repository
  my $stats = $indexer->create_index;

  # incrementally (re)index a single distribution
  $indexer->update_index( distribution => 'authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz' );

  # remove a distribution's packages from the index
  $indexer->delete_from_index( distribution => 'authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz' );

=head1 DESCRIPTION

C<DarkPAN::Indexer> builds and maintains a B<multi-version> package index for a
DarkPAN. Unlike C<02packages.details.txt.gz>, which records only the latest
version of each package, this index records B<every> version of every package
present in the repository, so a client can resolve and install a specific
historical version by name -- not just the latest.

The indexer is an B<orchestrator>. It composes two pluggable pieces and moves
opaque data between them:

=over 4

=item * A B<storage> engine (L</"STORAGE ENGINES">) -- where the distributions
and the index physically live (S3, local filesystem, ...).

=item * A B<format> engine (L</"FORMAT ENGINES">) -- how the index is built and
queried (SQLite, ...).

=back

The orchestrator itself knows nothing about S3 or SQLite. It reads config,
constructs the two engines named there, and drives them. This is what lets the
same code index an S3-backed DarkPAN behind CloudFront and a plain directory of
tarballs on a laptop.

=head1 CONSTRUCTOR

=head2 new

my $indexer = DarkPAN::Indexer->new( config_file => $path );
my $indexer = DarkPAN::Indexer->new( config      => \%config );

Constructs an indexer. Provide either C<config_file> (a path to a JSON config,
see L</CONFIGURATION>) or C<config> (an already-loaded config hashref). The
storage and format engines are constructed immediately from the config.

=head1 METHODS

=head2 create_index

  my $stats = $indexer->create_index;

Builds a fresh index from B<every> distribution in the repository. Enumerates
the repository (C<< storage->list_distributions >>), scans each distribution for
the packages it provides, loads them into a new index, and publishes the index
back to storage. This is the full-rebuild / authoritative operation; run it to
create the index initially or to rebuild it from ground truth.

Returns a stats hashref (distributions seen, distributions indexed, failures,
modules written).

=head2 update_index

  $indexer->update_index( distribution => $key );

Incrementally (re)indexes a single distribution. Retrieves the current index,
performs a delete-then-insert for the named distribution's packages, and
publishes the updated index. C<$key> is the storage key of the distribution
tarball (e.g. C<authors/id/A/AB/AUTHOR/Foo-1.0.tar.gz>). The whole
read-modify-write is performed under a storage lock.

=head2 delete_from_index

  $indexer->delete_from_index( distribution => $key );

Removes a single distribution's packages from the index. Retrieves the current
index, deletes the rows for the named distribution, and publishes. Also
performed under a storage lock.

=head1 CONFIGURATION

The config (JSON file via C<config_file>, or a hashref via C<config>) describes
one DarkPAN. The keys the indexer reads are:

=over 4

=item C<storage>

Selects and configures the storage engine, e.g.:

  "storage" : { "type" : "S3", "bucket" : "my-darkpan", "region" : "us-east-1" }
  "storage" : { "type" : "Filesystem", "root" : "/srv/darkpan" }

C<type> names the engine (resolved to C<DarkPAN::Indexer::Storage::E<lt>typeE<gt>>,
or a C<+Fully::Qualified> name). For backward compatibility, a config with a
legacy C<AWS> block and no C<storage> block is treated as S3.

=item C<format>

Selects the index format engine, e.g. C<< "format" : { "type" : "SQLite" } >>.
Defaults to C<SQLite> if omitted.

=item C<packages_version_index>

The storage key of the published index, e.g.
C<orepan2/modules/packages.db.gz>. A C<.gz> suffix causes the index to be
stored compressed.

=back

=head1 STORAGE ENGINES

A storage engine consumes the C<DarkPAN::Indexer::Storage> role and provides:
C<list_distributions>, C<fetch_object>, C<save_object>, C<has_object>, C<lock>,
and C<base_url>, plus the role-provided C<retrieve_index>/C<publish_index>.
C<DarkPAN::Indexer::Storage::S3> and C<DarkPAN::Indexer::Storage::Filesystem>
ship with this distribution.

=head1 FORMAT ENGINES

A format engine consumes the C<DarkPAN::Indexer::Format> role and provides:
C<create_index>, C<update_index>, C<load_index>, and C<delete_from_index>. The
role provides the shared C<index_distribution> (tarball -> package records)
machinery. C<DarkPAN::Indexer::Format::SQLite> ships with this distribution.

=head1 SEE ALSO

L<DarkPAN::Indexer::CLI>, L<DarkPAN::Resolver::SQLite>, L<OrePAN2::Lite>

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
