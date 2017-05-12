package Class::AutoDB::Object;

use vars qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %SYNONYMS);
use strict;
use Class::AutoClass;
use Class::AutoDB::Globals;
use Class::AutoDB::Serialize;
@ISA = qw(Class::AutoDB::Serialize);
@OTHER_ATTRIBUTES=qw();
Class::AutoClass::declare(__PACKAGE__);

my $GLOBALS=Class::AutoDB::Globals->instance();
sub __autodb {
  my $self=shift;
  $GLOBALS->autodb(@_);
}

# NG 10-08-27: Serialize also defines oid method, which is how Object previously got it
#              moved here as part of interface standardization and namespace cleanup tasks
sub oid {Class::AutoDB::Serialize->obj2oid(@_)}

# pass though to AutoDB if it exists. else, Serialize::store is the best we can do
sub put {
  my($self,$autodb)=@_;
  $autodb or $autodb=$self->__autodb;
  # NG 09-12-19: logic moved to AutoDB for cleanup of user-object namespace
  # my $transients=$autodb->registry->class2transients(ref $self);
  # my $collections=$autodb->registry->class2collections(ref $self);
  # my $oid=$self->oid;
  # $self->Class::AutoDB::Serialize::store($transients); # store the serialized form
  # my @sql=map {$_->put($self)} @$collections; # generate SQL to store object in collections
  # $autodb->do_sql(@sql);
  $autodb? $autodb->put($self): Class::AutoDB::Serialize->store($self);
}

# NG 10-09-09: decided to remove is_extant, is_deleted, del to avoid polluting namespace further
# # NG 10-08-27: part of support for deleted objects
# #              is_extant always says 'yes'; technically not right since object may have
# #              been deleted by another process behind our back. but this is only one
# #              of many ways we get screwed by concurrency. a problem for another day :)
# sub is_extant {1}
# sub is_deleted {0}

# # perfectly fine to call del on Oid. 
# # pass though to AutoDB if it exists. else, Serialize::del is the best we can do
# sub del {
#   my $self=shift;
#   my $autodb=$GLOBALS->autodb;
#   $autodb? $autodb->del($self): Class::AutoDB::Serialize->del($self->oid);
# }
#sub transients {
#  my($self,$autodb)=@_;
#  $autodb or $autodb=$self->autodb;
#  $autodb->registry->class2transients(ref $self);
#}

####################
# NG 05-12-26: added to correct what I think is a bug in Perl's overload support.
#              when I added overloaded "" operation to Oid, it caused real objects
#              to complain that "" was overloaded but no method found. the problem
#              may be caused by objects that start life os Oids then are reblessed.
# NG 10-09-09: as hypothesized above, there is a known bug in Perls < 5.9.4 that
#              cause overloading to fail sometimes with references to reblessed objects.
#              added '""' below as workaround.
use overload
  '""' => sub {$_[0]},
  fallback => 'TRUE';
####################
