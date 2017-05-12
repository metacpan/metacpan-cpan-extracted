#!/usr/bin/perl -w

#========================================================================
#
# t/multi.t 
#
# AppConfig::State test file for multiple options (list, hash) 
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
    print "1..27\n"; 
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
my $user1   = 'foo';
my $user2   = 'bar';
my $user3   = 'baz';
my $var1    = "age=29";
my $var2    = "sex=male";
my $var3    = "eyes=blue";

 
#------------------------------------------------------------------------
# define a new AppConfig::State object
#

my $state = AppConfig::State->new({ 
	GLOBAL => { 
	    DEFAULT  => $default,
	    ARGCOUNT => ARGCOUNT_NONE,
	},
    },
    'verbose', {
       	DEFAULT  => 0,
    },
    'user', {
	ARGCOUNT => ARGCOUNT_LIST,
    },
    'var', {
	ARGCOUNT => ARGCOUNT_HASH,
    });

   

#------------------------------------------------------------------------
# check and manipulate variables
#

#2: check state got defined
ok( defined $state );

#3 - #5: check default values
ok( $state->verbose()   == 0       );
ok( ref($state->user()) eq 'ARRAY' );
ok( ref($state->var())  eq 'HASH'  );

#6 - #8: check ARGCOUNT got set explicitly or by default
ok( $state->_argcount('verbose') == ARGCOUNT_NONE );
ok( $state->_argcount('user')    == ARGCOUNT_LIST );
ok( $state->_argcount('var')     == ARGCOUNT_HASH );

#9 - #10: set verbose value and check 
ok( $state->verbose(1)     );
ok( $state->verbose() == 1 );

#11 - #13: set multiple user values
ok( $state->user($user1) );
ok( $state->user($user2) );
ok( $state->user($user3) );

#14 - 15: check user values were set
my $userlist = $state->user();
ok( ref($userlist) eq 'ARRAY' );
ok(   $userlist->[0] eq $user1 
   && $userlist->[1] eq $user2 
   && $userlist->[2] eq $user3 );

#16 - #18: set hash var values
ok( $state->var($var1) );
ok( $state->var($var2) );
ok( $state->var($var3) );

#19 - #22: check var hash value were set
my $varhash = $state->var();
ok( ref($varhash)      eq 'HASH' );
ok( $varhash->{'age'}  ==  29    );
ok( $varhash->{'sex'}  eq 'male' );
ok( $varhash->{'eyes'} eq 'blue' );

#23 - #25 : reset values to defaults
ok(     $state->_default('verbose') eq 0 );
ok( ref($state->_default('user'))   eq 'ARRAY'  );
ok( ref($state->_default('var'))    eq 'HASH'   );

#26 - #27: check default ARRAY/HASH are empty
ok( scalar @{ $state->user() } == 0 );
ok( scalar %{ $state->var()  } == 0 );

