# -*- perl -*-

# Copyright (c) 2010 by AdCopy
# Author: Jeff Weisberg
# Created: 2010-Feb-18 11:05 (EST)
# Function: 
#
# $Id$

package AC::SHA1File;
use AC::Import;
use Digest::SHA1;
use strict;

our @EXPORT = qw(sha1_file);

sub sha1_file {
    my $file = shift;

    open(my $f, $file) || return ;
    my $sh = Digest::SHA1->new();
    $sh->addfile($f);
    return $sh->b64digest();
}


1;
