package Data::AnyXfer::Elastic;

use v5.16.3;

use Carp;
use Moo;
use MooX::Types::MooseLike::Base qw(:all);

use namespace::autoclean;

use Data::AnyXfer::Elastic::ServerDict ();
use Search::Elasticsearch;
use Cwd         ();
use Path::Class ();


our $VERSION = '1.80';


=head1 NAME

 Data::AnyXfer::Elastic - Elasticsearch support for Data::AnyXfer

=head1 DESCRIPTION

 This module is responisble for connecting to the correct elasticsearch server(s),
 depending on the execution environment. It is the foundation of all
 Elasticsearch modules and is extended by Elasticsearch Wrapper modules.

=head1 SYNOPSIS

    my $elasticsearch = Data::AnyXfer::Elastic->new();

    $elasticsearch->ping();
    $elasticsearch->connected_to_servers();

=head1 VERSION

    Version: 1.8

=head1 SEE ALSO

    L<Search::Elasticsearch>
    L<http://www.elasticsearch.org/>

=head1 ENVIRONMENT VARIABLES

=head2 C<DATA_ANYXFER_ES_DEBUG>

Enables tracing on the underlying elasticsearch client when true.

If the value is a truthy string, and not the number C<1>, it will be taken as the target to trace to.
Acceptable values are: C<Stderr>, C<Stdout>, or a filename.

When set to C<1> defaults to C<Stdout>.

=cut

=head1 ATTRIBUTES

=head2 C<elasticsearch>

    my $es = Data::AnyXfer::Elastic->new->elasticsearch();

 Returns a Search::Elasticsearch::Client::Direct object for direct usage. In
 practice wrapper modules should be used. Data::AnyXfer::Elastic::(.*).
 This should be used sparingly and only in circumstances where a wrapper module
 cannot be used.

=cut

has [qw/ silo connect_hint /] => (
  is  => 'ro',
  isa => Maybe[Str],
);

has elasticsearch => (
    is  => 'rw',
    isa => ConsumerOf['Search::Elasticsearch::Role::Client::Direct'],
);

=head2 C<is_inject_index_and_type()>

 If this attribute is set to true then index name and type is automatically
 injected into each method when called. Currently this is only used with
 L<Data::AnyXfer::Elastic::Index>.

=cut

has is_inject_index_and_type => (
    is      => 'rw',
    isa     => Bool,
    default => undef,
);

=head2 C<available_servers>

=cut

has available_servers => (
  is       => 'ro',
  required => 1,
  isa      => InstanceOf['Data::AnyXfer::Elastic::ServerDict'],
  default  => sub {
    return Data::AnyXfer::Elastic::ServerDict->from_env;
  },
);

=head1 CLASS METHODS

=head2 default

Returns a default configured instance of this package
(C<Data::AnyXfer::Elastic>).

=cut

sub default {
  return __PACKAGE__->new;
}

=head2 datafile_dir

Returns the default path that will be used for persisting datafiles,
as a L<Path::Class::Dir> object.

This can be set via environment variable C<DATA_ANYXFER_ES_DATAFILE_DIR>.

=cut

sub datafile_dir {
  my $dir = $ENV{DATA_ANYXFER_ES_DATAFILE_DIR};

  return $dir
    ? Path::Class::dir($dir)
    : Path::Class::dir(Cwd::getcwd())->subdir('datafiles');
}


=head1 METHODS

=cut

sub BUILD {
    my $self = shift;

    if ( my $silo = $self->silo ) {
        $self->elasticsearch(
          $self->client_for( $silo, undef, $self->connect_hint )
        );
    }
}


=head2 C<ping()>

    my $bool = Data::AnyXfer::Elastic->new->ping();

 Returns 1 if able to ping elasticsearch server(s), throws an error otherwise.

=cut

sub ping {
    my $self = shift;
    my $es   = $self->elasticsearch;

    unless ($es) {
        croak q!Ping failed. 'elasticsearch' attribute is undefined!;
    }

    $es->ping();
    return 1;
}

=head1 C<build_client>

  my $client = $self->build_client(
      nodes => [ qw/ some-node-1:9200 some-node-2:9200 / ]
  );

Returns an C<Search::Elasticsearch::Client::Direct> object for the supplied
nodes.

=cut

sub build_client {
    my ( $self, %client_opts ) = @_;

    my $version
        = $self->available_servers->get_node_version(
        $client_opts{nodes}[0] );

    return Search::Elasticsearch->new( %client_opts,
        $self->_get_standard_es_args($version) );
}


=head1 SILO ARCHITECTURE

=head2  C<client_for(silo_name)>

    my $elastic = Data::AnyXfer::Elastic->new;

    # Connects to the nearest elasticsearch cluster used for most senarios
    # where the data can be public
    $es = $elastic->client_for('public_data');

    # Private data for internal use only, croaks on an app server
    $es = $elastic->client_for('private_data');

Returns an C<Search::Elasticsearch::Client::Direct> object for the requested
silo.

=cut

sub client_for {
    my ( $self, $silo, $client_opts, $hint ) = @_;

    my $nodes = $self->_get_best_silo_nodes( $silo, $hint );
    return $self->build_client( nodes => $nodes->[0], %{$client_opts} );
}


=head2 C<all_clients_for(silo_name)>

    my $elastic = Data::AnyXfer::Elastic->new;

    # Get all clients
    my @targets = $elastic->all_clients_for('all');

    # Get just the internal cluster clients
    my @targets = $elastic->all_clients_for('private_data');

    # Get just the 6dg cluster clients
    my @targets = $elastic->all_clients_for('public_data');

Returns a list of C<Search::Elasticsearch::Client::Direct> object for the
appropriate machine and cluster type.

=cut

sub all_clients_for {
    my ( $self, $silo, $client_opts, $hint ) = @_;

    my $method = $hint && $hint eq 'readwrite'    #
        ? 'get_silo_write_nodes'                  #
        : 'get_silo_nodes';                       #

    # XXX : Because we run our readonly instances as 1 node clusters
    # split each node into a separate array (which will cause separate
    # clients to be created for each node)
    my ( @clients, %nodes_seen );
    foreach ( $self->available_servers->$method($silo) ) {

        # skip making clients with duplicate connection information
        my $nodes_sig = join '|', $_;
        next if $nodes_seen{$nodes_sig};

        # create the client
        push @clients, map { $self->build_client( nodes => $_, %{$client_opts} ) } @{$_};

        # looks good, mark this connection information as seen
        $nodes_seen{$nodes_sig} = 1;
    }
    return @clients;

}


#
# Assemble standard Search::Elasticsearch arguments
# for injection
#
sub _get_standard_es_args {
    my ( $self, $es_version ) = @_;
    # build default search elasticsearch arguments
    my %args = ();

    # XXX : Force our connection pool to be sticky
    # Do not round robin unless the current connection dies
    $args{cxn_pool} = 'Sticky';

    # Enable tracing when debug environment variable set
    if ( my $debug_target = $ENV{DATA_ANYXFER_ES_DEBUG} ) {
        $args{trace_to} = $debug_target eq 1 ? 'Stdout' : $debug_target;
    }

    # XXX : Detect elasticsearch version running and use the
    # correct direct client
    if ( $es_version =~ /^2/ ) {
        # use the version 2 direct client
        $args{client} = '2_0::Direct';
    } elsif ( $es_version =~ /^6/ ) {
        # use the version 6 direct client
        $args{client} = '6_0::Direct';
    } else {
        # we don't support any other version families of elasticsearch
        croak qq!Version '$es_version' not supported!;
    }
    return %args;
}

#
# Find the correct nodes for the silo specifed.
#

sub _get_best_silo_nodes {
    my ( $self, $silo, $hint, $test_hostname_override ) = @_;

    # initialise hint if undef
    $hint ||= 'default';

    croak 'Silo name must be defined'
        unless $silo;

    # bail out if an unknown connection hint is passed in
    if ( $hint !~ /^(?:default|readonly|readwrite)$/ ) {
        croak "Elasticsearch connection hint '$hint' not recognised!";
    }

    # Handle non-live environment and generic silos
    return
        # enforce list context, return the first group of nodes
        # matching the silo
        (
        $hint eq 'readwrite'
        ? $self->available_servers->get_silo_write_nodes($silo)
        : $self->available_servers->get_silo_nodes($silo)
        )[0];
}


__PACKAGE__->meta->make_immutable;

1;

=head1 COPYRIGHT

This software is copyright (c) 2019, Anthony Lucas.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
