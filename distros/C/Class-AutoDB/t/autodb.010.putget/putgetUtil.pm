package putgetUtil;
use t::lib;
use strict;
use Carp;
use autodbUtil;
use Exporter();

our @ISA=qw(Exporter);
our @EXPORT=(@autodbUtil::EXPORT,
	     qw($class2colls $class2transients $coll2keys label %test_args));

# class2colls for all classes in putget tests
our $class2colls=
  {Person=>[qw(Person HasName)],
   Student=>[qw(Person Student HasName)],
   Place=>[qw(Place HasName)],
   School=>[qw(Place HasName)],
   Thing=>[],
   Mechanics=>[qw(Mechanics)],
   AllTypes=>[qw(AllTypes HasName)],
   NoKeys=>[qw(NoKeys)],
   NoColls=>[],
   SelfCircular=>[qw(SelfCircular)],
   Structure=>[qw(Structure)],
   Transients=>[qw(Transients)],
   Persistent=>[qw(Persistent)],
   Persistent00=>[qw(Persistent)],
   Persistent02=>[qw(Persistent)],
   Expand=>[qw(Person)],
  };

# coll2keys for all collections in putget tests
our $coll2keys=
  {Person=>[[qw(id name sex)],[qw(friends)]],
   Place=>[[qw(id name country)],[]],
   HasName=>[[qw(id name)],[]],
   Student=>[[qw(id name school)],[]],
   Mechanics=>[[qw(id name string_key integer_key float_key object_key)],
	      [qw(string_list integer_list float_list object_list)]],
   AllTypes=>[[qw(string_key integer_key float_key object_key)],
	      [qw(string_list integer_list float_list object_list)]],
   NoKeys=>[[],[]],
   SelfCircular=>[[qw(id name self)],[qw(self_array)]],
   Structure=>[[qw(id name other)],[]],
   Transients=>[[qw(id name id_mod3)],[]],
   Persistent=>[[qw(id name)],[]],
  };

# class2transients for all collections in putget test
our $class2transients=
  {Transients=>[qw(name_prefix sex_word id_mod3 list)],
  };

# label sub for all putget 'TestObject' tests
sub label {
  my $test=shift;
  my $object=$test->current_object;
#  $object->id.' '.$object->name if $object;
  (UNIVERSAL::can($object,'name')? $object->name:
   (UNIVERSAL::can($object,'desc')? $object->desc:
    (UNIVERSAL::can($object,'id')? $object->id: '')));
}

our %test_args=(class2colls=>$class2colls,class2transients=>$class2transients,
		coll2keys=>$coll2keys,label=>\&label);

1;
