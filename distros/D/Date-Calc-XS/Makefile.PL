#!perl -w

###############################################################################
##                                                                           ##
##    Copyright (c) 1995 - 2015 by Steffen Beyer.                            ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use strict;

use ExtUtils::MakeMaker;

BEGIN
{
    eval { require Config_m; }; # ExtUtils::FakeConfig (+ ActivePerl)
    eval { require Config;   }  # Everyone else
    if ($@);
}

my $Patchlevel = 'patchlevel.h';
my $PATCHLEVEL = $Config::Config{'PATCHLEVEL'} || $Config::Config{'patchlevel'} || substr($],2,3);
my $SUBVERSION = $Config::Config{'SUBVERSION'} || $Config::Config{'subversion'} || substr($],5) || 0;

print qq{\n};
print qq{*************************************************************\n};
print qq{****** BEWARE: Use "make install UNINST=1" to install! ******\n};
print qq{*************************************************************\n};
print qq{\n};

WriteMakefile(
    'NAME'              => 'Date::Calc::XS',
    'VERSION_FROM'      => 'lib/Date/Calc/XS.pm',
    'ABSTRACT_FROM'     => 'lib/Date/Calc/XS.pod',
    'LICENSE'           => 'perl,lgpl',
    'AUTHOR'            => 'Steffen Beyer <STBEY@cpan.org>',
    'PREREQ_PM'         => {
                               'Carp::Clan'  => 5.3,
                               'Bit::Vector' => 7.4,
                               'Date::Calc'  => 6.4
                           },
    'META_MERGE'        => {
                               'recommends'  =>
                               {
                                   'Carp::Clan'     => 6.01
                               }
                           },
    'OBJECT'            => '$(O_FILES)',
    'dist'              => { COMPRESS => "gzip -9", SUFFIX => "gz" },
    'clean'             => { FILES => $Patchlevel },
#   for ActivePerl:
    ($] >= 5.005 && $^O eq 'MSWin32' && $Config::Config{'archname'} =~ /-object\b/i ?
        ('CAPI'         => 'TRUE') : ())
);

unless
(
    open  (PATCHLEVEL, ">$Patchlevel")                        and
    print("Writing $Patchlevel for $^X ($])\n")               and
    printf(PATCHLEVEL "#define PATCHLEVEL %d\n", $PATCHLEVEL) and
    printf(PATCHLEVEL "#define SUBVERSION %d\n", $SUBVERSION) and
    close (PATCHLEVEL)
)
{
    warn "Oops: Could not write file <$Patchlevel>: $!\n";
    warn "However, you might succeed in building this module anyway;\n";
    warn "Just give it a try!\n";
    exit 0;
}

__END__

