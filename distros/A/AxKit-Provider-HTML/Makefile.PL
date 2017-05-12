use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME' => 'AxKit::Provider::HTML',
    'VERSION_FROM' => 'lib/AxKit/Provider/HTML.pm',
    'PREREQ_PM' => {
        AxKit => '1.5',
        XML::LibXML => '1.50',
    },
    'ABSTRACT_FROM' => 'lib/AxKit/Provider/HTML.pm',
    'AUTHOR' => 'Matt Sergeant <matt@sergeant.org>',
);
