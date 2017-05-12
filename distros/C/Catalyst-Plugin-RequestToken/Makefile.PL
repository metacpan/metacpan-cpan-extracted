use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Catalyst::Plugin::RequestToken',
    VERSION_FROM => 'lib/Catalyst/Plugin/RequestToken.pm', # finds $VERSION
    AUTHOR       => 'Hideo Kimura (hide@hide-k.net)',
    ABSTRACT     => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                     'Catalyst' => 5.5,
                     'Catalyst::Plugin::Session' => 0,
                     'Digest' => 0,
                    },
);
