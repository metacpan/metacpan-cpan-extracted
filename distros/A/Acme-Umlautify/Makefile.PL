use ExtUtils::MakeMaker;

WriteMakefile(
  ABSTRACT => "Ädd ümläüts tö ëvërÿthïng",
  AUTHOR   => 'Phil Pollard <bennie@cpan.org>',
  LICENSE  => 'artistic_2',
  NAME     => 'Acme::Umlautify',
  VERSION  => '1.07',

  PREREQ_PM => {
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
          'Acme::Umlautify' => {
                                 'version' => '1.07',
                                 'file' => 'lib/Acme/Umlautify.pm'
                               }
        },

                release_status => 'stable',
                resources => {
                    repository => {
                        type => 'git',
                        url  => 'git://github.com/bennie/perl-Acme-Umlautify.git',
                        web  => 'http://github.com/bennie/perl-Acme-Umlautify',
                    },
                    bugtracker => {
                        web => 'https://rt.cpan.org/Dist/Display.html?Name=Acme-Umlautify',
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