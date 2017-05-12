# $Id: Makefile.PL,v 1.4 2006/02/27 19:19:44 reggers Exp $

use ExtUtils::MakeMaker;

WriteMakefile(
   NAME          => 'Apache2::AuthenMSAD',
   DISTNAME      => 'Apache2-AuthenMSAD',
   VERSION_FROM  => 'AuthenMSAD.pm',

   PREREQ_PM     => {
       'mod_perl2' => '0',
       'Apache2::Access' => '0',
       'Apache2::Log' => '0',
       'Apache2::RequestRec' => '0',
       'Apache2::RequestUtil' => '0',
       'Apache2::Const' => '0',
       'Net::LDAP' => '0',
       'strict' => '0',
   },

   dist          => { 
        COMPRESS => "gzip",
        SUFFIX => "gz"
   }
);
