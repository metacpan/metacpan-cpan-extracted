package DBIx::PgLink::Accessor;

# Connector role (accessor factory)

use Moose::Role;
use MooseX::Method;
use DBIx::PgLink::Accessor::BaseAccessor;
use DBIx::PgLink::Logger;
use DBIx::PgLink::Types;


#requires 'conn_name'; 
#requires 'adapter';

has 'accessor_class_for' => (
  is  => 'ro',
  isa => 'HashRef', # remote_object_type -> class name
  default => sub { 
    require DBIx::PgLink::Accessor::Table;
    require DBIx::PgLink::Accessor::Routine;
    {
      TABLE     => 'DBIx::PgLink::Accessor::Table',
      VIEW      => 'DBIx::PgLink::Accessor::Table',
      FUNCTION  => 'DBIx::PgLink::Accessor::Routine',
      PROCEDURE => 'DBIx::PgLink::Accessor::Routine',
    } 
  },
);


my $default_object_types = { 
  isa     => 'PostgreSQLArray', # Moose type coercion rules!
  coerce  => 1,
  default => [qw/TABLE VIEW FUNCTION PROCEDURE/],
};

method build_accessors => named (
  local_schema        => { isa => 'Str', required => 1 },
  remote_catalog      => { isa => 'StrNull', default => '%' },
  remote_schema       => { isa => 'StrNull', default => '%' },
  remote_object       => { isa => 'StrNull', default => '%' },
  remote_object_types => $default_object_types,
  object_name_mapping => { isa => 'PostgreSQLHash', coerce => 1, default => {} },
) => sub {
  my ($self, $p) = @_;

  my $types = delete $p->{remote_object_types};

  my $total_count = 0;
  for my $type (@{$types}) {
    my $class = $self->accessor_class_for->{$type} or next;
    my $cnt = $class->build_accessors( 
      %{$p}, 
      connector          => $self,
      remote_object_type => $type,
    );
    if (defined $cnt) {
      $total_count += $cnt;
    }
  }

  return $total_count;
};


method rebuild_accessors => named (
  local_schema        => { isa => 'Str', required => 1 },
  local_object        => { isa => 'Str', default => '%' },
  remote_object_types => $default_object_types,
) => sub {
  my ($self, $p) = @_;

  my $types = delete $p->{remote_object_types};

  my $total_count = 0;

  for my $type (@{$types}) {
    my $class = $self->accessor_class_for->{$type} or next;
    my $cnt = $class->rebuild_accessors(
      %{$p}, 
      connector          => $self,
      remote_object_type => $type,
    );
    if (defined $cnt) {
      $total_count += $cnt;
    }
  }

  return $total_count;
};


method for_accessors => named (
  local_schema        => { isa => 'Str', default => '%' }, # like
  local_object        => { isa => 'Str', default => '%' }, # like
  remote_object_types => $default_object_types,
  coderef             => { isa => 'CodeRef', required => 1 },
) => sub {
  my ($self, $p) = @_;

  my $types = delete $p->{remote_object_types};

  my $cnt = 0;
  for my $type (keys %{$self->accessor_class_for}) {
    next unless grep { $type eq $_ } @{$types};
    my $class = $self->accessor_class_for->{$type};
    $cnt += $class->for_accessors(
      %{$p},
      connector          => $self,
      remote_object_type => $type,
    );
  }

  return $cnt;
};


method for_all_accessors => positional (
  { isa => 'CodeRef', required => 1 },
) => sub {
  my ($self, $coderef) = @_;

  my @types = keys %{$self->accessor_class_for};

  $self->for_accessors(
    remote_object_types => \@types,
    coderef => $coderef,
  );
};


method load_accessor => positional (
  { isa=>'Int', required=>1 },
) => sub  {
  my ($self, $object_id) = @_;

  my $type = DBIx::PgLink::Accessor::BaseAccessor->get_accessor_type( $object_id )
    or confess "Cannot find type of object (id=$object_id)";

  my $class = $self->accessor_class_for->{$type}
    or trace_msg('ERROR', "Remote object of type '$type' is not supported (id=$object_id)");

  return $class->load(
    connector => $self,
    object_id => $object_id,
  );
};


1;
