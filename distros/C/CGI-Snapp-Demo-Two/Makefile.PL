use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
(
 ($] ge '5.005') ?
 (
  AUTHOR   => 'Ron Savage (ron@savage.net.au)',
  ABSTRACT => 'A template-free demo of CGI::Snapp using N run modes',
    ) : (),
 clean =>
 {
	 FILES => 'blib/* Makefile MANIFEST CGI-Snapp-Demo-Two*'
 },
 dist =>
 {
	 COMPRESS => 'gzip',
	 SUFFIX   => 'gz'
 },
 DISTNAME  => 'CGI-Snapp-Demo-Two',
 NAME      => 'CGI::Snapp::Demo::Two',
 PL_FILES  => {},
 PREREQ_PM =>
 {
	 CGI                => 3.00,
	 CGI::Emulate::PSGI => 0.14,
	 CGI::Snapp         => 1.03,
	 parent             => 0,
	 # Don't make user install Plack.
	 # Plack            => 0.9985,
	 # Starman          => 0.3000,
	 strict             => 1.03,
 	 Test::More         => 0.94,
 	 Test::Pod          => 1.44,
	 warnings           => 1.03,
 },
 VERSION_FROM => 'lib/CGI/Snapp/Demo/Two.pm',
);
