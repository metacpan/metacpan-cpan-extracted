use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "API Wrapper for Pure Storage devices.",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'API::PureStorage',
  VERSION  => '0.03',

  PREREQ_PM => {
          'REST::Client' => 0,
          'JSON' => 0,
          'Net::SSL' => 0,
          'Test::More' => 0,
          'Test::Simple' => '0'
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'API::PureStorage' => {
                                  'file' => 'lib/API/PureStorage.pm',
                                  'version' => '0.03'
                                }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-API-PureStorage.git',
                        web  => 'http://github.com/bennie/perl-API-PureStorage',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=API-PureStorage',
                    },

                },
            },
        )
    ),

  ( $ExtUtils::MakeMaker::VERSION < 6.48
        ? ()
        : ( MIN_PERL_VERSION => '5.006001' )
  )

);