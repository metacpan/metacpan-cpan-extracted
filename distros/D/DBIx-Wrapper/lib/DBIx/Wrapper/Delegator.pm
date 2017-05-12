# -*-perl-*-
# Creation date: 2005-03-04 21:15:40
# Authors: Don
# Change log:
# $Revision: 1963 $

# Copyright (c) 2005-2012 Don Owens <don@owensnet.com>.  All rights reserved.

# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.  See perlartistic.

# This program is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied
# warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.

use strict;

package DBIx::Wrapper::Delegator;

use warnings;

use vars qw($VERSION $AUTOLOAD);
$VERSION = do { my @r=(q$Revision: 1963 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

sub AUTOLOAD {
    my $self = shift;

    (my $func = $AUTOLOAD) =~ s/^.*::([^:]+)$/$1/;
    return undef if $func eq 'DESTROY';
        
    my $key = $func;            # turn method call into hash access
    return $self->{$func};
}


1;
