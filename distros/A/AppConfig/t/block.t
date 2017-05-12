#!/usr/bin/perl -w

#========================================================================
#
# t/block.t 
#
# AppConfig::File test file.  Tests [block] definitions in config files.
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
use AppConfig qw(:expand :argcount);
use AppConfig::File;
use Test::More tests => 7;


#------------------------------------------------------------------------
# create new AppConfig::State and AppConfig::File objects

my $state = AppConfig::State->new(
        {
                GLOBAL => {
                        ARGCOUNT => ARGCOUNT_ONE,
                },
        },
        'foo',
        'bar',
        'dir_home', {
                EXPAND => EXPAND_ENV,
        },
        'dir_html', {
                EXPAND => EXPAND_ENV,
        },
        );

# $state->_debug(1);

my $cfgfile = AppConfig::File->new($state);

# $state->_debug(0);

#2 - #3: test that state and cfgfile got instantiated correctly
ok( defined $state, 'defined state' );
ok( defined $cfgfile, 'defined cfgfile' );

#4: read the config file (from __DATA__)
ok( $cfgfile->parse(\*DATA), 'parsed config' );


#5 - #6: test simple variable values got set correctly
ok( $state->foo eq 'This is foo', 'foo is set' );
ok( $state->bar eq 'This is bar', 'bar is set' );

#7 - #8: test [dir] block variables got set correctly
SKIP: {
        skip 'No HOME environment variable set', 2 unless $ENV{ HOME };
        ok( $state->dir_home eq  $ENV{HOME}, 'matched HOME');
        ok( $state->dir_html eq ($ENV{HOME} . '/public_html'), 'matched HTML' );
}



#========================================================================
# the rest of the file comprises the sample configuration information
# that gets read by parse()
#

__DATA__
# lines starting with '#' are regarded as comments and are ignored
foo = This is foo
bar = This is bar

[dir]
home = ${HOME}
html = ${HOME}/public_html

