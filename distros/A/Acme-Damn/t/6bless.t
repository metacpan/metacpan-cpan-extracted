#!/usr/bin/perl -w
# $Id: 6bless.t 2311 2012-02-14 15:48:24Z ian $

# bless.t
#
# Ensure the replacement bless "does the right thing"

use strict;
use Test::More tests => 113;
use Test::Exception;

# load Acme::Damn, importing the replacement 'bless'
use Acme::Damn qw( bless );

#
# make sure bless displays the appropriate behaviour
#   - if called with two arguments, with the second argument explicitly set
#     set to 'undef', then default to damn()
#   - otherwise fall back to CORE::bless()
#

# define some argument types for damn
my  @array	= ();
my  %hash   = ();
my  $scalar = 0;

# set the patterns for matching bless exceptions
my  $x      = qr/Can't bless non-reference value/;
my  $c      = qr/Modification of a read-only value attempted/;

# ensure the new bless() exhibits the same live/die behaviour as the
# built-in function
  dies_ok { eval "bless"   or die }      "bless() dies with no arguments";
  dies_ok { eval "bless()" or die }      "bless() dies with no arguments";
throws_ok { bless 1               } $x , "bless() dies with numerical argument";
throws_ok { bless '2'             } $x , "bless() dies with string argument";
throws_ok { bless *STDOUT         } $x , "bless() dies with glob argument";
throws_ok { bless undef           } $x , "bless() dies with undefined argument";
throws_ok { bless \1              } $c , "bless() dies with constant reference";
throws_ok { bless \'2'            } $c , "bless() dies with constant reference";
throws_ok { bless @array          } $x , "bless() dies with array variable";
throws_ok { bless %hash           } $x , "bless() dies with hash variable";
throws_ok { bless $scalar         } $x , "bless() dies with scalar variable";
 lives_ok { bless []              }      "bless() lives with array reference";
 lives_ok { bless {}              }      "bless() lives with hash reference";
 lives_ok { bless sub {}          }      "bless() lives with code reference";
 lives_ok { bless qr/./           }      "bless() lives with regex reference";
 lives_ok { bless \*STDOUT        }      "bless() lives with glob reference";

# ensure we can't bless into a reference
throws_ok { bless [] , [] } qr/Attempt to bless into a reference/
        , "bless() throws correct error with reference argument";


# ensure bless() works with a named package
#   - if the package name is '' then we default to 'main'
my  %try    = ( ''         => 'main'
              , 'main'     => 'main'
              , 'foo'      => 'foo'
              , 'foo::bar' => 'foo::bar'
              );
my  @try    = ( \$scalar
              , []
              , {}
              , sub {}
              , qr/./
              , \*STDERR
              );
foreach my $try ( @try ) {
  my  $type   = ref $try;
  # for Perl earlier than v5.11, a blessed regex is modified to type SCALAR
  #   - $type records the reference type we expect after the 'unbless'
      $type   = 'SCALAR'    if ( $type =~ /Regex/ && $] < 5.011 );

  while ( my ( $pkg , $expect ) = each %try ) {
    no warnings;  # suppress 'excplict bless warning'
    my  $rtn;   undef $rtn;

    # ensure bless() with a package behaves as expected
    lives_ok { $rtn = bless $try , $pkg  }
             "bless() lives with named package and " . $type . " reference";

    is( ref( $rtn ) => $expect
      , "bless() returns " . $type . " reference in package " . $expect
      );

    # ensure bless() with an undef package unblesses the reference
    lives_ok { $rtn = bless $rtn , undef }
             "bless() lives with undef package and " . $type . " reference";

    is( uc ref( $rtn ) => uc $type
      , "bless() returns " . $type . " reference in package " . $expect
      );
  }
}
