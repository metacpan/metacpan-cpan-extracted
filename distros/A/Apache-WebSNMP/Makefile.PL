## -*- Perl -*-

use ExtUtils::MakeMaker qw(WriteMakefile);

WriteMakefile(NAME	   => "Apache::WebSNMP",
	      DISTNAME	   => "Apache-WebSNMP",
	      VERSION_FROM => "lib/Apache/WebSNMP.pm",
	      dist	   => { COMPRESS => "gzip", SUFFIX => "gz" },
	      ($] >= 5.005 ?
	       (ABSTRACT   => "Embed SNMP get statements into HTML documents",
		AUTHOR	   => "Chris Rigby <chris\@savantnet.com>") : ()),
	      );
