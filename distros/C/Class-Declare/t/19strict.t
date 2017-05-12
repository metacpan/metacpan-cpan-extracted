#!/usr/bin/perl -w
# $Id: 19strict.t 1511 2010-08-21 23:24:49Z ian $

# strict.t
#
# Ensure turning strict off permits calling of prohibited methods &
# attributes (e.g. private, protected, static, etc)

use strict;
use lib                   qw( t          );
use Class::Declare::Test  qw( :constants );

#
# define all the tests permutations that are expected to live
#

# all tests should behave the same regardless of context
my  @contexts = ( CTX_CLASS    , CTX_DERIVED   , CTX_UNRELATED ,
                  CTX_INSTANCE , CTX_INHERITED , CTX_FOREIGN   );

# class attributes/methods are accessible and readable, but not writeable
my  @class    = ( TGT_CLASS    , TGT_DERIVED   );
# instance attributes/methods are accessible, readable and writeable
my  @instance = ( TGT_INSTANCE , TGT_INHERITED );

# add the class tests
#   i.e. for class, static and restricted attributes and methods
my  @ctests;  undef @ctests;
foreach my $context ( @contexts ) {
  # the method and attribute behaviours are the same for classes as
  # for instances
  foreach my $target ( @class , @instance ) {
    # class attributes are accessible, readable and not writeable
    push @ctests , ( $context | $target | ATTRIBUTE | TST_ACCESS | LIVE ,
                     $context | $target | ATTRIBUTE | TST_READ   | LIVE ,
                     $context | $target | ATTRIBUTE | TST_WRITE  | DIE  ,

    # class methods are accessbile and readable
    # NB: Class::Declare::Test will only test methods for
    #     accessibility and to determine if the values are
    #     readable. All other tests are meaningless for methods.
                     $context | $target | METHOD    | TST_ALL    | LIVE );
  }
}

# add the instance tests
#   i.e. for public, private and protected attributes and methods
my  @itests;  undef @itests;
foreach my $context ( @contexts ) {
  # access is permitted for instances
  foreach my $target ( @instance ) {
    # instance attributes are accessible, readable and writeable
    push @itests , ( $context | $target | ATTRIBUTE | TST_ALL    | LIVE ,

    # instance methods are accessbile and readable
    # NB: Class::Declare::Test will only test methods for
    #     accessibility and to determine if the values are
    #     readable. All other tests are meaningless for methods.
                     $context | $target | METHOD    | TST_ALL    | LIVE );
  }

  # for classes, attribute access is denied since we need to be
  # able to resolve the referrant to a Class::Declare hash, but
  # access is permitted to methods (we have no idea what the
  # method will do)
  foreach my $target ( @class ) {
    push @itests , ( $context | $target | ATTRIBUTE | TST_ALL    | DIE  ,
                     $context | $target | METHOD    | TST_ALL    | LIVE );
  }
}


# run the class attribute/method tests
foreach my $type ( qw( class static restricted ) ) {
  # create the test object
  my  $test = Class::Declare::Test->new( type  =>  $type   ,
                                         tests => \@ctests ,
                                         check => 0        );
  # run the tests
    $test->run;
}

# run the instance attribute/method tests
foreach my $type ( qw( public private protected ) ) {
  # create the test object
  my  $test = Class::Declare::Test->new( type  =>  $type   ,
                                         tests => \@itests ,
                                         check => 0        );
  # run the tests
    $test->run;
}


# Declare Class::Declare-derived packages to test the return value of strict()
package Test::Strict::Undef;
use base qw( Class::Declare );
__PACKAGE__->declare( strict => undef );
1;

package Test::Strict::One;
use base qw( Class::Declare );
__PACKAGE__->declare( strict => 1    );
1;

package Test::Strict::Zero;
use base qw( Class::Declare );
__PACKAGE__->declare( strict => 0     );
1;


# Declare inherited classes for testing strict()
package Test::Strict::Inherit::Undef;
use base qw( Test::Strict::Undef );
1;

package Test::Strict::Inherit::One;
use base qw( Test::Strict::One );
1;

package Test::Strict::Inherit::Zero;
use base qw( Test::Strict::Zero );
1;


# Declare override classes for testing strict()
package Test::Strict::One::Zero;
use base qw( Test::Strict::One );
__PACKAGE__->declare( strict => 0 );
1;

package Test::Strict::Zero::One;
use base qw( Test::Strict::Zero );
__PACKAGE__->declare( strict => 1 );
1;

package Test::Strict::Zero::Undef;
use base qw( Test::Strict::Zero );
__PACKAGE__->declare( strict => undef );
1;

package Test::Strict::One::Undef;
use base qw( Test::Strict::One );
__PACKAGE__->declare( strict => undef );
1;


 
package main;

use Test::More;

# ensure strict() returns true for ::Undef and ::One but not ::Zero
#   - class access
ok(   Test::Strict::Undef->strict , 'strict() correct for class undef' );
ok(   Test::Strict::One->strict   , 'strict() correct for class one'   );
ok( ! Test::Strict::Zero->strict  , 'strict() correct for class zero'  );

#   - instance access
my  $undef = Test::Strict::Undef->new;
my  $one   = Test::Strict::One->new;
my  $zero  = Test::Strict::Zero->new;

ok(   $undef->strict , 'strict() correct for instance undef' );
ok(   $one->strict   , 'strict() correct for instance one'   );
ok( ! $zero->strict  , 'strict() correct for instance zero'  );

#   - inherited class access
ok(   Test::Strict::Inherit::Undef->strict     ,
    'inherit strict() correct for class undef' );
ok(   Test::Strict::Inherit::One->strict       ,
    'inherit strict() correct for class one'   );
ok( ! Test::Strict::Inherit::Zero->strict      ,
    'inherit strict() correct for class zero'  );

#   - inherited instance access
    $undef = Test::Strict::Undef->new;
    $one   = Test::Strict::One->new;
    $zero  = Test::Strict::Zero->new;

ok(   $undef->strict , 'strict() correct for inherited instance undef' );
ok(   $one->strict   , 'strict() correct for inherited instance one'   );
ok( ! $zero->strict  , 'strict() correct for inherited instance zero'  );

#   - inherited class access
ok( ! Test::Strict::One::Zero->strict    ,
    'override strict() correct for class 1-0'  );
ok(   Test::Strict::Zero::One->strict    ,
    'override strict() correct for class 0-1'  );
ok( ! Test::Strict::Zero::Undef->strict  ,
    'override strict() correct for class zero' );
ok(   Test::Strict::One::Undef->strict   ,
    'override strict() correct for class one'  );

#   - inherited instance access
    $one   = Test::Strict::One::Zero->new;
    $zero  = Test::Strict::Zero::One->new;
    $undef = Test::Strict::Zero::Undef->new;
my  $obj   = Test::Strict::One::Undef->new;

ok( ! $one->strict   , 'strict() correct for override instance 1-0'  );
ok(   $zero->strict  , 'strict() correct for override instance 0-1'  );
ok( ! $undef->strict , 'strict() correct for override instance zero' );
ok(   $obj->strict   , 'strict() correct for override instance one'  );
