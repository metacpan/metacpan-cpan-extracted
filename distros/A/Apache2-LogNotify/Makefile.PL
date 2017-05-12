require 5.005;
use ExtUtils::MakeMaker ;
use File::Path 'rmtree';
use IO::File;
use Config;
use Cwd;
#
# Created on Dec 04, 2007 by Carlos Rios <carlos.rios@bms.com>
# $Id: Makefile.PL,v 1.1 2007/12/04 15:01:50 rioscb Exp $
WriteMakefile(
              'INSTALLDIRS' => 'perl',
	      'NAME'	   => 'Apache2::LogNotify',
	      'VERSION_FROM' => 'lib/Apache2/LogNotify.pm',
	      'PREREQ_PM'    => {	
                  'Apache2::Const' => '2.000003',
                  'Apache2::Connection' => '2.000003',
                  'Apache2::RequestUtil' => '2.000003',
                  'Apache2::RequestRec' => '2.000003',
                  'Apache2::RequestRec' => '2.000003',
                  'Apache2::ServerRec' => '2.000003',
                  'Apache2::ServerUtil' => '2.000003',
                  'Apache2::Log' => '2.000003',
                  'Apache2::Process' => '2.000003',
                  'APR::Table' => '0.009000',
                  'APR::Finfo' => '0.009000',
                  'Mail::Mailer' => '1.74',
		  'IPC::Cache' => '0.02'
		  },
              'linkext'   => { LINKTYPE => '' },
#	      'PMLIBDIRS' => ['Apache2'],
	      'DISTNAME' => 'Apache2-LogNotify',
	      'dist'           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', }
);
