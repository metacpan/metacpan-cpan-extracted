#!/usr/bin/perl -w
####-----------------------------------
### File	: testGclk.pl
### Author	: Ch.Minc
### Purpose	: Synopsis for GameClock
### Version	: 1.0 2007/12/23
### copyright GNU license
####-----------------------------------

use strict ;
use warnings ;

use Tk ;
use Chess::GameClock::GameClock ;

use Chess::GameClock::GclkDisplay qw(display);

our $VERSION = '1.0' ;

my $clock=GameClock->new ;

# set a cadence following the GUI menu - no GUI
#my ($whites,$blacks)=$clock->set("Blitz Usuel 1") ;

# set a cadence using the cadence parameters
#my ($whites,$blacks)=$clock->set( [{qw/ct 15*60 mv 0 b 0 f 0 byo 1/},
#                                   {qw/ct 15*60 mv 0 b 0 f 0 byo 1/}] ) ;
# test byo-yomi japonais
#my ($whites,$blacks)=$clock->set(
#                                 [{qw/ct    7 mv 0 b 0 f 0 byo 0/},    
#                                  {qw/ct 3*5 mv 1 b 3 f 0 byo 0/}] ) ;

# last of the three modes no parameters means GUI
our ($whites,$blacks)=$clock->set ;
&GclkDisplay::display($whites,$blacks,0.75) ;
MainLoop ;


