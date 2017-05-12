use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Catalyst::Plugin::Textile',
    'VERSION_FROM' => 'Textile.pm',
    'PREREQ_PM'    => { Catalyst => 5, Text::Textile => 0 }
);
