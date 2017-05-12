# $Id: Makefile.PL,v 1.2 2002/07/30 20:15:39 Administrator Exp $

use ExtUtils::MakeMaker;

sub MY::libscan {
	my($self,$path) = @_;
	return '' if $path =~ /RCS/;
	$path;
}

WriteMakefile(
	'NAME'		=> 'Apache::AuthenSecurID',
	'VERSION_FROM'	=> 'AuthenSecurID.pm', 
	'PREREQ_PM'	=> { 	Authen::ACE => 0.90,
				Crypt::CBC => 1.25,
				Config::General => 1.20,
				Crypt::Blowfish => 2.06 },
	'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
