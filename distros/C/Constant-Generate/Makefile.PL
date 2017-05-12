use strict;
use warnings;
use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # developer version?
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    NAME                => 'Constant::Generate',
    AUTHOR              => q{M. Nunberg <mnunberg@haskalah.org>},
    VERSION_FROM        => 'lib/Constant/Generate.pm',
    ABSTRACT_FROM       => 'lib/Constant/Generate.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'constant'   => 1.17,
        'Scalar::Util' => 1.20
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Constant-Generate-*' },

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/mnunberg/Constant-Generate',
                    url  => 'https://github.com/mnunberg/Constant-Generate.git',
                },
            },
          })
    ),

);
