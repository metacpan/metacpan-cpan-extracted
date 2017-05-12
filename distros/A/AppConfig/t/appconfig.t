#!/usr/bin/perl -w
#========================================================================
#
# t/appconfig.t
#
# AppConfig test file.
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
$loaded = 1;
ok(1);


#------------------------------------------------------------------------
# define a new AppConfig object
#

my $default = "<default>";
my $anon    = "<anon>";
my $noage   = "<unborn>";

my $config = AppConfig->new({ 
        GLOBAL => { 
            DEFAULT  => $default,
            ARGCOUNT => ARGCOUNT_ONE,
        } 
    },
    'verbose', {
        DEFAULT  => 0,
        ARGCOUNT => ARGCOUNT_NONE,
    },
    'user', {
        ALIAS    => 'name|uid',
        DEFAULT  => $anon,
    });

$config->define(
    'age', {
        DEFAULT  => $noage,
        VALIDATE => '\d+',
    });

   

#------------------------------------------------------------------------
# check and manipulate variables
#

#2: check config got defined
ok( defined $config );

#3 - #5: check variables were defined
ok( $config->verbose() == 0      );
ok( $config->user()    eq $anon  );
ok( $config->age()     eq $noage );

#6: read config file at DATA handle
ok( $config->file(\*DATA) );

#7 - #9: check values got updated correctly
ok( $config->verbose() == 1     );
ok( $config->user()    eq 'abw' );
ok( $config->age()     == 42    );


__DATA__
verbose = 1
user    = abw
age     = 42
