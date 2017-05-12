package DBIx::PgLink::Connector::Roles::SQLServerProc;

# Connector role for building SybaseASE/MSSQL 
# procedure accessor with explicit resultset

use Carp;
use Moose::Role;
use MooseX::Method;
use DBIx::PgLink::Types;
use DBIx::PgLink::Accessor::RoutineColumns;
use Data::Dumper;

method 'build_procedure' => named(
  local_schema     => {isa=>'Str', required=>1},
  remote_catalog   => {isa=>'StrNull'},
  remote_schema    => {isa=>'StrNull'},
  remote_object    => {isa=>'Str', required=>1},
  local_object     => {isa=>'Str', required=>0},
  column_info      => {isa=>'PostgreSQLArray', coerce=>1, required=>1},
) => sub {
  my ($self, $p) = @_;

  $p->{remote_object_type} = 'PROCEDURE';

  my $class = $self->accessor_class_for->{'PROCEDURE'} 
   or die "PROCEDURE accessor is not installed";

  my $obj = $self->adapter->routine_info_arrayref(
    $p->{remote_catalog},
    $p->{remote_schema},
    $p->{remote_object},
    $p->{remote_object_type},
  );
  
  die "Procedure $p->{remote_object} not found\n"
    if !defined($obj);
  die "Procedure $p->{remote_object} not found\n"
    if @{$obj} == 0;
  die "Multiple objects found: " 
    . join(', ', map { 
        $self->adapter->quote_identifier(
          $_->{SPECIFIC_CATALOG},
          $_->{SPECIFIC_SCHEMA},
          $_->{SPECIFIC_NAME}
        )
      } @{$obj}) . "\n" 
    if @{$obj} > 1;

  my $accessor = $class->new_from_remote_metadata({
    %{$obj->[0]},
    connector    => $self,
    local_schema => $p->{local_schema},
    local_object => $p->{local_object} || $obj->{ROUTINE_NAME},
  });

  my $columns = DBIx::PgLink::Accessor::RoutineColumns->new( parent=>$accessor, metadata=>[] );
  my @ci = @{$p->{column_info}};
  my $index = 1;
  while (@ci) {
    my $name = shift @ci;
    my $type = shift @ci;
    my $c = $columns->create_column_metadata({
      COLUMN_NAME      => $name,
      TYPE_NAME        => $type,
      ORDINAL_POSITION => $index++,
      NULLABLE         => 'YES',
    });
    push @{$columns->metadata}, $c;
  }

  $accessor->columns($columns);

  $accessor->build;
};

