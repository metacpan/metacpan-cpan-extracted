use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Catalyst::View::Jemplate',
    'VERSION_FROM' => 'lib/Catalyst/View/Jemplate.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Jemplate => 0.19,
        Catalyst => 5.50,
        File::Find::Rule => 0,
    },
);
