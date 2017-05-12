use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Acme::Sneeze',
    'VERSION_FROM' => 'lib/Acme/Sneeze.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
        Exporter::Lite => 0,
    },
);
