#!/usr/bin/perl -w
# $Id: 16version.t 1511 2010-08-21 23:24:49Z ian $

# version.t
#
# Ensure VERSION() and REVISION() behave appropriately.

use strict;
use Test::More tests => 15;
use Test::Exception;

# create a package with just version information
package Test::Version::One;

use base qw( Class::Declare );
use vars qw( $VERSION       );
             $VERSION = '0.04';

1;

# return to the default package
package main;

# make sure this still reports 0.04 through the call to REVISION()
ok( Test::Version::One->VERSION eq '0.04' ,
    'normal version information reported correctly' );


# create a package with just revision information
#   NB: have to hack this to make sure CVS doesn't expand the
#       revision string (so that we can compare with a constant value)

package Test::Version::Two;

use base qw( Class::Declare );
use vars qw( $REVISION      );
             $REVISION  = '$Rev' . 'ision: 1.2.3 $';

1;

# return to the default package
package main;

# make sure the REVISION() method returns the correct revision number
ok( Test::Version::Two->REVISION eq '1.2.3' ,
    'revision information reported correctly' );

# make sure the version is the same as the revision
ok( Test::Version::Two->REVISION eq Test::Version::Two->VERSION ,
    'version numbers from revision strings reports correctly' );


# create a package with revision and version information
#   NB: have to hack this to make sure CVS doesn't expand the
#       revision string (so that we can compare with a constant value)

package Test::Version::Three;

use base qw( Class::Declare     );
use vars qw( $REVISION $VERSION );
             $REVISION  = '$Rev' . 'ision: 1.2.3 $';
             $VERSION   = '0.4';

1;

# return to the default package
package main;

# make sure the REVISION() method returns the correct revision number
ok( Test::Version::Three->REVISION eq '1.2.3' ,
    'revision information reported correctly with version information' );

# make sure the version is the reported correctly
ok( Test::Version::Three->VERSION  eq '0.4'   ,
    'version numbers overriding revision strings reports correctly' );

# ensure required versioning is supported
#   - packages with a defined version
ok( Test::Version::Three->VERSION(  '0.3' )  eq '0.4'   ,
    'required plain version supported' );
ok( Test::Version::Three->VERSION( 'v0.3' )  eq '0.4'   ,
    'required qualified version supported' );
#   - packages with a defined revision only
ok( Test::Version::Two->VERSION(  '1.2.1' )  eq '1.2.3' ,
    'required plain version supported' );
ok( Test::Version::Two->VERSION( 'v1.2.1' )  eq '1.2.3' ,
    'required qualified version supported' );
#   - require a version/revision ahead of that provided by the package
throws_ok { Test::Version::Three->VERSION( 'v2' ) }
          qr/version \S+ required--this is only/ ,
          'require qualified future version fails as expected';
throws_ok { Test::Version::Two->VERSION( '2.3.4' ) }
          qr/version \S+ required--this is only/ ,
          'require plain future version fails as expected';

# ensure an invalid required version is reported correctly
throws_ok { Test::Version::Three->VERSION( 'abcd' ) }
          qr/Invalid version format/ ,
          'require invalid version fails as expected';


# create a package without version or revision information

package Test::Version::Four;

use base qw( Class::Declare );

1;

# return to the default package
package main;

ok( ! defined( Test::Version::Four->REVISION ) ,
    'undefined revision reported correctly' );
ok( ! defined( Test::Version::Four->VERSION  ) ,
    'undefined version reported correctly' );

# ensure required version checks not supported for packages that do not
# provide a version or revision
throws_ok { Test::Version::Four->VERSION( '1.2' ) }
          qr/does not define \S+::VERSION--version check failed/ ,
          'require version fails as expected for non-versioned packages';
