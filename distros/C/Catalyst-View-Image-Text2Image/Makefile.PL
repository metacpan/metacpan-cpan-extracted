use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Catalyst::View::Image::Text2Image',
    AUTHOR              => q{Martin Gillmaier <gillmaus@cpan.org>},
    VERSION_FROM        => 'lib/Catalyst/View/Image/Text2Image.pm',
    ABSTRACT_FROM       => 'lib/Catalyst/View/Image/Text2Image.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'GD::Simple' => 0,
	'Catalyst::View' => 0,
	'parent' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Catalyst-View-Image-Text2Image-*' },
);
