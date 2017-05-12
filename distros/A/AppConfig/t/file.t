#!/usr/bin/perl -w

#========================================================================
#
# t/file.t 
#
# AppConfig::File test file.
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
use vars qw($loaded);
use lib qw( ../lib ./lib );
use Test::More tests => 43;

use AppConfig qw(:expand :argcount);
use AppConfig::File;
ok(1);


#------------------------------------------------------------------------
# create new AppConfig::State and AppConfig::File objects
#------------------------------------------------------------------------

my $state = AppConfig::State->new({
            CREATE   => '^(?:define|here)_',
            GLOBAL => { 
                EXPAND   => EXPAND_ALL,
                ARGCOUNT => ARGCOUNT_ONE,
            },
        },
        'html', 
        'same',
        'split',
        'title', 'ident',
        'cash'    => { EXPAND => EXPAND_NONE },     # ignore '$' in cash
        'hdir'    => { EXPAND => EXPAND_VAR  },     # expand only $vars
        'verbose' => { ARGCOUNT => ARGCOUNT_NONE }, # simple flags..
        'cruft'   => { 
            ARGCOUNT => ARGCOUNT_NONE,
            DEFAULT  => 1,
        },
        'debug'   => {
            ARGCOUNT => ARGCOUNT_NONE,
            DEFAULT  => 1,
        }, 
        'chance'   => {
            ARGCOUNT => ARGCOUNT_NONE,
            DEFAULT  => 1,
        }, 
        'hope'   => {
            ARGCOUNT => ARGCOUNT_NONE,
            DEFAULT  => 1,
        }, 
        'drink'  => {
            ARGCOUNT => ARGCOUNT_LIST,
        },
        'name'  => {
            ARGCOUNT => ARGCOUNT_HASH,
        },
        'here_empty' => {
            ARGCOUNT => ARGCOUNT_NONE,
        },
        'here_hash' => {
            ARGCOUNT => ARGCOUNT_HASH,
        },
    );

# turn debugging on to trigger debugging in $cfgfile
# $state->_debug(1);
my $cfgfile = AppConfig::File->new($state);

# AppConfig::State can be turned off, AppConfig::File debugging remains on.
# $state->_debug(0);

ok( defined $state, 'state defined' );
ok( defined $cfgfile, 'cfgfile defined' );

ok( $cfgfile->parse(\*DATA), 'parsed' );


#------------------------------------------------------------------------
# test variable values got set with correct expansion
#------------------------------------------------------------------------

# html has no embedded variables
ok( $state->html() eq 'public_html' );

# cash should *not* be expanded (EXPAND_NONE) to protect '$'
ok( $state->cash() eq 'I won $200!' );

SKIP: {
        skip("User does not have a home directory", 2) unless defined $ENV{HOME};

        #  hdir expands variables ($html) but not uids (~)
        ok( $state->hdir() eq '~/public_html' );

        # see if "[~/$html]" matches "[${HOME}/$html]".  It may fail if your
        #   platform doesn't provide getpwuid().  See AppConfig::Sys for details.
        my ($one, $two) = 
        $state->same() =~ / \[ ( [^\]]+ ) \] \s+=>\s+ \[ ( [^\]]+ ) \]/gx;
        is( $one, $two, 'one is two' );
}

# test that "split" came out the same as "same"
is( $state->same(), $state->split(), 'same split' );

# test that "verbose" got set to 1 when no parameter was provided
is( $state->verbose(), 1, 'verbose' );

# test that debug got turned off by explicit (debug = 0)
ok( ! $state->debug(), 'not debuggin' );

# test that cruft got turned off by "nocruft"
ok( ! $state->cruft(), 'not crufty' );
ok(   $state->nocruft(), 'nocruft' );

# test that chance got turned on by "nochance = 0"
ok(   $state->chance(), 'there is a chance' );
ok( ! $state->nochance(), 'there is not no chance' );

# test that hope got turned on by "nohope = off"
ok(   $state->hope(), 'there is hope' );
ok( ! $state->nohope(), 'there is not no hope'  );

# check auto-creation of variables and variable expansion of
#          [block] variable
is( $state->define_user(), 'abw', 'user is abw');
is( $state->define_home(), '/home/abw', 'home is /home/abw' );
is( $state->define_chez(), '/chez/abw', 'chez is /chez/abw' );
is( $state->define_choz(), 'foo#bar', 'choz is set' );
is( $state->define_chuz(), '^#', 'chuz is set' );

#21 - #22: test $state->varlist() without strip option
my (%set, $expect, $got);
%set    = $state->varlist('^define_');
$expect = 'define_chaz=/$chez/#chaz, define_chez=/chez/abw, define_choz=foo#bar, define_chuz=^#, define_home=/home/abw, define_user=abw';
$got    = join(', ', map { "$_=$set{$_}" } sort keys %set);

is( scalar keys %set, 6, 'five keys' );
is( $expect, $got, 'varlist' );

#23 - #24: test $state->varlist() with strip option
%set    = $state->varlist('^define_', 1);
$expect = 'chaz=/$chez/#chaz, chez=/chez/abw, choz=foo#bar, chuz=^#, home=/home/abw, user=abw';
$got    = join(', ', map { "$_=$set{$_}" } sort keys %set);

is( scalar keys %set, 6, 'five stripped keys');
is( $expect, $got, 'stripped varlist' );

#25 - #27: test ARGCOUNT_LIST
my $drink = $state->drink();
is( $drink->[0], 'coffee', 'coffee');
is( $drink->[1], 'beer', 'beer');
is( $drink->[2], 'water', 'water');

#28 - #31: test ARGCOUNT_HASH
my $name = $state->name();
my $crew = join(", ", sort keys %$name);
ok( $crew eq "abw, mim, mrp" );
ok( $name->{'abw'} eq 'Andy'           );
ok( $name->{'mrp'} eq 'Martin'          );
ok( $name->{'mim'} eq 'Man in the Moon' );

#32 - #33: test quoting
ok( $state->title eq "Lord of the Rings");
ok( $state->ident eq "Keeper of the Scrolls");

# test \$ and \# suppression 
is( $state->define_chaz(), '/$chez/#chaz', 'chaz defined' );

# test whitespace required before '#'
is( $state->define_choz(), 'foo#bar', 'choz defined' );
is( $state->define_chuz(), '^#', 'chuz defined' );

#39 - #42: test here-doc
ok( ! $state->here_empty(),    'empty here-doc');
is( $state->here_linebreaks(), <<HERE, 'line breaks');

 white spaces are preserved in here-doc, except the last linebreak.
HERE
is( $state->here_quote(), '<<NOT_A_HERE_DOC_if_in_quotes', 'heredoc in quotes');
is( $state->here_eof(), "parse() reads to eof if the boundary string is absent.\n", 'heredoc with EOF');
is_deeply( $state->here_hash(), {
        'key1' => 'value 1',
        'key2' => 'value 2',
        'key3' => "multi-line\nvalue 3",
        '"key 4"' => "<<AA\n  recursive here-doc not supported.\nAA",
}, 'hash with here-doc values');


#========================================================================
# the rest of the file comprises the sample configuration information
# that gets read by parse()
#========================================================================

__DATA__
# lines starting with '#' are regarded as comments and are ignored
html = public_html
cash = I won $200!
hdir = ~/$html
same  = [~/$html] => [${HOME}/$html]
verbose
debug = 0
nocruft

# this next one should turn chance ON (equivalent to "chance = 1")
nochance = 0
nohope   = off

# the next line has a continutation, but should be treated the same
split = [~/$html] => \
[${HOME}/$html]

# test list definitions
drink coffee
drink beer
drink water

# test hash definitions
name   abw = Andy
name   mrp = Martin
name = mim = "Man in the Moon"

# test quoting
title = "Lord of the Rings"
ident = 'Keeper of the Scrolls'

[define]
user = abw     # this is a comment
home = /home/$user
chez = /chez/$define_user
chaz = /\$chez/\#chaz  # this is also a comment
choz = foo#bar    # this is a comment, but the '# bar' part wasn't 
chuz = ^#         # so is this, nor was that

[here]
empty = <<BAR
BAR
linebreaks =<<'BAR'

 white spaces are preserved in here-doc, except the last linebreak.

BAR
quote ='<<NOT_A_HERE_DOC_if_in_quotes'

hash = key1 =<<---
value 1
---
hash = key2= "value 2"

# Putting hash keys in here doc is ugly, not recommended, but supported
hash = <<---
key3 = multi-line
value 3
---

hash = <<===
"key 4" = <<AA
  recursive here-doc not supported.
AA
===

eof = <<---
parse() reads to eof if the boundary string is absent.

