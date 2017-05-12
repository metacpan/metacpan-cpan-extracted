use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Bundle::Sledge',
    'VERSION_FROM' => 'lib/Bundle/Sledge.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
