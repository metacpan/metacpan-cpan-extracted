use 5.014000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'App::Gallery',
	VERSION_FROM      => 'lib/App/Gallery.pm',
	ABSTRACT_FROM     => 'lib/App/Gallery.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	EXE_FILES         => ['gallery.pl'],
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Image::Magick 0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=app-gallery.git',
		},
	}
);
