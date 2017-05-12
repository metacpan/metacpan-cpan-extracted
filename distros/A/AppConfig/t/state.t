#!/usr/bin/perl -w

#========================================================================
#
# t/state.t 
#
# AppConfig::State test file.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#========================================================================

use strict;
use vars qw($loaded);

BEGIN { 
    $| = 1; 
    print "1..45\n"; 
}

END {
    ok(0) unless $loaded;
}

my $ok_count = 1;
sub ok {
    shift or print "not ";
    print "ok $ok_count\n";
    ++$ok_count;
}

use AppConfig qw(:argcount);
use AppConfig::State;
$loaded = 1;
ok(1);


#------------------------------------------------------------------------
# define variables and handler subs
#

my $default = "<default>";
my $none    = "<none>";
my $user    = 'abw';
my $age     = 29;
my $verbose = 0;
my $errors  = 0;

# user validation routine
sub check_user {
    my $var = shift;
    my $val = shift;

    return ($val eq $user);
}

# verbose action routine
sub verbose {
    my $state = shift;
    my $var   = shift;
    my $val   = shift;

    # set global $verbose so we can test that this sub was called
    $verbose  = $val;

    # ok
    return 1;
}

sub error {
    my $format = shift;
    my @args   = @_;

    $errors++;
}

 
#------------------------------------------------------------------------
# define a new AppConfig::State object
#

my $state = AppConfig::State->new({ 
	ERROR  => \&error,
	GLOBAL => { 
	    DEFAULT  => $default,
	    ARGCOUNT => ARGCOUNT_ONE,
	},
    },
    'verbose', {
       	DEFAULT  => 0,
	ACTION   => \&verbose,
	ARGCOUNT => ARGCOUNT_NONE,
    },
    'user', {
	ALIAS    => 'name|uid',
	VALIDATE => \&check_user,
	DEFAULT  => $none,
    },
    'age', {
	VALIDATE => '\d+',
    });

# $state->_dump();
   

#------------------------------------------------------------------------
# check and manipulate variables
#

#2: check state got defined
ok( defined $state );

#3 - #5: check default values
ok( $state->verbose() == 0        );
ok( $state->user()    eq $none    );
ok( $state->age()     eq $default );

#6 - #8: check ARGCOUNT got set explicitly or by default
ok( $state->_argcount('verbose') == 0 );
ok( $state->_argcount('user')    == 1 );
ok( $state->_argcount('age')     == 1 );

#9 - #11: set values 
ok( $state->verbose(1)  );
ok( $state->user($user) );
ok( $state->age($age)   );

#12 - #14: read them back to check values got set correctly
ok( $state->verbose() == 1     );
ok( $state->user()    eq $user );
ok( $state->age()     == $age  );

#15: test that the verbose ACTION was called and $verbose set
ok( $verbose == 1 );

#16 - #19: test the VALIDATE patterns/subs by attempting to set invalid values
ok( ! $state->age('old')      );
ok(   $state->age()  == $age  );
ok( ! $state->user('dud')     );
ok(   $state->user() eq $user );

#20: check that the error handler correctly updated $errors
ok( $errors == 2 );

#21 - #22: access variables via alias
ok( $state->name() eq $user );
ok( $state->uid()  eq $user );

#23 - #25: test case insensitivity
ok( $state->USER() eq $user );
ok( $state->NAME() eq $user );
ok( $state->UID()  eq $user );

#26 - #27: explicitly test get() and set() methods
ok( $state->set('verbose', 100)   );
ok( $state->get('verbose') == 100 );


#------------------------------------------------------------------------
# define a different AppConfig::State object
#

my $newstate = AppConfig::State->new({ 
	CASE     => 1,
	CREATE => '^define_',
	PEDANTIC => 1,
	ERROR    => \&error,
    });

#28: check state got defined
ok( defined $newstate );

#29 - #30: test CASE sensitivity
$errors = 0;
ok( ! $newstate->Foo() );
ok( $errors );

#31 - #32: test PEDANTIC mode is/isn't set in states
ok( !  $state->_pedantic() );
ok( $newstate->_pedantic() );

#33 - #34: test auto-creation of define_ variable
ok( $newstate->define_user($user)     );
ok( $newstate->define_user() eq $user );



#------------------------------------------------------------------------
# define a third AppConfig::State object to test compact format
#

my $thirdstate = AppConfig::State->new("foo|bar|baz=s");

#35: check state got defined
ok( defined $thirdstate );

$thirdstate->define("tom|dick|harry=i@");
$thirdstate->define("red|green|blue=s");

#36 - #42: check set()/get() for foo and aliases
ok( $thirdstate->foo(5)     );
ok( $thirdstate->foo() == 5 );
ok( $thirdstate->bar(6)     );
ok( $thirdstate->bar() == 6 );
ok( $thirdstate->baz(7)     );
ok( $thirdstate->baz() == 7 );
ok( $thirdstate->foo() == 7 );

#43 - #45: check ARGCOUNT for all vars
ok( $thirdstate->_args('foo') eq '=s'  );
ok( $thirdstate->_args('tom') eq '=i@' );
ok( $thirdstate->_args('red') eq '=s'  );
 

