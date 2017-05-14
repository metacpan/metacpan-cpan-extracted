package CORBA::MICO::IRRoot;

use Carp;

require CORBA::MICO;
require CORBA::MICO::IREntry;

use strict;

#--------------------------------------------------------------------
sub new {
  my ($type, $ir_node) = @_;
  my $class = ref($type) || $type;
  my $self = { 'ROOT'       => $ir_node,
               'ENTRIES'    => {},
               'REPO_IDS'   => {} };
  bless $self, $class;
  $self->store_entry('', '', $ir_node);
  return $self;
}

#--------------------------------------------------------------------
sub entry {
  my ($self, $name) = @_;
  return exists($self->{'ENTRIES'}->{$name}) ? $self->{'ENTRIES'}->{$name}
                                             : $self->_entry($name);
}

#--------------------------------------------------------------------
sub entry_by_id {
  my ($self, $repoid) = @_;
  return exists($self->{'REPO_IDS'}->{$repoid}) ? $self->{'REPO_IDS'}->{$repoid}
                                                : $self->_entry_by_id($repoid);
}

#--------------------------------------------------------------------
sub store_entry {
  my ($self, $name, $repoid, $node) = @_;
  my $entry = new CORBA::MICO::IREntry($name, $node, $self);
  $self->{'ENTRIES'}->{$name}     ||= $entry;
  $self->{'REPO_IDS'}->{$repoid}  ||= $entry;
}

#--------------------------------------------------------------------
sub contents {
  my ($self, $kind, $flag) = @_;
  return $self->entry('')->contents($kind, $flag);
}

#--------------------------------------------------------------------
sub kind {
  my $self = shift;
}

#--------------------------------------------------------------------
sub _entry {
  my ($self, $name) = @_;
  my $node = $self->{'ROOT'}->lookup($name) or return undef;
  return $self->store_entry($name, $node->_get_id(), $node);
}

#--------------------------------------------------------------------
sub _entry_by_id {
  my ($self, $repoid) = @_;
  my $node = $self->{'ROOT'}->lookup_id($repoid);
  return undef unless $node;
  return $self->store_entry($node->_get_absolute_name, $repoid, $node);
}

1;
