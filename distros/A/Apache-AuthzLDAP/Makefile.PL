# $Id: Makefile.PL,v 1.3 2003/02/03 23:04:21 cgilmore Exp $

use strict;
use Config qw(%Config);
use ExtUtils::MakeMaker;

WriteMakefile 
  (
   'NAME'         => 'Apache::AuthzLDAP',
   'VERSION_FROM' => 'AuthzLDAP.pm',
   'PREREQ_PM'    => { 'Apache'           => '1.26',
		       'Apache::Log'      => '1.01',
		       'Net::LDAP'        => '0.25',
		       'Text::ParseWords' => '3.2' },
   'dist'         => { 'COMPRESS'         => 'gzip -9f',
		       'SUFFIX'           => 'gz', },
  );
