use ExtUtils::MakeMaker;

my $mm_ver = $ExtUtils::MakeMaker::VERSION;
if ($mm_ver =~ /_/) { # dev version
    $mm_ver = eval $mm_ver;
    die $@ if $@;
}

WriteMakefile(
    'NAME'	=> 'Clone::PP',
    'VERSION_FROM' => 'lib/Clone/PP.pm', 

    PREREQ_PM      => {
        'Exporter' => 0,
        'strict'   => 0,
        'warnings' => 0,
        'vars'     => 0,
    },

    ($mm_ver >= 6.48
        ? (MIN_PERL_VERSION => 5.006)
        : ()
    ),

    ($mm_ver >= 6.31
        ? (LICENSE => 'perl_5')
        : ()
    ),

    ($mm_ver >= 6.64
        ? (TEST_REQUIRES => {
               'Data::Dumper' => 0,
               'Benchmark'    => 0,
               'Carp'         => 0,
          })
        : ()
    ),

    ($mm_ver <= 6.45
        ? ()
        : (META_MERGE => {
            'meta-spec' => { version => 2 },
            resources => {
                bugtracker  => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Clone-PP',
                repository  => {
                    type => 'git',
                    web  => 'https://github.com/neilbowers/Clone-PP',
                    url  => 'git://github.com/neilbowers/Clone-PP.git',
                },
            },
          })
    ),

);

