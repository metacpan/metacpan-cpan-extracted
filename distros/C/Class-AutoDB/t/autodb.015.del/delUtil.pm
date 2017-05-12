package delUtil;
use t::lib;
use strict;
use Carp;
use autodbUtil;
use Exporter();

our @ISA=qw(Exporter);
our @EXPORT=(@autodbUtil::EXPORT,
	     qw($class2colls $coll2keys $default_diffs label %test_args));

# class2colls for all classes in del tests (adapted from putget tests)
# some classes not (yet) used in del tests
our $class2colls=
  {Person=>[qw(Person HasName)],
   Student=>[qw(Person Student HasName)],
   Place=>[qw(Place HasName)],
   School=>[qw(Place HasName)],
   Thing=>[],
   Mechanics=>[qw(Mechanics)],
   NoKeys=>[qw(NoKeys)],
   NoColls=>[],
   SelfCircular=>[qw(SelfCircular)],
   Structure=>[qw(Structure)],
   Persistent=>[qw(Persistent)],
   Persistent00=>[qw(Persistent)],
   Persistent02=>[qw(Persistent)],
   FindDel=>[qw(FindDel)],
   FindDel_case=>[qw(FindDel)],
  };

# coll2keys for all collections in del tests (adapted from putget tests)
# some classes not (yet) used in del tests
our $coll2keys=
  {Person=>[[qw(id name sex)],[qw(friends)]],
   Place=>[[qw(id name country)],[]],
   HasName=>[[qw(id name)],[]],
   Student=>[[qw(id name school)],[]],
   Mechanics=>[[qw(id name string_key integer_key float_key object_key)],
	      [qw(string_list integer_list float_list object_list)]],
   NoKeys=>[[],[]],
   SelfCircular=>[[qw(id name self)],[qw(self_array)]],
   Structure=>[[qw(id name other)],[]],
   Persistent=>[[qw(id name)],[]],
   FindDel=>[[qw(id name testcase)],[]],
  };

# default table diffs. any table not mentioned has default of 1
our $default_diffs=
  {Person_friends=>2,
  };

our %test_args=(class2colls=>$class2colls,coll2keys=>$coll2keys,default_diffs=>$default_diffs,
		label=>'');

1;
