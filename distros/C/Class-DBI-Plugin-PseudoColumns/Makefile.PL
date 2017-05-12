use ExtUtils::MakeMaker;
WriteMakefile(
    NAME         => 'Class::DBI::Plugin::PseudoColumns',
    VERSION_FROM => 'lib/Class//DBI/Plugin/PseudoColumns.pm',
    PREREQ_PM    => {
	'Test::More'   => 0.32,
	'Data::Dumper' => 0,
	'Class::DBI'   => 0,
    },
);

