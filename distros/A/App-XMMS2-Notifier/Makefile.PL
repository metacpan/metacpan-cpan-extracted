use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::XMMS2::Notifier',
	VERSION_FROM      => 'lib/App/XMMS2/Notifier.pm',
	EXE_FILES         => ['xmms2-notifier'],
	ABSTRACT_FROM     => 'lib/App/XMMS2/Notifier.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Audio::XMMSClient 0.03
		   Gtk2::Notify      0.05,
		   Getopt::Long      0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=app-xmms2-notifier.git'
		}
	}
);
