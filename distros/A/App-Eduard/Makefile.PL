use 5.014000;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share 'share';

WriteMakefile(
	NAME              => 'App::Eduard',
	VERSION_FROM      => 'lib/App/Eduard.pm',
	ABSTRACT_FROM     => 'lib/App/Eduard.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ceata.org>',
	EXE_FILES         => ['eduard'],
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Email::Sender::Simple 0
		   File::Share           0
		   File::Slurp           0
		   Getopt::Long          0
		   MIME::Entity          5.419
		   MIME::Parser          5.419
		   Mail::GnuPG           0
		   PerlX::Maybe          0
		   Template              0
		   Try::Tiny             0/,
	},
	BUILD_REQUIRES     => {
		qw/ExtUtils::MakeMaker     0
		   File::ShareDir::Install 0/,
	},
	META_MERGE         => {
		dynamic_config => 0,
		resources      => {
			repository => 'git://gitorious.org/ceata/ceata-eduard.git',
		}
	}
);

package MY;
use File::ShareDir::Install qw/postamble/;
