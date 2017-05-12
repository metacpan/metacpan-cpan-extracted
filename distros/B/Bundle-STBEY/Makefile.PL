#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 2009 by Steffen Beyer.                                   ##
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
    'NAME'              => 'Bundle::STBEY',
    'VERSION_FROM'      => 'lib/Bundle/STBEY.pm',
    'ABSTRACT_FROM'     => 'lib/Bundle/STBEY.pm',
    'AUTHOR'            => 'Steffen Beyer <STBEY@cpan.org>',
    'LICENSE'           => 'perl',
    'PREREQ_PM'         =>
                              {
                                  'Carp::Clan'       => 6.04,
                                  'Storable'         => 2.21,
                                  'Bit::Vector'      => 7.1,
                                  'Date::Calc'       => 6.2,
                                  'Date::Calc::XS'   => 6.2,
                                  'Date::Calc::Util' => 1.0,
                                  'Data::Locations'  => 5.5,
                                  'Math::MatrixBool' => 5.8,
                                  'Set::IntRange'    => 5.2
                              },
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" },
#   for ActivePerl:
    ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
        ('CAPI'         => 'TRUE') : ())
);

__END__

