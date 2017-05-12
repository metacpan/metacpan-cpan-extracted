
###############################################################################
##                                                                           ##
##    Copyright (c) 2003 by Steffen Beyer & Gerhard Albers.                  ##
##    All rights reserved.                                                   ##
##                                                                           ##
##    This package is free software; you can redistribute it                 ##
##    and/or modify it under the same terms as Perl itself.                  ##
##                                                                           ##
###############################################################################

use ExtUtils::MakeMaker;

use Config;

sub ExtUtils::MakeMaker::warnhandler
{
    $_[0] =~ /^Use of uninitialized value/ && return;
    $_[0] =~ /used only once/ && return;
    $_[0] =~ /^Subroutine\s+[\w:]+\s+redefined/ && return;
    $_[0] =~ /prerequisite .+ not found/ && die $_[0];
    warn @_;
}

WriteMakefile(
    'NAME'           => 'Config::Manager',
    'VERSION_FROM'   => 'Manager.pm', # finds $VERSION
    'PREREQ_PM'      => {
                            'Symbol'        => '0.0',
                            'Fcntl'         => '0.0',
                            'File::Compare' => '0.0',
                            'File::Copy'    => '0.0',
                            'Net::SMTP'     => '0.0',
                            'Digest::MD5'   => '0.0'
                        },
    'EXE_FILES'      => [ glob("scripts/*.pl") ],
#   ($] >= 5.005 ?
#        ('ABSTRACT' => 'Configuration Manager',
#         'AUTHOR'   => 'Steffen Beyer <sb@engelschall.com>, Gerhard Albers') : ()),
#   ($] >= 5.005 && $ eq 'MSWin32' && $Config{archname} =~ /-object\b/i ?
#        ('CAPI'     => 'TRUE') : ()),
    'dist'           => { COMPRESS => "gzip -9", SUFFIX => "gz" }
);

