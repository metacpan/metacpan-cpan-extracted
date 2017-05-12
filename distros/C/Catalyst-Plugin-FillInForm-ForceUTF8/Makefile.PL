use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME => 'Catalyst::Plugin::FillInForm::ForceUTF8',
    VERSION_FROM => 'lib/Catalyst/Plugin/FillInForm/ForceUTF8.pm',    # finds $VERSION
    AUTHOR    => 'Hideo Kimura (hide@hide-k.net)',
    ABSTRACT  => 'Module abstract (<= 44 characters) goes here',
    PREREQ_PM => {
        'Test::Simple'                => 0.44,
        'Catalyst'                    => 0,
        'HTML::FillInForm::ForceUTF8' => 0
    },
);
