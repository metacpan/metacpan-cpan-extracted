#!/usr/bin/perl -w

#========================================================================
#
# t/novars.t 
#
# AppConfig::State test file testing negative setting of flag options
# with "no<var>" syntax.
#
# Written by Andy Wardley <abw@cre.canon.co.uk>
#
# Copyright (C) 1998 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
#------------------------------------------------------------------------
#
# TODO
#
# * test PEDANTIC option
#
#========================================================================

use strict;
use vars qw($loaded);

BEGIN { 
    $| = 1; 
    print "1..18\n"; 
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
# create new AppConfig::State and AppConfig::Args objects
#

my $state = AppConfig::State->new(
    'verbose' => {
       	DEFAULT  => 0,
	ARGCOUNT => ARGCOUNT_NONE,
	ALIAS    => 'v',
    },
    'debug' => {
	ALIAS    => 'dbg|d',
	# should default ARGCOUNT to ARGCOUNT_NONE
    },
    'age' => {
	ALIAS    => 'a',
	ARGCOUNT => ARGCOUNT_ONE,
    },
    'nohope',
);

#2: test the state got instantiated correctly
ok( defined $state );

#3 - #6: update and check verbose
ok( $state->verbose(1)     );
ok( $state->verbose() == 1 );
ok( $state->noverbose(1)   );
ok( $state->verbose() == 0 );

#7 - #15: update and check debug, also using aliases
ok( $state->debug(1)     );
ok( $state->debug() == 1 );
ok( $state->nodebug(1)   );
ok( $state->debug() != 1 );
ok( $state->dbg(1)       );
ok( $state->dbg()   == 1 );
ok( $state->nodbg(1)     );

ok( ! $state->dbg()   );
ok(   $state->nodbg() );

#16 - #17: attempt to update nohope and check it doesn't get interpreted
#          as "no - hope"
ok( $state->nohope(1)     );
ok( $state->nohope() == 1 );

#18: attempt to update noage which should fail because it doesn't 
#    have an ARGCOUNT of ARGCOUNT_NONE
$state->_ehandler( sub { } );    # disable errors
ok( ! $state->noage(1) );

