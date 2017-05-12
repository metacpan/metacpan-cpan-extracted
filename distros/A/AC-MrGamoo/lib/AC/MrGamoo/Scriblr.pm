# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Dec-21 16:20 (EST)
# Function: 
#
# $Id: Scriblr.pm,v 1.1 2010/11/01 18:41:44 jaw Exp $

package AC::MrGamoo::Scriblr;
use AC::MrGamoo::Config;
use AC::MrGamoo::Debug 'scriblr';
use AC::Import;

require 'AC/protobuf/std_reply.pl';
require 'AC/protobuf/scrible.pl';

use strict;

our @EXPORT = qw(filename);

sub filename {
    my $file = shift;

    if( $file =~ m|/\.| || $file =~ m|^\.| ){
        problem("invalid file '$file'");
        return;
    }
    return conf_value('basedir') . '/' . $file;
}

1;
