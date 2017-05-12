use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
    'NAME'             => 'Bundle::Melody::Test',
    'VERSION_FROM'     => 'lib/Bundle/Melody/Test.pm',
    'MIN_PERL_VERSION' => '5.8.1',
    'LICENSE'          => 'perl',
    'AUTHOR'           => 'Timothy Appnel <tima@cpan.org>',
    'META_MERGE'       => {
        'resources' => {
            'license'    => 'http://dev.perl.org/licenses/',
            'repository' => 'http://github.com/tima/perl-bundle-melody-test',
            'bugtracker' =>
              'https://openmelody.lighthouseapp.com/projects/26604-melody',
        },
    }
);
