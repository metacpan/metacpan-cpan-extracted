# -*- perl -*-

# Copyright (c) 2010 by Jeff Weisberg
# Author: Jeff Weisberg <jaw @ tcp4me.com>
# Created: 2010-Nov-01 14:07 (EDT)
# Function: for convenience
#
# $Id: User.pm,v 1.1 2010/11/01 18:41:45 jaw Exp $

package AC::MrGamoo::User;
use strict;

sub import {
    my $class  = shift;
    my $caller = caller;

    no strict;
    no warnings;

    # export R
    *{$caller . '::R'} = \$AC::MrGamoo::User::R
}

1;

=head1 NAME

AC::MrGamoo::User - namespace where your map/reduce job lives

=cut

