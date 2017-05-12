# %AUTODB example from DESCRIPTION/Defining a persistent class

package PctAUTODB_AllTypes;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(name friend_names id friend_ids age friend_ages friend friends);
%DEFAULTS=(friend_names=>[],friend_ids=>[],friend_ages=>[],friends=>[]);
%AUTODB=
  (collection=>'PersonAllTypes',
   keys=>qq(name string, friend_names list(string),
            id integer, friend_ids list(integer),
            age float, friend_ages list(float),
            friend object, friends list(object)));  
Class::AutoClass::declare;

# set friend and list attributes
sub set_friends {
  my($self,$friend)=@_;
  $self->friend($friend);
  my @friends=($friend,$self);
  $self->friends(\@friends);
  for my $friend (@friends) {
    push(@{$self->friend_names},$friend->name);
    push(@{$self->friend_ids},$friend->id);
    push(@{$self->friend_ages},$friend->age);
  }
}
1;
