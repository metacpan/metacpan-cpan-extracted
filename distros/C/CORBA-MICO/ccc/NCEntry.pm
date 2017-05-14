package CORBA::MICO::NCEntry;

use Carp;

require CORBA::MICO::NCRoot;
require CORBA::MICO;

use strict;

#--------------------------------------------------------------------
sub new {
  my ($type, $name, $nc_node, $root_node, $kind, $parent) = @_;
  my $class = ref($type) || $type;
  return bless { 'CONTENTS' => undef,
                 'NAME'     => $name,
                 'ROOT'     => $root_node,
                 'KIND'     => $kind || 'ncontext',
                 'NODE'     => $nc_node,
                 'PARENT'   => $parent }, $class;
}

#--------------------------------------------------------------------
sub name {
  my $self = shift;
  return $self->{'NAME'};
}

#--------------------------------------------------------------------
sub kind {
  my $self = shift;
  return $self->{'KIND'};
}

#--------------------------------------------------------------------
sub root_nc {
  my $self = shift;
  return $self->{'ROOT'};
}

#--------------------------------------------------------------------
sub nc_node {
  my $self = shift;
  return $self->{'NODE'};
}

#--------------------------------------------------------------------
sub contents {
  my ($self) = @_;
  if( not defined($self->{'CONTENTS'}) ) {
    my $contents = [];
    if( $self->kind() eq 'ncontext' ) {
      my $nc = $self->{'NODE'};
      my ($bl, $bi) = $nc->list(0);
      if( defined($bi) ) {
        while( 1 ) {
          my ($ret, $b_list) = $bi->next_n(100);
          last unless $ret;
          foreach my $binding (@$b_list) {
            my $name = build_name($binding->{binding_name});
            my $node = $nc->resolve($binding->{binding_name});
            my $root_node = $self->root_nc();
            my $type = $binding->{binding_type};
            my $entry = new CORBA::MICO::NCEntry($name, $node,
                                                 $root_node, $type, $self);
            push(@$contents, $entry);
          }
        }
      }
      $self->{'CONTENTS'} = $contents;
    }
  }
  return $self->{'CONTENTS'};
}

#--------------------------------------------------------------------
sub parents {
  my ($self) = @_;
  return $self->{'PARENTS'} || $self->_parents();
}

#--------------------------------------------------------------------
sub is_ncontext {
  my ($self) = @_;
  my $kind = $self->{'KIND'};
  return ($kind eq 'ncontext');
}

#--------------------------------------------------------------------
sub full_name {
  my ($self) = @_;
  my $parent = $self->{'PARENT'};
  my $ret = (defined($parent) ? $parent->full_name() : "");
  return $self->{NAME} ? ($ret . "/$self->{NAME}") : $ret;
}

#--------------------------------------------------------------------
sub locurl {
  my ($self) = @_;
  return call_nsadmin("locurl " . $self->full_name());
}

#--------------------------------------------------------------------
sub url {
  my ($self) = @_;
  return call_nsadmin("url " . $self->full_name());
}

#--------------------------------------------------------------------
sub iordump {
  my ($self) = @_;
  return call_nsadmin("iordump " . $self->full_name());
}

#--------------------------------------------------------------------
sub call_nsadmin {
  my ($cmd) = @_;
  open CMD, "nsadmin $cmd|" or return "";
  my $of = select(CMD); undef $/; select($of);
  my $ret = <CMD>;
  close CMD;
  return $ret;
}

#--------------------------------------------------------------------
sub build_name {
  my $name = shift;
  return join(' ', map { "$_->{id}" } @$name);
}

1;
