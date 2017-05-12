use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Catalyst::Plugin::Pluggable',
    'VERSION_FROM' => 'Pluggable.pm',
    'PREREQ_PM'    => { Catalyst => '5.5' }
);
