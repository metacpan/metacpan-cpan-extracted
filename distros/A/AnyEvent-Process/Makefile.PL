use 5.008001;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'AnyEvent::Process',
	VERSION_FROM      => 'lib/AnyEvent/Process.pm',
	BUILD_REQUIRES    => {
		'Test::More' => 0.98,
	},
	PREREQ_PM         => {
		'AnyEvent' => 7.02,
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
		(ABSTRACT_FROM  => 'lib/AnyEvent/Process.pm',
			AUTHOR         => 'Petr Malat <oss@malat.biz>') : ()),
);
