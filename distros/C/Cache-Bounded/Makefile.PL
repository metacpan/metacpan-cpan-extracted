use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "A size-aware in-memory cache optimized for speed",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Cache::Bounded',
  VERSION  => '1.09',

  PREREQ_PM => {
          'Test::Simple' => '0',
          'Test::More' => '0'
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'Cache::Bounded' => {
                                'version' => '1.09',
                                'file' => 'lib/Cache/Bounded.pm'
                              }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Cache-Bounded.git',
                        web  => 'http://github.com/bennie/perl-Cache-Bounded',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Cache-Bounded',
                    },

                },
            },
        )
    ),

  ( $ExtUtils::MakeMaker::VERSION < 6.48
        ? ()
        : ( MIN_PERL_VERSION => '5.006' )
  )

);