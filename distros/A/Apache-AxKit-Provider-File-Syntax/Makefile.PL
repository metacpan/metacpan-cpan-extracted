# $Id: Makefile.PL,v 1.2 2004/07/16 04:34:50 nachbaur Exp $
use strict;
use ExtUtils::MakeMaker;
eval { require ExtUtils::AutoInstall };

if ($ExtUtils::AutoInstall::VERSION > 0) {
    ExtUtils::AutoInstall->import(
        -version => '0.32',
        -core => [
            'AxKit'          => 1.6,
            'Text::VimColor' => 0.07,
        ],
        'Use detailed mime-info module' => [
            -default => 1,
            'File::MimeInfo::Magic' => 0.9,
        ],
    );
}

WriteMakefile(
    'NAME'         => 'Apache::AxKit::Provider::File::Syntax',
    'VERSION_FROM' => 'Syntax.pm',
    'AUTHOR'       => 'Michael A Nachbaur <mike@nachbaur.com>',
    'ABSTRACT'     => 'AxKit file syntax XML generator',
);
