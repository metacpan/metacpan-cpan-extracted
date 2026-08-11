#! /usr/local/bin/perl

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile being created.

require 5.004;

WriteMakefile(
	'NAME' => 'Crypt::DES',
	'DISTNAME' => 'Crypt-DES',
	'VERSION_FROM' => 'DES.pm',,
	'OBJECT' => 'DES.o _des.o',
	'dist'   => {COMPRESS=>'gzip', SUFFIX=>'gz'},
        META_MERGE       => {
        'meta-spec' => { version => 2 },
        'resources' => {
            'repository' => {
                'type' => 'git',
                'url'  => 'git://github.com/timlegge/perl-Crypt-DES.git',
                'web'  => 'https://github.com/timlegge/perl-Crypt-DES',
            },
            'bugtracker' => {
                'web' => 'https://github.com/timlegge/perl-Crypt-DES/issues',
            },
        },
    },
);

