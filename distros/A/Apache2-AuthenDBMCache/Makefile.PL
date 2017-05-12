# $Id: Makefile.PL,v 1.8 2006/03/01 21:41:18 reggers Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Apache2::AuthenDBMCache',
   DISTNAME      => 'Apache2-AuthenDBMCache',
   VERSION_FROM  => 'AuthenDBMCache.pm',

   PREREQ_PM     => {
	'strict' => '0',
	'mod_perl2' => '0',
	'Apache2::Access' => '0',
	'Apache2::Log' => '0',
	'Apache2::RequestRec' => '0',
	'Apache2::RequestUtil' => '0',
	'Apache2::Const' => '0',
	'APR::Table' => '0',
	'Carp' => '0',
	'Digest::MD5' => '0',
   },

   dist          => { 
	COMPRESS => "gzip",
	SUFFIX => "gz"
   }
);
