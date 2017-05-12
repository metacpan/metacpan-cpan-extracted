# $Id: Makefile.PL,v 1.3 2003/09/10 00:23:46 cvspub Exp $
use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'CGI::Shorten',
    'VERSION_FROM'	=> 'Shorten.pm', 
    'PREREQ_PM'		=> {
	'Math::String' => '1.23',
	'Digest::MD5' => '2.27',
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Shorten.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
