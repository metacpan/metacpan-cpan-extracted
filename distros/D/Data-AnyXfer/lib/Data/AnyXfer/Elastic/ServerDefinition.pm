package Data::AnyXfer::Elastic::ServerDefinition;

use Modern::Perl;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use Carp;

use Data::AnyXfer ();
use Data::AnyXfer::JSON ();

=head1 NAME

Data::AnyXfer::Elastic::ServerDefinition - Stores node and cluster information

=head1 SYNOPSIS

    use Data::AnyXfer::Elastic::ServerDefinition ();

    # Load definitions...
    # from a path
    my @definitions =
      Data::AnyXfer::Elastic::ServerDefinition
      ->load_json_file('servers.json');

    # or from an open handle
    open(my $open_fh, '<:encoding(UTF-8)', 'servers.json')
      || croak "Failed to open server definitions file ($!)";

    my @definitions =
      Data::AnyXfer::Elastic::ServerDefinition
      ->load_json_handle($open_fh);

    # Or define them programatically...
    my $definition = Data::AnyXfer::Elastic::ServerDefinition->new(
          name              => 'testserver',
          env               =>  'live',
          installed_version => '6.4.0',
          silos             => ["public_data"],
          standalone_nodes  => ["test-es-1.example.com:9200"],
          cluser_nodes      => ["test-es-1.example.com:9201"],
        }
    );

=head1 DESCRIPTION

The class represents the information required to interact with
an Elasticsearch server.

This can consist of a traditional cluster, or a number of seperate instances
acting as a cluster.

These definitions will usually be L<loaded/load> from a JSON file.

=head1 CONSTANTS

=over 12

=item C<ENV_VARNAME>

This is the ENV variable name which L</load_env> will use to source and load
as a server definition JSON file.

=back

=cut

use constant ENV_VARNAME => 'DATA_ANYXFER_ES_SERVERS_FILE';
use constant TEST_SERVERS_JSON_PATH => 't/data/servers.json';

=head1 ATTRIBUTES

=over 12

=item C<name>

  E.g. -> 'my-test-name'

Type: SLUG/SIMPLE STRING

The name of the server cluster or standalone server group.

=item C<env>

  E.g. -> 'production'

Type: SLUG/SIMPLE STRING

An environment value for the definition. This will be used by calling code to
find the correct definition for the runtime environment.

=item C<installed_version>

  E.g. -> '6.4.0'

Type: VERSION STRING

The installed elasticsearch version for the cluster or standalone server group.

This will be used to adjust queries and API calls to allow support for both
the ES 3.5.x range and ES 6+ as there were major API and ABI breakages between
these versions.

=cut

has [qw{name env installed_version}] => (
  required => 1,
  is       => 'ro',
  isa      => sub { $_[1] && !ref $_[1] }
);

=item C<cluser_nodes>

  E.g. -> [ 'localhost:9200' ]

Type: ARRAY

An array of URI strings for each node in the cluster, without the protocol.

=item C<standalone_nodes>

  E.g. -> [ 'localhost:9200' ]

Type: ARRAY

An array of URI strings for each node in the standalone cluster,
without the protocol.

These nodes should be kept in sync with the same data, and will act as multipel
1x1 node clusters operating as a single group for high availability without
clustering and recovery overheads (and associated pitfalls).

=cut

has [qw{cluster_nodes standalone_nodes}] => (
  required => 0,
  is       => 'ro',
  isa      => sub { ref $_[1] eq 'ARRAY' },
);

=item C<silos>

E.g. -> [ 'public_data', 'sensitive_data' ]

Type: ARRAY

An array of silo strings, used to "zone" servers and allow different servers to
contain different datasets.

=cut

has silos => (
  required => 0,
  is       => 'ro',
  isa      => sub { ref $_[1] eq 'ARRAY' },
  default  => sub { ['default'] },
);

has _silos_lookup => (
  required => 0,
  is       => 'ro',
  init_arg => undef,
  lazy     => 1,
  builder  => sub {
    my @silos = @{$_[0]->silos};
    my %silos_lookup;

    # convert silos array into a lookup hash
    @silos_lookup{@silos} = (1) x scalar @silos;
    return \%silos_lookup;
  },
);

=back


=head1 METHODS

=head2 BUILD

  my $def =
    Data::AnyXfer::Elastic::ServerDefinition->new;
    # extra validation errors thrown

Extra validation of some attributes happens during the Moo (MOP) BUILD
hook / phase.

=cut

sub BUILD {
  my ($self) = @_;

  my $nodes = $self->nodes;
  my $snodes = $self->standalone_nodes;

  croak 'Requires at least one nodes or standalone_nodes element'
    unless ($nodes && @{$nodes}) || ($snodes && @{$snodes});
}



=head2 load_json_handle

  my @definitions =
    Data::AnyXfer::Elastic::ServerDefinition->load_json_handle($fh);

Loads the server definition from the supplied JSON file handle.

=cut

sub load_json_handle {
  my ($self, $source_fh) = @_;

  my $object = Data::AnyXfer::JSON::decode_json_handle($source_fh);
  return map { __PACKAGE__->new(%$_) } @{$object->{servers}};
}

=head2 load_json_file

  my @definitions =
    Data::AnyXfer::Elastic::ServerDefinition->load_json_file($file);

Loads the server definition from the supplied JSON file path.

=cut

sub load_json_file {
  my ($self, $source_file) = @_;

  my $object = Data::AnyXfer::JSON::decode_json_file($source_file);
  return map { __PACKAGE__->new(%$_) } @{$object->{servers}};
}

=head2 load_from_env

  # Launched with DATA_ANYXFER_SERVERS_FILE="~/servers.json" perl

  my @definitions =
    Data::AnyXfer::Elastic::ServerDefinition->load_from_env;

=cut

sub load_from_env {
  my ($self) = @_;

  my @files = split ';', $ENV{ENV_VARNAME()}||'';

  # XXX : Under testing automatically load test servers.json
  # to make test setup easier
  push @files, TEST_SERVERS_JSON_PATH if Data::AnyXfer->test;

  return map { __PACKAGE__->load_json_file($_) } @files;
}

=head2 belongs_to

  if ($server->belongs_to('public_data')) {
    # do something with it
  }

Checks if a server definition belongs to the supplied silo.

Return C<1> if it does, otherwise returns C<0>.

=cut

sub belongs_to {
  my ($self, $silo) = @_;
  return $self->_silos_lookup->{$silo} ? 1 : 0;
}

=head2 nodes

This will return the primary node information for data importing.

In an environment with standalone node clusters,
it will return just these nodes, as these should be your heavy read
nodes.

  ['node1'], ['node2'], ['node3']

A definition without standalone nodes will return the clustered nodes
as such:

  ['node1', 'node2', 'node3']

Each element in the array returned by this method will be treated as
a single target for population, this is why a multi-dimensional array
is used, signifingy that all nodes in a real multicast ES
cluster should be used for a single transport
(they will be round-robined in the case connection failure).

=cut

sub nodes {
  my ($self) = @_;

  my $cluster_nodes    = $self->cluster_nodes;
  my $standalone_nodes = $self->standalone_nodes;

  return @$standalone_nodes
    ? [map { [$_] } @{$standalone_nodes}]
    : [[@{$cluster_nodes}]];
}

use namespace::autoclean;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
