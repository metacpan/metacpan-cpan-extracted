use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Date::Namedays::Simple',
    VERSION_FROM => 'lib/Date/Namedays/Simple.pm', # finds $VERSION
    AUTHOR       => 'Csongor Fagyal (con-NOSPAM-cept@conceptonline.hu)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
