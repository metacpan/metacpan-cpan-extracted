use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
	NAME            => 'CPANPLUS::Shell::Default::Plugins::Prereqs',
    VERSION         => '0.1',
    PREREQ_PM       => { 
                        'Test::More'   => 0,
                        'File::Spec'   => 0,
                        'stuff'        => 0,
                        'Hash::Util'   => 0,
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>, Ken Williams <kwilliams@cpan.org>',
    ABSTRACT        => 'CPANPLUS plugin to install packages that use Build.PL',
);     
