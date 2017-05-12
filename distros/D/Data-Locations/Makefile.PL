#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 1997 - 2009 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;

use ExtUtils::MakeMaker;

use Config;

WriteMakefile(
    'NAME'              => 'Data::Locations',
    'VERSION_FROM'      => 'Locations.pm',
    'OBJECT'            => '$(O_FILES)',
#   ($] >= 5.005 ?
#       ('ABSTRACT'     => 'Magic (recursive) insertion points in your data',
#        'AUTHOR'       => 'Steffen Beyer (STBEY@cpan.org)') : ()),
#   ($] >= 5.005 && $ eq 'MSWin32' && $Config{archname} =~ /-object\b/i ?
#       ('CAPI'         => 'TRUE') : ()),
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" }
);

if ($] >= 5.006001 and $] <= 5.007)
{
    warn <<"VERBATIM";

=========================================================================

    WARNING:

    You are currently using Perl version $].

    Perl versions including and between Perl v5.6.1 and v5.7.0
    do not work well with this module.

    Test file "t/11_______dump.t" of the test suite ("make test")
    will probably fail with a core dump when using this Perl version.

    You may nevertheless be able to use this module if all the
    other tests pass (just "make install" anyway).

    However, I would rather recommend you to upgrade to a more stable
    Perl version.

    Sorry for the inconvenience!

=========================================================================

VERBATIM
}

__END__

