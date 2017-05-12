use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'DBIx::Pager',
    'VERSION_FROM' => 'lib/DBIx/Pager.pm', # finds $VERSION
    'PREREQ_PM' => {
	Test::More => 0.32,
	Class::Accessor => 0.17,
    },
);
