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
    'NAME'              => 'Bundle::STBEY::Favourites',
    'VERSION_FROM'      => 'lib/Bundle/STBEY/Favourites.pm',
    'ABSTRACT_FROM'     => 'lib/Bundle/STBEY/Favourites.pm',
    'AUTHOR'            => 'Steffen Beyer <STBEY@cpan.org>',
    'LICENSE'           => 'perl',
    'PREREQ_PM'         =>
                              {
                                  'YAML'              => 0.70,
                                  'Carp::Clan'        => 6.04,
                                  'Storable'          => 2.21,
                                  'Bit::Vector'       => 7.1,
                                  'Date::Calc'        => 6.2,
                                  'Date::Calc::XS'    => 6.2,
                                  'Date::Calc::Util'  => 1.0,
                                  'Data::Locations'   => 5.5,
                                  'Math::MatrixBool'  => 5.8,
                                  'Set::IntRange'     => 5.2,
                                  'Scalar::Util'      => 0,
                                  'V'                 => 0,
                                  'Bundle::libwin32'  => 0,
                                  'Bundle::CPAN'      => 0,
                                  'CPAN::Reporter'    => 0,
                                  'Bundle::libnet'    => 0,
                                  'Bundle::LWP'       => 0,
                                  'Parse::RecDescent' => 0,
                                  'Digest::MD5'       => 0,
                                  'Digest::SHA1'      => 0,
                                  'Unicode::String'   => 0,
                                  'IO::Stringy'       => 0,
                                  'MIME::Parser'      => 0,
                                  'Getopt::Long'      => 0,
                                  'MIME::Base64'      => 0,
                                  'MIME::Tools'       => 0,
                                  'Time::HiRes'       => 0,
                                  'HTML::Parser'      => 0,
                                  'MIME::Lite'        => 0

                              },
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" },
#   for ActivePerl:
    ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
        ('CAPI'         => 'TRUE') : ())
);

__END__

