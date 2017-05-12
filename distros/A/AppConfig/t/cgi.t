#!/usr/bin/perl -w

#========================================================================
#
# t/cgi.t 
#
# AppConfig::CGI test file.
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
    print "1..9\n"; 
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
use AppConfig::CGI;
$loaded = 1;
ok(1);


#------------------------------------------------------------------------
# create new AppConfig::State and AppConfig::CGI objects
#

my $default = "<default>";
my $anon    = "<anon>";
my $user    = "Fred Smith";
my $age     = 42;
my $notarg  = "This is not an arg";

my $state = AppConfig::State->new({
        GLOBAL => { 
            DEFAULT  => $default,
            ARGCOUNT => ARGCOUNT_ONE,
        } 
    },
    'verbose' => {
        DEFAULT  => 0,
        ARGCOUNT => ARGCOUNT_NONE,
        ALIAS    => 'v',
    },
    'user' => {
        ALIAS    => 'u|name|uid',
        DEFAULT  => $anon,
    },
    'age' => {
        ALIAS    => 'a',
        VALIDATE => '\d+',
    });

my $cfgcgi = AppConfig::CGI->new($state);

#2 - #3: test the state and cfgargs got instantiated correctly
ok( defined $state   );
ok( defined $cfgcgi );

my $args = "v&u=$user&age=$age";

#4: process the args
ok( $cfgcgi->parse($args) );

#5 - #7: check variables got updated
ok( $state->verbose() == 1     );
ok( $state->user()    eq $user );
ok( $state->age()     == $age  );

$age = $age * 2;

#8 - #9: check args defaults to using $ENV{ QUERY_STRING }
$ENV{ QUERY_STRING } = "v&u=$user=$user&age=$age";
ok( $cfgcgi->parse() );
ok( $state->age() == $age );

