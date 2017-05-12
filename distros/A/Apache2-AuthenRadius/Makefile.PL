# $Id: Makefile.PL,v 1.1 2005/04/18 17:40:44 jad Exp $

use ExtUtils::MakeMaker;

sub MY::libscan {
	my($self,$path) = @_;
	return '' if $path =~ /RCS/;
	$path;
}

WriteMakefile(
	'NAME'		=> 'Apache2::AuthenRadius',
	'VERSION_FROM'	=> 'AuthenRadius.pm', 
	'PREREQ_PM'	=> { 
		'Authen::Radius' => 0.05, 
		'Apache2'        => '0', # or a minimum workable version
	},
	'dist'		=> { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
