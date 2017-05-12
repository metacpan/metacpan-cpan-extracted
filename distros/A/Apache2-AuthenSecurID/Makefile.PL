# $Id: Makefile.PL,v 1.3 2007/12/08 03:24:02 atobey Exp $

use ExtUtils::MakeMaker;

sub MY::libscan {
	my($self,$path) = @_;
	return '' if $path =~ /RCS/;
	$path;
}

WriteMakefile(
	'NAME'		=> 'Apache2::AuthenSecurID',
	'VERSION_FROM'	=> 'AuthenSecurID.pm', 
	'PREREQ_PM'	=> {
                Authen::ACE => 0.90,
				Crypt::CBC => 1.25,
				Crypt::Blowfish => 2.06,
                Apache2::RequestUtil => 0.01,
                Apache2::RequestRec => 0.01,
                ModPerl::Registry => 0.01
    },
	'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
