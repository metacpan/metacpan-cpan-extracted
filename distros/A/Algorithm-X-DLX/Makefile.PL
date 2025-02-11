use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Algorithm::X::DLX',
    VERSION_FROM      => 'lib/Algorithm/X/DLX.pm',
    AUTHOR            => 'Steffen Heinrich <she@cpan.org>',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.06.0',
    PREREQ_PM => {
    	'Carp'            => 0,
    },
    BUILD_REQUIRES => {
      'Test::Exception' => 0,
    },
);

