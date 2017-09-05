use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Android::ADB',
	VERSION_FROM      => 'lib/Android/ADB.pm',
	ABSTRACT_FROM     => 'lib/Android/ADB.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Class::Accessor 0
		   File::Slurp     0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=android-adb.git',
		},
	}
);
