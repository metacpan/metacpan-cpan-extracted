#
# $Id: Makefile.PL,v 1.2 2005/03/16 13:50:26 pschoo Exp $
# $Source: /cvs-mis/local/web/proxyconf/Makefile.PL,v $
#

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Apache::ProxyConf',
    'VERSION_FROM'	=> 'ProxyConf.pm',
    'PREREQ_PM'		=> { 'Apache::Constants' => 0,
			     'Apache::Log' => 0,
			     'Config::IniFiles' => 0,
			     'Net::IPv4Addr'    => 0,
			   },
    'dist'		=> { PREOP => ('rm -f README; '.
			     'pod2text ProxyConf.pm > README; '.
			     'cp -f README $(DISTNAME)-$(VERSION);')}
);
