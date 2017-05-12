# base class that sets id
package HasID;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES);
use strict;
use autodbUtil;			# to get id_next

@AUTO_ATTRIBUTES=qw(id);
Class::AutoClass::declare;

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  $self->id(id_next());
}
1;
