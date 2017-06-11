use ExtUtils::MakeMaker;
use strict;
use warnings;

WriteMakefile(
	NAME              => 'Data::Faker::Colour',
	VERSION_FROM      => 'lib/Data/Faker/Colour.pm',
	ABSTRACT_FROM     => 'lib/Data/Faker/Colour.pm',
	AUTHOR            => 'Marius Gavrilescu <marius@ieval.ro>',
	MIN_PERL_VERSION  => '5.14.0',
	LICENSE           => 'perl',
	SIGN              => 1,
	PREREQ_PM         => {
		qw/Convert::Color::HSLuv 0
		   Data::Faker 0/,
	},
	META_ADD         => {
		dynamic_config => 0,
		resources      => {
			repository   => 'https://git.ieval.ro/?p=data-faker-colour.git',
		},
	}
);
