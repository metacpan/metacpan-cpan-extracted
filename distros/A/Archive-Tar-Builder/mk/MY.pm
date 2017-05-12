package
 MY;

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

#
# Cause the SRCDIR and OBJDIR values to be exposed in the Makefile.
#
sub postamble {
    my ( $self, %args ) = @_;

    return <<END;
SRCDIR = $args{'srcdir'}
OBJDIR = $args{'objdir'}
END
}

#
# A stupid hack to get ExtUtils::MakeMaker to write Makefiles that cause items
# listed in OBJECT to be built in the directory they actually exist in.
#
sub const_cccmd {
    my ( $self, @args ) = @_;
    my $ret = $self->SUPER::const_cccmd(@args);

    $ret .= ' -o $@';

    return $ret;
}

#
# A small hack to get the bootstrap file to be placed in the src/ directory.
#
sub dynamic_bs {
    my ( $self, %args ) = @_;
    my $ret = $self->SUPER::dynamic_bs(%args);

    $ret =~ s/BOOTSTRAP = \$\(BASEEXT\)\.bs/BOOTSTRAP = src\/\$\(BASEEXT\)\.bs/m;

    return $ret;
}

#
# A hack to clean gcov data spewed by Devel::Cover.
#
sub clean {
    my ( $self, %args ) = @_;
    my $ret    = $self->SUPER::clean(%args);
    my $srcdir = $self->{'postamble'}->{'srcdir'};

    $ret .= sprintf( "\t- \$(RM_F) *.gcov %s/*.gcda %s/*.gcno\n", $srcdir, $srcdir );

    return $ret;
}

1;
