
use 5;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME => 'Data::Template',
    VERSION_FROM => 'lib/Data/Template.pm',
    PREREQ_PM => {
        Class::Accessor => 0,
        Template => 0,

        Test::More => 0,
    },
    ($] >= 5.005 ? (
        ABSTRACT_FROM  => 'lib/Data/Template.pm', 
        AUTHOR         => 'A. R. Ferreira <ferreira@cpan.org>',
     ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
        LICENSE => 'perl',
    ) : ()),
    ($EUMM_VERSION > 6.4501 ? (
        META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository => {
                    type => 'git',
                    url => 'git://github.com/aferreira/cpan-Data-Template.git',
                    web => 'https://github.com/aferreira/cpan-Data-Template',
                }
            },
        },
    ) : ()),
);
