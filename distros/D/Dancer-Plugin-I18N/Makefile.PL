use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Dancer::Plugin::I18N',
    AUTHOR              => q{Igor Bujna <igor.bujna@post.cz>},
    VERSION_FROM        => 'lib/Dancer/Plugin/I18N.pm',
    ABSTRACT_FROM       => 'lib/Dancer/Plugin/I18N.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Dancer' => 1.3000,
        'Test::More' => 0,
		'Locale::Maketext::Simple' => "0.18",
		'I18N::LangTags' => '0.35',
		'Locale::Maketext::Lexicon' => 0,
    },
	(MM->can('signature_target') ? (SIGN => 1) : ()),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Dancer-Plugin-I18N-*' },
);
