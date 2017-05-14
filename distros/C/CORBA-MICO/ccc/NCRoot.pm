package CORBA::MICO::NCRoot;

use Carp;

require CORBA::MICO;
require CORBA::MICO::NCEntry;

use strict;

#--------------------------------------------------------------------
sub new {
  my ($type, $nc_node) = @_;
  my $class = ref($type) || $type;
  my $self = { 'ROOT'       => $nc_node,
               'ENTRIES'    => {} };
  bless $self, $class;
  $self->store_entry('', $nc_node);
  return $self;
}

#--------------------------------------------------------------------
sub entry {
  my ($self, $name) = @_;
  return exists($self->{'ENTRIES'}->{$name}) ? $self->{'ENTRIES'}->{$name}
                                             : $self->_entry($name);
}

#--------------------------------------------------------------------
sub store_entry {
  my ($self, $name, $node) = @_;
  my $entry = new CORBA::MICO::NCEntry($name, $node, $self);
  $self->{'ENTRIES'}->{$name}     ||= $entry;
}

#--------------------------------------------------------------------
sub contents {
  my ($self) = @_;
  return $self->entry('')->contents();
}

#--------------------------------------------------------------------
sub is_ncontext {
  my ($self) = @_;
  return $self->entry('')->is_ncontext();
}

#--------------------------------------------------------------------
sub _entry {
  my ($self, $name) = @_;
  my $node = $self->{'ENTRIES'}->{''}->lookup($name) or return undef;
  return $self->store_entry($name, $node);
}

1;
