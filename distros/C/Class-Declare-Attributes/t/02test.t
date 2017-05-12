#!/usr/bin/perl
# $Id: 02test.t 1515 2010-08-22 14:41:53Z ian $

# test.t
#
# Ensure the Class::Declare::Attribute::Test module compiles and we can create
# test instances correctly.

use strict;
use lib       	qw( t );
use Test::More;

# make sure Class::Declare::Attribute::Test compiles
BEGIN{ use_ok( 'Class::Declare::Attributes::Test' ) }

# This Is Bad(tm)
#   - changes somewhere in Perl mean that the first test below
#     fails if Test::Exception is included *before* the use_ok()
#     test above
#   - the error is within Carp::Heavy and appears to be the result
#     Perl getting lost in its handling of the stack
#   - not a lot of mention of it online, so it's not a common bug
#   - example error:
#         Bizarre copy of ARRAY in sassign at 
#             /usr/share/perl/5.10/Carp/Heavy.pm line 96
use Test::Exception;

# create test instances to ensure they can be created
#    NB: we'll use an empty set of tests
my	$tests	= [];
my	$test;

# create a class instance
lives_ok {
	Class::Declare::Attributes::Test->new( tests => $tests       ,
	                                       type  => 'class'      )
} 'class test object creation succeeded';

# create a static instance
lives_ok {
	Class::Declare::Attributes::Test->new( tests => $tests       ,
	                                       type  => 'static'     )
} 'static test object creation succeeded';

# create a restricted instance
lives_ok {
	Class::Declare::Attributes::Test->new( tests => $tests       ,
	                                       type  => 'restricted' )
} 'restricted test object creation succeeded';

# create a public instance
lives_ok {
	Class::Declare::Attributes::Test->new( tests => $tests       ,
	                                       type  => 'public'     )
} 'public test object creation succeeded';

# create a private instance
lives_ok {
	Class::Declare::Attributes::Test->new( tests => $tests       ,
	                                       type  => 'private'    )
} 'private test object creation succeeded';

# create a protected instance
lives_ok {
	Class::Declare::Attributes::Test->new( tests => $tests       ,
	                                       type  => 'protected'  )
} 'protected test object creation succeeded';
