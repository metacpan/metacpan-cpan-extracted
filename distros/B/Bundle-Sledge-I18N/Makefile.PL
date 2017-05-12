use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Bundle::Sledge::I18N',
    'VERSION_FROM' => 'lib/Bundle/Sledge/I18N.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
    },
);
