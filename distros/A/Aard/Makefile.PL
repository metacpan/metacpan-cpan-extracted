use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Aard',
	VERSION_FROM      => 'lib/Aard.pm',
	ABSTRACT_FROM     => 'lib/Aard.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/IO::Uncompress::Inflate 0
		   IO::Uncompress::Bunzip2 0
		   List::Util 0

		   JSON::MaybeXS 0
		   UUID::Tiny 0/,
	},
	META_MERGE        => {
		dynamic_config => 0,
		resources      => {
			repository => 'https://git.ieval.ro/?p=aard.git',
		}
	}
);
