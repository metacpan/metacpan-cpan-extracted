package CORBA::MICO::IREntry;

use Carp;

require CORBA::MICO::IRRoot;
require CORBA::MICO;

use strict;

#--------------------------------------------------------------------
sub new {
  my ($type, $name, $ir_node, $root_node) = @_;
  my $class = ref($type) || $type;
  return bless { 'CONTENTS' => {},
                 'PARENTS'  => undef,
                 'NAME'     => $name,
                 'ROOT'     => $root_node,
                 'NODE'     => $ir_node,
                 'KIND'     => $ir_node->_get_def_kind() }, $class;
}

#--------------------------------------------------------------------
sub name {
  my $self = shift;
  return $self->{'NAME'};
}

#--------------------------------------------------------------------
sub shname {
  my $self = shift;
  return $self->{'NAME'} ? $self->{'NODE'}->_get_name() : '';
}

#--------------------------------------------------------------------
sub repoid {
  my $self = shift;
  return $self->{'NAME'} ? $self->{'NODE'}->_get_id() : '';
}

#--------------------------------------------------------------------
sub kind {
  my $self = shift;
  return $self->{'KIND'};
}

#--------------------------------------------------------------------
sub root_ir {
  my $self = shift;
  return $self->{'ROOT'};
}

#--------------------------------------------------------------------
sub ir_node {
  my $self = shift;
  return $self->{'NODE'};
}

#--------------------------------------------------------------------
sub contents {
  my ($self, $kind) = @_;
  return exists($self->{'CONTENTS'}->{$kind}) ? $self->{'CONTENTS'}->{$kind}
                                              : $self->_contents($kind);
}

#--------------------------------------------------------------------
sub parents {
  my ($self) = @_;
  return $self->{'PARENTS'} || $self->_parents();
}

#--------------------------------------------------------------------
sub is_abstract {
  my ($self) = @_;
  my $kind = $self->{'KIND'};
  if( $kind ne 'dk_Interface' and $kind ne 'dk_Value' ) {
    return 0;
  }
  return $self->{'NODE'}->_get_is_abstract();
}

#--------------------------------------------------------------------
sub _contents {
  my ($self, $kind) = @_;
  my $root_ir = $self->{'ROOT'};
  my $ir_node = $self->{'NODE'};
  my $contents;
  eval { $contents = $ir_node->contents($kind, 1) };
  if( $@ ) {
    # carp "method contents() is not supported by ", ref($ir_node);
    $self->{'CONTENTS'}{$kind} = undef;
    return undef;
  }
  my $buffered = $self->{'CONTENTS'}{$kind} = [];
  foreach my $node (@$contents) {
    _add_entry($buffered, $node, $root_ir);
  }
  return $buffered;
}

#--------------------------------------------------------------------
sub _parents {
  my ($self) = @_;
  my $root_ir = $self->{'ROOT'};
  my $ir_node = $self->{'NODE'};
  my $kind = $self->{'KIND'};
  my $buffered = $self->{'PARENTS'} = [];
  my $parents;
  if( $kind eq 'dk_Interface' ) {
    $parents = $ir_node->_get_base_interfaces();
  }
  elsif( $kind eq 'dk_Value' ) {
    return [];  # not implemented yet
  }
  else {
    # carp "method base_interfaces() is not supported by ", ref($ir_node);
    return [];
  }
  foreach my $node (@$parents) {
    _add_entry($buffered, $node, $root_ir);
  }
  return $buffered;
}

#--------------------------------------------------------------------
sub _add_entry {
  my ($array, $node, $root_ir) = @_;
  my $name = $node->_get_absolute_name();
  $root_ir->store_entry($name, $node->_get_id(), $node);
  push(@$array, $root_ir->entry($name));
}

1;
