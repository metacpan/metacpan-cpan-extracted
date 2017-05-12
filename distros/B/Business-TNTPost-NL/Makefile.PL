use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Business::TNTPost::NL',
    VERSION_FROM => 'lib/Business/TNTPost/NL.pm', # finds \$VERSION
    AUTHOR       => 'M. Blom (blom@cpan.org)',
    ABSTRACT     => 'Calculate Dutch (TNT Post) shipping costs',
    PREREQ_PM    => {
                     'Carp'         		=> 0,
		     'Class::Accessor::Fast'	=> 0,
                     'List::Util'   		=> 0,
                     'Test::Simple' 		=> 0.44,
                     'YAML'         		=> 0,
                    },
);
