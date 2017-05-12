package Class::AutoDB::Oid;
use Class::AutoDB::Serialize;
use Class::AutoDB::Globals;
use Scalar::Util qw(refaddr);

my $GLOBALS=Class::AutoDB::Globals->instance();
my $OID2OBJ=$GLOBALS->oid2obj;
my $OBJ2OID=$GLOBALS->obj2oid;

sub DUMPER_freeze {return $_[0];}
sub DUMPER_thaw {
  my($self)=@_;
  my $oid=$self->{_OID};
  #print "<<< Class::AutoDB::Oid::DUMPER_thaw $self ($oid)\n";  
  my $obj=$OID2OBJ->{$oid};
  # NG 10-09-11: yet another place where testing object messes up on Oid or OidDeleted,
  #              'cuz 'bool' overloaded...
  # return $obj if $obj;
  return $obj if ref $obj;
  $OID2OBJ->{$oid}=$self;	# save for next time -- to preserve shared object structure
  $OBJ2OID->{refaddr $self}=$oid;
  $self;
}
# AutoClass defines a 'class' method and AutoDB::Object defines 'oid' method
# but invoking on Oid forces a fetch.
# We override methods here to avoid fetch.
# NG 09-11-12: AutoClass no longer defines class
# NG 09-12-19: Object->oid now deprecated. I say this to clarify comment above
# sub class {$_[0]->{_CLASS};}
sub oid {$_[0]->{_OID};}

# AutoDB::Object defines 'put' method but invoking on Oid forces a fetch.
# If object not in memory, put is unncessary anyway
# NG 09-12-19: Object->put now deprecated. I say this to clarify comment above
sub put {
  # NG 10-08-27: entire subroutine is exercise in futile paranoia.
  #              can only get here if object is Oid in which case 'put' is nop
  # my $self=shift;
  # my $oid=$self->oid;
  # my $obj=$OID2OBJ->{$self->oid};
  # return if !$obj || UNIVERSAL::isa($obj,'Class::AutoDB::Oid');
  # return $obj->put(@_);
}

# NG 12-10-28: redispatch UNIVERSAL methods to Oid's class
sub isa {shift->{_CLASS}->isa(@_)}
sub can {shift->{_CLASS}->can(@_)}
sub DOES {shift->{_CLASS}->DOES(@_)}
sub VERSION {shift->{_CLASS}->VERSION(@_)}

# NG 10-09-09: decided to remove is_extant, is_deleted, del to avoid polluting namespace further
# # NG 10-08-27: part of support for deleted objects
# #              have to fetch object since that's the only way to know whether it's deleted.
# #              probably not too big a performance hit, since application is likely to
# #              access object pretty soon anyway...
# sub is_extant {
#   my $self=shift;
#   my $oid=$self->oid;
#   Class::AutoDB::Serialize::fetch($oid); # changes $self to real object or OidDeleted
#   ref $self ne 'Class::AutoDB::OidDeleted';
# }
# sub is_deleted {!shift->is_extant}

# # perfectly fine to call del on Oid. 
# # pass though to AutoDB if it exists. else, Serialize::del is the best we can do
# sub del {
#   my $self=shift;
#   my $autodb=$GLOBALS->autodb;
#   $autodb? $autodb->del($self): Class::AutoDB::Serialize->del($self->oid);
# }

use vars qw($AUTOLOAD);
sub AUTOLOAD {
  my $self=shift;
  my $method=$AUTOLOAD;
  $method=~s/^.*:://;             # strip class qualification
  return if $method eq 'DESTROY'; # the books say you should do this
  my $oid=$self->{_OID};

  ####################
  # use object's class if not already done
  # Caution: this all works fine if people follow the Perl convention of
  #  placing module Foo in file Foo.pm.  Else, there's no easy way to
  #  translate a classname into a string that can be 'used'
  # The test 'unless ${$class.'::'}{AUTODB}' cause the 'use' to be skipped if
  #  the class is already loaded.  This should reduce the opportunities
  #  for messing up the class-to-file translation.
  # Note that %{$class.'::'} is the symbol table for the class. There seem
  # to be many cases in which perl creates skeleton symbol tables for a
  # class. By looking for the AUTODB slot, I'm trying to make sure that the
  # body of the class has been used.

  # NG 09-01-14: fixed dumb ass bug: the eval "use..." below is, of course, not run 
  #   if the class is already loaded.  This means that the value of $@ is not reset
  #   by the eval.  So, if it had a true value before the eval, it will have the 
  #   same value afterwards causing the error code to be run!
  #   FIX: changed "use" to "require" (which returns true on success) and use the
  #   return value to control whether error code run
  #  eval "use $class" unless ${$class.'::'}{AUTODB};
  my $class=$self->{_CLASS};
  unless (${$class.'::'}{AUTODB}) {
    eval "require $class" or die $@;
  }
  
  ####################
  my $obj=Class::AutoDB::Serialize::fetch($oid);

  return $obj->$method(@_);
}
####################
# NG 05-12-26
# Fetch object when used as string, so serialized objects will work as expected
# when used as hash keys. Body of code same as AUTOLOAD. 
# TODO: refactor someday
sub stringify {
  my $self=shift;
  my($oid,$class)=@$self{qw(_OID _CLASS)};

  # NG 09-01-14: fixed dumb ass bug: see abouve 
  # eval "use $class" unless ${$class.'::'}{AUTODB};
  unless (${$class.'::'}{AUTODB}) {
    eval "require $class" or die $@;
  }
  my $obj=Class::AutoDB::Serialize::fetch($oid);
  "$obj";
}
# NG 10-09-11: removed eq, ne. Perl autogenerates from stringify
# NG 10-09-11: changed bool to force fetch
# NG 10-09-17: added '0+' (convert to number), since Perls >= 5.10 stringify objects otherwise
use overload
  '""' => \&stringify,
  '0+' => sub {refaddr($_[0])},
  'bool'=>sub {length(stringify($_[0]))>0},
  fallback => 'TRUE';
####################
1;
