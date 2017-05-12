######################################################################
# Makefile.PL for Buffalo::G54
# 2006, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Buffalo::G54',
    'VERSION_FROM' => 'lib/Buffalo/G54.pm', # finds $VERSION
    'PREREQ_PM'    => {
        "WWW::Mechanize" => 1,
        "Log::Log4perl"  => 1,
        "Test::More"     => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Buffalo/G54.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
