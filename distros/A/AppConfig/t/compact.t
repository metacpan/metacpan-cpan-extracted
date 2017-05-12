#!/usr/bin/perl -w

#========================================================================
#
# t/compact.t 
#
# AppConfig test file validating the use of the compact definition format.
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
    print "1..19\n"; 
    $" = ', ';
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
my $file1   = 'File_Number_One';
my $file2   = 'File_Number_Two';
my %define  = (
        'first' => 'first hash value',
        'next'  => 'next hash value',
        'last'  => 'last hash value',
    );

my $config = AppConfig->new({
        ERROR    => sub { 
                my $format = "ERR: " . shift() . "\n"; 
                printf STDERR $format, @_;
            },
        GLOBAL => { 
            DEFAULT  => $default,
            ARGCOUNT => ARGCOUNT_ONE,
        } 
    },
    'verbose|v!',
    'filelist|file|f=s@',
    'user|u|name|uid=s',
    'define|defvar' => { 
        ARGS => "=s%" 
    },
    'multi' => { 
        ARGCOUNT => ARGCOUNT_LIST,
    },
    'age|a' => {
        VALIDATE => '\d+',
                                       # NOTE: Getopt::Long args 
                                       # constructed automatically
    });

#2: test the AppConfig got instantiated correctly
ok( defined $config );

my @defargs = map { ( "--define", "\"$_=$define{ $_ }\"" ) } keys %define;

my @args = ('-v', 
        '-u', $user, 
        '--age', $age, 
        '--file', $file1, '-f', $file2, 
        @defargs,
        '-multi', 1, '--multi', 2, '-m', 3,
        $notarg);

#3: process the args
# $config->_debug(1);
ok( $config->getopt(qw(default auto_abbrev), \@args) );
# $config->_debug(0);

#4 - #6: check variables got updated
ok( $config->verbose() == 1     );
ok( $config->user()    eq $user );
ok( $config->age()     eq $age  );

#7 - #10: check list variable (file) got set
my $files;
ok( defined ($files = $config->filelist()) );
ok( scalar @$files == 2 );
ok ($files->[0] eq $file1 );
ok ($files->[1] eq $file2 );

#11 - #15: check list variable (multi) got set
my $multi;
ok( defined ($multi = $config->multi()) );
ok( scalar @$multi == 3 );
foreach my $i (1..3) {
    ok ($multi->[$i - 1] == $i ); 
}


#16: next arg should be $notarg
ok( $args[0] = $notarg );

#17 - #19: check args defaults to using @ARGV
@ARGV = ('--age', $age * 2, $notarg);
ok( $config->getopt() );
ok( $config->age() == ($age * 2) );
ok( $ARGV[0] eq $notarg );


