use 5.008000;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME              => 'Crypt::RSA::Yandex',
	VERSION_FROM      => 'lib/Crypt/RSA/Yandex.pm',
	PREREQ_PM         => { },
	BUILD_REQUIRES    => { 'MIME::Base64' => 0 },
	ABSTRACT_FROM     => 'lib/Crypt/RSA/Yandex.pm',
	AUTHOR            => 'Vladimir Timofeev <vovkasm@gmail.com>',
	AUTHOR            => 'Mons Anderson <mons@cpan.org>',
	LIBS              => ['-lstdc++'],
	META_ADD          => { license => 'perl' },
	#DEFINE            => '-D__DEBUG__',
	DEFINE            => '',
	INC               => '-I.',
	OBJECT            => '$(O_FILES)',
	H                 => ['CP_RSA.h'],
	C                 => ['CP_RSA.cpp','Yandex.c'],
	CC                => 'g++',
	XSOPT             => '-C++',
	TYPEMAPS          => ['perlobject.map'],
);
