#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.

package Bio::Gonzales::Role::BioPerl::Constructor;

use Mouse::Role;

use warnings;
use strict;
use Carp;

use 5.010;
our $VERSION = '0.0546'; # VERSION

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    return $class->$orig(@_) unless ( substr( $_[0] || '', 0, 1 ) eq '-' );
    push @_, undef unless $#_ % 2;

    my %param;
    while (@_) {
        ( my $key = shift ) =~ tr/A-Z\055/a-z/d;    #deletes all dashes!
        $param{$key} = shift;
    }

    return $class->$orig(%param);
};

1;
