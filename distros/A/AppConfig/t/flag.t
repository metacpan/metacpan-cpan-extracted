#!/usr/bin/perl -w
#========================================================================
#
# t/flag.t 
#
# Tests the setting and unsetting of flag variables.
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
# * test EXPAND_WARN option
#
#========================================================================

use strict;
use vars qw($loaded @expect);

BEGIN { 
    # what we expect the debug state(s) to be
    @expect = qw(1 0 1 0 1 0 1 0 1 0 1 0 1 1 1 0);
    my $max = 3 + @expect;

    $| = 1; 
    print "1..$max\n"; 
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

use AppConfig qw(:expand :argcount);
$loaded = 1;
ok(1);



#------------------------------------------------------------------------
# define storage and callback for keeping track of the state of 'debug' 
# variable as it changes.
#
my @debug;

# callback routine to store the state of 'debug' each time it changes
sub debug_set {
    my $cfg = shift;
    my $var = shift;
    my $val = shift;
    push(@debug, $val);
    1;
}


#------------------------------------------------------------------------
# create new AppConfig object
#

my $config = AppConfig->new('debug', { ACTION => \&debug_set });

#2: test config got instantiated correctly
ok( defined $config   );

#3: read the config file (from __DATA__)
ok( $config->file(\*DATA) );

while (@expect) {
    my $e = shift @expect;
    my $d = shift @debug;

    ok( $e == $d );
}


#========================================================================
# the rest of the file comprises the sample configuration information
# that gets read by file()
#

__DATA__
debug
debug 0
debug 1
debug = 0
debug = 1
debug off
debug on
debug Off
debug On
debug OFF
debug ON
debug = off
debug = on
debug is very much turned on
debug = a turned on thing
nodebug


