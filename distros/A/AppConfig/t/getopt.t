#!/usr/bin/perl -w

#========================================================================
#
# t/getopt.t 
#
# AppConfig::Getopt test file.
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
    print "1..10\n"; 
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
# create new AppConfig
#

my $default = "<default>";
my $anon    = "<anon>";
my $user    = "Fred Smith";
my $age     = 42;
my $notarg  = "This is not an arg";

my $config = AppConfig->new({
#	DEBUG    => 1,
	ERROR    => sub { 
		my $format = "ERR: " . shift() . "\n"; 
		printf STDERR $format, @_;
	    },
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
	ARGS     => '=s',              # explicit Getopt::Long args
	DEFAULT  => $anon,
    },
    'age' => {
	ALIAS    => 'a',
	VALIDATE => '\d+',
	                               # NOTE: Getopt::Long args 
				       # constructed automatically
    });

#2: test the AppConfig got instantiated correctly
ok( defined $config );

my @args = ('-v', '-u', $user, '--age', $age, $notarg);

#3: process the args
# $config->_debug(1);
ok( $config->getopt(qw(default auto_abbrev), \@args) );
# $config->_debug(0);

#4 - #6: check variables got updated
ok( $config->verbose() == 1     );
ok( $config->user()    eq $user );
ok( $config->age()     eq $age  );

#7: next arg should be $notarg
ok( $args[0] = $notarg );

#8 - #10: check args defaults to using @ARGV
@ARGV = ('--age', $age * 2, $notarg);
ok( $config->getopt() );
ok( $config->age() == ($age * 2) );
ok( $ARGV[0] eq $notarg );


