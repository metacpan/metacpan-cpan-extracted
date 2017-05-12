use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Business::TPGPost',
    VERSION_FROM => 'lib/Business/TPGPost.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'Calculate Dutch (TPG Post) shipping costs',
    PREREQ_PM    => {
                     Business::TNTPost::NL      => 0
                    },
);
