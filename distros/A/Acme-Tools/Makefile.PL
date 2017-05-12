use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Acme::Tools',
    'VERSION_FROM'	=> 'Tools.pm', # finds $VERSION
    'MIN_PERL_VERSION'  => '5.6.2',
    'PREREQ_PM'		=> {
			    Compress::Zlib => 0.01,
			    Time::HiRes    => 0.01,
			    MIME::Base64   => 0.01,
			    Carp           => 0.01,
			    Test::More     => 0.01,
			   #Compress::Bzip2 => 0.01, #hm
			   #Term::ANSIColor => 0.01, #hm
			   },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Tools.pm', # retrieve abstract from module
       AUTHOR     => 'Kjetil Skotheim <kjetilskotheim@gmail.com>') : ()),
);
