#!/usr/bin/perl -w
# $Id: 05test.t 1511 2010-08-21 23:24:49Z ian $

# test.t
#
# Ensure the Class::Declare::Test module compiles and we can create
# test instances correctly.

use strict;
use lib         qw( t );
use Test::More;
use Test::Exception;

# make sure Class::Declare:;Test compiles
BEGIN{ use_ok( 'Class::Declare::Test' ) }

# create test instances to ensure they can be created
#    NB: we'll use an empty set of tests
my  $tests  = [];

# create a class instance
lives_ok { Class::Declare::Test->new( tests => $tests  ,
                                      type  => 'class' ) }
         'class test object creation succeeded';

# create a static instance
lives_ok { Class::Declare::Test->new( tests => $tests  ,
                                      type  => 'static' ) }
         'static test object creation succeeded';

# create a restricted instance
lives_ok { Class::Declare::Test->new( tests => $tests  ,
                                      type  => 'restricted' ) }
         'restricted test object creation succeeded';

# create a public instance
lives_ok { Class::Declare::Test->new( tests => $tests  ,
                                      type  => 'public' ) }
         'public test object creation succeeded';

# create a private instance
lives_ok { Class::Declare::Test->new( tests => $tests  ,
                                      type  => 'private' ) }
         'private test object creation succeeded';

# create a protected instance
lives_ok { Class::Declare::Test->new( tests => $tests  ,
                                      type  => 'protected' ) }
         'protected test object creation succeeded';

# create an unknown instance
{
 # don't want the warning message to show with the test results
 local  $SIG{__WARN__}  = sub {};

 dies_ok { Class::Declare::Test->new( tests => $tests  ,
                                      type  => 'foobar' ) }
         'foobar test object creation failed';
}
