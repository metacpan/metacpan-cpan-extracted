package Data::AnyXfer::Elastic::ServerDict;

use Modern::Perl;
use Carp;

use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Data::AnyXfer::Elastic::ServerDefinition ();

=head1 NAME

Data::AnyXfer::Elastic::ServerDict - Logic for server selection and metadata lookup

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::ServerDict ();

    # Create dictionary from env
    my $dict = Data::AnyXfer::Elastic::ServerDict->from_env;

    # Or manually add server definitions
    my $dict = Data::AnyXfer::Elastic::ServerDict->new;
    $dict->add_server_definition($def);

    # Now lookup information needed for connecting or importing
    # data
    my @nodes = $dict->all_testing_nodes;
    my @nodes = $dict->all_development_nodes;
    my @nodes = $dict->get_silo_nodes('public_data');


=head1 DESCRIPTION

This class provides the metadata and connection info lookup logic for
L<Data::AnyXfer::Elastic> to locate or populate your Elasticsearch instances.

=cut

use constant CURRENT_ENV_VARNAME => 'DATA_ANYXFER_ES_CURRENT_ENV';

has server_definitions => (
  is      => 'ro',
  isa     => ArrayRef[InstanceOf['Data::AnyXfer::Elastic::ServerDefinition']],
  default => sub { return [] },
);

has current_env => (
  is      => 'ro',
  isa     => Maybe[Str],
  default => sub {
    return $ENV{CURRENT_ENV_VARNAME()} || undef;
  },
);


has _stash_outdated => (
  is      => 'rw',
  isa     => Bool,
  default => 0,
);

has _lookup_cache => (
  is       => 'rw',
  init_arg => undef,
  default  => sub {
    return {
      node_to_def               => {},
      silo_to_def               => {},
      node_to_installed_version => {},
    };
  },
);


=head1 METHODS

=cut

sub BUILD {
  my ($self) = @_;
  $self->_build_lookup_cache;
}


=head2 from_env

    # Create dictionary from env
    my $dict = Data::AnyXfer::Elastic::ServerDict->from_env;

Creates a server dict using
L<Data::AnyXfer::Elastic::ServerDefinition/load_from_env>.

Returns a new L<Data::AnyXfer::Elastic::ServerDict> instance.

=cut

sub from_env {
  return __PACKAGE__->new(
    server_definitions => [
      Data::AnyXfer::Elastic::ServerDefinition->load_from_env
    ],
  );
}


=head2 add_server_definition

  $dict->add_server_definition(
    Data::AnyXfer::Elastic::ServerDefinition->new( ... )
  );

Adds a server definition to the

=cut

sub add_server_definition {
  my ($self, @definitions) = @_;

  push @{$self->server_definitions}, @definitions;
  $self->_stash_outdated(1);
  return 1;
}


=head2 LOOKUP METHODS

=cut

sub _find_all_for_env {
  my ($self, $env) = @_;
  return grep { $_->env eq $env } @{$self->server_definitions};
}


=head3 all_production_nodes

  my @nodes = $dict->all_production_nodes;

Return connection details for all elasticsearch nodes in the
C<production> environment.

=cut

sub all_production_nodes {
   return map { $_->nodes } $_[0]->_find_all_for_env('production');
}


=head3 all_development_nodes

  my @nodes = $dict->all_development_nodes;

Return connection details for all elasticsearch nodes in the
C<development> environment.

=cut

sub all_development_nodes {
   return map { $_->nodes } $_[0]->_find_all_for_env('development');
}


=head3 all_testing_nodes

  my $nodes = $dict->all_testing_nodes;

Return connection details for all elasticsearch nodes in the
C<testing> environment.

=cut

sub all_testing_nodes {
   return map { $_->nodes } $_[0]->_find_all_for_env('testing');
}


=head3 list_silos

  my @silo_names = $dict->list_silos;

Retrieves all known silo names..

=cut

sub list_silos {
  my ($self) = @_;
  return sort keys %{$self->_get_lookup_cache()->{silo_to_def}};
}


=head3 get_silo_nodes

  my @node_groups = $dict->get_silo_nodes($silo_name);

Retrieves groups of nodes assigned to clusters tagged with the given silo.

=cut

sub get_silo_nodes {
  my ($self, $silo) = @_;
  return map { $_->nodes } @{$_[0]->_get_lookup_cache()->{silo_to_def}{$silo}};
}


=head2 get_silo_write_nodes

    my @node_groups = $dict->get_silo_write_nodes($silo_name);

Retrieves groups of nodes assigned to clusters tagged with the given silo,
like C<get_silo_nodes> but looks for a C<cluser_nodes> definition,
before falling back to C<nodes>.

=cut

sub get_silo_write_nodes {
  my ($self, $silo) = @_;

  # XXX: shallow clone for safety. this should probably be done in the definition class
  my $silo_lookup = $self->_get_lookup_cache()->{silo_to_def}{$silo};
  my @silo_members = $silo_lookup ? @{$silo_lookup} : ();

  return map {
    [@{$_->cluster_nodes} ? $_->cluster_nodes : @{$_->standalone_nodes}]
  } @silo_members;
}


=head2 get_node_version

  my $version = $dict->get_node_version('test-es-1.example.com:9200');

Returns the target node's elasticsearch version as defined by all
matching L<Data::AnyXfer::Elastic::ServerDefinition> instances
belonging to this ServerDict.

=cut

sub get_node_version {
  my ($self, $node) = @_;

  return unless $node;
  my $version = $self->_get_lookup_cache()->{node_to_installed_version}{$node};
  return $version;
}


# PRIVATE METHODS

sub _get_lookup_cache {
  my ($self) = @_;
  return $self->_stash_outdated
    ? $self->_build_lookup_cache
    : $self->_lookup_cache;
}

sub _build_lookup_cache {
  my ($self) = @_;

  # optimisticly unset outdated flag for safety
  $self->_stash_outdated(0);

  # Let's cache all possible lookups to keep overheads on
  # connections or high frequency queries to a minimum
  my %node_to_def = ();
  my %silo_to_def = ();
  my %node_to_installed_version = ();
  for my $server_def (@{$self->server_definitions}) {

    for (@{$server_def->silos}, $server_def->env) {
      # map nodes to server definition instance
      push @{$silo_to_def{$_} ||= []}, $server_def;
    }

    for ($server_def->cluster_nodes, $server_def->standalone_nodes) {
      for (@{$_}) {

        # map nodes to server definition instance
        push @{$node_to_def{$_} ||= []}, $server_def;

        # map nodes to installed elasticsearch version
        # make sure that the node does not already have a record
        # that contains a different version to the one we will set
        my $installed_version = $server_def->installed_version;
        if ( $node_to_installed_version{$_} ) {

            if ( $node_to_installed_version{$_} ne $installed_version) {
                croak qq/Node '$_' has conflicting installed_version /
                    . qq/($node_to_installed_version{$_} != $installed_version)/;
            }

        } else {
            # there is no existing record, so store the installed version
            $node_to_installed_version{$_} = $installed_version;
        }
      }
    }
  }

  # Overwrite existing lookups
  return $self->_lookup_cache({
    node_to_def               => \%node_to_def,
    silo_to_def               => \%silo_to_def,
    node_to_installed_version => \%node_to_installed_version,
  })
}


1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
