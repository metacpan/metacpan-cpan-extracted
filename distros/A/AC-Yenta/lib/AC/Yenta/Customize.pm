# -*- perl -*-

# Copyright (c) 2010 AdCopy
# Author: Jeff Weisberg
# Created: 2010-Jan-26 10:37 (EST)
# Function: connect user provided implementation
#
# $Id$

package AC::Yenta::Customize;
use strict;

sub customize {
    my $class  = shift;
    my $implby = shift;

    (my $default = $class) =~ s/(.*)::([^:]+)$/$1::Default::$2/;

    # load user's implemantation + default
    for my $p ($implby, $default){
        eval "require $p" if $p;
        die $@ if $@;
    }

    # import/export
    no strict;
    no warnings;
    for my $f ( @{$class . '::CUSTOM'} ){
        *{$class . '::' . $f} = ($implby && $implby->can($f)) || $default->can($f);
    }
}

1;
