#!/usr/bin/perl -w

# Note - I create a bunch of classes in these tests and then change
# their valid_params() and contained_objects() lists several times.
# This isn't really supported behavior of this module, but it's
# necessary to do it in the tests.

use strict;

use Test;

use Class::Container;
use Params::Validate qw(:types);
use File::Spec;
require File::Spec->catfile('t', 'classes.pl');

my $HAVE_WEAKEN = 0 + exists $INC{'Scalar/Util.pm'};

plan tests => 67 + 1*$HAVE_WEAKEN;

use Carp; $SIG{__DIE__} = \&Carp::confess;

eval {new Daughter(hair => 'long')};
ok $@, '', "Try making an object";

eval {new Parent()};
ok $@, '/mood/', "Should fail, missing required parameter";

my %args = (parent_val => 7,
	    mood => 'bubbly');

eval {new Parent(%args)};
ok $@, '', "Try creating top-level object";

my $mood = eval {Parent->new(%args)->{son}->{mood}};
ok $mood, 'bubbly';
ok $@, '', "Make sure sub-objects are created with proper values";

if ($HAVE_WEAKEN) {
  my $p = Parent->new(%args);
  ok $p->{son}->container, $p, "Container of son should be parent";
}

eval {my $p = new Parent(%args);
      $p->create_delayed_object('daughter')};
ok $@, '', "Create a delayed object";

my $d = eval {Parent->new(%args)->create_delayed_object('daughter', hair => 'short')};
ok $@, '', "Create a delayed object with parameters";
ok $d->{hair}, 'short', "Make sure parameters are propogated to delayed object";

eval {new Daughter(foo => 'invalid')};
ok $@, '/Daughter/', "Make sure error messages contain the name of the class";

# Make sure we can override class names
{
  ok my $p = eval {new Parent(mood => 'foo', parent_val => 1,
			      daughter_class => 'StepDaughter',
			      toy_class => 'Ball',
			      other_toys_class => 'Streamer',
			      son_class => 'StepSon')};
  warn $@ if $@;

  my $d = eval {$p->create_delayed_object('daughter')};
  ok $@, '';

  ok ref($d), 'StepDaughter';
  ok ref($p->{son}), 'StepSon';

  # Note - if one of these fails and the other succeeds, then we're
  # not properly passing 'toy_class' to both son & daughter classes.
  ok ref($d->{toy}), 'Ball';
  ok ref($p->{son}{toy}), 'Ball';

  ok $d->delayed_object_class('other_toys'), 'Streamer';
  ok $p->{son}->delayed_object_class('other_toys'), 'Streamer';

  # Special 'container' parameter shouldn't be shared among objects
  ok ($p->{container} ne $p->{son}{container});

  # Check some of the formatting of show_containers()
  my $string = $p->show_containers;
  ok $string, '/\n  son -> StepSon/', $string;
}


{
  # Check that subclass contained_objects override superclass

  local @Superclass::ISA = qw(Class::Container);
  local @Subclass::ISA = qw(Superclass);
  'Superclass'->valid_params( foo => {isa => 'Foo'} );
  'Subclass'->valid_params(   foo => {isa => 'Bar'} );
  'Superclass'->contained_objects( foo => 'Foo' );
  'Subclass'->contained_objects(   foo => 'Bar' );
  local @Bar::ISA = qw(Foo);
  sub Foo::new { bless {}, 'Foo' }
  sub Bar::new { bless {}, 'Bar' }

  my $child = 'Subclass'->new;
  ok ref($child->{foo}), 'Bar', 'Subclass contained_object should override superclass';

  my $spec = 'Subclass'->validation_spec;
  ok $spec->{foo}{isa}, 'Bar';
}

{
  local @Top::ISA = qw(Class::Container);
  'Top'->valid_params(      document => {isa => 'Document'} );
  'Top'->contained_objects( document => 'Document',
			    collection => {class => 'Collection', delayed => 1} );
  
  local @Collection::ISA = qw(Class::Container);
  'Collection'->contained_objects( document => {class => 'Document', delayed => 1} );
  
  local @Document::ISA = qw(Class::Container);
  local @Document2::ISA = qw(Document);
  
  my $k = new Top;
  print $k->show_containers;
  ok $k->contained_class('document'), 'Document';
  my $collection = $k->create_delayed_object('collection');
  ok ref($collection), 'Collection';
  ok $collection->contained_class('document'), 'Document';

  my $string = $k->show_containers;
  ok $string, '/ collection -> Collection \(delayed\)/';
  ok $string, '/  document -> Document \(delayed\)/';

  my $k2 = new Top(document_class => 'Document2');
  print $k2->show_containers;
  ok $k2->contained_class('document'), 'Document2';
  my $collection2 = $k2->create_delayed_object('collection');
  ok ref($collection2), 'Collection';
  ok $collection2->contained_class('document'), 'Document2';

  my $string2 = $k2->show_containers;
  ok $string2, '/ collection -> Collection \(delayed\)/';
  ok $string2, '/  document -> Document2 \(delayed\)/';
}

{
  local @Top::ISA = qw(Class::Container);
  'Top'->valid_params( document => {isa => 'Document1'} );
  'Top'->contained_objects( document => 'Document1' );
  
  my $contained = 'Top'->get_contained_object_spec;
  ok  $contained->{document};
  ok !$contained->{collection}; # Shouldn't have anything left over from the last block
  
  local @Document1::ISA = qw(Class::Container);
  'Document1'->valid_params( doc1 => {type => SCALAR} );
  
  local @Document2::ISA = qw(Class::Container);
  'Document2'->valid_params( doc2 => {type => SCALAR} );
  
  my $allowed = 'Top'->allowed_params();
  ok  $allowed->{doc1};
  ok !$allowed->{doc2};
  
  $allowed = 'Top'->allowed_params( document_class => 'Document2' );
  ok  $allowed->{doc2};
  ok !$allowed->{doc1};
}

{
  local @Top::ISA = qw(Class::Container);
  'Top'->_expire_caches;
  'Top'->valid_params( document => {isa => 'Document1'} );
  'Top'->contained_objects( document => 'Document1' );
  
  local @Document1::ISA = qw(Class::Container);
  'Document1'->valid_params();
  local @Document2::ISA = qw(Document1);
  'Document2'->valid_params();
  
  my $t = new Top( document => bless {}, 'Document2' );
  ok $t;
  ok ref($t->{document}), 'Document2';
}

{
  local @Top::ISA = qw(Class::Container);
  'Top'->valid_params( document => {isa => 'Document'} );
  'Top'->contained_objects( document => 'Document' );
  
  local @Document::ISA = qw(Class::Container);
  'Document'->valid_params( sub => {isa => 'Class::Container'} );
  'Document'->contained_objects( sub => 'Sub1' );
  
  local @Sub1::ISA = qw(Class::Container);
  'Sub1'->valid_params( bar => {type => SCALAR} );
  'Sub1'->contained_objects();

  local @Sub2::ISA = qw(Class::Container);
  'Sub2'->valid_params( foo => {type => SCALAR} );
  'Sub2'->contained_objects();
  
  my $allowed = 'Top'->allowed_params();
  ok  $allowed->{document};
  ok  $allowed->{bar};
  ok !$allowed->{foo};
  
  $allowed = 'Top'->allowed_params(sub_class => 'Sub2');
  ok  $allowed->{document};
  ok !$allowed->{bar};
  ok  $allowed->{foo};
}

{
  local @Top::ISA = qw(Class::Container);
  Top->valid_params(foo => {type => SCALAR});
  Top->contained_objects();
  
  ok 'Top'->valid_params;
  ok 'Top'->valid_params->{foo}{type}, SCALAR;
}

{
  local @Top::ISA = qw(Class::Container);
  Top->valid_params(foo => {type => SCALAR}, child => {isa => 'Child'});
  Top->contained_objects(child => 'Child');
  
  local @Child::ISA = qw(Class::Container);
  Child->valid_params(bar => {type => SCALAR}, grand_child => {isa => 'GrandChild'});
  Child->contained_objects(grand_child => 'GrandChild');
  
  local @GrandChild::ISA = qw(Class::Container);
  GrandChild->valid_params(baz => {type => SCALAR}, boo => {default => 5});
  GrandChild->contained_objects();

  local @GrandSibling::ISA = qw(GrandChild);

  my $dump = GrandSibling->new(baz => 'BAZ')->dump_parameters;
  ok keys(%$dump), 2;
  ok $dump->{baz}, 'BAZ', "Sibling has baz=BAZ";
  ok $dump->{boo}, 5, "Sibling has boo=5";

  $dump = Child->new(bar => 'BAR', baz => 'BAZ')->dump_parameters;
  ok keys(%$dump), 3;
  ok $dump->{bar}, 'BAR';
  ok $dump->{baz}, 'BAZ';

  $dump = Child->new(bar => 'BAR', baz => 'BAZ', grand_child_class => 'GrandChild')->dump_parameters;
  ok keys(%$dump), 3;
  ok $dump->{bar}, 'BAR';
  ok $dump->{baz}, 'BAZ';
  
  $dump = Top->new(foo => 'FOO', bar => 'BAR', baz => 'BAZ')->dump_parameters;
  ok keys(%$dump), 4;
  ok $dump->{foo}, 'FOO';
  ok $dump->{bar}, 'BAR';
  ok $dump->{baz}, 'BAZ';
  
  
  # Test default values in a delayed object
  Top->valid_params(undef);
  Top->contained_objects(child => {class => 'Child', delayed => 1});
  
  Child->valid_params(bar => {default => 4});
  Child->contained_objects();

  $dump = Top->new()->dump_parameters;
  ok keys(%$dump), 1;
  ok $dump->{bar}, 4;
  
  $dump = Top->new(bar => 6)->dump_parameters;
  ok keys(%$dump), 1;
  ok $dump->{bar}, 6;
}

{
  # Make sure a later call to valid_params() clears the param list
  local @Top::ISA = qw(Class::Container);
  Top->valid_params(undef);
  Top->contained_objects();
  
  ok eval{ new Top };
}

{
  # Make sure valid_params() gives sensible null output
  local @Nonexistent::ISA = qw(Class::Container);
  my $params = Nonexistent->valid_params;
  ok ref($params), 'HASH';
  ok keys(%$params), 0;
}
