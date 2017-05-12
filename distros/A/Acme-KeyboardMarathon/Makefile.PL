use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "How far have your fingers ran?",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Acme::KeyboardMarathon',
  VERSION  => '1.25',

  PREREQ_PM => {
          'Test::Simple' => 0,
          'Carp' => 0,
          'Math::BigInt' => 0,
          'File::Slurp' => 0,
          'Test::More' => 0
        },

  ( $ExtUtils::MakeMaker::VERSION < 6.46
        ? ()
        : ( META_MERGE => {
                'meta-spec' => { version => 2 },
                no_index => {directory => [qw/t/]},
                provides => 

	{
          'Acme::KeyboardMarathon' => {
                                        'file' => 'lib/Acme/KeyboardMarathon.pm',
                                        'version' => '1.25'
                                      }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Acme-KeyboardMarathon.git',
                        web  => 'http://github.com/bennie/perl-Acme-KeyboardMarathon',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Acme-KeyboardMarathon',
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