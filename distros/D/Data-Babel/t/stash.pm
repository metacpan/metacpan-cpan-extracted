package t::stash;
#################################################################################
# AutoDB wrapper for hash. used to store setup parameters across runs in some tests
# to store data: (NOTE: do NOT call new!)
#  put t::stash autodb=>$autodb,id=>$id,data=>$data
# to get it back:
#  $data=get t::stash autodb=>$autodb,id=>$id
#################################################################################
use strict;
use Carp;
use Class::AutoClass;
use Hash::AutoHash::Args;
use vars qw(@AUTO_ATTRIBUTES @CLASS_ATTRIBUTES %AUTODB);
use base qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(id data);
@CLASS_ATTRIBUTES=qw(autodb);
%AUTODB=(-collection=>'Stash',keys=>'id');
Class::AutoClass::declare;

sub put {
  my $class=shift;
  my $args=new Hash::AutoHash::Args(@_);
  my($autodb,$id,$data)=@$args{(qw(autodb id data))};
  confess "Required parameter 'autodb' missing" unless $autodb;
  confess "Required parameter 'id' missing" unless $id;
  my $self=new $class id=>$id,data=>$data;
  $autodb->put($self);
}

# get data from database
sub get {
  my $class=shift;
  my $args=new Hash::AutoHash::Args(@_);
  my($autodb,$id)=@$args{(qw(autodb id))};
  confess "Required parameter 'autodb' missing" unless $autodb;
  confess "Required parameter 'id' missing" unless defined $id;
  my($old_self)=$autodb->get(collection=>'Stash',id=>$id);
  $old_self->data;
}

1;
