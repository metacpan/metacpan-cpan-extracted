use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'            => 'Attribute::Static',
    'VERSION_FROM'    => 'lib/Attribute/Static.pm',
    'AUTHOR'          => 'Jiro Nishiguchi <jiro@cpan.org>',
    'PREREQ_PM'		  => {
        Attribute::Handlers => 0.70,
        Test::More          => 0,
    },
);
