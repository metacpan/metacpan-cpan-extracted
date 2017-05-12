

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'API::Intis',
    VERSION_FROM => 'lib/API/Intis.pm', # finds \$VERSION
    AUTHOR       => 'Nick Nomos (nnmos@cpan.org)',
    ABSTRACT     => 'Intis Telecom API',
    PREREQ_PM    => {
                        'Test::Simple' => '0',
                        'Modern::Perl' => '0',
                        'YAML::Tiny' => '0',
                        'WWW::Mechanize' => '0',
                        'Crypt::SSLeay' => '0',
                        'JSON' => '0',
                        'Digest::Perl::MD5' => '0',
                        'Switch' => '0',
                    },
);
