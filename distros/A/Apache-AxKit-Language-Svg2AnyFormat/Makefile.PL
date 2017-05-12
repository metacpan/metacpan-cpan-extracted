# use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'	    => 'Tom Schindl <tom.schindl@bestsolution.at>',
    'NAME'          => 'Apache::AxKit::Language::Svg2AnyFormat',
    'VERSION_FROM'  => 'lib/Apache/AxKit/Language/Svg2AnyFormat.pm', # finds $VERSION
    'PREREQ_PM'	    => {
        AxKit         => "1.6.1",
        Image::Magick => "5.55",
        Image::LibRSVG => "0.01",
    },
    'dist' => {
        COMPRESS => "gzip -9",
        SUFFIX   => "gz",
    },
);
