# $Id: Makefile.PL,v 1.1 2001/06/15 17:57:00 root Exp $

use ExtUtils::MakeMaker;

sub MY::libscan {
	my($self,$path) = @_;
	return '' if $path =~ /RCS/;
	$path;
}

WriteMakefile(
	'NAME'		=> 'Apache2::AuthenSecurID::Auth',
	'VERSION_FROM'	=> 'Auth.pm', 
	'PREREQ_PM'	=> { 	Authen::ACE => 0.90,
				Crypt::CBC => 1.25,
				Crypt::Blowfish => 2.06 },
	'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
