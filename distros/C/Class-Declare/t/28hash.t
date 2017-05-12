#!/usr/bin/perl -w
# $Id: 28hash.t 1511 2010-08-21 23:24:49Z ian $

# hash.t
#
# Ensure hash() behaves as it should.

use strict;
use warnings;

use Test::More      tests => 19;
use Test::Exception;


# subroutine prototypes
sub cmp_hash    ($$);
sub is_num      ($);


# define default values for test classes
my  $__array  = [ 1 , 2 , 3 , 4 ];
my  $__hash   = { key => 'value' };
my  $__code   = sub { rand };


# firstly, create a package that we can generate a hash of
#  - want to ensure it contains each type of attribute
package Test::Hash::Zero;

use strict;
use warnings;
use base qw( Class::Declare );

# add a reoutine for calling hash()
sub parent
{
  my  $self = __PACKAGE__->class( shift );
      $self->hash;
} # parent()

1;

package Test::Hash::One;

use strict;
use base qw( Test::Hash::Zero );

{
  my  $friends  = [ qw( main::hash Test::Hash::Three ) ];

__PACKAGE__->declare( class      => { my_class      => 1        } ,
                      static     => { my_static     => $__code  } ,
                      restricted => { my_restricted => $__array } ,
                      public     => { my_public     => $__hash  } ,
                      private    => { my_private    => undef    } ,
                      protected  => { my_protected  => $__hash  } ,
                      abstract   =>  'my_abstract'                ,
                      friends    =>  $friends                     );

# add a routine for calling the hash()
sub call
{
  my  $self = __PACKAGE__->class( shift );
      $self->hash;
} # call()

}

1;

# return to main for the tests
package main;

# create a test instance
my  $class  = 'Test::Hash::One';
my  $object = $class->new;

# define an is_num() comparitor
sub is_num($)
{
  # certain strings can cause the lines after this one to throw a
  # warning, so let's try to catch it out
  return 0        if ( $_[ 0 ] =~ /\W/o );

  my  $value  = ( eval $_[ 0 ] ) || $_[ 0 ];
  return ( ( $value & ~$value ) eq '0' );
} # is_num()


# define hash comparison routines
#   - not a recursive comparison; just to the first-level values
sub cmp_hash($$)
{
  my  $a    = shift;
  my  $b    = shift;

  # if both $a and $b are undefined, then they are considered the same
    ( $a && $b )       or return ( ! defined $a && ! defined $b );

  # if $a and $b refer to the same hash then they are the same
    ( $a == $b )      and return 1;

  # two hashes are only the same if they have the same keys and if the values
  # for each key matches
  #   - find the keys in $a that are not in $b
  my  @nb   = grep { ! exists $b->{ $_ } } keys %{ $a };
  #   - find the keys in $b that are not in $a
  my  @na   = grep { ! exists $a->{ $_ } } keys %{ $b };

  # if we have a mismatch in keys then these two hashes are not the same
    ( @nb || @na )    and return undef;

  # otherwise, we know that these two hashes share the same keys, so we now
  # must compare values
  KEY: foreach my $k ( keys %{ $a } ) {
    my  $va   = $a->{ $k };
    my  $vb   = $b->{ $k };

    # if the two values are undefined, then they are the same
    next KEY        if ( ! defined $va && ! defined $vb );
    # otherwise, if one of them is undefined, then they are different
    return undef    if ( ! defined $va || ! defined $vb );

    # we now know that these two values are defined, so we can compare values
    #   - have to see if we are dealing with numbers or strings
    #   - first, let's look for references
    if ( ref $va && ref $vb ) {
      # if we have a reference, then if they are the same type then we need to
      # dig deeper
      if ( ref $va eq ref $vb ) {
        foreach ( ref $va ) {
          # compare the two hashes
          /HASH/o   && do {
            # if these two hashes are different, then fail the comparison
            ( cmp_hash( $va => $vb ) )
                and next KEY
                 or return undef;
          };

          # compare two arrays
          /ARRAY/o  && do {
            # if the two arrays are different, then fail the comparison
            ( join( ':' , @{ $va } ) eq join( ':' , @{ $vb } ) )
                and next KEY
                 or return undef;
          };

          # compare the two scalars
          /SCALAR/o && do {
            my  $sa   = ${ $va };
            my  $sb   = ${ $vb };

            # have we got numbers or strings?
            if ( is_num $sa  && is_num $sb ) {
              ( $sa == $sb )
                and next KEY
                 or return undef;
            } else {
              ( $sa eq $sb )
                and next KEY
                 or return undef;
            }
          };

          # if we have anything else, compare the references themselves
          ( $va == $vb )
              and next KEY
               or return undef;
        }

      # otherwise, the two references aren't the same type
      } else {
        return undef;
      }

    # otherwise, if we have one reference only
    } elsif ( ref $va || ref $vb ) {
      return undef;
    }

    # otherwise, both $va and $vb are scalars, so we need to know whether we
    # have a number or string for both values
    if ( is_num $va && is_num $vb ) {
      ( $va == $vb )
          and next KEY
           or return undef;
    } else {
      ( $va eq $vb )
          and next KEY
           or return undef;
    }
  }

  1;  # the two hashes are the same
} # cmp_hash()


#
# define the expected results strings
#

my  %hash_zero_class    = ();
my  %hash_zero_instance = ();
my  %hash_one_class     = ( my_class    => 1       ,
                            my_abstract => undef   );
my  %hash_one_instance  = ( my_class    => 1       ,
                            my_abstract => undef   ,
                            my_public   => $__hash );

    $class              = 'Test::Hash::Zero';
    $object             = $class->new;
# ensure the 'all' conversion to hash works from a public access
ok( cmp_hash( scalar( $class->hash  ) => \%hash_zero_class    ) ,
    'Test::Hash::Zero->hash() returns correctly'                );
ok( cmp_hash( scalar( $object->hash ) => \%hash_zero_instance ) ,
    'Test::Hash::Zero=REF->hash() returns correctly'            );

    $class              = 'Test::Hash::One';
    $object             = $class->new;
# ensure the 'all' conversion to hash works from a public access
ok( cmp_hash( scalar( $class->hash  ) => \%hash_one_class    ) ,
    'Test::Hash::One->hash() returns correctly'                );
ok( cmp_hash( scalar( $object->hash ) => \%hash_one_instance ) ,
    'Test::Hash::One=REF->hash() returns correctly'            );

# now try the call within the class context
    %hash_one_class     = ( my_restricted => $__array ,
                            my_class      => 1        ,
                            my_abstract   => undef    ,
                            my_static     => $__code  );
    %hash_one_instance  = ( my_restricted => $__array ,
                            my_class      => 1        ,
                            my_private    => undef    ,
                            my_public     => $__hash  ,
                            my_abstract   => undef    ,
                            my_protected  => $__hash  ,
                            my_static     => $__code  );
ok( cmp_hash( scalar( $class->call  ) => \%hash_one_class    ) ,
    'Test::Hash::One->call() returns correctly'                );
ok( cmp_hash( scalar( $object->call ) => \%hash_one_instance ) ,
    'Test::Hash::One=REF->call() returns correctly'            );


# ensure access controls are preserved
dies_ok { $class->hash( static      => 1 ) }
        'access controls honoured on class method';
dies_ok { $object->hash( restricted => 1 ) }
        'access controls honoured on instance method';


# now create a derived class so that we can test the hash output from the
# derived scope
package Test::Hash::Two;

use strict;
use warnings;
use base qw( Test::Hash::One );

# add a local routine for calling hash()
sub dispatch
{
  my  $self = __PACKAGE__->class( shift );
      $self->hash( @_ );
} # dispatch()

1;


# create another derived class for testing depth and backtrace
package Test::Hash::Three;

use strict;
use warnings;

use base qw( Test::Hash::Two );

my  $one    = Test::Hash::One->new;

__PACKAGE__->declare(

  class  => { my_nested    => $one ,
              my_reference => $one }

);  # declare()

1;


# return to main to resume the testing
package main;

# OK, now take a hash from within a derived class
my  %hash_two_class     = ( my_class    => 1       ,
                            my_abstract => undef   );
my  %hash_two_instance  = ( my_class    => 1       ,
                            my_abstract => undef   ,
                            my_public   => $__hash );

    $class              = 'Test::Hash::Two';
    $object             = $class->new;
# ensure the 'all' conversion to hash works from a public access
ok( cmp_hash( scalar( $class->hash  ) => \%hash_two_class    ) ,
    'Test::Hash::Two->hash() returns correctly'                );
ok( cmp_hash( scalar( $object->hash ) => \%hash_two_instance ) ,
    'Test::Hash::Two=REF->hash() returns correctly'            );

# now try the call within the class context
    %hash_two_class     = ( my_restricted => $__array ,
                            my_class      => 1        ,
                            my_abstract   => undef    );
    %hash_two_instance  = ( my_restricted => $__array ,
                            my_class      => 1        ,
                            my_public     => $__hash  ,
                            my_abstract   => undef    ,
                            my_protected  => $__hash  );
ok( cmp_hash( scalar( $class->dispatch  ) => \%hash_two_class    ) ,
    'Test::Hash::Two->dispatch() returns correctly'                );
ok( cmp_hash( scalar( $object->dispatch ) => \%hash_two_instance ) ,
    'Test::Hash::Two=REF->dispatch() returns correctly'            );


# now test for backtrace and depth support
#   - restrict this to class methods to keep it short ;)
    $class              = 'Test::Hash::Three';

# if we set the depth to 0, we shouldn't get an expansion of 'my_nested'
my  $ref                = $class->dispatch( depth => 0 );
#   - so 'my_nested' shouldn't be a HASH reference
ok( ref $ref->{ my_nested } ne 'HASH' ,
    'depth => 0 tested as expected'   );
#   - while no 'depth' should expand it
    $ref                = $class->dispatch;
ok( ref $ref->{ my_nested } eq 'HASH' ,
    'no depth tested as expected'     );

# if we have backtracing on (default), then the hash references generated
# should be repeated where the object references are the same
#   - my_nested->my_restricted == my_restricted
ok( $ref->{ my_nested } == $ref->{ my_reference } ,
    'backtracing working as expected'             );

# turn backtracing off and the references should be different
    $ref                = $class->dispatch( backtrace => 0 );
ok( $ref->{ my_nested } != $ref->{ my_reference } ,
    'backtracing off working as expected'         );


# create another class for testing references buried in arrays and hashes
package Test::Hash::Four;

use strict;
use warnings;

use base qw( Test::Hash::One );

__PACKAGE__->declare(

  class => { my_array => [            1 , Test::Hash::One->new ] ,
             my_hash  => { one   =>   1                        ,
                           two   =>       Test::Hash::One->new ,
                           three => [ 1 , Test::Hash::One->new ] } ,
           }

);  # declare()

1;


# return to main to resume the testing
package main;

# now test to ensure hash references and arrays are properly expanded as well
    $class              = 'Test::Hash::Four';

# perform a normal expansion for this class
    $ref                = $class->call;

# we should be able to test the following conditions
#   - $ref->{ my_array }->[1] == $hash_one_instance
ok( cmp_hash( $ref->{ my_array }->[1] , \%hash_one_instance ) ,
    'array expansion working as expected'                     );
#   - $ref->{ my_hash }->{ two } = $hash_one_instance
ok( cmp_hash( $ref->{ my_hash }->{ two } , \%hash_one_instance ) ,
    'hash expansion working as expected'                         );
#   - $ref->{ my_hash }->{ three }->[1] = $hash_one_instance
ok( cmp_hash( $ref->{ my_hash }->{ three }->[1] , \%hash_one_instance ) ,
    'nested expansion working as expected'                              );
