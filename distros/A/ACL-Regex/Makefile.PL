use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'ACL::Regex',
    VERSION_FROM => 'lib/ACL/Regex.pm',
    AUTHOR       => 'Peter Blair (pblair@cpan.org)',
    ABSTRACT     => 'Class to generate access controls using PCRE',
    PREREQ_PM    => {
                    },
);
