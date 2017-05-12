require 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %prereqs = (
    'File::Find'     => 0,
    'Getopt::Long'   => 0,
    'Image::Magick'  => 0,
    'Module::Pluggable' => 0,
);

WriteMakefile(
    NAME => 'CSS::SpriteMaker',
    LICENSE => 'perl',
    AUTHOR => q{Savio Dimatteo <darksmo@gmail.com>},
    VERSION_FROM => 'lib/CSS/SpriteMaker.pm',
    ABSTRACT_FROM => 'lib/CSS/SpriteMaker.pm',
    TEST_REQUIRES => {
        %prereqs,
        'Test::More'          => 0,
#        'Test::CheckManifest' => 0, # author-only
#        'Test::Pod::Coverage' => 0,
#        'Test::Pod'           => 0,
    },
    MIN_PERL_VERSION => 5.006,
    PREREQ_PM => \%prereqs,
    clean => { FILES => ['CSS-SpriteMaker-*'] },
    META_MERGE          => {
      "meta-spec" => { version => 2 },
      resources => {
        repository => {
          type => 'git',
          url => 'git@github.com:lokku/Css-SpriteMaker.git',
          web => 'https://github.com/lokku/Css-SpriteMaker',
        },
      },
    },
);
