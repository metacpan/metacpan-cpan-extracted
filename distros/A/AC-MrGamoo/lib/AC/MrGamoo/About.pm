# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-26 11:29 (EST)
# Function: 
#
# $Id: About.pm,v 1.1 2010/11/01 18:41:39 jaw Exp $

package AC::MrGamoo::About;
use AC::Import;
use strict;

our @EXPORT = 'my_port';
my $port;

sub init {
    my $class = shift;
    $port = shift;
}

sub my_port { $port }

1;
