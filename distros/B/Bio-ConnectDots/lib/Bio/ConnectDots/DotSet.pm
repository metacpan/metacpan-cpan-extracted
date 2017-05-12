package Bio::ConnectDots::DotSet;
use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use Bio::ConnectDots::Connector;
use Bio::ConnectDots::Dot;
use Class::AutoClass;
@ISA = qw(Class::AutoClass); # AutoClass must be first!!

@AUTO_ATTRIBUTES=qw(name db db_id _id2dot);
@OTHER_ATTRIBUTES=qw();
%SYNONYMS=();
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  return if $self->db_id;	       # already fetched
  return unless $self->db;
  my $saved=Bio::ConnectDots::DB::DotSet->get($self);
  unless ($saved) {
    Bio::ConnectDots::DB::DotSet->put($self);
  } else {			# copy relevant attributes from db object to self
    $self->db_id($saved->db_id);
  }
}
sub id2dot {
  my $self=shift;
  my $id2dot=$self->_id2dot || $self->_id2dot({});
  if (@_==0) {
    return  wantarray? %$id2dot: $id2dot;
  } elsif (@_==1 && ('HASH' eq ref $_[0] || !defined $_[0])) {
    my $result=$self->_id2dot($_[0]);
    return wantarray? %$result: $result;
  } elsif (@_==1) {
    return $id2dot->{$_[0]};
  } else {
    return $id2dot->{$_[0]}=$_[1];
  }
}
sub instances {
  my($self)=@_;
  my $id2dot=$self->id2dot;
  my @instances=values %$id2dot;
  wantarray? @instances: [@instances];
}
sub lookup_connect {
  my($self,$id,$connector)=@_;
  my $dot=$self->id2dot($id);
  unless ($dot) {
    $dot=new Dot(-id=>$id);
    $self->id2dot($id,$dot);
  }
  $dot->put($connector);
}
sub lookup {
  my($self,$id)=@_;
  my $dot=$self->id2dot($id);
  unless ($dot) {
    $dot=new Bio::ConnectDots::Dot(-id=>$id);
    $self->id2dot($id,$dot);
  }
  $dot;
}
1;
