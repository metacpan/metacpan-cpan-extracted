use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'      => 'Apache::Session::Serialize::YAML',
    'VERSION_FROM' => 'lib/Apache/Session/Serialize/YAML.pm', # finds $VERSION
    'PREREQ_PM' => {
	'Test::More' => 0.32,
	'YAML' => 0.35,
	'Apache::Session::Flex' => 1.01,
    },
);
